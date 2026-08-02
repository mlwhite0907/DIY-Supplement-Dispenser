# Amazon Shopping Guide – DIY Supplement Drink Machine

**Companion to:** [BOM.md](BOM.md)  
**Last updated:** 2026-08  
**Region:** amazon.com (US). Links and ASINs change; if a link 404s, use the **search keywords**.

Prices below are **approximate ranges** only. **Verify live price, seller rating, and “ships from/sold by” before checkout.**

---

## Cart strategy (read this first)

1. **Order Phase 1 MVP cart only** — one powder station + water path + Pi power.  
2. Do **not** buy 12× NEMA17 / TMC2209 until dosing works.  
3. Prefer **one combined order** for free-shipping thresholds, but split if you’re unsure about pump type (peristaltic vs diaphragm).  
4. Check **food-grade** wording on anything in the wet path (tank, tube, pump head, check valves).  
5. After MVP works: Full Phase 1 niceties (touchscreen, sensors, mix motor).  
6. Phase 2: multiply powder electronics; keep **one shared** cup load cell.

### Approximate cart totals (parts only, USD)

| Cart | Rough total |
|------|-------------|
| Phase 1 MVP | **$250–500** |
| Full Phase 1 add-ons | **+$100–280** |
| Per extra powder station | **+$25–50** electronics |

---

## How to use the tables

| Column | Meaning |
|--------|---------|
| **Search keywords** | Paste into Amazon search |
| **Example ASIN / link** | Known commodity parts when available — **confirm the listing matches the description** |
| **Why this part** | Role in the machine |
| **What to avoid** | Common junk / mismatch |

Direct product URL pattern: `https://www.amazon.com/dp/ASIN`  
Search URL pattern: `https://www.amazon.com/s?k=URL+ENCODED+KEYWORDS`

---

## 1. Computing (Raspberry Pi)

### Raspberry Pi 5 (8 GB preferred)

