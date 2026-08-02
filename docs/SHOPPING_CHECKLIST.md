# Shopping Checklist – DIY Supplement Drink Machine

**Print this page** and check items as you add them to cart or receive them.  
**Details & prices:** [BOM.md](BOM.md) · **Amazon keywords / ASINs:** [BOM_AMAZON.md](BOM_AMAZON.md)

**Rule:** Finish **Phase 1 MVP** and prove ±0.1 g powder dosing before buying multi-station bulk.

---

## Phase 1 – MVP cart (order first)

### Computing & control

- [ ] Raspberry Pi 5 (4 GB OK / 8 GB preferred) — *or use Pi you already own*
- [ ] Official 27W USB-C PSU (or proven 5 V 5 A Pi supply)
- [ ] Pi 5 Active Cooler or fan case
- [ ] microSD 32–64 GB (A2/U3 preferred)
- [ ] Breadboard
- [ ] Dupont jumper kit (M-M, M-F, F-F)

### Powder dosing (1 station)

- [ ] NEMA17 stepper (1.5–2 A, body ≥40 mm, 5 mm shaft)
- [ ] TMC2209 driver module
- [ ] 5 kg bar load cell
- [ ] HX711 amplifier board (spares nice)
- [ ] Coin vibration motors Ø10–12 × ~3 mm (buy a small pack)
- [ ] Logic-level MOSFET module for vibration motor
- [ ] Optional: 5 mm shaft coupler (if not using printed coupling)

### Water system

- [ ] Food-safe tank 2–5 L (removable, cleanable) — **FC**
- [ ] 12 V food-grade peristaltic pump **or** diaphragm pump — **FC path preferred**
- [ ] Food-grade silicone tubing (ID matches pump) — **FC**
- [ ] Food-grade check valves (2–4) — **FC**
- [ ] Hose clamps / spring clips
- [ ] MOSFET **or** opto-isolated relay for 12 V pump

### Power (12 V rail)

- [ ] 12 V switching PSU ≥10 A (15 A nicer)
- [ ] Terminal / distribution block
- [ ] Inline fuse holder + appropriate fuse
- [ ] Hookup wire (18 AWG power, 22 AWG signal)

### Fasteners & smalls

- [ ] M3 screw/nut/washer assortment
- [ ] M4 screws/nuts (many load cells use M4)
- [ ] Optional M2 for vibe motor clips / tiny mounts
- [ ] Calibration weight **or** plan to use known kitchen weights

### Mixing (MVP)

- [ ] Test cups (paper/reusable) — manual swirl OK

### 3D printed (not Amazon — your printer)

- [ ] `powder_hopper` (PETG)
- [ ] `auger_housing` + outlet (PETG)
- [ ] `auger_screw` (print 2 pitch variants if possible)
- [ ] Module stand / feet
- [ ] Load-cell cup platform

---

## Phase 1 – Full / niceties (second cart or same order if budget allows)

### UI

- [ ] 7–10" HDMI capacitive touchscreen for Raspberry Pi
- [ ] HDMI + USB touch cables (if not bundled)

### Water / sensing upgrades

- [ ] Hall flow sensor (e.g. YF-S201) + tube adapters
- [ ] Float level sensor **or** capacitive level sensor
- [ ] IR / cup presence sensor
- [ ] Food-grade quick disconnects — **FC**
- [ ] Drip tray (buy or print)

### Mixing upgrade

- [ ] Small DC gear motor **or** simple stirrer solution
- [ ] Printed / stainless stir interface (easy clean)

### Wiring upgrade

- [ ] Screw terminals / protoboard / ferrules
- [ ] Optional buck converter 12 V → 5 V for accessories
- [ ] Extra MOSFET channels if needed

---

## Phase 2 – Expansion (only after Phase 1 works)

### Per additional powder station (repeat)

