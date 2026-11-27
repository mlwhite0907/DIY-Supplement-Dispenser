# Print guide: Bambu Lab P2S, PLA + TPU 95A

> The parts table with grams and plate layouts is generated per jar size: see `cad/v5/build/<preset>/PARTS.md` after running `tools/build.py`. This page covers the settings and the order of work.

## 0. Order of work (don't skip step 1)

1. **Tolerance coupon** (`coupon.stl`, ~25 min). Check that the slide fit, pin fits and gear mesh feel right on *your* printer. If anything binds or rattles, adjust the clearance tokens in `cad/v5/lib/style.scad` and rebuild.
2. **One complete head** (std). Assemble it, calibrate it with your BCAA or creatine, and live with it for a day.
3. **Batch the rest.** Same plates, repeated.

## 1. PLA settings (Bambu Studio)

| Setting | Value | Why |
|---|---|---|
| Profile | Bambu PLA Basic / Matte @ 0.4 nozzle | Stock profiles are tuned for the P2S |
| Layer height | 0.20 mm (0.16 for dial, name plate, jaws) | Finer layers for the visible detail parts |
| Walls | 3 (≈1.2 mm) | Strength at screw bosses and edges |
| Top / bottom shells | 5 / 4 | Smooth sliding faces |
| Infill | 15 % gyroid (30 % for jaws, ring, pinion) | Light where it can be, stiff where it carries load |
| Supports | **Off**: every part is designed support-free | |
| Ironing | **On (top surfaces)** for base, slide, plunger, deck flange | Glass-smooth sliding faces |
| Elephant-foot compensation | 0.15 mm (default) | Parts also carry 0.4 mm bed chamfers |
| Seam | Back / aligned | Seams face the wall |
| Plate | Textured PEI | Gives the matte finish on the dial top and guide plate |

## 2. TPU 95A settings

- **Spool:** load from the **external spool holder**, not the AMS.
- **Profile:** Bambu TPU 95A HF (or Generic TPU).
- **Layer:** 0.20 mm. Infill 100 % (bands, wiper, pads, gasket and detent are small and need to be solid).
- **Speed:** keep the profile's slow speeds. Turn **Avoid crossing walls** on.
- **Bands:** print flat. Make 2 per head plus a spare set. Variants: `light` / `medium` / `firm`. Start with medium.

## 3. Multi-color parts (AMS)

The dial numerals and the name text are separate STLs (`dial_inlay.stl`, `name_inlay.stl`) that sit exactly in their pockets.

1. In Bambu Studio, select both files → drag them in together → when asked, choose **"Load as a single object with multiple parts."**
2. Assign the body filament to `dial.stl` and the contrast color to `dial_inlay.stl`.
3. Both print face-down on the textured plate, so the numerals come out flush and crisp.

## 4. Colors

| Role | Parts | Suggested PLA |
|---|---|---|
| Body | base, deck, slide, guide plate, bay plates, legs | Matte Ivory White / Bone White |
| Accent | twist ring, dial, pinion, jaws, plunger, stir post, stop pin, name plate | Matte Charcoal |
| Ink | dial numerals, name text | Accent color on a body-color plate, or the reverse |
| TPU | bands, wiper, gasket, jaw pads, detent, feet | Black or grey TPU 95A |

## 5. Screws (from your assortment)

| Where | Screw | Qty per head |
|---|---|---|
| Base → deck | M3 × 30–35 | 4 |
| Guide plate → hub | M3 × 10–12 | 3 |
| Pinion → dial shaft | M3 × 12 + washer | 1 |
| Bay plate → legs | M4 × 16–20 | 4 per bay |

M3 and M4 screws self-tap into the printed pilot holes. Drive them by hand and stop when snug. PLA strips if you keep turning.

## 6. Care

- **PLA softens at ~55 °C.** Hand-wash only, in lukewarm soapy water. No dishwasher, no hot car.
- Dry every part completely before refilling (powder + water = paste).
- Dry powders only.
