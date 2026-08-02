# Phase 1 Power Budget

Sizing for the dual-PSU architecture (official Pi USB-C + separate fused 12 V).  
Schematics: [ELECTRICAL_SCHEMATIC.md](ELECTRICAL_SCHEMATIC.md) · Tree: [docs/diagrams/power_tree.mmd](../docs/diagrams/power_tree.mmd).

---

## 1. Rails Overview

| Rail | Source | Used by | Isolation notes |
|------|--------|---------|-----------------|
| **Pi internal 5 V / 3.3 V** | Official USB-C PSU | SoC, USB, GPIO logic, HX711 (3.3 V), TMC **VIO** only | Do not share with motor current |
| **+12 V fused** | Bench/brick PSU | TMC **VM**, peristaltic pump, optional 12 V vibe | Primary actuator rail |
| **+5 V aux** | Pi 5 V header **or** 12→5 buck | Default coin vibe, some sensors | If from Pi header, keep total draw modest |

**Preferred:** Pi never supplies pump or stepper coil current. Coin vibe at ~50–100 mA from Pi 5 V is acceptable for Phase 1; move vibe to a buck if you see brownouts.

---

## 2. Load Table (Design Estimates)

Currents are **typical working values** for budgeting. Measure yours after assembly.

### 2.1 Raspberry Pi rail (official PSU)

| Load | Idle | Peak / note |
|------|------|-------------|
| Pi 5 (board only, light I/O) | 0.6–1.0 A @ 5 V | 1.5–2.5 A with USB devices / stress |
| Pi 4 (board only) | 0.4–0.7 A @ 5 V | ~1.5–2.0 A peak |
| HX711 @ 3.3 V | < 5 mA | Negligible |
| TMC2209 logic VIO | < 20 mA | Negligible |
| Sensors (float, IR digital) | < 30 mA combined | |
| Flow sensor (YF-S201 class) | ~5–15 mA | Often from 5 V |
| Coin vibe @ 5 V (if from Pi) | 0 | **50–100 mA** when on (some 150 mA) |
| **Budgeted continuous from Pi PSU** | | **Pi 5: use ≥ 5 A official PSU; leave headroom** |

**Do not** power a 7–10" HDMI/DSI screen from the same thin USB cable without checking total draw. Prefer powered display path per screen docs.

### 2.2 12 V actuator rail

| Load | Voltage | Typical run | Stall / worst | Phase 1 duty |
|------|---------|-------------|---------------|--------------|
| NEMA17 via TMC2209 | 12 V | 0.4–0.8 A (RMS, after tuning) | Driver limit ~1.0–1.5 A peak setting | Burst dosing 1–30 s |
| Peristaltic pump | 12 V | 0.3–0.8 A | 1.0–1.5 A stall | 5–30 s water dose |
| Coin vibe @ 12 V (alt) | 12 V | 0.05–0.2 A | — | With powder |
| MOSFET / wiring loss | 12 V | small | — | |
| **Sum typical simultaneous** | 12 V | **~1.0–1.8 A** | **~2.5–3.5 A** | Stepper + pump rarely max together |

**Recommended 12 V PSU:** **3 A continuous minimum**, **5 A preferred** for margin, long cable, and future second station experiments. Voltage regulation ±5% under load.

### 2.3 5 V auxiliary (vibe default)

| Load | Current |
|------|---------|
| Coin vibration motor | 50–150 mA |
| Optional IR module | 20–50 mA |
| **Total** | **< 250 mA** typical |

If drawn from Pi 5 V pins: usually fine. If issues → small 12 V→5 V buck (≥ 1 A) on the 12 V bus.

---

## 3. Peak Scenarios

| Scenario | 12 V approx | Pi rail notes |
|----------|-------------|---------------|
| Idle, scale only | ~0 A actuators | Pi idle |
| Powder dose (stepper + vibe) | 0.5–1.2 A | Vibe pulse on 5 V |
| Water dose (pump + flow sense) | 0.5–1.2 A | Flow sensor on 5 V |
| **Worst Phase 1** (pump + stepper if software overlap) | **1.5–2.5 A** | Avoid overlapping in software if PSU is 3 A weak |
| Stall (pump jammed + stepper high current) | **3 A+ possible** | Fuse + current limit; software timeouts |

