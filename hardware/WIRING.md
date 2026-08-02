# Phase 1 Wiring Guide

Practical harness guide: colors, connectors, lengths, and assembly order.  
Pin numbers and electrical rules: [PINOUT.md](PINOUT.md) · [ELECTRICAL_SCHEMATIC.md](ELECTRICAL_SCHEMATIC.md).

---

## 1. Conventions

### 1.1 Wire color standard (Phase 1)

| Color | Use |
|-------|-----|
| **Red** | +12 V power (fused) |
| **Black** | Ground / return (all rails) |
| **Yellow** | +5 V auxiliary (vibe, some sensors) |
| **Orange** | +3.3 V logic (short runs only) |
| **White** | Digital signal / data (generic) |
| **Green** | Clock / secondary signal (e.g. HX711 SCK) |
| **Blue** | Direction / secondary control (DIR) |
| **Purple / Violet** | Enable / chip-select style (EN) |
| **Grey** | Sensor input (flow, float, cup, e-stop) |
| **Brown** | MOSFET gate drive (actuator control) |

If using pre-made rainbow Dupont kits, map functions with heat-shrink labels rather than forcing colors. **Labels beat colors** when in doubt.

### 1.2 Load cell special colors (industry standard)

HX711 load-cell bridge (4-wire bar cell — most common 5 kg):

| Load cell wire | Function | HX711 pad |
|----------------|----------|-----------|
| **Red** | E+ (excitation +) | E+ |
| **Black** | E− (excitation −) | E− |
| **Green** | A+ (signal +) | A+ / IN+A |
| **White** | A− (signal −) | A− / IN−A |

Some cells swap green/white. If weight **decreases** when mass is added, swap A+ and A− (or invert in software). Shield (if present): connect to HX711 GND / chassis at **one** end only.

### 1.3 Connector recommendations

| Junction | Connector | Why |
|----------|-----------|-----|
| Pi GPIO breakout | 40-pin female header or **T-Cobbler + breadboard** for first bring-up | Fast iteration |
| Permanent Pi harness | **JST-XH 2.54** or **Dupont 2.54** keyed where possible | Cheap, serviceable |
| 12 V distribution | Screw terminal block (5 mm) or WAGO 221 | High current, safe |
| TMC2209 logic | Dupont 1×4 or 1×6 female | Match common driver pins |
| TMC2209 motor | JST-XH 4-pin or screw terminals on driver | Secure under vibration |
| MOSFET modules | Screw terminals for power; Dupont for signal | |
| Pump / vibe motors | JST-SM or bullet 2 mm + inline connector near chassis | Service without resoldering |
| Sensors (float, IR, flow) | JST-XH 3-pin (V, OUT, GND) | Consistent sensor pinout |
| Load cell → HX711 | Solder or screw terminal on HX711 board; strain relief | Microvolt signals |
| HX711 → Pi | 4-pin Dupont (VCC, DT, SCK, GND), ≤ 30 cm preferred | Noise |

**Do not** use flimsy breadboard jumpers for 12 V motor current. Breadboard is OK for **logic only** during bring-up.

### 1.4 Wire gauge

| Path | AWG | Notes |
|------|-----|-------|
| 12 V PSU → fuse → distribution | **18–16 AWG** | Short runs preferred |
| Distribution → TMC VM, pump | **20–18 AWG** | Stepper peak current |
| MOSFET low-side returns | Match supply gauge | |
| Pi USB-C power | Official cable | Do not power Pi 5 from GPIO 5V pins |
| Logic / sensors / gates | **26–24 AWG** Dupont | |
| Load cell leads | Stock cable; extend with **shielded** 4-core if > 30 cm | |

---

## 2. Power Wiring

### 2.1 Preferred dual-PSU layout

