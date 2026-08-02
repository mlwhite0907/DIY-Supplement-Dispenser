# Module: Scale Platform (Phase 1)

Cup scale for closed-loop powder dosing and optional water mass checks.  
**HX711** ADC + **5 kg** load cell + optional cup-present IR.

Pin map: [../PINOUT.md](../PINOUT.md) · Wiring: [../WIRING.md](../WIRING.md).

---

## 1. Function

1. Continuously (or on demand) measure mass of the collection cup + contents.  
2. Provide feedback so the powder station stops near the target weight.  
3. Optionally confirm cup presence before any dispense.  
4. Support calibration with known reference weights.

Target accuracy context: powder **±0.1 g** after vibration settle (project handoff). A 5 kg cell is over-ranged for drinks but common, cheap, and stiff enough for a cup platform; resolution depends on HX711 rate, noise, and mechanics.

---

## 2. Parts

| Item | Spec | Notes |
|------|------|-------|
| Load cell | **5 kg**, 4-wire, bar or single-point | Common 80 × 12.7 mm bar style |
| HX711 module | 24-bit, 10/80 SPS selectable | Prefer short path to cell |
| Cup platform | Printed plate + standoffs | Flat, light, food-splash aware |
| Fixed base | Printed or metal | Rigid to table/frame |
| Hardware | M4/M5 bolts per cell holes | Do not over-torque aluminum cells |
| Cup-present IR (optional) | Reflective or break-beam | GPIO24 |
| Calibration weights | **50 g and/or 100 g** Class M2 or better kitchen cal weights | See §7 |

---

## 3. Electrical Interface

| Signal | BCM | Direction | Notes |
|--------|-----|-----------|-------|
| DT / DOUT | **5** | Pi IN | Data ready / bit stream |
| SCK / PD_SCK | **6** | Pi OUT | Clock; also power-down if held high long |
| VCC | 3V3 preferred | — | See level note below |
| GND | GND star | — | Critical for noise |
| Cup IR DO | **24** | Pi IN | Optional |

### 3.1 HX711 supply level

| Option | Pros | Cons |
|--------|------|------|
| **3.3 V VCC (recommended)** | DT safe for Pi; one less rail | Slightly lower excitation vs 5 V |
| 5 V VCC | Stronger excitation, common default on modules | DT may be 5 V — **verify** or level-shift before Pi GPIO |

**Recommendation:** Wire HX711 **VCC to Pi 3.3 V** unless your module explicitly requires 5 V for stable operation.

### 3.2 Load cell wire map (standard)

| Cell wire | Function | HX711 |
|-----------|----------|-------|
| **Red** | E+ | E+ |
| **Black** | E− | E− |
| **Green** | A+ | A+ |
| **White** | A− | A− |

Unused B channel: leave open or per module docs.

**Negative weights when loading:** swap green/white **or** invert sign in software (`scale = -scale`).

If a 5th shield wire exists: ground at HX711 end only.

---

## 4. Mechanical Mounting (Critical)

Bar load cells measure **bending**. Wrong mounting destroys accuracy.

```
  Side view (bar cell):

      [ FIXED BASE / FRAME ]          [ CUP PLATFORM ]
               ||                            ||
            bolt||                          ||bolt
               ||==== LOAD CELL BAR ========||
            fixed end                    free end
               ^                            ^
               |                            |
          Do not support               Cup weight here
          this end on soft
          foam only — rigid
```

| Rule | Detail |
|------|--------|
| One end fixed | Bolted to stiff base that does not flex with cup load |
| Other end free | Only supports the platform; platform must not touch the base |
| Clearance | Platform undersides clear of wires and frame through full deflection |
| Level | Cell horizontal; cup centered over free-end bolt axis as designed |
| Overload | 5 kg cell — do not lean on platform; avoid > rated force |
| Isolation | Powder station and pump plumbing **must not** rest on the platform |

Single-point “kitchen scale” cells use a different spider mount — follow that cell’s arrow/label (force direction). Still: **force path through the sensing element only**.

---