**Software guidance:** Prefer sequential phases — powder first, then water — so peaks do not stack. Saves PSU size and reduces scale vibration during weighing.

---

## 4. Fuse & Protection Sizing

| Device | Rating | Location |
|--------|--------|----------|
| F1 main 12 V | **3 A** fast-blow start; **5 A** if pump stall trips nuisance | 12 V PSU + within 15 cm |
| Optional per-branch | 2 A stepper, 2 A pump | Distribution block |
| Pi | Internal / official PSU protection | Do not add series resistance on USB-C |

Fuse must be **lower** than wire ampacity and **higher** than normal peaks. If F1 blows on every pump start, add bulk capacitor (470–1000 µF) on 12 V bus before raising fuse rating.

---

## 5. TMC2209 Current Budget

| Setting | Approx motor current | Heat | Use |
|---------|----------------------|------|-----|
| Vref low | 0.3–0.5 A | Cool | First bring-up, empty auger |
| Working | 0.5–0.9 A | Warm | Powder feeding |
| Too high | ≥ 1.2 A continuous | Hot motor/driver | Avoid for small NEMA17 Phase 1 |

Power at 12 V roughly: \( P \approx I_{motor} \times V \times \) efficiency factor; driver dissipates a portion — provide airflow/heatsink.

**Hold current:** If TMC supports reduced hold via UART later, use it. In pure STEP/DIR, disable EN between moves when holding torque is not required (auger can free-spin slightly — acceptable for Phase 1).

---

## 6. Voltage Drop & Cable Length

| Path | Max recommended length | Gauge |
|------|------------------------|-------|
| 12 V PSU → distribution | ≤ 1 m | 16–18 AWG |
| Distribution → TMC VM | ≤ 40 cm | 18–20 AWG |
| Distribution → pump | ≤ 50 cm | 18–20 AWG |
| Logic Dupont | ≤ 30 cm | 24–26 AWG |
| HX711 digital to Pi | ≤ 30 cm (shorter better) | 26 AWG |

At 2 A, 18 AWG copper drop is small on short runs; still measure VM at the TMC under load (should stay ≥ 11.5 V).

---

## 7. Brownout Checklist

Symptoms: Pi reboots when pump/stepper starts; HX711 freezes; USB drops.

| Check | Action |
|-------|--------|
| Shared undersized “12 V 1 A” wall wart | Upgrade to ≥ 3 A |
| Pi powered from GPIO 5 V from same buck as motors | Move to official USB-C PSU |
| Missing bulk capacitance | Add 470 µF+ on 12 V bus |
| Vibe on Pi 5 V + screen + WiFi heavy | Move vibe to buck |
| Ground only through thin Dupont | Add dedicated GND wire 18–20 AWG to star |

---

## 8. Example PSU Shopping Spec

**Pi:** Raspberry Pi 27 W USB-C PSU (Pi 5) or official 15 W (Pi 4).

**12 V:** Mean Well style or quality bench supply:

- 12 V DC  
- ≥ 3 A (36 W), prefer 5 A (60 W)  
- Over-current / short protection  
- Bare wire or barrel → adapt to fused terminal block  

**Optional buck:** 12 V→5 V, ≥ 1 A, for vibe + sensors if isolating from Pi.

---

## 9. Phase 2 Headroom (Informative)

| Extra station (each) | Add ~0.5–1.0 A @ 12 V while dosing |
|----------------------|-------------------------------------|
| 4 stations worst-case simultaneous | Needs larger PSU or sequenced motion |
| Shared 12 V bus | Fuse per branch; thicker backbone |

Phase 1 docs intentionally size for **one** powder station + **one** pump.

---

## 10. Quick Math Summary

```
P_12V_typical ≈ 12 V × 1.5 A ≈ 18 W
P_12V_peak    ≈ 12 V × 3.0 A ≈ 36 W
P_pi_budget   ≈ 5 V × 3 A   ≈ 15 W  (Pi 5 PSU headroom above this)

F1 = 3 A … 5 A on 12 V
Sequential dose → keep peaks near typical, not worst-case sum
```

---

## Revision

| Rev | Date | Notes |
|-----|------|-------|
| 1.0 | 2026-08-02 | Initial Phase 1 power budget |