```
[Wall]
   |
   +--[ Official Pi USB-C PSU ]---- USB-C ----[ Raspberry Pi 5/4 ]
   |
   +--[ 12V PSU ]--(F1 fuse 3–5 A)--[ RED bus ]--+-- TMC2209 VM
                                                 +-- Pump + (via MOSFET high side supply)
                                                 +-- (optional) 12V vibe supply
                                                 +-- Buck IN (optional 12→5)
        [ 12V PSU − ]--------------[ BLACK bus ]--+-- all power returns
                                                  +-- Pi GND (star)
                                                  +-- TMC GND
                                                  +-- MOSFET sources
```

**Star ground:** one screw or copper bar where Pi GND, 12 V PSU −, and chassis (if metal) meet. Avoid daisy-chaining grounds through the HX711.

### 2.2 Optional single-brick + bucks (not preferred for Phase 1)

If only one PSU is available: 12 V brick → (1) fused 12 V bus, (2) quality 5 V/3 A+ buck for Pi **via USB-C** (not GPIO), (3) 5 V for vibe. Still fuse 12 V. Pi 5 prefers PD negotiation — official PSU is simpler.

### 2.3 Fuse

| Location | Rating (Phase 1 start) | Type |
|----------|------------------------|------|
| 12 V positive, within 15 cm of PSU | **3 A** fast or 5 A if long cable + pump stall margin | Blade ATC or panel fuse holder |

Never omit the fuse “just for a quick test.”

---

## 3. Subsystem Harnesses

### 3.1 Scale — HX711 + load cell

```
Load cell (under platform)
  Red  ---- E+
  Black --- E−
  Green --- A+
  White --- A−
         |
      [ HX711 module ]
         |
  VCC --- Pi 3V3 (pin 1)     [preferred]  or 5V if required by module
  GND --- Pi GND
  DT  --- GPIO5  (phys 29)   wire: White
  SCK --- GPIO6  (phys 31)   wire: Green
```

**Practices:**

- Keep DT/SCK away from stepper motor cables (cross at 90° if they must cross).
- Strain-relieve load cell cable at both platform and HX711.
- Mount HX711 on the frame, not dangling on the cell.

See [modules/scale_platform.md](modules/scale_platform.md).

### 3.2 Powder station — TMC2209 + NEMA17

```
Pi                TMC2209                    NEMA17
GPIO12 (STEP) --- STEP
GPIO13 (DIR)  --- DIR
GPIO16 (EN)   --- ENN / EN
3V3           --- VIO
GND           --- GND ------------------- PSU GND
12V fused     --- VM  (MOT)
                  A1,A2,B1,B2 ----------- coil pairs
```

**Motor cable:** 4-conductor, 22–20 AWG, length as short as practical (≤ 50 cm Phase 1).  
**Coil pairing:** Use meter: two pairs with ~1–3 Ω each. Wrong pairing → weak vibration, no torque. Typical color order varies by motor brand — **measure**, do not assume.

**DIR/STEP/EN wires:** 24–26 AWG Dupont, label both ends `STEP`, `DIR`, `EN`.

See [modules/powder_station.md](modules/powder_station.md).

### 3.3 Coin vibration motor (default 5 V)

```
Pi GPIO17 --[100–220Ω]-- MOSFET Gate
                           MOSFET Source --- GND
                           MOSFET Drain  --- Vibe motor −
5V (yellow) ----------------------------- Vibe motor +
Flyback diode: cathode to motor +, anode to motor − (across motor)
Gate pulldown 10–100 kΩ Gate to Source/GND
```

**12 V vibe option:** same MOSFET circuit but motor + on fused 12 V. Confirm motor voltage rating. Default docs and BOM assumption: **5 V coin vibe**.

Connector: 2-pin JST near hopper for motor replacement.

### 3.4 Peristaltic pump (12 V)

```
Pi GPIO27 --[100–220Ω]-- MOSFET Gate  (or relay module IN)
                           MOSFET Source --- GND
                           MOSFET Drain  --- Pump −
12V fused (red) ------------------------- Pump +
Flyback diode across pump (±)
```

**Relay alternative:** use a module with optocoupler, **active-HIGH or active-LOW** noted on silk; wire JD-VCC to 5 V or 12 V per module docs; never put pump current through Pi pins.

