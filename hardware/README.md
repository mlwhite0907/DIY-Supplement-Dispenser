# Hardware – Phase 1 Electrical & Module Design

**Scope:** Single powder station + cup scale + water system on a Raspberry Pi 5 (Pi 4 compatible).  
**Goal:** Document every signal, power path, connector, and safety rule needed to wire and power the Phase 1 test rig without guessing.

Related project docs:

| Doc | Purpose |
|-----|---------|
| [docs/PROJECT_PLAN.md](../docs/PROJECT_PLAN.md) | Build phases and success criteria |
| [docs/PHASE1_DESIGN_HANDOFF.md](../docs/PHASE1_DESIGN_HANDOFF.md) | Mechanical powder-module CAD constraints |
| [docs/BOM.md](../docs/BOM.md) | Parts list (high level) |
| [3d_models/README.md](../3d_models/README.md) | Printable mechanical parts |

---

## Document Index

| File | Contents |
|------|----------|
| [PINOUT.md](PINOUT.md) | BCM GPIO assignment table, reserved buses, HAT-safe notes |
| [WIRING.md](WIRING.md) | Wire colors, connectors, per-subsystem harnesses, build order |
| [ELECTRICAL_SCHEMATIC.md](ELECTRICAL_SCHEMATIC.md) | ASCII + Mermaid signal/power schematics, MOSFET notes, safety |
| [POWER_BUDGET.md](POWER_BUDGET.md) | PSU sizing, current peaks, fusing, rails |
| [modules/powder_station.md](modules/powder_station.md) | NEMA17 + TMC2209 + vibration motor |
| [modules/water_system.md](modules/water_system.md) | Peristaltic pump, float, flow sensor, tank |
| [modules/scale_platform.md](modules/scale_platform.md) | HX711 + 5 kg load cell + cup-present IR |
| [docs/diagrams/wiring_phase1.mmd](../docs/diagrams/wiring_phase1.mmd) | Mermaid wiring overview (source) |
| [docs/diagrams/power_tree.mmd](../docs/diagrams/power_tree.mmd) | Mermaid power distribution tree (source) |

---

## Phase 1 Controlled Devices

| # | Device | Interface | Power | Drive method |
|---|--------|-----------|-------|--------------|
| 1 | HX711 + 5 kg load cell (cup scale) | 2× GPIO (DT, SCK) | 3.3 V or 5 V from Pi / regulated rail | Bit-bang or library |
| 2 | NEMA17 stepper via TMC2209 | STEP / DIR / EN GPIO | **12 V** motor; logic from Pi 3.3 V | STEP/DIR standalone (Phase 1) |
| 3 | Coin vibration motor | 1× GPIO → MOSFET | **5 V default** (document 12 V option) | N-channel MOSFET low-side |
| 4 | 12 V peristaltic pump | 1× GPIO → MOSFET or relay | **12 V** | MOSFET preferred; relay OK |
| 5 | Float level sensor (optional) | 1× GPIO input | Pull-up / dry contact | Digital input |
| 6 | Flow sensor (optional) | 1× GPIO interrupt | 5 V module typical | Pulse counting |
| 7 | Cup-present IR sensor (optional) | 1× GPIO input | 3.3 V or 5 V (level-safe) | Digital input |
| 8 | E-stop (optional) | 1× GPIO input | Pull-up, NC preferred | Latched software disable |

**Hard rule:** Never drive motors, pumps, or inductive loads from Pi GPIO pins. GPIO only provides **logic-level control** into drivers/MOSFETs with a **common ground**.

---

## Recommended Power Architecture

**Preferred (Phase 1):**

```
Wall AC
  ├── Official Raspberry Pi USB-C PSU  →  Pi 5 / Pi 4 only
  └── 12 V bench / brick PSU (fused)   →  TMC2209 VM, pump, (optional 12 V vibe)
         └── Optional buck 12 V→5 V     →  coin vibe, some sensors (if not from Pi 5 V)
```

Rationale:

- Pi gets a clean, rated supply (especially important for Pi 5 USB-C PD behavior).
- Motor/pump noise stays on the 12 V rail; common ground only at a single star point.
- Avoids starving the Pi when the stepper or pump stalls.

