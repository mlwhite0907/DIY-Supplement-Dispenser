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
4. Check **food-grade** wording on anything in the wet path (tank, tube, pump head, check valves). PETG prints are **DIY provisional** only — see [SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md).  
5. After MVP works: Full Phase 1 niceties (touchscreen, sensors, mix motor).  
6. Phase 2: multiply powder electronics; keep **one shared** cup load cell.

### Approximate cart totals (parts only, USD)

| Cart | Rough total |
|------|-------------|
| Phase 1 MVP | **~$250–500** |
| Full Phase 1 add-ons | **+$100–280** |
| Per extra powder station | **+$25–50** electronics |

> **⚠ Top shopping traps (do not skip)**  
> 1. **TMC2209** example ASINs are often **printer stepsticks** — need carrier/breakout or careful pin wiring; **not** a plug-and-play Pi module.  
> 2. **Load cell kits** (e.g. B07BGS58TL): **select 5 kg** — default is often 20 kg (worse ±0.1 g resolution).  
> 3. **Coin vibe:** electrical default is **5 V** on MOSFET from 5 V rail — not 3 V.  
> 4. **12 V PSU:** **5 A is enough for Phase 1**; 10 A is multi-station headroom later.  
> 5. Every example ASIN below is **verify listing** only (title, options, seller).

---

## How to use the tables