Tubing and check valves: mechanical — see [modules/water_system.md](modules/water_system.md).

### 3.5 Optional sensors

| Sensor | Typical wires | Pi |
|--------|---------------|-----|
| Flow (YF-S201 class) | Red 5 V, Black GND, Yellow pulse | Pulse → GPIO22 (level-safe) |
| Float switch | 2 wires, dry contact | One → GND, other → GPIO23 with pull-up |
| Cup IR (TCRT5000 / E18 style) | VCC, GND, DO | DO → GPIO24 |
| E-stop | NC switch | One side GND, other GPIO25 pull-up |

Label grey sensor cables at the Pi end with heat-shrink: `FLOW`, `LVL`, `CUP`, `ESTOP`.

---

## 4. Cable Routing Rules

1. **Power and motor cables** along one side of the chassis; **signal/sensor** along the other.
2. Minimum **3 cm** separation between HX711 DT/SCK and NEMA17 cable; more is better.
3. Clamp cables so vibration does not fatigue solder joints (especially vibe motor leads).
4. Leave a **service loop** at the Pi header so the board can be unplugged without tension.
5. No cables across the cup landing zone or drip path.

---

## 5. Bring-Up Wiring Order

| Step | Connect | Verify before next |
|------|---------|-------------------|
| 1 | 12 V PSU → fuse → empty terminal block; measure 12.0 V | Voltage stable |
| 2 | Official PSU → Pi only; SSH/boot OK | Pi healthy |
| 3 | Common GND: Pi ↔ 12 V − | Continuity < 1 Ω |
| 4 | HX711 + load cell only | Raw readings change with finger press |
| 5 | TMC logic + EN high (disabled); then VM 12 V | Driver idle, cool |
| 6 | NEMA17; enable; slow steps by hand script | Correct direction |
| 7 | Vibe MOSFET + 5 V motor | Click on/off, no Pi reset |
| 8 | Pump MOSFET + pump (bucket loop) | Flow, no 12 V sag reboot |
| 9 | Float, flow, cup, e-stop | Logic levels correct in `gpio readall` / Python |
| 10 | Full interlock software | No pump without cup; no motion on e-stop |

---

## 6. Labeling Template

Print or write on heat-shrink / flag labels:

```
PI-G5-HX-DT
PI-G6-HX-SCK
PI-G12-STEP
PI-G13-DIR
PI-G16-EN
PI-G17-VIBE
PI-G27-PUMP
PI-G22-FLOW
PI-G23-LVL
PI-G24-CUP
PI-G25-ESTOP
12V-FUSED
GND-STAR
5V-AUX
```

---

## 7. Common Mistakes

| Mistake | Symptom | Fix |
|---------|---------|-----|
| No common ground | Random GPIO, motors ignore commands | Bond Pi GND to 12 V − |
| HX711 at 5 V with 5 V DT into Pi | Possible Pi damage over time | Run HX711 at 3.3 V or level-shift DT |
| EN polarity inverted | Motor always on or never on | Invert software or wire |
| Pump without flyback | MOSFET death, Pi glitches | Add diode or use protected module |
| Powering Pi from 5 V GPIO while motors share rail | Brownouts | Official USB-C PSU |
| Load cell wires loose | Noisy ± few grams | Solder + strain relief |
| Stepper cable next to HX711 | Weight jumps when motor runs | Reroute / shield |

---

## 8. Diagrams

- Mermaid overview: [docs/diagrams/wiring_phase1.mmd](../docs/diagrams/wiring_phase1.mmd)
- Power tree: [docs/diagrams/power_tree.mmd](../docs/diagrams/power_tree.mmd)
- ASCII schematics: [ELECTRICAL_SCHEMATIC.md](ELECTRICAL_SCHEMATIC.md)

---

## Revision

| Rev | Date | Notes |
|-----|------|-------|
| 1.0 | 2026-08-02 | Initial Phase 1 wiring guide |