See [POWER_BUDGET.md](POWER_BUDGET.md) and [docs/diagrams/power_tree.mmd](../docs/diagrams/power_tree.mmd).

---

## Suggested Phase 1 GPIO Map (Summary)

BCM numbering. Full table and rationale: [PINOUT.md](PINOUT.md).

| Function | BCM GPIO | Notes |
|----------|----------|-------|
| HX711 DT | 5 | Data |
| HX711 SCK | 6 | Clock |
| Stepper STEP | 12 | PWM-capable (hardware PWM channel) |
| Stepper DIR | 13 | PWM-capable pair with 12 |
| Stepper EN | 16 | Active-low on most TMC2209 boards |
| Vibe MOSFET | 17 | Low-side switch |
| Pump MOSFET | 27 | Low-side switch |
| Flow sensor | 22 | Interrupt-friendly |
| Level float | 23 | Input + pull-up |
| Cup present | 24 | Input |
| E-stop (optional) | 25 | Input, NC to GND recommended |

**Reserved / do not use for Phase 1 actuators:**

- **I2C:** GPIO 2 (SDA), GPIO 3 (SCL) — future HATs, OLED, temp sensors
- **SPI:** GPIO 7–11 — keep free unless an SPI device is added
- **UART:** GPIO 14/15 — console / future TMC UART or debug
- **ID EEPROM:** GPIO 0/1 — HAT ID; leave alone

---

## Safety Checklist (Wire Before First Power-On)

- [ ] Common **GND** between Pi and 12 V PSU (single star point near the distribution block)
- [ ] **No** motor/pump current through Pi 3.3 V or 5 V pins
- [ ] **Fuse** (or polyfuse + fuse holder) on 12 V positive near the PSU
- [ ] Flyback **diode** across pump and any discrete inductive load if using discrete MOSFETs (relay modules often include this)
- [ ] MOSFET gates have series resistor (~100–220 Ω) and gate-source pulldown (~10–100 kΩ)
- [ ] TMC2209 **VM** = 12 V; **VIO** = 3.3 V (or board jumper for 3.3 V logic)
- [ ] Load cell platform mechanically isolated; wires strain-relieved
- [ ] E-stop or software kill path disables EN + MOSFET gates on fault
- [ ] ESD: handle HX711/Pi by edges; ground yourself on metal frame before plugging ribbon cables

---

## Module Overview

### Powder station
Hopper + 3D-printed auger driven by **NEMA17** on **TMC2209** (STEP/DIR). Coin vibe motor on hopper/barrel for anti-bridge. Details: [modules/powder_station.md](modules/powder_station.md).

### Scale platform
**5 kg** bar or single-point load cell → **HX711** → Pi. Cup sits on free end of cell. Closed-loop dosing: run auger/vibe until target mass. Details: [modules/scale_platform.md](modules/scale_platform.md).

### Water system
Refillable tank → **12 V peristaltic** (or diaphragm) pump → optional **flow sensor** → dispense into cup. **Float** for low-water interlock. Details: [modules/water_system.md](modules/water_system.md).

---

## Build Sequence (Electrical)

1. Bench power: verify 12 V PSU voltage and fuse; verify Pi boots on official PSU alone.
2. Wire **common GND** and distribution block; leave loads disconnected.
3. HX711 + load cell only → bring-up and calibrate with 50 g / 100 g weights.
4. TMC2209 + NEMA17 (no powder) → direction, enable polarity, gentle current limit.
5. MOSFET + coin vibe on 5 V rail.
6. MOSFET + pump dry-run (or water loop into a bucket), then flow/float sensors.
7. Cup-present IR last; integrate software interlocks (no dispense without cup, no pump if low water).

---

## Phase 1 Non-Goals (Hardware)

- Multi-station daisy-chained steppers / shared bus
- TMC2209 UART stealthChop tuning (optional later; STEP/DIR first)
- Hard plumbing / mains solenoid valves
- Full vending enclosure electrical certification

---

## Revision

| Rev | Date | Notes |
|-----|------|-------|
| 1.0 | 2026-08-02 | Initial Phase 1 electrical package |
