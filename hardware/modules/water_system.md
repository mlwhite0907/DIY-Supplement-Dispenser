# Module: Water System (Phase 1)

Refillable tank, 12 V pump, optional flow and level sensing. No hard plumbing to building water.

Pin map: [../PINOUT.md](../PINOUT.md) · Power: [../POWER_BUDGET.md](../POWER_BUDGET.md).

---

## 1. Function

1. Store water in a **removable food-safe tank** (2–5 L target class).  
2. Dose water into the collection cup with a **12 V peristaltic** (preferred) or diaphragm pump.  
3. **Phase 1 dosing: open-loop timed** only (`ml_per_second` calibration).  
4. GPIO **flow pulse pin reserved** for a future sensor path — not required for Phase 1 software.  
5. Interlock on **low level** via float (or capacitive) switch when fitted.  
6. Drip tray under dispense area (mechanical).

Phase 1 success: **calibrated timed** repeatable volume (verify with graduated cylinder) without leaks or dry-run damage — not automatic closed-loop volume.

---

## 2. Electrical Parts

| Item | Spec | Notes |
|------|------|-------|
| Peristaltic pump | 12 V DC, food-grade tubing path | Flow rate varies by model — calibrate |
| MOSFET or relay module | Logic-level from 3.3 V GPIO | MOSFET preferred for soft on/off |
| Flyback diode | Across pump | If discrete MOSFET |
| Float level switch | Dry contact, PP/food-safe | Mount near tank low point |
| Flow sensor (optional) | Hall pulse, e.g. YF-S201 class or smaller | Match tubing ID |
| Tubing / check valve | Food-safe silicone/PVC as appropriate | Prevent back-drain |
| Inline connector | 2-pin for pump | Serviceable |

---

## 3. Control & Sense Pins

| Function | BCM | Type | Notes |
|----------|-----|------|-------|
| Pump drive | **27** | OUT | HIGH → MOSFET on → pump runs (confirm module polarity) |
| Flow pulses | **22** | IN / interrupt | Rising edge count |
| Level float | **23** | IN pull-up | Define “empty” polarity in software |
| Cup present | **24** | IN | **Interlock:** do not pump without cup |
| E-stop | **25** | IN | Force pump off |

---

## 4. Pump Drive Circuit

### 4.1 MOSFET (preferred)

```
+12V_FUSED ---- pump +
pump − ---- MOSFET drain
source ---- GND_STAR
GPIO27 --[150Ω]-- gate --[47k]-- GND
Diode: cathode @ pump +, anode @ pump −
```

### 4.2 Relay module (acceptable)

- Use opto-isolated module if available.  
- Pump on COM/NO of relay; coil supply per module (often 5 V **JD-VCC** — not Pi 3.3 V).  
- GPIO27 → IN. Note active-LOW modules (common on cheap boards): software may invert.

### 4.3 Soft-start (optional)

PWM on GPIO27 at a few hundred Hz can reduce inrush; many peristaltic pumps are fine with hard on. If PWM is used, ensure MOSFET thermal OK and flyback still present.

---

## 5. Dosing Strategies

| Method | Phase 1 status | How | Notes |
|--------|----------------|-----|--------|
| **Timed** | **Implemented / primary** | Pump ON for T s after calibration | Drift with head height, voltage, tube wear |
| **Flow count** | Future (pin reserved) | N pulses ≈ volume | Not Phase 1 software |
| **Weight-of-water** | Future | Closed-loop on HX711 Δmass | Not Phase 1 software |

**Calibration (required for open-loop accuracy):**

1. Prime tubing; no air.  
2. Dispense into **graduated cylinder** (or scale, 1 g ≈ 1 ml water).  
3. Record `ml_per_second`.  
4. Store in software config (`hardware.pump.ml_per_second`). Re-check after tubing or tank-height changes.

---

## 6. Flow Sensor Wiring

Typical 3-wire Hall sensor:

| Wire | Connect |
|------|---------|
| Red / VCC | 5 V (check max 5 V) |
| Black / GND | GND star |
| Yellow / OUT | GPIO22 via divider if 5 V logic |

```
5V pulse ----[10k]----+---- GPIO22
                      |
                     [20k]
                      |
                     GND
```

(Adjust divider for your sensor HIGH level; open-collector sensors may only need pull-up to 3.3 V.)

**Software:** count edges during pump window; abort if zero pulses while pump ON (dry / disconnected).

---

## 7. Float Level Sensor

| Style | Wiring |
|-------|--------|
| 2-wire float | GPIO23 pull-up to 3.3 V; other side to GND when closed |
| 3-wire electronic | Follow module VCC/OUT/GND; keep OUT ≤ 3.3 V |

**Recommended software meaning (document in config):**

```text
LEVEL_OK   = water present = switch closed = GPIO LOW
LEVEL_EMPTY = open = GPIO HIGH → refuse pump, alert user
```

Invert if your float is mounted upside-down (common).

**Interlock:** `pump_allowed = cup_present and level_ok and not estop`.

---

## 8. Hydraulic Layout (Electrical-Relevant)

```
[ Removable tank ]
       |
   [ Float at low level ]
       |
   [ Pump inlet ]
       |
   [ 12V peristaltic ]
       |
   [ Check valve ]
       |
   [ Flow sensor (optional) ]
       |
   [ Outlet nozzle → cup ]
       |
   [ Drip tray ]
```

- Keep pump **below** or primed relative to water line per pump type (peristaltic is self-priming within limits).  
- Nozzle fixed relative to cup; do not rest plumbing weight on the **scale platform**.  
- Strain-relieve wires at pump so vibration does not fatigue solder.

---

## 9. Safety

| Hazard | Mitigation |
|--------|------------|
| Dry run overheat | Float interlock + max pump ON time software cap |
| Overflow cup | Volume limit; cup-present sensor; drip tray |
| Leak onto electronics | Route water path away from Pi/TMC; drip tray lips; no 12 V splices under tank |
| MOSFET failure ON | E-stop cuts enable path in software; prefer fuse; never leave unattended long runs in prototype |
| Contaminated water | Food-safe materials; user-cleanable tank |

**Electrical:** pump current only through 12 V bus and MOSFET/relay — never through Pi GPIO.

---

## 10. Bring-Up Checklist

- [ ] Tank empty: float reports EMPTY  
- [ ] Tank filled: float reports OK  
- [ ] Pump bench-test into bucket with MOSFET only (no Pi duty cycle mistakes)  
- [ ] Measure run current @ 12 V; confirm fuse rating  
- [ ] Calibrate timed dose (e.g. 100 ml) three times  
- [ ] If flow sensor: calibrate pulses/ml  
- [ ] Cup-present false → pump command rejected  
- [ ] E-stop → pump off within one control loop  

---

## 11. Failure Modes

| Symptom | Likely cause |
|---------|--------------|
| Pump silent | EN/polarity; fuse; MOSFET wiring; empty interlock |
| Pump hums weak | Voltage sag; worn tube; wrong supply (5 V by mistake) |
| Volume short | Air leak; tube slip in pump head; calibration drift |
| Pi reboots on pump start | PSU too small; missing bulk cap; ground issue |
| Flow count zero | Sensor unpowered; wrong edge; debris; not level-shifted |

---

## Revision

| Rev | Date | Notes |
|-----|------|-------|
| 1.0 | 2026-08-02 | Initial water system electrical module doc |
| 1.1 | 2026-08-02 | Align with Phase 1 open-loop timed water; flow as future pin |
