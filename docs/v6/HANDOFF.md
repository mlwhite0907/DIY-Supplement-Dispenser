# Dose Bar v6: handoff

Read this first if you are continuing the project (person or AI). Updated with every push.

## 1. Goal and hard constraints

| Constraint | Detail |
|---|---|
| Purpose | Manual, no-electronics dispenser for 10+ supplement powders; one action gives the set dose |
| Jars | The owner's glass jars, used upside down. **Lids are never drilled.** Twist-lock chuck on the neck |
| Make at home | Bambu Lab P2S, **PLA + TPU 95A only**, M3 screws, no metal springs, nothing to order |
| Dose | Universal dial in mL, set once, hidden in use |
| Use | Pull a drawer, pour from it into a cup. Units sit side by side in a cabinet or on a counter |
| Look | Clean, uniform, modern. One rounded body, flat fronts, dark fluted collar |
| Expandable | Any jar size by preset; add heads to the row at will |

Jars (measured with lids on): nine with 4.5 in lids (seven 6.5 in tall, two about 4.6 in), one with a 5 in lid (11.5 in tall).
**Neck OD and mouth ID are estimates** (108/96 mm and 121/108 mm). The chuck takes ±10 mm on diameter; the gasket and funnel bore follow the preset.

## 2. Design in one table

| Subsystem | Decision | Why |
|---|---|---|
| Doser | Slide with a through-pocket chamber; plunger sets its length | Volumetric, calibrated once by weight |
| Sealed transit | Land = L_max + 5 mm, stroke = throat + L_max + 8 mm | The chamber is never open to the throat and the drop hole at once (assert in `dosebar.scad`) |
| Drivetrain | m1 z12 pinion, 25° stub teeth, 40 clicks over 300°, L_max 31.4 mm on every head | One dial, one rack; only the chamber cross-section changes per class |
| Classes | S 0–20 mL (H 18), M 0–40 (H 24), L 0–100 (H 40) | Class follows the dose, not the jar |
| Dial | Flush disc on the slide, pinch bar, PLA pawl + TPU tube spring, M3 from below | Hidden at home: cannot be bumped or turned with a full chamber |
| Stops | Plunger faces are the dial stops; optional `limit_block` caps the maximum | Compression of big faces, not a small tab |
| One-pull coupling | Scoop pulls the slide through two TPU flaps; scoop front wall pushes two dogs on the way back | Release by bending, not by sliding on a cam: friction-tolerant |
| Slide stops | PLA piers in the chassis walls with TPU boots; TPU bumper with a soft home catch | Survives a yank |
| Agitation | Rocking gate, lost-motion drive, TPU finger follower | Cohesive powders bridge otherwise; a jam cannot block the pull |
| Seal | TPU U-blade behind and beside the throat, rigid strike-off edge in front | Wipes the slide top, keeps powder out of the mechanism |
| Chuck | 3-start scroll ring, 110° twist, dovetail jaws with TPU boots, gasket in a seat | Self-locking (lead angle about 4.6°), closes like a lid in the refill pose |
| Body | Tub + chassis + funnel insert + shell; TPU mat tile per head | Every part prints without supports; the head lifts off the tub |

## 3. Repository map

| Path | What |
|---|---|
| `cad/v6/params.scad` | **Every dimension.** Start here |
| `cad/v6/dosebar.scad` | Entry. `PART="assembly"`, `"<part>"` (print pose), `"posed:<part>"` |
| `cad/v6/parts/*.scad` | chassis, slide, plunger (+ limit block), dial (+ pawl), funnel, shell, chuck, tub, scoop, wand, soft (TPU parts + name band), coupon |
| `cad/v6/presets/*.scad` | `std`, `pro`, `_template` (five jar measurements + dose class) |
| `cad/v6/tools/build.py` | Export print STLs + manifest |
| `cad/v6/tools/fitcheck.py` | Interference sweep over the whole motion |
| `cad/v6/tools/overhang.py` | Printability audit |
| `cad/v6/tools/fast/` | Optional fast renderer (OpenSCAD WASM + Manifold). `npm install` there once |
| `stl/v6/<preset>-<class>/` | Print-ready STLs |
| `docs/v6/` | Guides, images, 3D viewer |
| `docs/archive/v5/` | Superseded design notes |

## 4. Rebuild and verify

```bash
cd cad/v6/tools/fast && npm install && cd ../../../..     # once; without it the tools use system openscad (slow)
python3 cad/v6/tools/fitcheck.py --preset std             # must print OK on every line
python3 cad/v6/tools/overhang.py --preset std             # only chamfer steps and short bridges
python3 cad/v6/tools/build.py --preset std                # -> stl/v6/std-M
python3 cad/v6/tools/build.py --preset std --class S --limit 10
python3 cad/v6/tools/build.py --preset pro
```

New jar: copy `presets/_template.scad`, fill in neck OD, mouth ID, body OD, height, neck height and the dose class, then run the three commands with `--preset <name>`.

## 5. Status

| Item | State |
|---|---|
| CAD: all parts, three head sizes | Done; zero interference in every state (`fitcheck.py`) |
| STLs: std-M, std-S, pro-L | Exported, watertight, bed-checked |
| Guides, renders, viewer | Done |
| **Physical test** | **Not done.** Nothing has been printed yet |

## 6. Known risks (test in this order)

1. **Real jar necks** are unmeasured. If the neck is far from the preset, re-run `build.py` with measured values (gasket, bore and jaw range follow).
2. **Latch release force** depends on the TPU. Three flap thicknesses are exported (`latch_soft`, `latch`, `latch_firm`).
3. **Cohesive powders** (whey, collagen) may still dose light: check the gate moves, then consider a taller gate.
4. **Chuck hold** is friction plus the boots. Carry by the base. A positive hook under the neck bead is a possible upgrade once the neck is measured.
5. **PLA budget**: about 0.8 kg per standard head. The funnel insert and slide are the heavy parts and could be hollowed.
6. **Dial index after cleaning**: the dial can be refitted a tooth off. Rule: at 0 the plunger touches the back wall.

## 7. Ideas not built

- Carousel base that carries these same heads on a turntable.
- Hollowed funnel insert and slide to save filament.
- Shell-to-chassis locating ribs for a perfectly even reveal.
- Lock/open arrows engraved on the deck.
