# Dose Bar v5: design intent

## How you use it (v5.1)

1. **Set the dial once.**
   - Pull the dose handle out (that empties the measuring chamber), lift the dial ~1.6 mm, turn it to your mL and let go.
   - It drops into a lock, so nothing can bump it off.
   - Push the handle back in.
2. **Every dose: pull the handle out to its stop.**
   - It's a smooth ~2.8 in drawer pull, and one level dose drops into the **dose drawer** in the pedestal below.
   - Push the handle back in; that refills the measuring chamber for next time.
3. **Slide the dose drawer out and pour** it into your cup (it has a pour spout). Slide it back.

Two pulls before pouring = a double dose. Heads sit on their own low pedestals and line up side by side on a table, counter or cabinet shelf.

> **v5.1 note.** The design review changed four things:
> - The drawer travels farther (≈72 mm), so a dose is always fully sealed off before it drops.
> - It's push–pull instead of spring-return, so there's no slam, every grain falls, and there are fewer parts.
> - The dial locks.
> - The chuck turns like a jar lid in the refill position.
>
> The numbered sections below are the original draft-0 intent. `cad/v5/README.md` ("v5.1 OVERRIDES") is authoritative where they differ.

## 1. What it is

A manual, no-electronics powder dispenser built around the glass jars you already own.

- Each jar is flipped upside down onto its own **head**.
- You set a **dose dial**, in mL, once.
- Each **pull** of the dose handle drops one dose into the **dose drawer** below. Let go and the handle springs back. Slide the dose drawer out and pour.
- Each head sits on its own **pedestal**. Pedestals line up side by side, and adding a jar means printing one more head.

| Goal | How v5 meets it |
|---|---|
| ≥ 10 powders | One head per jar. The bar is modular with no upper limit. |
| One pull = correct dose | Volumetric chamber, struck level, dropped through a sealed path |
| Adjustable but preset | Single-turn mL dial with clicks. **0 = closed / off.** |
| No holes in lids | The lid comes off. A 3-jaw twist chuck grips the glass neck and the rim sits on a TPU gasket. |
| Print at home, same day | **PLA + TPU only.** Bambu Lab P2S (256³ mm). Screws from a general assortment. **No metal springs, nothing to buy.** |
| Any jar, any time | Every part is generated from three jar measurements, so a new jar means a new preset file and a print. |
| Beautiful and uniform | One design language across every part: same radii, flutes, type, colors. |

## 2. Hard constraints

1. **Materials:** PLA (rigid parts) and TPU 95A (springs, seals, pads, detent). No PETG, no metal springs, no glue-critical joints.
2. **PLA limits:**
   - Tg ≈ 55–60 °C, so hand-wash lukewarm only: no dishwasher, no hot car.
   - PLA creeps under sustained load, so there are no permanently stressed PLA snaps or flexures. Any part that must stay springy is TPU.
3. **Printer:** Bambu Lab P2S, 0.4 mm nozzle, 256 × 256 × 256 mm. AMS 2 Pro for multi-color PLA. TPU runs from the external spool.
4. **Fasteners:** a general screw and bolt assortment. Design for **M3 and M4 machine screws** self-tapped into printed pilots, and printed pins. No heat-set inserts required.
5. **No supports** on any part if at all possible (cosmetic and functional faces stay clean).
6. **Food contact:** dry powders only. Every powder-contact surface can be taken apart by hand and washed.

## 3. Jars (measured with lids on)

| Preset | Qty | Lid OD | Height (lid on) | Neck OD* | Mouth ID* |
|---|---|---|---|---|---|
| `std` | 9 (7 tall, 2 short) | 4.5 in ≈ 114 mm | 6.5 in ≈ 165 mm (7), ≈ 117 mm (2) | ≈ 108 | ≈ 96 |
| `pro` | 1 (protein) | 5 in ≈ 127 mm | 11.5 in ≈ 292 mm | ≈ 121 | ≈ 108 |

\*Estimated from lid OD. The chuck covers ±10 mm around the nominal neck OD, so the estimates only need to be close. Measuring with the lid off (see `MEASURE_YOUR_JAR.md`) tightens them.

## 4. Architecture (one head)

```
            ┌───────── glass jar (upside down) ─────────┐
            │                                           │
            └──────────┐                     ┌──────────┘
                       │  neck (threads)     │ ← 3 jaws grip here (TPU pads)
   twist ring ═════════╧═════ gasket ════════╧═════════ (scroll ring, knurled)
   guide plate ─────────\                   /────────── (fixed, jaw slots)
   deck / funnel          \   stir wand   /
                           \______||______/   ← throat (strike-off edge = front)
   slide ════[rear section][CHAMBER|plunger]══rod══[dial]═[pull]  → pulls forward
   floor ─────────────────────────────╲  drop hole  ╱──────────
                                       ╲__spout___╱
                                          ↓ cup
```

