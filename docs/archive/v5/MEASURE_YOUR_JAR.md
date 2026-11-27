# Add a jar (any size)

Every Dose Bar part is generated from one small preset file per jar size. Adding a new jar takes five numbers and one command.

## 1. Measure (lid OFF)

| # | Name in preset | What to measure | Tip |
|---|---|---|---|
| 1 | `NECK_OD` | Outside diameter **across the threads** | Measure the widest point. The chuck grips ±10 mm around this, so ±1 mm is plenty. |
| 2 | `MOUTH_ID` | **Inside** diameter of the opening | Measure the narrowest point of the inner lip. |
| 3 | `BODY_OD` | Widest point of the jar body | Sets how far apart bays sit. |
| 4 | `JAR_H` | Overall height **with the lid on** | Used for the height check under cabinets. |
| 5 | `NECK_H` | Height of the threaded neck above the rim | Jaws stay below the shoulder. |

A ruler works. Calipers are nicer. If you're unsure, round **down** for the mouth and **up** for the neck.

## 2. Make the preset

```bash
cd DIY-Supplement-Dispenser/cad/v5
cp presets/_template.scad presets/myjar.scad
# edit the numbers in presets/myjar.scad (any text editor)
```

`DOSE_CLASS = "auto"` picks the chamber from the mouth size. You can force one instead:

| Class | Dial range | Per click | Typical use |
|---|---|---|---|
| `S` | 0–20 mL | 0.5 mL | Electrolytes, creatine, small jars |
| `M` | 0–40 mL | 1 mL | BCAA, pre-workout, fiber, glutamine |
| `L` | 0–80 mL | 2 mL | Protein, collagen |

## 3. Build the files and print

```bash
python3 tools/build.py --preset myjar --name "CREATINE"
# STLs land in cad/v5/build/myjar/ along with PARTS.md (what to print, how many, in which color)
```

Print one head's worth of parts (see `PRINT_GUIDE.md`). To add a bar bay, also print **one bay plate and one leg**, then bolt them onto the end of the bar.

## 4. Limits

- `NECK_OD` from 60 to 140 mm is supported, and the generator is tested at 86, 108 and 121 mm.
- Every head uses the same drawer mechanism. Small jars still get a ~150 mm head, because the drawer needs that room.
- Wider than 140 mm or narrower than 60 mm: open an issue with your numbers.
