# Assembly Guide – Phase 1 (Single Powder + Water + Mix)

Step-by-step from unboxing electronics through the first full drink. Mechanical dimensions for the powder module are locked in [PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md). Architecture: [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md). Safety: [SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md).

> **Scope:** Phase 1 bench rig only. No full vending enclosure.

---

## Before You Start

### Tools

- Hex drivers / screwdriver set (M2–M3 common)
- Wire strippers, ferrules optional
- Multimeter
- Digital calipers (verify print critical dims)
- Food-safe brush / cloth for powder cleanup
- Kitchen measuring cup or graduated cylinder (water calibration)
- Known calibration masses (e.g. 100 g, 500 g) for the load cell

### Prerequisites

- [ ] Phase 1 parts on hand ([BOM.md](BOM.md)): Pi, HX711 + 5 kg cell, NEMA17, driver, vibe motor, pump, tank, tubing, PSU
- [ ] Printed parts: hopper, auger housing, auger screw, test stand (and optional cup holder)
- [ ] Software environment for dry-run available (see software agent / `software/` when ready)
- [ ] Read [SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md) — especially liquid isolation and food contact

### Safety callouts used below

| Tag | Meaning |
|-----|---------|
| **⚠ POWER** | Disconnect mains / PSU before wiring changes |
| **⚠ LIQUID** | Keep water away from Pi, drivers, and load-cell amp |
| **⚠ FOOD** | Powder path is food-adjacent; clean before edible tests |
| **⚠ MOTION** | Fingers clear of auger and coupler when powered |

---

## 1. Unbox and Inventory Electronics

1. Unpack Raspberry Pi, power supply (5 V for Pi), 12 V high-current supply for motors/pump, HX711 board, load cell, NEMA17, stepper driver (e.g. TMC2209), coin vibration motor, water pump, tubing, tank, level sensor if any, jumper wires, breadboard or proto PCB.
2. Photograph bag labels and keep screws with their modules.
3. Verify load cell type (common 5 kg bar, ~12.7 × 80 mm style) matches your printed cup platform if you printed one.

![Photo: all Phase 1 electronics laid out and labeled](images/assembly_01_inventory.jpg)

*Placeholder: inventory layout.*

---

## 2. Inspect and Prep Printed Parts

1. Confirm prints match handoff targets: hopper **~90 mm** top ID, **~22 mm** outlet, **~65°** wall; auger and barrel free to rotate with **~0.6–0.9 mm** radial clearance.
2. Deburr outlet and auger flights lightly; **do not** gouge the internal hopper surface.
3. Dry-fit hopper → housing → stand; check outlet height **~40–60 mm** above table for cup + scale clearance.
4. Wash food-path parts with mild dish soap, rinse, fully dry ([SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md)).

**⚠ FOOD:** Do not run edible powder until post-print wash and dry are done.

![Photo: hopper, barrel, auger, stand dry-fit](images/assembly_02_dryfit.jpg)

*Placeholder: printed module dry-fit.*

---

## 3. Mount Load Cell and Cup Platform

1. Bolt load cell to a stable base (bench plate or printed base) using the correct strain-side orientation (follow cell datasheet: one end fixed, one end loaded).
2. Attach cup platform / holder to the free end; ensure no binding against the base.
3. Place a removable cup; confirm it sits centered and does not rock.
4. Route HX711 away from the future water nozzle splash zone.

**⚠ LIQUID:** Elevate or shield HX711; never let the amp sit in the drip path.

![Photo: load cell + cup on platform](images/assembly_03_scale.jpg)

*Placeholder: scale assembly.*

---

## 4. Assemble Powder Module

1. Insert auger into barrel; shaft toward NEMA17 face.
2. Mount NEMA17 (31 mm hole pattern); couple to auger with set-screw coupling — secure set screws on flat if present.
3. Seat hopper on housing inlet (snap/screw/bayonet per print); confirm alignment so powder falls into flights, not a dead ledge.
4. Install coin vibe motor in its pocket; secure so it cannot rattle free; leave serviceable wire exit.
5. Mount module on test stand so nozzle is above the cup centerline with a short drop.
6. Hand-rotate auger (power off) to feel for rub; fix interference before applying power.

**⚠ MOTION:** Never probe the outlet with a finger while the stepper is enabled.

![Photo: assembled powder module over cup](images/assembly_04_powder_module.jpg)

*Placeholder: module over scale.*

---

## 5. Water Path (Dry Fit First)

1. Mount refillable tank (2–5 L food-safe) at a fixed height relative to the pump.
2. Install tubing: tank outlet → pump inlet → (optional flow sensor) → nozzle aimed at cup (not at electronics).
3. Add check valve if specified in your BOM to reduce back-drain.
4. Fit level sensor if used; verify float/capacitive clear of lid slam.
5. **Do not** fill yet until electrical isolation check passes (step 7).

**⚠ LIQUID:** Nozzle and drip tray plan before any wet test. Prefer a tray under the cup area.

![Photo: tank, pump, tubing to nozzle](images/assembly_05_water.jpg)

*Placeholder: water path dry fit.*

---

## 6. Wiring (Power Off)

**⚠ POWER:** All supplies unplugged until the checklist at the end of this section.