### 4.1 Dosing principle

A horizontal **slide** (drawer) runs in a channel under the jar.

1. **Rest:** the chamber (an open-top, open-bottom pocket in the slide) sits under the throat and fills by gravity. Its bottom sits on the solid channel floor.
2. **Pull:** the slide moves forward. The throat's **front edge strikes the powder off level**, and the chamber is sealed top and bottom while it travels.
3. **End of stroke:** the chamber's open bottom is over the **drop hole**, and the dose falls down the spout into the cup.
4. **Release:** TPU bands pull the slide back. The chamber returns under the throat and refills.

Throughout the stroke the throat stays covered by the slide's solid **rear section**, so nothing pours through.

**Live bottom.** The slide top shears the powder above it on every stroke, and the **stir wand** (§4.5) sweeps the funnel and the jar neck.

### 4.2 Adjustable chamber (the dial)

- The chamber's **rear wall is fixed** in the slide. Its **front wall is a plunger** block.
- The plunger slides in the slot and carries a **rack rod** forward to the handle.
- A **pinion under the dial** drives the rack. The dial is a single turn, ~300°, with **40 clicks**. Hard stops sit at 0 and at max.
- **Dial at 0:** the plunger touches the rear wall, so the chamber volume is zero and the head is locked off.
- The plunger is at least as long as the throat. Whatever the setting, the part of the throat not over the chamber sits over the plunger's solid top.
- **Locking dial ("set it and forget it"):**
  - Matching V-teeth under the dial and on a keyed PLA lock ring hold it in one of 40 positions.
  - Lift the dial 2.4 mm to turn it. A TPU spring pulls it back down into the lock.
  - Pulling the handle or bumping the dial can't change the dose.

| Dose class | Range | Per click | Chamber W × H (mm) | L_max (mm) | Pinion |
|---|---|---|---|---|---|
| S (small jars) | 0–20 mL | 0.5 mL | 40 × 18 | 27.8 | m1 × z11 (r_p 5.5 → 28.8 mm / 300°) |
| **M (`std`)** | **0–40 mL** | **1 mL** | **53 × 24** | **31.4** | **m1 × z12** |
| **L (`pro`)** | **0–80 mL** | **2 mL** | **62.4 × 28** | **45.8** | **m1.25 × z14** |

These numbers are approximate and will be re-solved in the parametric model, so that **one click = exactly the stated mL**.

### 4.3 Geometry rules (slide/channel)

Coordinates: y runs forward. y = 0 is the throat rear edge and the chamber rear wall at rest.

- Throat length `T = L_max + 1`. Throat width = chamber width W.
- Seal land between the strike-off edge and the drop hole: `s ≥ 5 mm`.
- Stroke `D = T + s`, so the chamber's rear wall clears the strike-off edge, then the land, then reaches the hole.
- Drop hole spans `[T + s, D + L_max]` along y and is the full chamber width.
- Rear section `R ≥ D + 6`. It keeps the throat covered at full pull.
- Plunger length `P ≥ T + 1`.
- Clearances:
  - Slide in channel: 0.25 mm per side, 0.25 mm vertical.
  - Plunger in slot: 0.2 mm.
  - Gear backlash: 0.15 mm.
  - Pins: 0.3 mm.
  - All clearances are tunable in `params.scad`.
- **Contact only on lands.** The ceiling and floor touch the slide only on narrow rails and around the throat, chamber and hole. Everywhere else is relieved 0.4 mm so stray powder never packs and jams.
- **TPU wiper lip at the throat's *rear* edge.** It scrapes the slide top clean as the slide retracts under the rear ceiling.
- The **front (strike-off) edge is rigid PLA** with a sharp edge and minimal gap.

### 4.4 Chuck (drill-chuck style, holds the jar without touching the lid)

- **Stack:** deck → **scroll ring** (rotates; 3-start Archimedean spiral grooves on its top face; knurled outer band) → **guide plate** (fixed to the deck hub with screws; 3 radial jaw slots) → **3 jaws** (pins pointing down into the scroll; TPU grip pads) → **TPU gasket** under the jar rim.
- **Twist:** ~150° from fully open to fully closed. The spiral lead angle is ≈ 4–7°, so it is **self-locking** in PLA (tan α < μ) and won't back off.
- **Grip range:** nominal neck OD ± 10 mm per preset.
- **Refill:**
  1. Lift the head and jar off the bay together and turn them over (jar upright).
  2. Twist the ring open and lift the head off.
  3. Fill the jar.
  4. Put the head back on, twist it closed, flip it, and dock it.

