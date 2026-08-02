# Module: Powder Station (Phase 1)

Single hopper + auger feed with vibration assist. Controlled by the Pi via TMC2209 and a MOSFET-driven coin motor.

Mechanical CAD constraints (hopper angles, auger dims): [docs/PHASE1_DESIGN_HANDOFF.md](../../docs/PHASE1_DESIGN_HANDOFF.md).  
Electrical pin map: [../PINOUT.md](../PINOUT.md).

---

## 1. Function

1. Hold dry supplement powder in a steep conical hopper.  
2. Meter powder with a 3D-printed Archimedes auger driven by **NEMA17**.  
3. Pulse a **coin vibration motor** to break bridges / ratholes.  
4. Drop powder into a cup on the scale platform for **closed-loop** mass control.

Phase 1 success: 1–10 g targets within **±0.1 g** after settle (see project handoff).

---

## 2. Bill of Electrical Parts (This Module)

| Item | Spec | Notes |
|------|------|-------|
| NEMA17 stepper | 42×42 mm face, 31 mm hole pattern, 5 mm shaft, ~1.5 A max class | Use current well below max |
| TMC2209 driver board | STEP/DIR standalone capable, 12 V VM, 3.3 V VIO | BTT / Fysetc / clone OK if pinout verified |
| Coin / pancake vibe motor | **Default 5 V**, Ø10–12 mm × ~2.5–3.5 mm | 12 V variants exist — see §5 |
| N-MOSFET switch | Logic-level, ≥ 2 A | Discrete or module |
| Flyback diode | 1N5819 or 1N4007 across vibe | If not on module |
| Wiring | 4-wire motor cable + Dupont logic | See [../WIRING.md](../WIRING.md) |
| Coupling | Printed set-screw or flexible 5 mm | Shaft to auger |

---

## 3. Control Interface

| Signal | BCM | Active | Description |
|--------|-----|--------|-------------|
| STEP | 12 | Rising edge | One microstep per edge (per MS jumpers) |
| DIR | 13 | Level | CW / CCW — define “dispense” direction in software once |
| EN | 16 | **LOW = enabled** (typical ENN) | HIGH = high-Z coils / freewheel |
| VIBE | 17 | HIGH = on (if low-side N-FET) | PWM optional for intensity |

**Safe defaults at boot:** EN = HIGH (disabled), VIBE = LOW, no STEP stream.

---

## 4. TMC2209 — Phase 1 Configuration

### 4.1 Mode: STEP/DIR standalone

| Item | Choice |
|------|--------|
| UART | **Not used** in Phase 1 |
| Microstep | Start **1/8** or **1/16** (MS jumpers per board silkscreen) |
| SpreadCycle / stealth | Board default (often stealth via CFG pins) |
| Current | Trimpot: start low; raise until no skipped steps under powder |

### 4.2 Standalone vs UART

| | STEP/DIR (Phase 1) | UART (later) |
|--|--------------------|--------------|
| Wiring | STEP, DIR, EN only | PDN_UART + GND + optional TX path |
| Software | gpiozero / pigpio pulse | `tmc` libs, serial |
| Tuning | Pot + jumpers | Runtime current, CoolStep, diag |
| Recommendation | **Ship Phase 1 on STEP/DIR** | Add UART if noise/heat/diagnostics need it |

### 4.3 Power pins

| Pin | Connect |
|-----|---------|
| VM | +12 V fused |
| GND | GND star |
| VIO | Pi 3.3 V |
| Motor A/B | NEMA17 coil pairs (metered) |

**Never** feed VM from the Pi.

### 4.4 Enable polarity

Most silent-stepper boards use **ENN active low**. Confirm with a meter: ENN pulled low → motor holds. Document any inverted clone board in a sticky note on the chassis.

---

## 5. Vibration Motor

### 5.1 Default: 5 V coin vibe

```
+5V_AUX ---- motor +
motor − ---- MOSFET drain
MOSFET source ---- GND
GPIO17 ---- Rg ---- gate (+ Rpd to GND)
Diode across motor (cathode to +)
```

Mount in printed pocket on hopper cone or barrel inlet region so vibration couples into powder, not only into the NEMA17 frame.

### 5.2 Alternate: 12 V coin / cylinder vibe

Same MOSFET topology; motor + on **+12V_FUSED**. Confirm:

- Motor rated voltage  
- MOSFET Vds ≥ 20 V  
- Higher flyback energy — diode mandatory  

Prefer 5 V for Phase 1 (lower power, safer near Pi 5 V aux).

### 5.3 Drive pattern (software contract)

Typical anti-bridge pattern (not exclusive):

- Short vibe pulses (50–150 ms) between or during slow auger bursts  
- Avoid continuous vibe during final 0.2 g approach (scale noise)  
- Always stop vibe before final settle weight reading  

---

## 6. Mechanical–Electrical Interfaces

| Interface | Requirement |
|-----------|-------------|
| NEMA17 mount | 31 mm hole spacing; screws must not bottom into windings |
| Shaft | 5 mm; coupling with set screw on flat if present |
| Wire path | Channel from vibe pocket so motor can be replaced without full teardown |
| Outlet height | ~40–60 mm above cup/scale for clean drop (handoff) |
| Isolation | Station body should not rest on the load-cell platform |

The powder station is **not** weighed in Phase 1 — only the collection cup is. Do not rigidly couple the auger outlet to the cup.

---

## 7. Dosing Control Loop (Hardware Implications)

```
while mass < target - settle_margin:
    enable stepper
    step N pulses (or T ms)
    optional vibe pulse
    disable or pause
    wait settle_ms
    read HX711
finalize: verify within ±0.1 g
```

Hardware must support:

- Fast enable/disable without brownout  
- Clean STEP edges (short wires, GND solid)  
- Scale reading not destroyed by EMI (cable routing)

---

## 8. Bring-Up Checklist

- [ ] Coil pairs identified with multimeter  
- [ ] VIO = 3.3 V, VM = 12 V, EN disabled  
- [ ] Hand-spin free with EN high (disabled)  
- [ ] Slow step sequence, correct dispense direction (powder moves toward outlet)  
- [ ] Current pot adjusted under light load  
- [ ] Vibe fires without Pi reboot  
- [ ] 10-minute idle enabled: driver and motor only warm, not hot  
- [ ] Dry powder test into cup on scale; no cable snag  

---

## 9. Failure Modes

| Symptom | Likely cause |
|---------|--------------|
| Motor buzzes, no rotation | Current too low; wrong microstep; EN polarity; coil miswire |
| Motor very hot quickly | Current too high; always enabled at full current |
| Steps skip under powder | Current low; microstep too fine; auger jam; voltage sag |
| Scale jumps when motor runs | Shared ground daisy-chain; cable coupling — reroute |
| Vibe always on at boot | Missing gate pulldown; GPIO default; inverted module |
| Powder bridges | Increase vibe duty; check hopper angle (mechanical) |

---

## 10. Phase 2 Note

Each additional powder station needs its own TMC2209 (or multi-driver board), STEP/DIR/EN trio, and vibe MOSFET. GPIO map reserves free pins (19/20/21/26) for a second station — see [../PINOUT.md](../PINOUT.md) §7.

---

## Revision

| Rev | Date | Notes |
|-----|------|-------|
| 1.0 | 2026-08-02 | Initial powder station electrical module doc |