1. **Common ground** between Pi logic ground and 12 V PSU ground (as required by your driver setup).
2. **Stepper driver:** VMOT from 12 V (fused), logic from 5 V/3.3 V per driver docs; STEP/DIR/EN to Pi GPIO; motor coils to NEMA17.
3. **HX711:** VCC/GND/DT/SCK to Pi per your chosen pins (document in software config later — not in this guide).
4. **Vibe motor:** via MOSFET or driver channel rated for the motor; flyback diode if needed; GPIO control.
5. **Pump:** 12 V through MOSFET/relay rated for stall current; GPIO control; never drive pump coils from Pi pins directly.
6. **Optional mixer:** same rule as pump — switched 12 V, not direct GPIO power.
7. Strain-relieve wires so vibration and pump do not yank connectors.
8. Visual inspection: no frayed conductors; no shorts on motor terminals.

### Pre-power checklist

- [ ] Correct supply voltages to each device
- [ ] Fused 12 V branch
- [ ] Liquids still empty or capped
- [ ] Clear emergency unplug path
- [ ] Pi SD image boots headless or with display as you prefer

![Photo: wiring loom, labeled](images/assembly_06_wiring.jpg)

*Placeholder: labeled wiring.*

---

## 7. First Power-On (No Powder, No Water)

1. Power Pi only; confirm SSH/console.
2. Enable 12 V; confirm driver idle current not excessive (no smoke, no hot smell).
3. Software **dry run** (no powder in hopper):
   - Read scale continuously; verify noise band.
   - Step motor short moves both directions.
   - Pulse vibe briefly.
   - Click pump **with tubing open to air or still empty tank** only if pump allows dry run for a second — many diaphragm pumps dislike long dry runs; prefer water only after step 9 priming plan.
4. Confirm E-stop procedure: disable EN / cut 12 V.

**⚠ POWER / MOTION:** If anything unexpected moves, kill 12 V first.

![Photo: serial log of scale and step test](images/assembly_07_dryrun.jpg)

*Placeholder: dry-run console.*

---

## 8. Scale Calibration

Follow the formal procedure in [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md) § Scale calibration.

1. Empty platform + empty cup → tare.
2. Place known mass → set calibration factor.
3. Spot-check a second mass.
4. Record factor and date in your lab notes.

![Photo: calibration weight on cup platform](images/assembly_08_cal.jpg)

*Placeholder: calibration mass.*

---

## 9. First Powder Tests (No Water)

**⚠ FOOD:** Use a sacrificial powder first if you want (e.g. cheap creatine you accept wasting), still food-grade path clean.

1. Fill hopper partially (not over rim); fit lid if available.
2. Place empty cup; tare.
3. **Open-loop:** short step bursts; confirm mass increases and powder lands in cup.
4. Watch for bridging; use vibe pulses as designed.
5. **Closed-loop:** run target 3 g then 5 g with settle + verify ([TESTING_PROTOCOL.md](TESTING_PROTOCOL.md)).
6. Empty cup between runs; do not zero mid-dose.
7. Clean spills immediately; keep powder off the load cell flexure and electronics.

**Pass gate before water:** open-loop predictable and closed-loop roughly approaching target (full 20× suite can wait until comfortable).

![Photo: powder stream into cup](images/assembly_09_powder.jpg)

*Placeholder: first powder dispense.*

---

## 10. Water Bring-Up

1. Fill tank with clean water; check fittings for seepage **before** powering pump near electronics.
2. Place waste cup or measuring cup under nozzle.
3. Prime tubing until steady stream; purge air.
4. Timed calibration: run fixed times; measure volume; compute ml/s at your tank level.
5. Integrate water step after powder in software (timed first is fine).
6. Re-check that splash does not hit HX711 or Pi.

**⚠ LIQUID:** At first leak, power down 12 V and mop — do not “watch if it gets worse.”

![Photo: water stream into graduated cup](images/assembly_10_water.jpg)

*Placeholder: water volume check.*

---

## 11. Mix + First Full Drink

1. Confirm powder path and water path each work alone.
2. Recipe for first drink: moderate powder (e.g. 3–5 g) + water (e.g. 200–300 ml) + mix duration.
3. Sequence: tare → powder closed-loop → verify → water → mix ([dispense sequence](diagrams/dispense_sequence.mmd)).
4. Taste/quality is secondary to **mass and volume accuracy** and **no electrical wetness**.
5. Log results; note any foam, clumping, or undissolved powder for mixer tuning.
6. Clean cup, wipe nozzle area, empty drip tray ([SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md)).

![Photo: first completed drink in cup](images/assembly_11_drink.jpg)

*Placeholder: first full drink.*

---

## 12. Post-Assembly Checklist

- [ ] Powder closed-loop meets or is on track for [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md) criteria
- [ ] Water accuracy measured and recorded
- [ ] At least one full automated (or semi-auto) drink completed safely
- [ ] Faults for no-cup / stop-all understood by operator
- [ ] Cleaning done after session
- [ ] Phase 1 exit criteria tracked in [PROJECT_PLAN.md](PROJECT_PLAN.md)

---

## Troubleshooting (Quick)

| Symptom | Likely cause | Action |
|---------|--------------|--------|
| Auger stalls / noise | Binding, packed powder, bad clearance | Power off; hand-turn; clear; check print dims |
| No weight change | Empty, bridge, cup not on cell, cal wrong | Vibe; refill; reseat cup; recal |
| Scale jumps | Cable stress, liquid on cell, unstable base | Reroute; dry; stiffen mount |
| Pump no flow | Air lock, clog, dry tank, bad polarity | Prime; check level; verify wiring |
| Splash on electronics | Nozzle aim / missing tray | Re-aim; add shield; stop tests |

---

## Next After Phase 1 Assembly

1. Complete formal test matrices in [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md).
2. Meet Phase 1 exit criteria in [PROJECT_PLAN.md](PROJECT_PLAN.md).
3. Only then expand to multi-station (Phase 2).
