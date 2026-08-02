# Bill of Materials – DIY Supplement Drink Machine

**Last updated:** 2026-08  
**Scope:** Phase 1 (single powder + water + mix) through Phase 2 expansion notes  
**Prices:** Approximate USD retail ranges as of 2026. **Always verify current Amazon / vendor pricing.** Shipping, tax, and sales not included.

---

## How to use this BOM

| Tier | What it is | When to buy |
|------|------------|-------------|
| **Phase 1 MVP** | Bare minimum to prove powder dosing, water dosing, and a mixed drink | Order first |
| **Full Phase 1** | MVP + niceties (touchscreen, level sensor, better mixing, cleaner wiring) | Add after MVP works, or buy together if budget allows |
| **Phase 2 expansion** | Extra powder stations toward multi-module (pills later) | Only after Phase 1 accuracy is proven |

**Legend**

| Tag | Meaning |
|-----|---------|
| **Buy** | Purchase off-the-shelf |
| **3D** | Print yourself (PETG preferred for food-adjacent parts) |
| **FC** | Food-contact or food-adjacent — choose food-safe materials / grades |
| **Opt** | Optional for Phase 1 |

---

## 1. Phase 1 – Minimum Viable Kit (MVP)

Goal: one powder hopper + auger + vibration + HX711 cup scale + refillable tank + pump + basic mix + Pi control (serial / SSH is fine; no touchscreen required).

### 1.1 Computing & control

| Qty | Item | Category | Purpose | Buy/3D | ~USD | Notes |
|-----|------|----------|---------|--------|------|-------|
| 1 | Raspberry Pi 5 (4 GB OK; 8 GB preferred) | Compute | Control, HX711, steppers, UI later | Buy | 60–90 | 8 GB if you want headroom for touch UI |
| 1 | microSD 32–64 GB (A2/U3) | Compute | OS + code | Buy | 8–15 | Or use NVMe if you already have a HAT |
| 1 | Official Pi 27W USB-C PSU (or quality 5V 5A) | Power | Powers Pi only | Buy | 12–18 | Do **not** power motors from the Pi PSU |
| 1 | Active cooler / case with fan (Pi 5) | Thermal | Keeps Pi cool under load | Buy | 10–20 | Official Active Cooler is fine |
| 1 | Breadboard + jumper wire kit (M-M, M-F, F-F) | Wiring | Prototyping | Buy | 8–15 | Move to permanent wiring later |

**Subtotal computing (MVP):** ~**$100–160**

### 1.2 Powder dosing (single station)

| Qty | Item | Category | Purpose | Buy/3D | ~USD | Notes |
|-----|------|----------|---------|--------|------|-------|
| 1 | NEMA17 stepper, 1.5–2.0 A, body ≥40 mm, 5 mm shaft | Actuation | Drive auger | Buy | 12–25 | Prefer dual-shaft only if useful; single is fine |
| 1 | TMC2209 stepper driver module (UART or STEP/DIR) | Driver | Quiet, accurate microstepping | Buy | 8–15 | BIGTREETECH-style modules common |
| 1 | 5 kg bar load cell (rectangular, bathroom-scale style) | Sensing | Weigh cup for closed-loop powder | Buy | 5–12 | Standard ~12.7 × 12.7 × 80 mm form factor |
| 1 | HX711 amplifier board (or kit with load cell) | Sensing | Load-cell ADC → Pi GPIO | Buy | 3–10 | Buy spare; cheap and useful |
| 2–5 | Coin vibration motors Ø10–12 mm × ~3 mm, 3 V | Actuation | Anti-clog / anti-bridge on hopper | Buy | 5–12 | Pack of 10 is cheapest; FC-adjacent housing only |
| 1 | Logic-level MOSFET module (or opto MOSFET) for vibe | Switching | Drive vibration motor from 3.3 V GPIO | Buy | 5–10 | Or share a multi-channel MOSFET board |
| 1 | 5 mm shaft coupler / flex coupler (optional) | Mechanical | Auger ↔ NEMA17 if not direct-drive print | Buy | 4–8 | Printed coupling often enough for Phase 1 |
| 1 | Powder hopper (steep cone, 65° walls) | Mechanical | Hold powder | **3D** | filament | See design handoff; **FC** after post-process |
| 1 | Auger housing + outlet nozzle | Mechanical | Meter powder | **3D** | filament | **FC**-adjacent |
| 1 | Auger screw (1–2 pitch variants) | Mechanical | Meter powder | **3D** | filament | Print 2 pitches to A/B test |
| 1 | Module stand / feet | Mechanical | Clearance for cup + load cell | **3D** | filament | |
| 1 | Load-cell cup platform / holder | Mechanical | Mount 5 kg cell + cup | **3D** | filament | Match cell hole pattern |