### 4.5 Stir wand (anti-bridging, driven by the slide)

Cohesive powders can arch or rat-hole over a ~32 mm slot. These include whey, collagen, instantized BCAA and hygroscopic pre-workouts.

- A slim **wand** pivots on a cross-axle near the throat and reaches up into the jar neck.
- An **arm on the axle's outer end** is driven by a pin on the slide's side, so every pull and return swings the wand ±~20° through the funnel and neck.
- Parts: wand, arm, 1 bolt as the axle, and a TPU seal washer.
- It is optional for free-flowing powders, but it uses the same hole pattern on every head, so the heads stay uniform.

### 4.6 Return and feel

- **TPU return bands:** two printed loops in side channels, routed for low strain (≤ 25 %), in light, medium and firm variants. A **hair tie or rubber band fits the same hooks** if a band ever breaks.
- **Without bands it still works** as push-pull.
- **Pull force target:** 6–10 N (a light drawer). There's a soft TPU pull lip.
- **Return stop:** a light knock at the end of the return helps settle the powder. It is damped enough to be quiet.

### 4.7 Outlet → dose drawer

- The drop hole opens straight down through the head's bottom into the **dose drawer** in the pedestal (a ~40 mm drop).
- The drawer is a smooth tray with big internal radii and a pour spout.
- It lines up under the dose handle and slides out toward you.

## 5. Pedestals (expandable, cabinet-friendly)

- **Pedestal:** a low round base, the same diameter as the head. The head drops onto 2 dock pins.
  - It houses the **dose drawer**, which slides out toward you.
  - TPU feet underneath.
- **Line them up:** pedestals sit side by side on a table, counter or cabinet shelf. Optional joiner clips keep a row straight.
- **Heights:** about 30 cm with a 6.5″ jar and about 25 cm with a 4.5″ jar. The protein jar is taller; give it a tall shelf or the counter.
- **To add a jar:** print one more head and pedestal.
- **Stability:** wide 157 mm footprint + TPU feet. A single head doesn't tip when you pull the handle.

## 6. Expandability: generator

- **Jar preset:**
  - Required: `neck_od`, `mouth_id`, `jar_h`.
  - Optional: `neck_h`, `name`.
- **Everything else is derived:**
  - Chuck size and range.
  - Funnel.
  - Dose class (auto-picked from the mouth, overridable).
  - Puck diameter.
  - Bay width.
  - Label text.
- **Range:** the generator must produce valid, printable, non-interfering parts for `neck_od` 60–140 mm. This is tested at several sizes.
- **Name plates:** each head gets a swappable plate with the powder's name. The dial stays universal (mL).

## 7. Design language (uniform everywhere)

- **Form:**
  - A round **puck** head under each jar.
  - The twist ring is the puck's upper band.
  - The drawer front carries the dial and the pull.
  - Proportions are calm and low: puck height ≤ ~0.6 × puck diameter.
- **Edges:** one radius family.
  - 2 mm on vertical edges.
  - 0.6 mm chamfer on top edges.
  - 0.4 mm chamfer on bed edges (no elephant's foot).
- **Grip:**
  - One flute profile on both the twist ring and the dial (different counts).
  - No other textures.
- **Type:**
  - Inter Semibold for the dial numerals and name plates.
  - Dial: long tick every 5 clicks, numerals every 10 mL (M) or 20 mL (L).
  - Index ▲ on the drawer.
- **Color:**
  - Body: one neutral (e.g. matte ivory or matte charcoal).
  - Accent: one color, on the dial, the ring and the pull lip.
  - Numerals: printed in the contrast color via the AMS.

## 8. Dosing accuracy and calibration

- Volumetric dosing repeats to roughly ±3–8 %, depending on the powder.
- Absolute grams depend on bulk density, so the chart gives a starting mL. **Calibrate once:**
  1. Pull 5 doses onto a kitchen scale.
  2. Work out the grams per pull.
  3. New setting = setting × target ÷ measured.
- **Safety:**
  - Caffeinated pre-workouts are never dosed by guess.
  - Calibrate them first, and keep their head at 0 when not in use.
  - Never use pure caffeine powder in this system.

## 9. Open questions for the design review

1. Is the slide/throat/chamber geometry sound? Will it fill fully and strike off consistently for cohesive powders? Is the stir wand the simplest effective anti-bridging measure?
2. Are the tolerances, gear modules, detent and TPU band sizing right for PLA/TPU on a P2S?
3. What is the best part split and print orientation for support-free printing with flat sealing faces? How many grams and hours per head and per bay?
4. Industrial design: proportions, details and colors that make it look like a product.
5. System: bar height vs under-cabinet clearance, tip-over margin, refill workflow, hygiene, caffeine safety.