| | |
|--|--|
| **Search** | `Raspberry Pi 5 8GB` or `Raspberry Pi 5 8GB starter kit` |
| **Example** | Search kits that include heatsink/cooler; board-only if you already have accessories |
| **Link pattern** | [Search: Pi 5 8GB](https://www.amazon.com/s?k=Raspberry+Pi+5+8GB) |
| **Why** | Main controller: GPIO for HX711, STEP/DIR, MOSFETs; later touchscreen UI |
| **Avoid** | Random “Pi compatible” clones with no community support; Pi Zero for this project (too weak / painful I/O for multi-motor later) |
| **~Price** | Board ~$60–90; kits higher |

### Official 27W USB-C PSU

| | |
|--|--|
| **Search** | `Raspberry Pi 27W USB-C power supply` `official` |
| **Link** | [Search: Pi 27W PSU](https://www.amazon.com/s?k=Raspberry+Pi+27W+USB-C+power+supply) |
| **Why** | Pi 5 needs proper PD/5A supply; brownouts cause SD corruption and flaky USB |
| **Avoid** | Phone chargers, “fast charge” bricks that don’t sustain 5A at 5V |
| **~Price** | $12–18 |

### Active cooler / case

| | |
|--|--|
| **Search** | `Raspberry Pi 5 Active Cooler` or `Pi 5 case dual fan` |
| **Link** | [Search: Pi 5 Active Cooler](https://www.amazon.com/s?k=Raspberry+Pi+5+Active+Cooler) |
| **Why** | Stepper bit-banging + UI can warm the SoC; cooler = stable clocks |
| **Avoid** | Passive-only tiny heatsinks if you plan a warm enclosure |
| **~Price** | $8–20 |

### microSD card

| | |
|--|--|
| **Search** | `microSD 64GB A2 V30` (SanDisk, Samsung, Kingston) |
| **Link** | [Search: microSD 64GB A2](https://www.amazon.com/s?k=microSD+64GB+A2+V30) |
| **Why** | OS + logs; A2 helps random I/O |
| **Avoid** | No-name bulk cards (counterfeit capacity) |
| **~Price** | $8–15 |

### 7–10" HDMI capacitive touchscreen (**Full Phase 1**)

| | |
|--|--|
| **Search** | `7 inch HDMI capacitive touchscreen Raspberry Pi` or `10 inch HDMI touchscreen capacitive Pi` |
| **Link** | [Search: 7" HDMI touch Pi](https://www.amazon.com/s?k=7+inch+HDMI+capacitive+touchscreen+Raspberry+Pi) · [Search: 10" HDMI touch](https://www.amazon.com/s?k=10+inch+HDMI+capacitive+touchscreen+Raspberry+Pi) |
| **Why** | Vending-style UI; capacitive multi-touch preferred over resistive |
| **Avoid** | Resistive-only panels; screens that need obscure driver ISOs with no Pi 5 notes; “HDMI” displays that are power-hungry without a clear 5V plan |
| **~Price** | 7" ~$50–80; 10" ~$80–120 |

---

## 2. Load cell & HX711 (powder accuracy)

### HX711 amplifier boards

| | |
|--|--|
| **Search** | `HX711 module` `Stemedu HX711` |
| **Example ASIN** | `B07MTYT95R` (Stemedu 5PCS HX711 — common multipack) |
| **Link** | [dp/B07MTYT95R](https://www.amazon.com/dp/B07MTYT95R) · [Search: HX711](https://www.amazon.com/s?k=HX711+load+cell+amplifier) |
| **Why** | 24-bit ADC for strain-gauge load cells; industry-standard for DIY scales |
| **Avoid** | Broken-out boards with no silkscreen; assuming every “HX711” breakout is 3.3 V-safe on DOUT without checking (most work with Pi 3.3 V logic; still verify) |
| **~Price** | $6–15 for multipacks |

### 5 kg load cell (bar / bathroom-scale style)

| | |
|--|--|
| **Search** | `5kg load cell bar` `HX711 load cell kit 5kg` `NOYITO load cell` |
| **Example ASIN** | `B07BGS58TL` (NOYITO-style load cell kits — **confirm weight rating & includes HX711**) |
| **Link** | [dp/B07BGS58TL](https://www.amazon.com/dp/B07BGS58TL) · [Search: 5kg load cell HX711](https://www.amazon.com/s?k=5kg+load+cell+HX711+kit) |
| **Why** | Closed-loop powder dosing: cup sits on cell; software runs auger until target grams |
| **Avoid** | 1 kg cells if you want cup + full drink margin (5 kg is the sweet spot); 50 kg cells (poor resolution for ±0.1 g); half-bridge single-strain cheapies without four-wire color convention docs |
| **~Price** | Bare cell $5–12; kit $10–20 |

**Mount tip:** Standard rectangular bar cells are often **~80 mm long** with M4 holes. Design the 3D cup platform around the cell’s datasheet hole spacing after it arrives (measure with calipers).

---

## 3. Stepper + driver (auger)

### NEMA17 stepper motor

| | |
|--|--|
| **Search** | `NEMA17 stepper motor 1.5A` `NEMA 17 42mm 2A 40mm` `Nema 17 0.4Nm` |
| **Link** | [Search: NEMA17 1.5A](https://www.amazon.com/s?k=NEMA+17+stepper+motor+1.5A+40mm) |
| **Why** | Drives 3D-printed auger; 42×42 face, **31 mm** hole spacing, **5 mm** shaft (matches design handoff) |
| **Avoid** | Tiny NEMA14 (weak); huge NEMA23 (overkill, heavier PSU); motors with unknown current >2.5 A unless your driver/PSU are sized |
| **~Price** | $12–25 each |

### TMC2209 driver module

| | |
|--|--|
| **Search** | `TMC2209 BIGTREETECH` `TMC2209 stepper driver UART` |
| **Example ASIN** | `B07ZQ3C1XW` or `B08SMDY3SQ` (BIGTREETECH TMC2209-style modules — **verify listing title**) |
| **Link** | [dp/B07ZQ3C1XW](https://www.amazon.com/dp/B07ZQ3C1XW) · [dp/B08SMDY3SQ](https://www.amazon.com/dp/B08SMDY3SQ) · [Search: TMC2209](https://www.amazon.com/s?k=TMC2209+BIGTREETECH+stepper+driver) |
| **Why** | Quiet StealthChop, good microstepping, tunable current — better powder metering than A4988 clunk |
| **Avoid** | Counterfeit “TMC” with fake markings; bare bare-chip without heatsink pad if you’ll run high current continuous; forgetting series resistors / level details for UART on Pi (STEP/DIR-only mode is fine for Phase 1) |
| **~Price** | $8–15 |

---

## 4. Vibration motors + switching

### Coin / pancake vibration motors

| | |
|--|--|
| **Search** | `coin vibration motor 10x3mm` `1027 vibration motor 3V` `pancake vibrator motor 10mm` |
| **Link** | [Search: coin vibe 10x3](https://www.amazon.com/s?k=coin+vibration+motor+10x3mm+3V) |
| **Why** | Anti-bridging on hopper wall / barrel pocket (see Phase 1 handoff Ø10–12 × ~3 mm) |
| **Avoid** | Huge eccentric pager motors that don’t fit the pocket; 12 V industrial vibrators for Phase 1 |
| **~Price** | $5–12 per 5–10 pack |

### Logic-level MOSFET modules (pump + vibe)

| | |
|--|--|
| **Search** | `logic level MOSFET module 3.3V` `IRLZ44N MOSFET module` `opto isolated MOSFET 5V 12V` |
| **Link** | [Search: logic MOSFET module](https://www.amazon.com/s?k=logic+level+MOSFET+module+3.3V+GPIO) |
| **Why** | Pi GPIO cannot drive pump/vibe current; MOSFET (or opto MOSFET) is the right switch |
| **Avoid** | Bare BJT “arduino modules” that drop too much voltage; mechanical relays for high-frequency vibe PWM if you want smooth control (relay OK for pump on/off) |
| **~Price** | $6–15 (1–4 channel) |

### Opto-isolated relay board (alternate for pump)

| | |
|--|--|
| **Search** | `opto isolated relay module 1 channel 5V` `Pi relay 12V` |
| **Link** | [Search: opto relay 1ch](https://www.amazon.com/s?k=opto+isolated+relay+module+1+channel+5V) |
| **Why** | Simple on/off for 12 V pump; galvanic isolation |
| **Avoid** | Non-isolated junk; active-HIGH/LOW confusion — read the silkscreen |
| **~Price** | $5–12 |

---

## 5. Water system (**food-contact critical**)

### Peristaltic pump (preferred hygiene story)

| | |
|--|--|
| **Search** | `12V food grade peristaltic pump silicone` `peristaltic pump dosing 12V` `peristaltic pump 100ml/min` / `500ml/min` |
| **Link** | [Search: 12V food-grade peristaltic](https://www.amazon.com/s?k=12V+food+grade+peristaltic+pump+silicone) |
| **Why** | Fluid only touches silicone tube — easy replace, good for beverage DIY. **Dosing-class** ~100–400 ml/min is precise; **fill-class** ~500–1500 ml/min fills a cup faster |
| **Avoid** | Oil-only / chemical pumps with non-food tube; 24 V pumps on a 12 V PSU; unknown “food grade” with PVC tube that smells |
| **~Price** | $15–40 |
| **Phase 1 tip** | One pump is enough. Prefer a model with replaceable silicone tube and published flow vs voltage |

### Diaphragm pump (budget alternate)

| | |
|--|--|
| **Search** | `12V diaphragm water pump food grade` `mini DC water pump 12V` |
| **Link** | [Search: 12V diaphragm water pump](https://www.amazon.com/s?k=12V+diaphragm+water+pump+food) |
| **Why** | Cheap and strong flow |
| **Avoid** | Automotive windshield pumps with mystery elastomers for long-term drink use; running dry frequently |
| **~Price** | $12–25 |

### Food-grade silicone tubing

| | |
|--|--|
| **Search** | `food grade silicone tubing 4mm ID` (match your pump barb!) `platinum cure silicone tube beverage` |
| **Link** | [Search: food-grade silicone tubing](https://www.amazon.com/s?k=food+grade+silicone+tubing+beverage) |
| **Why** | **FC** wet path; buy ID/OD that matches pump and check valves |
| **Avoid** | Vinyl/PVC that stiffens and leaches; random “silicone” with no food claim for the drink line |
| **~Price** | $8–20 for a few meters |

### Check valves + quick disconnects

| | |
|--|--|
| **Search** | `food grade check valve 1/4"` `plastic one way valve silicone tube` `food grade quick disconnect fittings water` |
| **Link** | [Search: food-grade check valve](https://www.amazon.com/s?k=food+grade+check+valve+tubing) · [Search: food QD fittings](https://www.amazon.com/s?k=food+grade+quick+disconnect+water+tubing) |
| **Why** | Anti-siphon; tank removal without draining the house |
| **Avoid** | Fuel/air check valves not rated for potable water |
| **~Price** | $6–25 |

### Refillable tank 2–5 L

| | |
|--|--|
| **Search** | `food grade water container 1 gallon` `beverage dispenser 1 gallon spigot` `HDPE water jug 5L` |
| **Link** | [Search: food-grade 1 gal water](https://www.amazon.com/s?k=food+grade+water+container+1+gallon) |
| **Why** | Project requirement: refillable tank, no hard plumbing |
| **Avoid** | Non-food jerry cans previously used for fuel; tanks that can’t be opened to clean |
| **~Price** | $10–25 |

### Hall flow sensor (**Full Phase 1**)

| | |
|--|--|
| **Search** | `YF-S201 flow sensor` `hall water flow sensor 1/2` `G1/2 water flow meter Arduino` |
| **Link** | [Search: YF-S201](https://www.amazon.com/s?k=YF-S201+water+flow+sensor) |
| **Why** | Pulse count ≈ volume; better than pure timed pump |
| **Avoid** | Expecting perfect accuracy without calibration; using above pump max pressure/flow rating |
| **~Price** | $5–12 |
| **Note** | May need barb adapters to your silicone ID |

### Float / level sensor (**Full Phase 1**)

| | |
|--|--|
| **Search** | `float level sensor tank Arduino` `stainless float switch water` `capacitive liquid level sensor non contact` |
| **Link** | [Search: float level sensor](https://www.amazon.com/s?k=float+level+sensor+tank+Arduino) |
| **Why** | Low-water lockout so pump doesn’t run dry |
| **Avoid** | Mercury switches; floats that can’t handle your tank geometry |
| **~Price** | $5–15 |

### Cup presence sensor (**Full Phase 1 optional**)

| | |
|--|--|
| **Search** | `IR obstacle avoidance sensor module` `TCRT5000 sensor` `ultrasonic HC-SR04` |
| **Link** | [Search: IR obstacle sensor](https://www.amazon.com/s?k=IR+obstacle+avoidance+sensor+module) |
| **Why** | Don’t dose powder into empty air |
| **Avoid** | Overthinking — a simple IR break-beam or reflective IR is enough |
| **~Price** | $3–12 |

---

## 6. Power supply (12 V rail)

### 12 V 10 A (or 15 A) switching PSU

| | |
|--|--|
| **Search** | `12V 10A switching power supply` `12V 15A power supply Mean Well` `LRS-150-12` |
| **Link** | [Search: 12V 10A PSU](https://www.amazon.com/s?k=12V+10A+switching+power+supply) · [Search: Mean Well 12V](https://www.amazon.com/s?k=Mean+Well+LRS-150-12) |
| **Why** | NEMA17 + pump + future stations; **10 A minimum** for Phase 1 comfort; **15 A** nicer |
| **Avoid** | Undersized 2 A “LED” supplies; no-name PSUs with no strain relief / safety marks for permanent installs; powering Pi from this without a proper buck |
| **~Price** | $20–45 |

### Terminal blocks / distribution

| | |
|--|--|
| **Search** | `power distribution block 12V` `DIN rail terminal block set` `screw terminal block dual row` |
| **Link** | [Search: power distribution block](https://www.amazon.com/s?k=12V+power+distribution+block+screw+terminal) |
| **Why** | Safe +V / GND fan-out without solder blobs |
| **Avoid** | Tiny breadboard rails for motor current |
| **~Price** | $6–15 |

### Fuse holder

| | |
|--|--|
| **Search** | `inline ATC fuse holder 12V` `blade fuse holder automotive 10A` |
| **Link** | [Search: inline fuse holder](https://www.amazon.com/s?k=inline+ATC+fuse+holder+12V) |
| **Why** | Short-circuit protection on 12 V |
| **~Price** | $3–8 |

---

## 7. Wiring, hardware, tools

### Breadboard + Dupont wires

| | |
|--|--|
| **Search** | `breadboard jumper wire kit male female` `830 point breadboard` |
| **Link** | [Search: breadboard jumper kit](https://www.amazon.com/s?k=breadboard+jumper+wire+kit+male+female) |
| **Why** | Phase 1 bring-up speed |
| **Avoid** | Staying on breadboard forever for motor current paths |
| **~Price** | $8–15 |

### M2 / M3 hardware

| | |
|--|--|
| **Search** | `M3 screw assortment kit hex` `M2 M3 stainless button head assortment` |
| **Link** | [Search: M3 assortment](https://www.amazon.com/s?k=M3+screw+nut+assortment+kit) |
| **Why** | NEMA17 mounts (M3), hoppers, many load-cell plates (M4 also useful) |
| **Also grab** | `M4 screw nut kit` if your load cell uses M4 |
| **~Price** | $8–18 |

### Hookup wire

| | |
|--|--|
| **Search** | `18 AWG silicone wire kit` `22 AWG stranded hookup wire` |
| **Link** | [Search: 18 AWG silicone wire](https://www.amazon.com/s?k=18+AWG+silicone+wire+kit+12V) |
| **Why** | 18 AWG for 12 V power; 22–24 AWG for signals |
| **~Price** | $10–20 |

### Multimeter

| | |
|--|--|
| **Search** | `digital multimeter auto ranging` |
| **Link** | [Search: digital multimeter](https://www.amazon.com/s?k=digital+multimeter+auto+ranging) |
| **Why** | Confirm 12 V, continuity, sense bad grounds |
| **~Price** | $15–40 |

### Calipers

| | |
|--|--|
| **Search** | `digital calipers inch mm` |
| **Link** | [Search: digital calipers](https://www.amazon.com/s?k=digital+calipers+inch+mm) |
| **Why** | Measure load cell, tube OD, printed bore clearances |
| **~Price** | $15–30 |

### Soldering iron (**optional** for Phase 1)

| | |
|--|--|
| **Search** | `temperature controlled soldering iron kit` |
| **Link** | [Search: soldering iron kit](https://www.amazon.com/s?k=temperature+controlled+soldering+iron+kit) |
| **Why** | Strain relief, connectors, permanent wiring later |
| **Avoid** | Thinking you *must* solder before first powder test — Dupont + screw terminals can start |
| **~Price** | $20–50 |

---

## 8. Mixing extras (**Full Phase 1**)

| Item | Search keywords | Why | Avoid | ~USD |
|------|-----------------|-----|-------|------|
| Mini stir / gear motor | `6V 12V gear motor 100rpm` `DIY magnetic stirrer motor` | Active mix of powder + water | Food-unsafe painted rods left in drink | 10–25 |
| Food-safe stir options | Use stainless spoon on motor mount you design, or manual swirl first | Hygiene | Wooden sticks that absorb slurry | — |

---

## 9. Example ASINs quick reference

> Double-check that the live listing still matches the part. ASINs get recycled or retitled.

| Part | Example ASIN | Notes |
|------|--------------|-------|
| HX711 multipack (Stemedu-style) | `B07MTYT95R` | [amazon.com/dp/B07MTYT95R](https://www.amazon.com/dp/B07MTYT95R) |
| Load cell kit (NOYITO-style) | `B07BGS58TL` | [amazon.com/dp/B07BGS58TL](https://www.amazon.com/dp/B07BGS58TL) — confirm 5 kg |
| TMC2209 (BIGTREETECH-style) | `B07ZQ3C1XW` / `B08SMDY3SQ` | [B07ZQ3C1XW](https://www.amazon.com/dp/B07ZQ3C1XW) · [B08SMDY3SQ](https://www.amazon.com/dp/B08SMDY3SQ) |
| YF-S201 flow sensor | Search `YF-S201` | Common generic |
| Pi 5 / 27W PSU / cooler | Search official / authorized sellers | Prefer reputable Pi resellers |

---

## 10. Phase 1 MVP “add to cart” list (copy/paste)

Use search keywords if ASIN drifts:

1. Raspberry Pi 5 (4 or 8 GB) — *skip if you already own a Pi 4/5*  
2. Official 27W USB-C PSU + Active Cooler  
3. microSD 64 GB A2  
4. HX711 board(s) — e.g. ASIN `B07MTYT95R`  
5. 5 kg load cell or kit — e.g. ASIN `B07BGS58TL`  
6. NEMA17 1.5–2 A, ≥40 mm body  
7. TMC2209 module — e.g. `B07ZQ3C1XW` / `B08SMDY3SQ`  
8. Coin vibration motors 10×3 mm (pack)  
9. Logic MOSFET module(s) (enough channels for vibe + pump)  
10. 12 V 10 A (or 15 A) switching PSU  
11. Terminal block + inline fuse  
12. Breadboard + Dupont kit + 18 AWG wire  
13. M3 (and M4) screw assortment  
14. 12 V food-grade peristaltic pump + matching **FC** silicone tube  
15. Food-grade check valves  
16. 2–5 L food-safe tank  
17. Multimeter / calipers if missing  

**Defer:** 10" touchscreen, 11 extra steppers, enclosure aluminum extrusion, pill hardware.

---

## 11. Full Phase 1 add-on cart

1. 7–10" HDMI capacitive touch for Pi  
2. YF-S201 flow sensor + adapters  
3. Float or capacitive level sensor  
4. IR cup sensor  
5. Quick disconnects (**FC**)  
6. Optional gear motor for stirrer  
7. Screw terminal / proto upgrade off breadboard  

---

## 12. What “food grade” should mean when you click Buy

| Prefer | Be skeptical |
|--------|--------------|
| “Food grade silicone”, “beverage”, “platinum cure” | Only “FDA” in a bullet with no material named |
| PP / HDPE / stainless tank with cleanable opening | Opaque chemical jugs with strong odor |
| Pump listings that show **silicone** tube path | Diaphragm pumps with unknown rubber and no spare parts |
| Easy-to-disassemble hoppers (your prints) | Permanent glued powder paths |

Home DIY ≠ commercial NSF certification. Still: **if you wouldn’t put it in a kitchen drink project, don’t put it in this machine.**

---

## 13. Seller / quality heuristics

- ★4.3+ with recent reviews that include photos  
- “Sold by” Amazon or known brand storefront when possible for Pi and PSUs  
- For steppers/drivers: reviews mentioning 3D printers or CNC (same use case)  
- Reject listings with stock photos only and no dimensional drawing for mechanical fit  
- Watch unit price on multipacks (HX711, vibe motors) — multipacks usually win  

---

## 14. Related docs

- [BOM.md](BOM.md) — full quantities, subtotals, power budget  
- [SHOPPING_CHECKLIST.md](SHOPPING_CHECKLIST.md) — printable checkboxes  
- [PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md) — mechanical dimensions to match parts  
