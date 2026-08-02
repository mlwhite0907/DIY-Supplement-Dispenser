# Software Architecture – DIY Supplement Dispenser

High-level software design aligned with the **Phase 1 implementation** under `software/`. Pin numbers live in [hardware/PINOUT.md](../hardware/PINOUT.md) and `software/config/default.yaml` — not duplicated as a second source of truth here.

Hardware and control intent: [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md).  
Test expectations: [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md).  
Phase plan: [PROJECT_PLAN.md](PROJECT_PLAN.md).

---

## 1. Goals by Phase

| Phase | Software goal |
|-------|----------------|
| **1** | Reliable closed-loop single-powder dose + **open-loop timed water** + **settle delay** from CLI / local API |
| **2** | Multi-station dispatch + pill steps in one job |
| **3** | Touchscreen recipes, inventory estimates, optional WiFi |
| **4** | Hardened recovery, cal routines, logging for soak tests |

Phase 1 success is defined by measured mass and **calibrated** water volume, not UI polish.  
**Powder goal:** ±0.1 g after settle. **Water:** timed dose checked with a graduated cylinder / scale — not automatic closed-loop volume.

---

## 2. Layered Architecture

```text
┌─────────────────────────────────────────────┐
│  UI / Clients                                 │
│  CLI · FastAPI (localhost) · touch later      │
└─────────────────────┬───────────────────────┘
                      │ commands / job requests
┌─────────────────────▼───────────────────────┐
│  Application services                         │
│  Recipe store (SQLite) · DispenseCycle · logs │
└─────────────────────┬───────────────────────┘
                      │
┌─────────────────────▼───────────────────────┐
│  DispenseCycle (linear script)                │
│  Preflight → powder → water → mix_delay → end │
└───────────┬─────────────────────┬───────────┘
            │                     │
┌───────────▼──────────┐  ┌───────▼────────────┐
│  Domain controllers    │  │  Hardware ports     │
│  PowderDoser           │  │  Scale · Stepper ·  │
│  WaterDoser (timed)    │  │  Vibe · Pump · I/O  │
│  ScaleService          │  │                     │
└────────────────────────┘  └─────────┬──────────┘
                                      │
                            ┌─────────▼──────────┐
                            │  HAL / drivers       │
                            │  sim or Pi GPIO      │
                            └────────────────────┘
```

**Rules of thumb:**

- Controllers do not bit-bang HX711 directly; they use **ScaleService** for filtered weight.
- CLI/API never drive motors outside `DispenseCycle` / dosers; they submit jobs and show status.
- Hardware pin maps stay in config/HAL — not scattered through recipe code.

---

## 3. Real Module Names (Phase 1 package)

Implementation package: `dispenser` under `software/src/dispenser/`.

| Logical role | Module / class |
|--------------|----------------|
| Config load | `config.py` + `config/default.yaml` |
| Models | `models.py` — `Recipe`, `Ingredient`, `DispenseResult`, `CycleResult` |
| DB | `db.py` — SQLite recipes, inventory, logs |
| Runtime wiring | `main.py` — `DispenserRuntime` |
| Scale helper | `control/scale_service.py` — `ScaleService` |
| Powder closed-loop | `control/powder_dose.py` — `PowderDoser` |
| Water timed dose | `control/water_dose.py` — `WaterDoser` |
| Full recipe | `control/dispense_cycle.py` — `DispenseCycle` |
| Calibration helpers | `control/calibration.py` — `CalibrationService` |
| Hardware ports | `hardware/base.py` (+ `sim.py`, `scale_hx711.py`, `stepper_tmc.py`, `vibration.py`, `pump.py`, `sensors.py`) |
| REST | `api/app.py` — FastAPI factory |
| CLI | `cli.py` / `__main__.py` |

---

## 4. Core Behaviors (As Implemented)

### 4.1 ScaleService

- Averaged / settled reads over the scale backend
- `tare()`, gram reads, settle helpers
- Calibration factor via config / calibration service

### 4.2 Actuators (ports)

| Port | Responsibilities |
|------|------------------|
| **StepperMotor** | Enable/disable, timed run (forward/reverse for jam reverse-auger) |
| **VibrationMotor** | On/off (or soft PWM duty); dosing uses **short pulses**, not continuous vibe for the whole dose |
| **Pump** | Timed run with calibrated `ml_per_second`; max-time style guards in doser |
| **DigitalSensor** | Cup present, tank level; **flow pin reserved** for future use |

There is **no mixer motor driver** in Phase 1.

### 4.3 PowderDoser (closed-loop mass)

1. Optional tare  
2. Auger bursts; **pulse** vibration assist between/during bursts  
3. Settle + measure; adapt burst length near target  
4. Jam path: no progress → reverse-auger, retry, then fault  
5. Final settle + verify vs configurable tolerance (**goal ±0.1 g**)

Outputs: measured grams, success flag, message (including jam retries).

### 4.4 WaterDoser (open-loop timed only)

**Phase 1 reality:** water is **open-loop timed** using `pump.ml_per_second` (and config timeout factor / tolerance for estimated actual).

- **Implemented:** `WaterDoser` timed run; optional **level** sensor refuse if empty  
- **Not implemented as dosing strategies:** no `FlowSensorWaterStrategy`, no `WeightStrategy` / weight-of-water closed loop  
- **GPIO22 flow pin:** reserved in pinout/config for a **future** pulse-count path; not required for Phase 1 success  

Accuracy is achieved by **calibrating** `ml_per_second` against a graduated cylinder or scale, then re-checking after tubing/tank changes — not by automatic closed-loop volume.

