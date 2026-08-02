# Safety and Hygiene – DIY Supplement Dispenser

This machine is a **DIY home project** for preparing personal supplement drinks. It is **not** a medical device and is **not** validated for clinical or pharmaceutical dosing.

---

## 1. Disclaimer (Read First)

- **Not for medical dosing claims.** Do not market, describe, or rely on this device as accurate medication dispensing, prescription compounding, or treatment of any disease.
- Supplement labels, your physician’s advice, and your own measuring tools remain authoritative for health decisions. Machine tolerances (±0.1 g powder goal, water ±5–10 ml) are engineering targets, not a guarantee of nutritional or medical adequacy.
- You are responsible for what you put in the hoppers, how you clean the device, and whether a drink is safe for you (allergens, interactions, contaminants).
- Keep out of reach of children and pets when powered or when hoppers contain concentrated powders.
- If you feel unwell after using any self-made drink system, seek appropriate medical help.

---

## 2. Food-Contact Materials

### 2.1 Principles

| Principle | Practice |
|-----------|----------|
| Know the path | Anything that touches powder, water, or finished drink is a **food path** |
| Prefer known plastics | Food-safe rated tubing, tank, seals; PETG or smooth PLA for prototypes with thorough cleaning |
| Minimize dead zones | Steep hopper, short drop, flushable water lines |
| No mystery coatings | Avoid unknown sprays on internal powder surfaces unless food-safe and cured per label |

### 2.2 Typical Phase 1 materials

| Part | Guidance |
|------|----------|
| Hopper / auger / barrel (printed) | PETG preferred for durability/cleanability; print dense walls; wash before first food use |
| Tank | Food-grade plastic (HDPE/PP etc.) sold for drinking water |
| Tubing | Food-grade silicone or similar rated for potable water |
| Cup | Your drinking cup; dishwasher-safe preferred |
| Seals / O-rings | Food-grade silicone when in liquid path |
| Fasteners in food path | Stainless preferred; avoid bare rusting steel above the cup |

### 2.3 Prototype honesty

FDM prints are **not** perfectly smooth: layer lines can hold residue. For Phase 1 this is accepted with **aggressive cleaning** and accepting that prints are prototypes. Later phases may add food-safe liners, coatings, or commercial food-path parts where risk warrants.

**Do not** use ABS prints in the food path for first prototypes if avoidable (print fumes during manufacture; less ideal for this use case per design handoff).

### 2.4 Powders

- Only put in hoppers ingredients you would otherwise consume, from reputable sources, within date.
- Do not mix incompatible chemicals in one hopper.
- Label hoppers; avoid cross-contamination if allergens matter to your household.
- Hygroscopic powders (many supplements) clump — dry storage and lids matter as much as cleaning.

---

## 3. Cleaning Schedule

### 3.1 After every session (minimum)

- [ ] Empty or cover hoppers if the machine will sit idle more than a day with hygroscopic powder
- [ ] Wipe outlet nozzle exterior and any visible powder dust
- [ ] Wash or rinse drinking cup
- [ ] Empty and dry drip tray
- [ ] Visual check: no standing water near electronics

### 3.2 Daily use (if used every day)

- [ ] Rinse water line briefly or run a clean-water purge if water sat stagnant
- [ ] Wipe mix tool / stirrer if used
- [ ] Spot-clean scale platform (dry cloth); keep liquids off the load cell

### 3.3 Weekly (or every ~10–20 drinks)

- [ ] Empty hopper; brush out residue; wash hopper/auger/barrel if design allows disassembly
- [ ] Fully dry food-path prints before refill (moisture + powder = paste)
- [ ] Inspect tubing for biofilm haze; replace if questionable
- [ ] Clean tank interior with mild dish soap; rinse thoroughly; air dry
- [ ] Check nozzle aim and fittings for crust

### 3.4 Monthly / storage

- [ ] Deep clean all removable food-path parts
- [ ] Flush pump and tubing with clean water; optional food-safe sanitizer **compatible with your materials**, then thorough rinse
- [ ] Power off; store dry; do not leave stagnant sweet drinks in lines

### 3.5 Cleaning agents

| OK | Avoid |
|----|--------|
| Mild dish soap, warm water | Strong solvents that attack PETG/PLA (e.g. aggressive ketones on prints) |
| Dilute food-safe sanitizers per label + rinse | Bleach soaks that leave residue in powder path without complete rinse |
| Soft brushes, non-scratch cloths | Metal scrapers that gouge printed bores |

Never immerse the **load cell**, **HX711**, **Pi**, or **stepper driver**.

---

## 4. Electrical Isolation of Liquids

### 4.1 Layout rules

1. **Gravity and splash:** Electronics and HX711 sit **outside** the drip cone of the water nozzle and cup.
2. **Tray:** Use a drip tray under the dispense area; empty it before it overflows toward cables.
3. **Routing:** Tubing does not cross open terminal blocks; drip loops so a leak falls to tray, not into PSU.
4. **Barriers:** Simple plastic shield between wet zone and control zone is encouraged on the bench and required in a finished enclosure.
5. **Power:** Fused 12 V; accessible disconnect; do not leave a leaking pump running unattended.

### 4.2 If liquid contacts electronics

1. Cut power immediately (unplug mains / shut PSU).
2. Do not power on to “see if it still works.”
3. Disassemble wet modules; dry thoroughly (days if needed for connectors).
4. Inspect for corrosion; replace compromised boards.

### 4.3 Pump and tank

- Prefer pumps and fittings rated for the duty cycle; many pumps must not run dry for long.
- Level sensing or timeout protection is part of safe water control ([SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) failure modes).
- Tank lids reduce contamination and evaporation; do not use non-potable containers.

### 4.4 Grounding and low voltage

- Follow good 12 V / Pi wiring practice: common ground as required, no mains wiring experiments unless you are qualified.
- This project assumes **low-voltage DC actuation** + Pi supply adapters — do not improvise mains heaters or mains pumps without proper isolation design.

---

## 5. Mechanical and Operational Safety

| Hazard | Mitigation |
|--------|------------|
| Auger pinch | Guards/outlet design; never finger the outlet when enabled |
| Hot drivers / PSU | Ventilation; don’t rest plastics on PSU vents |
| Cup knock-off | Stable platform; software NO_CUP check |
| Overfill | Max mass limit in software; appropriately sized cup |
| Powder inhalation | Don’t dump fine powders aggressively; clean dust; basic caution for bulk powders |
| Allergens | Dedicated hoppers / full clean between allergen changes |

---

## 6. What This Device Is / Is Not

| Is | Is not |
|----|--------|
| A hobby automation for personal drinks | An FDA-cleared or CE medical dispenser |
| An accuracy *project* aiming for ±0.1 g powder | A substitute for pharmacy compounding |
| A learning platform for closed-loop dosing | Certified food-service equipment |
| Something you clean and own end-to-end | A “set and forget” sterile system |

---

## 7. Related Documents

- [ASSEMBLY_GUIDE.md](ASSEMBLY_GUIDE.md) — build-time safety callouts  
- [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md) — accuracy tests (engineering, not clinical)  
- [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) — fault responses  
- [PROJECT_PLAN.md](PROJECT_PLAN.md) — phase gates including hygiene walk-through  