**Subtotal powder (bought parts only):** ~**$45–90**  
**Printed parts:** use PETG from inventory (~50–150 g for first module set)

### 1.3 Water system (refillable tank)

| Qty | Item | Category | Purpose | Buy/3D | ~USD | Notes |
|-----|------|----------|---------|--------|------|-------|
| 1 | Food-safe tank 2–5 L, removable | Water | Reservoir | Buy | 10–25 | **FC**. Camping jug, beverage dispenser, or lab carboy |
| 1 | 12 V food-grade peristaltic pump **or** diaphragm pump | Water | Move water into cup | Buy | 15–40 | **FC** tubing path preferred; see Amazon guide |
| 1–2 m | Food-grade silicone tubing (ID matched to pump) | Water | Plumbing | Buy | 8–20 | **FC**. Match pump barb size (often 4–8 mm ID) |
| 2–4 | Check valves, food-grade (same tube ID) | Water | Anti-siphon / backflow | Buy | 6–15 | **FC** |
| 4–8 | Hose clamps or spring clips | Water | Secure tubing | Buy | 5–10 | |
| 1 | Logic-level MOSFET or opto-isolated relay (12 V pump) | Switching | Switch pump from Pi | Buy | 5–12 | Relay OK if pump is noisy inductive load |
| 1 | Tank mount / lid adapter (optional) | Mechanical | Hold tank on bench rig | **3D** | filament | |

**Water volume control (pick one path for MVP):**

| Option | Qty | Item | ~USD | Tradeoff |
|--------|-----|------|------|----------|
| **A – Timed pump (simplest)** | — | Software timed run of known flow rate | $0 | Calibrate once; OK for MVP |
| **B – Flow sensor** | 1 | Hall flow sensor YF-S201 (or similar) | 5–12 | Better repeatability |
| **C – Solenoid + gravity / pressure** | 1 | 12 V food-grade solenoid valve | 10–20 | More plumbing complexity |

**Recommended MVP:** timed peristaltic (A); add flow sensor when refining.

**Subtotal water (bought, path A):** ~**$50–120**

### 1.4 Mixing (minimal)

| Qty | Item | Category | Purpose | Buy/3D | ~USD | Notes |
|-----|------|----------|---------|--------|------|-------|
| 1 | User cup (disposable or reusable) | Mix | Receive powder + water | Buy | 0–5 | Manual swirl OK for first tests |
| 0–1 | Mini DC mixer / magnetic stirrer later | Mix | Optional mechanical stir | Buy | 10–30 | **Opt** for true MVP |

**Subtotal mix MVP:** ~**$0–5** (use existing cups)

### 1.5 Power (shared 12 V rail)

| Qty | Item | Category | Purpose | Buy/3D | ~USD | Notes |
|-----|------|----------|---------|--------|------|-------|
| 1 | 12 V switching PSU, **≥10 A** (15 A nicer) | Power | Steppers, pump, vibe (if 12 V), relays | Buy | 20–40 | Mean Well–class quality preferred over no-name |
| 1 | Terminal block / distribution board | Wiring | Clean 12 V / GND distribution | Buy | 6–15 | |
| 1 | Inline fuse holder + fuse (on 12 V) | Safety | Short protection | Buy | 3–8 | Size to PSU / load (e.g. 5–10 A) |
| — | Hookup wire 18–22 AWG, assorted | Wiring | Power + signal | Buy | 8–15 | |

**Subtotal power:** ~**$40–80**

### 1.6 Fasteners & misc (MVP)

| Qty | Item | Category | Purpose | Buy/3D | ~USD | Notes |
|-----|------|----------|---------|--------|------|-------|
| 1 kit | M2 / M3 screw + nut + washer assortment | Hardware | Motors, hoppers, load cell | Buy | 8–15 | Include M3×8–20 and M4 for some load cells |
| 1 | Digital multimeter (if you don’t own one) | Tools | Debug power / continuity | Buy | 15–40 | Essential |
| 1 | Calibration weights or known coins/weights | Cal | HX711 calibration | Buy | 0–15 | Kitchen scale + known object also works |