## 5. Noise & Layout

| Practice | Why |
|----------|-----|
| HX711 within 10–20 cm of cell | Less noise pickup |
| DT/SCK away from STEP and motor cables | Avoid gram-level spikes |
| Star GND; no motor return through HX711 GND pin alone | Reject ground bounce |
| No PWM vibe during final sample | Mechanical + electrical noise |
| Average N samples after settle | Software filter |

---

## 6. Software Contract (Hardware-Relevant)

| Parameter | Phase 1 suggestion |
|-----------|-------------------|
| Sample rate | 10 SPS for lower noise (jumper/rate pin per module) |
| Tare | Empty cup on platform before each recipe (or known empty cup mass) |
| Settle time | 300–800 ms after last motor/vibe action before “final” weight |
| Reject window | If reading unstable (std dev high), wait and retry |
| Overflow | Abort if mass >> cup + max recipe |

Libraries (for software team; not implemented here): common HX711 Python libs bit-bang DT/SCK on BCM 5/6.

**Power-down:** Holding SCK high for > 60 µs powers down many HX711s — do not idle the clock pin high in “bit stuck” GPIO states.

---

## 7. Calibration

### 7.1 Recommended weights

| Weight | Use |
|--------|-----|
| **50 g** | Primary mid-range cal for small powder doses |
| **100 g** | Alternate / verification |
| Optional 20 g | Linearity check at low end |

Prefer stamped calibration weights over random coins. If using water: 100.0 g water ≈ 100.0 ml at room temp — OK for rough check, not primary cal.

### 7.2 Procedure

1. Warm up HX711 ~1–2 minutes powered.  
2. Platform empty **or** with empty cup — choose one convention and stick to it.  
3. Tare (zero offset).  
4. Place **50 g** (or 100 g) cal weight.  
5. Set scale factor so reading matches (library `reference_unit` / slope).  
6. Remove weight; confirm return to ~0.  
7. Repeat 3 times; log residual error.  
8. Verify with the other weight if available (linearity).

Recalibrate after mechanical changes, cable moves, or large temperature shifts.

---

## 8. Cup-Present IR (Optional)

| Item | Detail |
|------|--------|
| GPIO | **24** |
| Role | Block powder/water if no cup |
| Mount | Aim at cup wall/base; avoid powder dust on optics |
| Polarity | Document whether HIGH or LOW means present |

Reflective sensors need threshold pot tuning for cup color (white cups vs clear).

---

## 9. Bring-Up Checklist

- [ ] Cell wired Red/Black/Green/White → E+/E−/A+/A−  
- [ ] HX711 VCC/GND correct; DT/SCK on GPIO 5/6  
- [ ] Raw readings change when pressing free end gently  
- [ ] Positive mass when weight added (or sign inverted in SW)  
- [ ] Fixed end rigid; platform only on free end; no rub  
- [ ] Calibrate with 50 g / 100 g  
- [ ] Motor running on station does not create permanent offset (only transient noise)  
- [ ] Cup IR (if used) toggles reliably  

---

## 10. Failure Modes

| Symptom | Likely cause |
|---------|--------------|
| Always zero / frozen | SCK stuck; wrong pins; module unpowered |
| Wild jumps | Loose cell wires; no common ground; EMI from stepper |
| Non-linear / sticks | Platform rubbing; overload damage; side load |
| Drift over minutes | Temperature; mechanical creep; poor tare timing |
| Wrong scale factor | Cal weight incorrect; channel A gain rate jumper |

---

## 11. Relationship to Other Modules

```
[ Powder station outlet ]
         |  (air gap)
         v
[ Cup ] ---- on ---- [ Platform ] ---- free end ---- [ Load cell ] ---- fixed ---- [ Base ]
         ^
         | optional IR beam
[ Water nozzle ]  (must not touch cup/platform)
```

Closed-loop powder control depends on this module being mechanically independent and electrically quiet.

---

## Revision

| Rev | Date | Notes |
|-----|------|-------|
| 1.0 | 2026-08-02 | Initial scale platform module doc |