### 4.5 DispenseCycle — linear script, not a full FSM

`DispenseCycle` is a **linear script** with interlocks, not a formal multi-state machine with transition tables.

Typical flow:

```text
cup check (if required)
  → for each powder ingredient: PowderDoser.dose(...)
  → for each water ingredient: WaterDoser.dose(...)
  → mix_delay = time.sleep only
  → log CycleResult
```

| Feature | Phase 1 behavior |
|---------|------------------|
| **Cup check** | Optional `cup_sensor`; refuse start when `require_cup` and cup missing |
| **E-stop** | Hardware pin reserved (GPIO25); safe-stop policy in wiring docs — cycle aborts / refuses work when interlocks fail |
| **Concurrency lock** | One job at a time (do not run concurrent cycles against the same hardware) |
| **mix_delay** | **`time.sleep(mix_delay_seconds)` only** — **no mixer motor**, no stir GPIO |
| **Faults** | Failed powder/water step stops the cycle and logs; actuators should be left off by dosers |

There is no separate `IDLE / PREFLIGHT / DOSE_* / FAULT` enum FSM in the Phase 1 code path. Document later phases as “add recovery states” if needed — do not claim a full FSM today.

### 4.6 Recipe and job models

- Recipes in SQLite (`Recipe` + `Ingredient` with kind powder | water | …)
- Phase 1 demos: e.g. `creatine_water` with powder grams + water ml
- `DispenseResult` / `CycleResult` carry targets, actuals, messages, duration for logs

### 4.7 Logging

- SQLite session logs via `Database.add_log` — enough for [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md) campaigns without handwritten-only tables
- Log success, messages, step payloads, duration

---

## 5. Configuration

Single YAML surface (`software/config/default.yaml`, override with `DISPENSER_CONFIG`):

- GPIO / bus assignments (BCM; match [PINOUT](../hardware/PINOUT.md))
- Scale calibration factor and sample counts
- Powder burst / settle / jam parameters
- Water: `ml_per_second` on pump, timeout factor, tolerance_ml (for estimated check)
- Cycle: `mix_delay_seconds`, `require_cup`
- Database path
- API host/port

`DISPENSER_SIM=1` forces simulation backends (Mac/CI).

---

## 6. API (Phase 1)

- **FastAPI** app from `api/app.py` (`create_app`)
- **Default use case: localhost** — bind to loopback for bench use (`127.0.0.1`); do not assume the API is hardened for the public internet
- **Optional token:** when exposing beyond loopback, require a configured bearer/API token (optional; empty = no auth on local-only bind)
- Typical endpoints: `/health`, `/recipes`, `/dispense`, `/inventory`, `/logs`, OpenAPI at `/docs`

CLI remains the primary bring-up path (`python -m dispenser …`).

---

## 7. Concurrency and Real-Time Notes

- Prefer **one** owner of the cycle at a time; actuators are not commanded from multiple clients concurrently (use a process/job lock around `run_recipe`).
- Soft real-time is enough; settle windows are hundreds of ms, not microsecond control loops.
- UI/API should queue “start job” / fail busy rather than re-enter the cycle mid-dose.

---

## 8. Failure Handling (Software)

| Fault | Software behavior |
|-------|-------------------|
| NO_CUP | Refuse start; actuators off |
| SCALE / dose out of tolerance | Fail step; cycle stops; log |
| JAM / empty (no progress) | Reverse-auger retries then fail powder step |
| LOW_WATER / level | Water doser refuses or aborts when level sensor says empty |
| PUMP error / uncalibrated rate | Fail water step if `ml_per_second` ≤ 0 or pump throws |
| USER abort / E-stop | Immediate safe stop (disable stepper, vibe/pump off) |
| OVERFILL | Product policy later; refuse extreme targets in config if added |

Faults are first-class job outcomes, not exceptions swallowed silently.

---

## 9. Testing Support Hooks

- Sim mode: full stack without GPIO (`DISPENSER_SIM=1`)
- CLI: `dose-powder`, `dose-water`, `run-recipe`, calibrate helpers
- `pytest` under `software/tests/` (hardware-free)
- Water accuracy tests need a **graduated cylinder** on real hardware (open-loop)

---

## 10. UI Progression

| Stage | Interface |
|-------|-----------|
| Phase 1a | CLI: dose powder/water, run recipe, serve API |
| Phase 1b | Optional simple touch buttons mirroring CLI |
| Phase 3 | Recipe browser, progress, inventory warnings |
| Later | Optional local web UI / phone on LAN (token recommended) |

---

## 11. Explicit Non-Goals / Non-Claims

- **No** implemented flow-sensor or weight-of-water strategy classes as Phase 1 dosing
- **No** mixer motor control — `mix_delay` is sleep only
- **No** full formal FSM for the cycle
- No pinout tables here (see hardware docs)
- No cloud backend for Phase 1
- No medical dosing decision logic

---

## 12. Handoff to Software Agent

Implement / keep aligned with:

1. HAL + scale cal + open-loop powder characterization  
2. Closed-loop `PowderDoser` meeting test protocol hooks (±0.1 g **goal**)  
3. Timed `WaterDoser` + calibrated `ml_per_second`  
4. Linear `DispenseCycle` with cup / e-stop awareness and single-job lock  
5. Local FastAPI + optional token; SQLite logging for 20× campaigns  

Mechanical geometry remains constrained by [PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md); software adapts burst parameters to real flow, not the other way around, until tests fail hard enough to justify CAD revision (decision D4 in the project plan).