**Subtotal misc:** ~**$10–50** (tools often already owned)

### Phase 1 MVP – cost summary (bought parts)

| Group | Approx. range (USD) |
|-------|---------------------|
| Computing & control | 100–160 |
| Powder dosing (electronics) | 45–90 |
| Water system | 50–120 |
| Mixing | 0–5 |
| Power distribution | 40–80 |
| Fasteners / smalls | 10–30 |
| **MVP grand total (parts)** | **~$245–485** |
| Filament (PETG, first module) | 5–15 of filament cost |
| Tools you may already own | 0–50 |

> Order **MVP first**. Do not buy 12 steppers or a full enclosure until ±0.1 g powder dosing works with real creatine / protein.

---

## 2. Full Phase 1 – Niceties (recommended upgrades)

Add these when the open-loop / closed-loop powder path works, or include them in the first cart if you want a nicer bench rig.

| Qty | Item | Category | Purpose | Buy/3D | ~USD | Notes |
|-----|------|----------|---------|--------|------|-------|
| 1 | 7–10" HDMI capacitive touchscreen for Pi | UI | Recipe / test UI | Buy | 50–120 | 7" cheaper; 10" more “vending” feel |
| 1 | Official or quality HDMI + USB touch cable set | UI | Screen ↔ Pi | Buy | 0–15 | Often bundled with screen |
| 1 | Float level sensor **or** capacitive non-contact level | Water | Low-water detect | Buy | 5–15 | **FC** if immersed float |
| 1 | IR / ultrasonic cup presence sensor | Sensing | Don’t dispense with no cup | Buy | 3–12 | **Opt** but highly useful |
| 1 | Hall flow sensor YF-S201 (if not in MVP) | Water | Closed-loop water volume | Buy | 5–12 | |
| 1 | Small DC gear motor + printed stirrer **or** USB mug mixer | Mix | Active mixing | Buy | 10–35 | Food-safe stir rod path |
| 1 | Quick-disconnect fittings (food-grade) | Water | Easy tank removal | Buy | 10–25 | **FC** |
| 1 | Drip tray + grate (printed or bought) | Hygiene | Catch spills | Buy/3D | 5–20 | |
| 1 | DIN rail / protoboard / screw terminals | Wiring | Move off breadboard | Buy | 10–25 | |
| 1 | Buck converter 12 V → 5 V (optional) | Power | Power peripherals from 12 V rail | Buy | 5–12 | Pi still best on its own 27W PSU |
| 1 pack | Dupont → JST / proper connectors | Wiring | Strain relief | Buy | 5–15 | |
| 1 | Enclosure panels / simple frame | Mech | Bench or wall-look box | **3D**/Buy | filament / 20–60 | Aesthetics not required for validation |

**Full Phase 1 niceties subtotal:** ~**$100–280**  
**Full Phase 1 total (MVP + niceties):** ~**$350–750**

---

## 3. Phase 2 – Expansion (multi-station path)

After Phase 1 success criteria (reliable flow + ±0.1 g), scale powder stations. Pills are a separate mechanical design — budget below is for **powder stations only** unless noted.

### Per additional powder station (repeat × N)

| Qty | Item | ~USD each station |
|-----|------|-------------------|
| 1 | NEMA17 1.5–2 A | 12–25 |
| 1 | TMC2209 module | 8–15 |
| 1–2 | Coin vibration motor | 1–3 |
| 1 | MOSFET channel (or share multi-ch board) | 2–8 |
| 1 set | Printed hopper + auger + housing | filament |
| — | Extra load cell? | Usually **one shared cup scale** for Phase 2, not one per hopper |

**Per-station electronics ≈ $25–50** (shared HX711 under cup remains one unit)

### Shared Phase 2 items

