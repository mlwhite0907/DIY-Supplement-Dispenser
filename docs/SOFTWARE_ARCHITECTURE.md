# Software Architecture – DIY Supplement Dispenser

High-level software design only. **Implementation lives under `software/` and is owned by the software agent** — this document does not specify pin numbers, libraries, or source files in detail.

Hardware and control intent: [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md).  
Test expectations: [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md).  
Phase plan: [PROJECT_PLAN.md](PROJECT_PLAN.md).

---

## 1. Goals by Phase

| Phase | Software goal |
|-------|----------------|
| **1** | Reliable closed-loop single-powder dose + water + mix from CLI/serial (or minimal UI) |
| **2** | Multi-station dispatch + pill steps in one job |
| **3** | Touchscreen recipes, inventory estimates, optional WiFi |
| **4** | Hardened recovery, cal routines, logging for soak tests |

Phase 1 success is defined by measured mass/volume, not UI polish.

---

## 2. Layered Architecture

```text
┌─────────────────────────────────────────────┐
│  UI / Clients                                 │
│  CLI · Serial REPL · Touch UI (later) · API   │
└─────────────────────┬───────────────────────┘
                      │ commands / job requests
┌─────────────────────▼───────────────────────┐
│  Application services                         │
│  Recipe store · Job runner · Inventory (later)│
└─────────────────────┬───────────────────────┘
                      │
┌─────────────────────▼───────────────────────┐
│  Dispense orchestrator (state machine)        │
│  Preflight → Powder loop → Water → Mix → End  │
└───────────┬─────────────────────┬───────────┘
            │                     │
┌───────────▼──────────┐  ┌───────▼────────────┐
│  Domain policies       │  │  Device adapters    │
│  Tolerances, bursts,   │  │  Scale · Stepper ·  │
│  fault rules           │  │  Vibe · Pump · Mix  │
└────────────────────────┘  └─────────┬──────────┘
                                      │
                            ┌─────────▼──────────┐
                            │  HAL / drivers       │
                            │  GPIO · SPI/I²C ·    │
                            │  HX711 · TMC · PWM   │
                            └────────────────────┘
```

**Rules of thumb:**

- Orchestrator does not bit-bang HX711 directly; it asks a **Scale** port for filtered weight.
- UI never drives motors; it only submits jobs and shows status.
- Hardware pin maps stay in config/HAL — not scattered through recipe code.

---

## 3. Core Modules (Logical)

### 3.1 Scale service

- Raw read → filter (moving average / median / settle detector)
- `tare()`, `read_grams()`, `wait_stable(timeout)`
- Calibration factor load/store
- Faults: unstable, out of range, timeout

### 3.2 Actuator services

| Service | Responsibilities |
|---------|------------------|
| **AugerStepper** | Enable/disable, move steps or timed run, acceleration policy optional |
| **Vibration** | Timed pulses; duty limits so motor is not left on indefinitely |
| **Pump** | Run with max-time guard; optional pulse count input from flow sensor |
| **Mixer** | Timed stir |

Each actuator exposes **safe stop** used by fault paths.

### 3.3 Powder dosing controller

Implements closed loop from [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md):

1. Zero/tare context  
2. Coarse/fine bursts with optional vibe  
3. Settle + measure  
4. Empty/jam detection (no progress)  
5. Final verify vs ±0.1 g (configurable)

Outputs: measured grams, burst stats, status enum.

### 3.4 Water dosing controller

Strategy interface:

- `TimedWaterStrategy`
- `FlowSensorWaterStrategy` (optional)
- `WeightWaterStrategy` (preferred upgrade path)

All strategies accept target ml (or g), timeouts, and abort callbacks.

### 3.5 Orchestrator / state machine

Suggested states:

```text
IDLE → PREFLIGHT → TARE → DOSE_POWDER → VERIFY_POWDER
     → DOSE_WATER → MIX → COMPLETE
     → FAULT (from any) → IDLE (after ack)
```

Illegal transitions should be rejected (e.g. no dosing from FAULT without clear).

### 3.6 Recipe and job models

Align with recipe outline in system architecture:

- Phase 1: hardcoded or single JSON recipe (`powder_g`, `water_ml`, `mix_ms`)
- Later: multi-ingredient list + station map

`DispenseJob` records targets, measurements, timestamps, faults for logging.

### 3.7 Logging

- Append-only session log (CSV or JSON lines): enough to complete [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md) 20× series without handwritten tables
- Log calibration events and software version label

---

## 4. Configuration

Prefer a single config surface (file or env) for:

- GPIO / bus assignments (owned by implementer)
- Scale calibration factor path
- Burst defaults (coarse/fine thresholds, settle ms, jam K)
- Water strategy + calibration constants (ml/s or pulses/ml)
- Tolerances (powder_g, water_ml)
- Cup empty / max weight thresholds

Secrets are not expected in Phase 1; WiFi credentials appear only if Phase 3 remote control is added.

---

## 5. Concurrency and Real-Time Notes

- Prefer **one** owner thread/task for the orchestrator; actuators are not commanded from multiple clients concurrently.
- Scale reads may be continuous in a background task with a thread-safe latest sample.
- UI input should queue “start job” / “abort” rather than re-enter the state machine.
- Soft real-time is enough; settle windows are hundreds of ms, not microsecond control loops.

---

## 6. Failure Handling (Software)

| Fault | Software behavior |
|-------|-------------------|
| NO_CUP | Refuse start; actuators off |
| SCALE_FAULT | Abort job; request recal |
| JAM / EMPTY | Stop auger/vibe; surface clear/refill |
| LOW_WATER / PUMP_TIMEOUT | Stop pump; abort or pause per policy |
| OVERFILL | Emergency stop all |
| USER_ABORT | Immediate safe stop; mark job aborted |

Faults are first-class job outcomes, not exceptions swallowed silently.

---

## 7. Testing Support Hooks

Software should make protocol tests easy:

- **Open-loop command:** fixed steps/time without closed loop  
- **Closed-loop command:** full powder controller  
- **Water-only command**  
- **Full recipe command**  
- **Calibrate scale** interactive or scripted  
- Export last N runs for the 20× matrices  

Unit tests can mock Scale/Actuators; bench tests use real HAL behind the same interfaces.

---

## 8. UI Progression

| Stage | Interface |
|-------|-----------|
| Phase 1a | CLI: `cal`, `dose 3`, `water 250`, `drink demo` |
| Phase 1b | Optional simple touch buttons mirroring CLI |
| Phase 3 | Recipe browser, progress, inventory warnings |
| Later | Optional local web UI / phone on LAN |

---

## 9. Explicit Non-Goals (Software Doc)

- No pinout tables here (avoid conflicting with hardware docs)
- No full class diagrams required before first CLI works
- No cloud backend for Phase 1
- No medical dosing decision logic or “recommended daily allowance” engines

---

## 10. Handoff to Software Agent

Implement against this architecture and system control loops:

1. HAL + scale cal + open-loop step  
2. Closed-loop powder meeting test protocol hooks  
3. Water strategy + mix  
4. Single-command full drink  
5. Logging sufficient for 20× campaigns  

Mechanical geometry remains constrained by [PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md); software adapts burst parameters to real flow, not the other way around, until tests fail hard enough to justify CAD revision (decision D4 in the project plan).