| Column | Meaning |
|--------|---------|
| **Search keywords** | Paste into Amazon search (preferred when ASINs drift) |
| **Example ASIN / link** | Commodity examples — **verify listing** still matches the part |
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
| **Example ASIN** | `B07MTYT95R` (**verify listing** — Stemedu-style 5PCS HX711 multipack) |
| **Link** | [dp/B07MTYT95R](https://www.amazon.com/dp/B07MTYT95R) · [Search: HX711](https://www.amazon.com/s?k=HX711+load+cell+amplifier) |
| **Why** | 24-bit ADC for strain-gauge load cells; industry-standard for DIY scales |
| **Avoid** | Broken-out boards with no silkscreen; assuming every “HX711” breakout is 3.3 V-safe on DOUT without checking (most work with Pi 3.3 V logic; still verify) |
| **~Price** | $6–15 for multipacks — check **unit** price on multipacks |

### 5 kg load cell (bar / bathroom-scale style)

| | |
|--|--|
| **Search** | `5kg load cell bar` `HX711 load cell kit 5kg` `NOYITO load cell` |
| **Example ASIN** | `B07BGS58TL` (**verify listing** — NOYITO-style kits; **must select 5 kg variant**) |
| **Link** | [dp/B07BGS58TL](https://www.amazon.com/dp/B07BGS58TL) · [Search: 5kg load cell HX711](https://www.amazon.com/s?k=5kg+load+cell+HX711+kit) |
| **Why** | Closed-loop powder dosing: cup sits on cell; software runs auger until target grams |
| **Avoid** | Accepting the listing’s **default 20 kg** option (worse resolution for ±0.1 g); 50 kg cells; half-bridge single-strain cheapies without four-wire docs |
| **~Price** | Bare cell $5–12; kit $10–20 |

> **⚠ Load cell trap — B07BGS58TL and similar kits**  
> - **Select 5 kg** in the size/options dropdown. Default is often **20 kg**.  
> - **20 kg = worse resolution** for small powder doses (±0.1 g targets suffer).  
> - Real bar dims may be ~**76 × 13.5 mm**; CAD / handoff often assumes ~**80 × 12.7 mm**.  
> - **Verify hole pattern** (M4 or M5) with calipers before finalizing the printed cup platform.

**Mount tip:** Do **not** trust “standard 80 mm” blindly — measure after arrival. Design/adjust the 3D cup platform around the actual hole spacing.

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

### TMC2209 driver (stepstick / carrier)

| | |
|--|--|
| **Search (chip form)** | `TMC2209 BIGTREETECH` `TMC2209 stepper driver UART` |
| **Search (easier Pi wiring)** | `TMC2209 standalone` `TMC2209 breakout` `stepstick expansion board` |
| **Example ASIN** | `B07ZQ3C1XW` or `B08SMDY3SQ` (**verify listing** — usually BIGTREETECH-style **printer stepsticks**) |
| **Link** | [dp/B07ZQ3C1XW](https://www.amazon.com/dp/B07ZQ3C1XW) · [dp/B08SMDY3SQ](https://www.amazon.com/dp/B08SMDY3SQ) · [Search: TMC2209](https://www.amazon.com/s?k=TMC2209+BIGTREETECH+stepper+driver) · [Search: TMC2209 standalone](https://www.amazon.com/s?k=TMC2209+standalone) · [Search: stepstick expansion](https://www.amazon.com/s?k=stepstick+expansion+board) |
| **Why** | Quiet StealthChop, good microstepping, tunable current — better powder metering than A4988 clunk |
| **Avoid** | Treating a bare stepstick as a “plug into Pi” module; counterfeit “TMC”; multipacks that hide poor unit price; UART level issues (STEP/DIR-only is fine for Phase 1) |
| **~Price** | $8–15 per stick; multipacks common — **check unit cost** before buying 5-packs for one station |

> **⚠ TMC2209 is a printer stepstick — not a plug-and-play Pi module**  
> ASINs like **B07ZQ3C1XW** / **B08SMDY3SQ** (verify listing) are typically **SilentStepStick-form 3D-printer drivers**. They are **not** a ready HAT/breakout with labeled Dupont-friendly rails.  
> **You need one of:**  
> 1. A **stepstick expansion / carrier board** (or printer mainboard footprint), **or**  
> 2. **Careful pin wiring** — VMOT (12 V), GND, VIO/logic, STEP, DIR, EN, motor A/B coils — with correct 3.3 V logic assumptions.  
> **Prefer searching:** `TMC2209 standalone`, `TMC2209 breakout`, or `stepstick expansion board` if you want fewer pinout mistakes.  
> **Multipack warning:** 5-packs look cheap; fine for Phase 2, wasteful before one station works. Compare **$/driver**.

---

## 4. Vibration motors + switching

### Coin / pancake vibration motors (**5 V electrical default**)

| | |
|--|--|
| **Search** | `coin vibration motor 10x3mm 5V` `1027 vibration motor 5V` `pancake vibrator motor 10mm` |
| **Link** | [Search: coin vibe 10x3 5V](https://www.amazon.com/s?k=coin+vibration+motor+10x3mm+5V) · [Search: coin vibe 10mm](https://www.amazon.com/s?k=coin+vibration+motor+10x3mm) |
| **Why** | Anti-bridging on hopper wall / barrel pocket (see Phase 1 handoff Ø10–12 × ~3 mm) |
| **Default wiring** | **5 V coin motor** → MOSFET switch from **5 V rail**; Pi GPIO only drives the MOSFET gate |
| **3 V motors** | **Only** with a **series resistor** from 5 V, or a dedicated **3 V supply** — not the project electrical default |
| **Avoid** | Documenting/wiring as if 3 V is the system default; huge eccentric motors that don’t fit the pocket; 12 V industrial vibrators for Phase 1 |
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

### 12 V PSU — **5 A Phase 1 / 10 A future**

| | |
|--|--|
| **Search (Phase 1 MVP)** | `12V 5A switching power supply` |
| **Search (headroom / multi-station later)** | `12V 10A switching power supply` `Mean Well LRS-150-12` |
| **Link** | [Search: 12V 5A PSU](https://www.amazon.com/s?k=12V+5A+switching+power+supply) · [Search: 12V 10A PSU](https://www.amazon.com/s?k=12V+10A+switching+power+supply) · [Search: Mean Well 12V](https://www.amazon.com/s?k=Mean+Well+LRS-150-12) |
| **Why** | Powers NEMA17 VMOT + 12 V pump. Phase 1 peak is ~**3–5 A** → **12 V 5 A is enough for MVP**. **10 A** is optional headroom for multi-station Phase 2 — **not required** for first cart |
| **Avoid** | Treating “must be 10 A” as an MVP rule; undersized 2 A “LED” supplies; powering Pi from this without a proper buck; skipping fuse on 12 V |
| **~Price** | 5 A ~$15–30; 10–15 A ~$20–45 |

> **⚠ PSU sizing**  
> - **Phase 1 MVP:** **12 V 5 A** covers one stepper + pump with margin.  
> - **10 A:** buy when you add stations or want spare headroom — not a hard MVP requirement.  
> - Coin vibe is on the **5 V** rail (not this PSU’s current budget in the usual design).

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

## 9. Example ASINs quick reference (**verify listing**)

> **Verify listing** every time: ASINs get recycled, retitled, or option-defaults change. Prefer search keywords if the page no longer matches.

| Part | Example ASIN | Notes |
|------|--------------|-------|
| HX711 multipack (Stemedu-style) | `B07MTYT95R` | [amazon.com/dp/B07MTYT95R](https://www.amazon.com/dp/B07MTYT95R) — **verify listing**; multipack unit price |
| Load cell kit (NOYITO-style) | `B07BGS58TL` | [amazon.com/dp/B07BGS58TL](https://www.amazon.com/dp/B07BGS58TL) — **select 5 kg** (not 20 kg default) |
| TMC2209 (BIGTREETECH-style stepstick) | `B07ZQ3C1XW` / `B08SMDY3SQ` | [B07ZQ3C1XW](https://www.amazon.com/dp/B07ZQ3C1XW) · [B08SMDY3SQ](https://www.amazon.com/dp/B08SMDY3SQ) — **printer stepsticks**; need carrier or pin wiring; multipack pricing trap |
| YF-S201 flow sensor | Search `YF-S201` | Common generic |
| Pi 5 / 27W PSU / cooler | Search official / authorized sellers | Prefer reputable Pi resellers |

---

## 10. Phase 1 MVP “add to cart” list (copy/paste)

Use search keywords if ASIN drifts. All ASINs = **verify listing**.

1. Raspberry Pi 5 (4 or 8 GB) — *skip if you already own a Pi 4/5*  
2. Official 27W USB-C PSU + Active Cooler  
3. microSD 64 GB A2  
4. HX711 board(s) — e.g. ASIN `B07MTYT95R` (**verify listing**)  
5. **5 kg** load cell or kit — e.g. ASIN `B07BGS58TL` — **select 5 kg option** (not 20 kg)  
6. NEMA17 1.5–2 A, ≥40 mm body  
7. TMC2209 — e.g. `B07ZQ3C1XW` / `B08SMDY3SQ` (**verify listing**; **stepstick** — plan carrier/breakout or pin wiring; or search `TMC2209 standalone`)  
8. Coin vibration motors 10×3 mm, prefer **5 V** (pack) — MOSFET from 5 V rail  
9. Logic MOSFET module(s) (enough channels for vibe + pump)  
10. **12 V 5 A** switching PSU (enough for Phase 1); **10 A** only if you want multi-station headroom early  
11. Terminal block + inline fuse  
12. Breadboard + Dupont kit + 18 AWG wire  
13. M3 (and M4/M5) screw assortment — match load-cell holes after measure  
14. 12 V food-grade peristaltic pump + matching **FC** silicone tube  
15. Food-grade check valves  
16. 2–5 L food-safe tank  
17. Multimeter / calipers if missing  

**Defer:** 10" touchscreen, 11 extra steppers, enclosure aluminum extrusion, pill hardware.

**Honest Phase 1 MVP total:** ~**$250–500** parts (prices vary; verify live).

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

> **⚠ PETG / printed powder path**  
> PETG is **DIY provisional** for hoppers/augers — practical and cleanable for home prototypes, **not** certified food equipment. This project is **not** NSF/commercial food-service gear.  
> Full hygiene, cleaning, and disclaimers: **[SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md)**.

Home DIY ≠ commercial NSF certification. Still: **if you wouldn’t put it in a kitchen drink project, don’t put it in this machine.**

---

## 13. Seller / quality heuristics

- ★4.3+ with recent reviews that include photos  
- “Sold by” Amazon or known brand storefront when possible for Pi and PSUs  
- For steppers/drivers: reviews mentioning 3D printers or CNC (same use case) — remember those **TMC** listings are often **stepsticks**  
- Reject listings with stock photos only and no dimensional drawing for mechanical fit  
- Watch **unit** price on multipacks (HX711, TMC2209, vibe motors) — multipacks usually win **per unit**, but don’t over-buy Phase 2 qty early  
- On multi-option listings (load cell kg rating): open the dropdown — **defaults lie**

---

## 14. Related docs

- [BOM.md](BOM.md) — full quantities, subtotals, power budget  
- [SHOPPING_CHECKLIST.md](SHOPPING_CHECKLIST.md) — printable checkboxes  
- [PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md) — mechanical dimensions to match parts  
- [SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md) — food-contact, PETG provisional, cleaning  