| Qty | Item | Purpose | ~USD |
|-----|------|---------|------|
| 1 | Larger 12 V PSU (15–30 A) if many steppers move | Power headroom | 30–70 |
| 1 | Multi-channel MOSFET / relay board | Vibe + aux loads | 15–30 |
| 1 | Frame / rail system for N hoppers | Mechanical | 3D + fasteners |
| 0–N | Pill modules (TBD design) | Solid dose | Design later |
| 1 | Better HMI (same 7–10" touch) | Multi-recipe UI | already in Full P1 |
| 1 | WiFi — onboard Pi | Remote / inventory later | $0 |

### Example Phase 2 target: 4 powder stations total

| Item | Approx. |
|------|---------|
| 3 × additional station kits | 75–150 |
| Frame / wiring / PSU upgrade | 50–120 |
| **Add-on from working Phase 1** | **~$125–270** |

### Example long-term: 12 powder stations

| Item | Approx. |
|------|---------|
| 11 × station electronics | 275–550 |
| Heavy frame, panels, cabling | 100–300 |
| PSU upgrade, distribution | 40–100 |
| Pill modules (unknown) | TBD |
| **Rough add-on (powders only)** | **~$400–950** |

> Grand total for a polished 12-station vending unit (parts only, not labor) is commonly cited in the **~$800–2000+** band depending on screen, enclosure materials, and pump quality. Treat that as a planning envelope, not a quote.

---

## 4. 3D printed vs bought (summary)

### Print (PETG recommended; food-adjacent)

| Part | Phase | Food-contact notes |
|------|-------|--------------------|
| Powder hopper (65° cone) | 1 | **FC** surface — smooth print, easy clean; optional food-safe coating later |
| Auger screw + barrel/housing | 1 | **FC**-adjacent — powder path; design for disassembly |
| Module stand / feet | 1 | Non-contact |
| Load-cell platform / cup holder | 1 | Cup sits on top; keep dry side separate from electronics |
| Tank adapters, drip tray, mixer mounts | 1–2 | **FC** where water/powder touch |
| Multi-module frame, panels | 2+ | Mostly structural |
| Pill module bodies | 2+ | **FC** for dose path |

**Avoid** for food path: ABS fumes/warping for first prototypes; recycled mystery filament for powder-contact surfaces.

### Buy (do not reinvent)

| Part | Why buy |
|------|---------|
| Pi, screen, PSUs | Safety, EMI, reliability |
| NEMA17, TMC2209, HX711, load cells | Precision / commodity |
| Pumps, silicone tube, check valves | **FC** certifications easier off-shelf |
| Vibration motors, MOSFETs, sensors | Cheap and standardized |
| Fasteners, terminal blocks | Strength and serviceability |

---

## 5. Alternatives – budget vs premium

| Function | Budget pick | Premium pick | Notes |
|----------|-------------|--------------|-------|
| Compute | Pi 4 4GB used / existing | Pi 5 8GB + Active Cooler + NVMe | Phase 1 works on either |
| Touchscreen | 7" HDMI capacitive ~$50–70 | 10" IPS capacitive ~$90–120 | Defer screen until powder works if saving cash |
| Stepper | Generic 42N·cm NEMA17 ~$12 | Name-brand low-backlash ~$25 | Generic fine for auger |
| Driver | A4988 / DRV8825 ~$3–5 | **TMC2209** ~$8–15 | TMC strongly preferred (quiet, less resonance) |
| Load cell | 5 kg bar bare ~$5 | Kit with HX711 + acrylic plates ~$12–20 | Kit saves mount design time |
| Water pump | Cheap 12 V diaphragm ~$15 | Food-grade peristaltic silicone ~$25–40 | Peristaltic = better hygiene story |
| Water volume | Timed pump | YF-S201 + calibration | Sensor worth it by Full Phase 1 |
| 12 V PSU | No-name 12 V 10 A ~$20 | Mean Well LRS-150/200-12 ~$30–45 | Better ripple and longevity |
| Mixing | Manual swirl | Dedicated stir motor + printed paddle | Hygiene: removable paddle |
| Wiring | Breadboard forever | Screw terminals + ferrules | Reliability |

---

## 6. Power budget summary

Assumptions: Phase 1 Full (1× NEMA17, 1× pump, 1× vibe, Pi 5, screen). Steppers rarely run continuous stall current if current-limited on TMC2209.

### 5 V / Pi side

| Load | Typical draw | Notes |
|------|--------------|-------|
| Raspberry Pi 5 (idle–loaded) | 1.5–4 A @ 5 V | Use **official 27W (5.1 V / 5 A)** USB-C |
| 7–10" HDMI touchscreen | 0.5–1.5 A @ 5 V | Often powered from Pi USB or separate 5 V |
| HX711 | < 20 mA | GPIO / 5 V or 3.3 V per board design |
| Logic / sensors | < 100 mA | IR, level, etc. |
| **Pi rail budget** | **Use dedicated Pi PSU** | Do not share motor PSU without proper buck + filtering |

### 12 V rail

| Load | Peak (approx.) | Duty / notes |
|------|----------------|--------------|
| NEMA17 @ ~1.5 A RMS (chopper) | ~1.5–2.0 A | Short bursts while dosing |
| TMC2209 + logic | included above | Set `I_run` appropriately |
| 12 V pump (peristaltic / diaphragm) | 0.5–2.0 A | Seconds per drink |
| Coin vibe motor (if driven 5 V from buck or 3 V) | 0.05–0.2 A | Often **not** on 12 V — use 3–5 V via MOSFET |
| Solenoid (if used) | 0.3–1.0 A | Short open time |
| Relay coils / MOSFET boards | < 0.1 A | |
| **Phase 1 continuous-ish peak** | **~3–5 A** | **10 A PSU is comfortable** |
| **Phase 2 (4 steppers, not all simultaneous)** | **~5–10 A** | Size for worst-case simultaneous moves |
| **Phase 2 (12 stations, sequenced)** | **~8–15 A** | Sequence motors; 15–20 A PSU headroom |

### Power design rules

1. **Separate** Pi 5 V PSU from 12 V motor/pump PSU.  
2. Common **GND** between Pi and 12 V system (required for logic-level MOSFETs / STEP signals).  
3. Fuse the 12 V positive near the PSU.  
4. Use flyback diodes / modules with built-in protection on inductive loads (pumps, solenoids).  
5. Set TMC2209 current so the motor is strong enough but not scorching hot.

### Quick reference table

| Rail | Source | Phase 1 recommend | Phase 2 (multi) recommend |
|------|--------|-------------------|---------------------------|
| 5 V (Pi) | Official 27W USB-C | 27W | 27W (unchanged) |
| 5 V (aux / vibe) | Buck from 12 V or USB | 3 A buck optional | Multi-rail distribution |
| 12 V | Switching PSU | **10 A min, 15 A nice** | **15–30 A** depending on concurrency |

---

## 7. Food-contact & hygiene checklist

Mark these as **FC** when shopping:

- [ ] Tank material rated food-safe (PP, HDPE, stainless, glass)  
- [ ] Pump labeled food-grade / beverage / with silicone tubing  
- [ ] Silicone tubing platinum-cure or explicitly food-grade  
- [ ] Check valves / QD fittings food-grade  
- [ ] Printed powder path: PETG, smooth walls, removable for wash  
- [ ] No bare copper/brass in long-term wet path unless known potable-safe  
- [ ] Drip tray emptyable; no standing water near electronics  
- [ ] Design for dry powder side vs wet water side separation  

This machine is a **home DIY project**, not a certified commercial food appliance. Use common sense: clean regularly, don’t leave wet powder sludge in hoppers, and prefer materials you’d accept for kitchen DIY gadgets.

---

## 8. Suggested buy order

1. **Week 1 – prove powder:** Pi (if needed), HX711 + 5 kg cell, NEMA17, TMC2209, vibe motors, MOSFET, 12 V PSU, fasteners, PETG filament → print hopper/auger.  
2. **Week 2 – add water:** tank, peristaltic + silicone + check valves, pump MOSFET/relay.  
3. **Week 3 – refine:** flow sensor, level sensor, cup sensor, mix motor, leave breadboard.  
4. **When boringly reliable:** touchscreen UI, nicer wiring, then Phase 2 extra stations.

---

## 9. Grand totals (planning only)

| Configuration | Approximate parts cost (USD) |
|---------------|------------------------------|
| Phase 1 MVP | **$245–485** |
| Full Phase 1 (MVP + niceties) | **$350–750** |
| + 3 extra powder stations (4 total) | **+$125–270** |
| Path toward ~12 powder stations (add-on envelope) | **+$400–950** |
| Filament (prototype iterations) | **$20–60** over several revisions |

Prices fluctuate; **verify on Amazon / vendors before ordering**. See [BOM_AMAZON.md](BOM_AMAZON.md) for search keywords, example ASINs, and cart strategy, and [SHOPPING_CHECKLIST.md](SHOPPING_CHECKLIST.md) for printable checkboxes.

---

## Related docs

- [PROJECT_PLAN.md](PROJECT_PLAN.md) – phase goals  
- [PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md) – hopper / auger dimensions  
- [BOM_AMAZON.md](BOM_AMAZON.md) – Amazon shopping guide  
- [SHOPPING_CHECKLIST.md](SHOPPING_CHECKLIST.md) – Phase 1 / Phase 2 checklists  
