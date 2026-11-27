# Dose Bar v6: print guide

Printer: Bambu Lab P2S (any 256 mm bed works). Materials: **PLA** and **TPU 95A**. No supports anywhere.
Every STL in `stl/v6/<head>/` is already in its print orientation: load it and print it as it lands.

## 1. Which folder

| Folder | For | Dial |
|---|---|---|
| `stl/v6/std-M/` | 4.5 in lid jars, medium doses | 0–40 mL, 1 mL per click |
| `stl/v6/std-S/` | 4.5 in lid jars, small doses (creatine, fiber, electrolytes, pre-workout) | 0–20 mL, 0.5 mL per click |
| `stl/v6/pro-L/` | 5 in lid protein jar | 0–100 mL, 2.5 mL per click |

Pick the head by the **dose**, not the jar: the dose should land in the upper two thirds of the dial.
S and M heads share the same outer parts (tub, shell, ring, guide plate, jaws, mat, gasket).

## 2. Print order

Print **one complete head first** and test it before you commit filament to the rest.

| # | Plate | Parts | Material | Why this order |
|---|---|---|---|---|
| 1 | Coupon | `coupon` + `dial` + `dial_inlay` + `pawl` + 1 `jaw` | PLA | Checks every fit in about 2 hours |
| 2 | Coupon TPU | `coupon_tpu` + `seal` | TPU | Latch stiffness, spring, seal root |
| 3 | Mechanism | `slide`, `plunger` | PLA | The parts that matter most |
| 4 | Chassis | `chassis` | PLA | |
| 5 | Insert | `funnel` | PLA | |
| 6 | Chuck | `ring`, `guide_plate`, 3 × `jaw` | PLA | Ring in the accent color |
| 7 | Body | `shell` | PLA | Visible: one spool for all visible parts |
| 8 | Base | `tub`, then `scoop` | PLA | |
| 9 | Small PLA | `wand`, `wand_arm`, `name_plate_*` + `name_inlay_*` | PLA | |
| 10 | Small TPU | 2 × `latch`, 2 × `stop_boot`, `bumper`, `pawl_spring`, `wand_finger`, 3 × `jaw_boot`, `gasket` | TPU | |
| 11 | Mat | `mat` | TPU | One tile per head |

## 3. Settings

| Setting | PLA | TPU 95A |
|---|---|---|
| Layer height | **0.20 mm** (the model's heights sit on this grid) | 0.20 mm |
| Plate | Textured PEI | Textured PEI (glue stick as a release layer) |
| Walls | 3 | 2 |
| Infill | 15 % gyroid | 100 % for latch, seal, spring, finger, boots; 20 % for the mat |
| Top / bottom layers | 5 / 4 | 4 / 4 |
| Supports | Off | Off |
| Ironing | Off | Off |
| Speed | Default profile | 25–30 mm/s outer wall, direct feed, dry filament |
| Seam | Aligned, at the back | Aligned |
| Brim | Off (add 3 mm only if `chassis` or `tub` lifts) | Off |

- **Do not scale anything.** Fits are built into the model.
- `jaw`: 100 % infill. `dial`: 100 % infill.
- Keep one PLA spool for everything you see side by side (shell, tub, scoop, slide, guide plate). Batches differ.
- PLA softens near 55 °C. Keep the row out of direct sun.

## 4. Two-color parts

| Object | Load these two files together | Colors |
|---|---|---|
| Dial | `dial.stl` + `dial_inlay.stl` | Accent body, light numerals |
| Name band | `name_plate_NAME.stl` + `name_inlay_NAME.stl` | Accent band, light text |

In Bambu Studio: select both files in the import dialog and answer **Yes** to "load as a single object with multiple parts". Then give each part its filament. Both print face down, so the visible face gets the plate texture and crisp text. With one color only, print just the first file: the numerals stay as engraved recesses.

Need another name? `python3 cad/v6/tools/build.py --preset std --names "MY NAME"`

## 5. What one head costs

| | Per head (std) | Ten heads |
|---|---|---|
| PLA | about 0.8 kg | about 8 kg |
| TPU | about 60 g | about 0.6 kg |
| Print time | about a day | about ten days of printing |

These are estimates from part volume at the settings above; the slicer's number is the real one. `manifest.json` in each folder lists every part's size and solid weight.

## 6. Fit check (the coupon)

| Test | Pass | If it fails |
|---|---|---|
| Dial block: drop in dial, pawl, TPU spring; slide the rack stub past the pinion | Crisp clicks, rack moves with the dial, no skipping | Too tight: check for stringing in the well. No click: spring missing or pawl backwards (nose points at the dial) |
| Rail strip + slide stub | Glides, slight play, no rattle | Binding: lower flow 2 % or check elephant's foot |
| Jaw track + jaw | Jaw slides freely, cannot lift out | Binding: clean the first-layer edge of the track |
| Latch corner + latch | Root pushes into the dovetail and stays | Loose: print the latch at 102 % in X/Y only |
| Seal block + seal | Root presses into the groove, blade leans toward the opening | Loose: it is still trapped once assembled |

If the coupon passes, print the head.