- [ ] NEMA17 1.5–2 A
- [ ] TMC2209 module
- [ ] Coin vibration motor(s)
- [ ] MOSFET channel for vibe
- [ ] Printed hopper + auger + housing set (PETG)

### Shared Phase 2

- [ ] Higher-capacity 12 V PSU if needed (15–30 A class)
- [ ] Multi-channel MOSFET / relay board
- [ ] Frame / rails for multiple modules (print or extrusion)
- [ ] Extra wire, terminals, fusing as required
- [ ] Pill module parts — **TBD after powder stations proven**
- [ ] Still **one** shared cup load cell + HX711 (unless redesign)

---

## Tools (own or buy)

| Have? | Tool | Need for |
|:-----:|------|----------|
| [ ] | Digital multimeter | 12 V checks, continuity, debug |
| [ ] | Digital calipers | Load cell, tube OD, print fit |
| [ ] | Hex / Allen drivers (metric) | M3 motor mounts |
| [ ] | Small screwdriver set | Terminals, couplers |
| [ ] | Wire strippers | Power wiring |
| [ ] | Soldering iron + solder | **Optional** Phase 1; useful for permanent install |
| [ ] | Flush cutters / snips | Zip ties, leads |
| [ ] | Zip ties / adhesive cable clips | Strain relief |
| [ ] | Isopropyl alcohol + paper towels | Clean powder residue, flux |
| [ ] | Kitchen scale (reference) | Cross-check HX711 calibration |
| [ ] | Safety glasses | Cutting / first power-up |

---

## Filament & print supplies

| Have? | Item | Notes |
|:-----:|------|-------|
| [ ] | **PETG** filament (primary) | Preferred for hoppers / auger — tough, dishwasher-friendly enough for DIY clean |
| [ ] | PLA (optional) | OK for jigs, stands, non-food fixtures |
| [ ] | Avoid ABS for first **FC** prototypes | Warping + fumes; not first choice for powder path |
| [ ] | Spare nozzles / glue stick / bed prep | Per your printer (e.g. Bambu) |
| [ ] | Light sandpaper or reamer | Smooth auger bore if needed |

**Food-contact reminder:** Powder-contact prints should be smooth, washable, and removable. This is home DIY hygiene practice, not a commercial food cert.

---

## Food-contact (**FC**) gate — check before first drink test

- [ ] Tank is food-safe material and fully washable
- [ ] Pump + tubing marketed food-grade / beverage / silicone wet path
- [ ] Check valves / QDs food-grade
- [ ] Powder path parts printed in PETG (or better), no mystery filament
- [ ] Electronics kept dry / separated from splash zone
- [ ] You can completely empty and wipe hopper + barrel

---

## Receive & smoke-test checklist

- [ ] All packages inventory-checked against this list  
- [ ] 12 V PSU outputs ~12 V **before** connecting motors  
- [ ] Pi boots from microSD  
- [ ] HX711 reads and calibrates with known weight  
- [ ] NEMA17 steps (low current first) with auger free  
- [ ] Vibration motor runs via MOSFET  
- [ ] Pump primes with water into a cup (watch for leaks)  
- [ ] Only then: powder in hopper + closed-loop dose tests  

---

## Phase checkbox summary

| Phase | Status |
|-------|--------|
| [ ] Phase 1 MVP parts ordered | |
| [ ] Phase 1 MVP parts received | |
| [ ] Phase 1 printed parts done | |
| [ ] Powder ±0.1 g proven | |
| [ ] Water dose acceptable | |
| [ ] Drink mix acceptable | |
| [ ] Full Phase 1 niceties ordered | |
| [ ] Phase 2 first extra station ordered | |

---

## Related docs

- [BOM.md](BOM.md) — quantities, price ranges, power budget  
- [BOM_AMAZON.md](BOM_AMAZON.md) — search terms, example ASINs, cart strategy  
- [PROJECT_PLAN.md](PROJECT_PLAN.md) — phase goals  
- [PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md) — hopper/auger design targets  
