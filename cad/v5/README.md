# Dose Bar v5: CAD source and build contract

Parametric OpenSCAD (2021.01 compatible). One entry file, one master parameter file, one file per part.

```
cad/v5/
  dosebar.scad      entry: PART=assembly | <part> (print pose) | posed:<part> | bar
  params.scad       MASTER parameters + interface datums (owned by the lead; do not edit in part work)
  lib/style.scad    design tokens + shape helpers (rbox, ccyl, ctube, fluted_circle, label3d)
  lib/gears.scad    involute pinion_2d / rack_2d (stub teeth, PA 25)
  lib/scroll.scad   3-start Archimedean scroll grooves for the chuck
  presets/*.scad    jar presets (std, pro, _template)
  parts/*.scad      one file per part (see ownership)
  tools/            build.py (STL export), fitcheck.py (interference), render/ (photo renders)
```

## 1. Coordinates and datums

- **Head coordinates** (assembled):
  - x = user's right, **y = away from the user** (the front of the head is −y), z = up.
  - Origin = jar axis at the head's bottom face. The bottom face is also the underside of the channel floor.
- **u** = distance along the pull, toward the user (u = −y).
  - Body u = 0 is the throat's **rear** edge. The throat spans u ∈ [0, `T_LEN`] (x ∈ ±`T_WID`/2) and is centred on the jar axis.
  - `hy(u)` converts body u to head y.
- **Slide-local frame:** same axes as the head, with the origin at the chamber's fixed **rear wall**.
  - The slide extends toward −y (front) for the chamber, plunger slot, neck and drawer front, and toward +y for the solid rear section.
  - Place the slide (and everything riding on it: plunger, dial, pinion, lock ring, dial spring, pinion cap, stir post, name plate) with `translate([0, SLIDE_Y0, 0])`. `SLIDE_Y0` already includes the pull state.
  - Slide-local u = −(local y).
- **Vertical stack:**
  - `Z_FLOOR` is the slide running surface; the floor occupies z ∈ [0, `FLOOR_T`].
  - The slide occupies [`Z_FLOOR`, `Z_SLIDE_TOP`].
  - `Z_CEIL` is the ceiling underside and also the **base/deck joint plane**. The ceiling plate is `CEIL_T` thick.
  - The funnel runs from `Z_CEIL_TOP` to `Z_FUNNEL_TOP`. There it reaches radius `MOUTH_R`, and the hub top sits at the same height.
  - The deck flange top is at `Z_RING_BOT`. Above it: the twist ring [`Z_RING_BOT`, `Z_RING_TOP`], then the guide plate [`Z_GP_BOT`, `Z_GP_TOP`].
  - The gasket sits in a pocket in the guide plate top and stands `GASKET_PROUD` proud. The jar rim sits at `Z_RIM`.
- **State variables** (honor them in every posed module):
  - `STATE_PULL` (0..1): `PULL_D` = `STATE_PULL` × `STROKE`.
  - `DIAL_ML`: `CH_L` is the current chamber length; `DIAL_ANGLE` is the dial rotation.
  - `CHUCK_CLOSE` (0..1): `R_PIN` is the current jaw-pin radius; `RING_PHI` is the ring rotation.

### How a dose works (geometry rules already solved in params)

**Rest.** The chamber sits under the throat.
- The chamber spans slide-local u ∈ [0, `CH_L`], open top and bottom.
- The plunger (front wall) spans [`CH_L`, `CH_L`+`PLUNGER_L`], solid top flush with the slide top.

**Pull.** The slide moves `STROKE` toward the user.
- The chamber passes the strike-off edge (throat **front** edge, u = `T_LEN`), crosses the `LAND`, and lands over the drop hole in the floor at body u ∈ [`HOLE_U0`, `HOLE_U1`] (x ∈ ±`CH_W`/2, corner radius `HOLE_R`).
- The solid rear section (`REAR_L` long, rear corners chamfered `SLIDE_REAR_CHAMFER`) keeps the throat and the post slot covered the whole time.
- The **stir post** rides in a square socket in the slide top at slide-local u = `POST_U0`. It passes up through a slot in the ceiling (body u ∈ [`SLOT_U0`, 0], half-width `SLOT_HW`) and through a keyway in the funnel's rear wall (`KEYWAY_H` tall). It sweeps the throat and funnel on every stroke.

## 2. Ownership: edit ONLY your files

| Group | Files |
|---|---|
| BODY | `parts/base.scad`, `parts/deck.scad`, `parts/stir_post.scad`, `parts/stop_pin.scad`, `parts/wiper.scad` |
| SLIDE | `parts/slide.scad`, `parts/band.scad`, `parts/name_plate.scad` |
| DRIVE | `parts/plunger.scad`, `parts/dial.scad`, `parts/pinion.scad`, `parts/lock_ring.scad`, `parts/dial_spring.scad`, `parts/pinion_cap.scad` |
| CHUCK | `parts/ring.scad`, `parts/guide_plate.scad`, `parts/jaw.scad`, `parts/jaw_pad.scad`, `parts/gasket.scad` |
| PEDESTAL | `parts/pedestal.scad` (pedestal, joiner, row_assembly), `parts/dose_drawer.scad`, `parts/foot.scad` |
| TOOLS | `tools/*` (not part geometry) |

- Never edit `params.scad`, `lib/`, `dosebar.scad`, `presets/`, or another group's files.
- Need a value that a mating part must also know? Put it in your report under "params requests"; the lead adds it to `params.scad`.
- Private constants go at the top of your file, prefixed with the part name (`SLIDE_…`, `DECK_…`).
- Scratch files go in your scratchpad, never in the repo.

## 3. Module contract

- Keep the exact module signatures in the stubs.
- Every part file starts with `include <../params.scad>` and contains **no top-level geometry**.
- `<part>()` = the part in **head coordinates** in its assembled pose, honoring the state variables. Jaws and pads take an index `i` (0..2) and are placed at `JAW_ANGLES[i]`.
- `<part>_print()` = the part oriented for printing: sitting on z = 0, centred near the origin, best orientation per §4. It must fit 250 × 250 × 250 mm.
- **Multi-color:** a part with inlaid text exports the ink as a separate body.
  - The dial numerals go in `dial_inlay()` / `dial_inlay_print()`. The name text goes in `name_inlay(txt)` / `name_inlay_print(txt)`.
  - The ink body occupies exactly the pocket it fills (flush, 0.6 mm deep) and shares the print pose of its parent. The two STLs load as one object in Bambu Studio.
- Don't call `color()` inside part modules (the entry colors by part).
- `$fa=3; $fs=0.35` are the defaults. Use finer values only where needed (gears, text, small pins).

## 4. Printability rules (Bambu P2S, PLA + TPU 95A, 0.4 nozzle, 0.2 mm layers)

**Supports and overhangs**
- **No supports.** Overhangs ≤ 45° from vertical. Unsupported bridges ≤ 25 mm. Horizontal holes ≥ 6 mm use a teardrop or diamond top.
- Default plate is **textured PEI**. Bed-side faces come out matte-textured, which is good on visible tops and acceptable on sliding faces. Top surfaces can be ironed.
- Pick which sealing or sliding face is bed-side vs top-side, and say so in a comment above `_print()`.

**Walls and features**
- Min PLA wall 1.2 mm (3 perimeters ≈ 1.2–1.3). Structural walls 2.0–2.4. Min positive feature 0.8 mm. Min TPU section 1.2 mm.
- Every bed edge gets `C_BED` (0.4) chamfer, which kills elephant's foot. **Every sliding fit needs this.**

**Clearances** (from `style.scad`): `CL_SLIDE` 0.25/side, `CL_PLUNGER` 0.2/side, `CL_PIN` 0.3 on dia, `CL_ROT` 0.3 on radius, `BACKLASH` 0.15. Tune them only via the test coupon.

**Screws** (self-tapped into PLA)
- M3 pilot 2.6, M4 pilot 3.5. Pilot depth ≥ 2.5 × d. Bosses ≥ 2 × d OD.
- Screw heads are **never on a visible face**: from below or under the gasket.

**Text**
- Inter SemiBold, cap height ≥ 3.5 mm, inlaid 0.6 mm (multi-color, flush).
- Text faces print bed-side for crisp edges.

## 5. Interfaces between groups (all values in params.scad)

**Base ↔ slide**
- Floor top `Z_FLOOR`.
- Slide side guidance: **channel walls in the base**, `RAIL_W` thick, inner faces at x = ±`CHAN_HW`, full height `Z_FLOOR`..`Z_CEIL`.
- Each wall has a horizontal **hook slot** `HOOK_SLOT_H` tall centred on `Z_ROD`, long enough for the band hook's whole travel (rest → full pull, ±4 mm).
- The deck ceiling is flat: no rails hang from it, since they wouldn't print.
- Drop hole: `HOLE_U0`/`HOLE_U1`/`HOLE_R`, width `CH_W`.
- Stop pin: Ø `STOP_D`, pushed up through the floor at body u = `U_STOP`, x = 0. It rides in the slide-underside groove spanning slide-local u ∈ `STOP_GROOVE`, 4 mm deep, width `STOP_D`+0.6. The groove ends ARE the rest and full-pull stops.
- Channel rear wall at head y = `Y_REAR_WALL`.
- Drawer opening in the front skin: channel cross-section + 0.5 mm.
- **Bands (two)**
  - Hooks: each slide side has a hook at slide-local u = `U_HOOK_S`, z = `Z_ROD`.
  - Base posts: a **rear post** Ø `BAND_POST_D` centred at (±(`BAND_X` + `BAND_POST_D`/2), `Y_BAND_ANCHOR`) and a **front anchor** at (±`BAND_X_OUT`, `Y_BAND_FRONT`).
  - TPU loop routing is hook → around rear post → front anchor. A hair tie loops hook ↔ rear post directly.

**Deck ↔ slide**
- Ceiling underside `Z_CEIL`.
- Throat `T_WID` × `T_LEN` with a **sharp, rigid strike-off edge** at its front.
- Post slot behind it.
- **TPU wiper** in a 2 × 2 mm groove in the ceiling underside, 1.0 mm behind the throat's rear edge, following the throat rear edge and the post slot outline (the slide top moves rearward under it on return).
- Contact only on lands: relieve the rest of the ceiling 0.4 mm where the slide never needs sealing.

**Base ↔ deck**
- Joint plane `Z_CEIL`.
- 4 × M3 from below at `JOIN_SCREWS`. Heads recessed in the base bottom; pilots in deck bosses ≥ 8 mm.
- A 1 mm reveal groove on the outside skin at the joint line is a design feature.

**Deck ↔ chuck**
- Flange top `Z_RING_BOT` (bearing face for the ring).
- Hub OD `HUB_OD` from the flange up to `Z_GP_BOT`; hub bore = funnel top (`MOUTH_R`).
- 3 × M3 pilots in the hub top at `GP_SCREW_R`, `GP_SCREW_ANGLES` (heads hide under the gasket).

**Ring ↔ guide plate ↔ jaws**
- Ring: ID `RING_ID`, OD `RING_OD`, thickness `RING_T`.
  - Scroll grooves on its **top** face: `GROOVE_W` wide, `SCROLL_DEPTH` deep, 3 starts, radius from `R_PIN_MAX` (open) to `R_PIN_MIN` over `TWIST` degrees plus 12° run-out each end.
  - **Clockwise from above closes.**
  - Posed rotation `RING_PHI`.
- Guide plate: OD `GP_OD`.
  - 3 radial dovetail tracks (`DOVETAIL` = [top w, bottom w, depth]) at `JAW_ANGLES`, with pin slots through to the ring.
  - Gasket pocket, OD `GASKET_OD`, ID `GASKET_ID`, depth `GASKET_T` − `GASKET_PROUD`.
- Jaw: pin Ø `PIN_D` down into the scroll; PLA face at radius `R_PIN` − `PIN_OFF`, concave to the neck; TPU pad `PAD_T`. Width `JAW_W`, height `JAW_H`.

**Slide ↔ plunger ↔ dial**
- Slot: `CH_W` × full height, slide-local u ∈ [0, `SLOT_L`].
- Bulkhead `BULK_T`.
- Rack rod: x ∈ [`ROD_X0`, `ROD_X1`], z = `Z_ROD` ± `ROD_H`/2; teeth face −x toward the pinion at x = 0.
- Pinion (separate part `pinion`): m `G_M`, z `G_Z`, PA `G_PA`, addendum `G_ADD`, on the dial axis at slide-local u = `U_DIAL`, face width `PIN_FW`.
  - It slides onto the dial shaft's hex key (`DIAL_KEY_AF` across flats, `PINION_BORE_CL`) from below and is clamped by an M3 screw into the shaft end.
- Rod front end at slide-local u = `U_ROD_FRONT0` + `CH_L`.
- Dial seat (cut by the slide): a well `DIAL_WELL_D` × `DIAL_WELL_DEPTH` with 2 key notches `DIAL_WELL_KEY` at `DIAL_WELL_KEYS`, and a stop post `STOP_POST` at `STOP_TAB_ANGLE`. Pinion cavity radius `PINION_CAVITY_R`, open at the drawer-front bottom and closed by the `pinion_cap`.
- **Locking dial (set it and forget it):**
  - The PLA `lock_ring` sits keyed in the well with `DETENT_TEETH` V-teeth (`LOCK_TOOTH_H`, 90°) on its top. They mesh with matching teeth under the dial.
  - Lift the dial `LOCK_LIFT` to turn it. The TPU `dial_spring` (under the pinion cap, on the dial shaft's end washer/M3 screw) pulls it back down into the nearest of the 40 positions.
  - The pinion is axially captured; the dial's hex key slides through it.
- Lock teeth: `DETENT_TEETH` per revolution, 40 positions used. Hard stop tab at `STOP_TAB_ANGLE`, so the gears and the plunger are never the stop.
- Drawer front: starts at slide-local u = `U_HANDLE0`, length `HANDLE_L`, width `HANDLE_W`, z ∈ [`HANDLE_Z0`, `Z_HANDLE_TOP`].

**Pedestal ↔ base ↔ dose drawer**
- The head bottom has 2 locating holes Ø `DOCK_PIN_D` + `CL_PIN`, 3 deep, at `DOCK_PINS`.
- The pedestal top plate (z ∈ [−`PED_TOP_T`, 0], round Ø `PUCK_D`) carries matching pins and an opening `PED_HOLE` centred at y = `PED_HOLE_Y`, right under the drop hole.
- The dose drawer slides in the pedestal:
  - Outer width `CUP_W`. Rim at `CUP_TOP_Z`, bottom at `CUP_BOT_Z`.
  - It runs from `CUP_Y_REAR` to `CUP_Y_FRONT`.
  - Its front block rises to `CUP_FRONT_TOP_Z`, lining up under the dose handle.
- Pedestal height `PED_H`; TPU feet `FEET_T`. Neighbouring pedestals sit `ROW_PITCH` apart with an optional joiner at y = `JOINER_Y`.

## 6. Design language (uniform everywhere)

- **Form:** a calm round puck under each jar, with the drawer front as a clean rounded "tongue". No sharp visible corners.
  - Radii: vertical edges `R_V` 2.0; top edges `C_TOP` 0.6 chamfer; bed edges `C_BED` 0.4.
  - Visible part-to-part gaps = `REVEAL` 0.8 (shadow lines), consistent everywhere.
- **Grip:** one scallop flute profile (`FLUTE_DEPTH`, `FLUTE_W`) on the twist ring and the dial, and nowhere else.
- **Type:** Inter SemiBold.
  - Dial: ticks every click (short), every 5 clicks (long); numerals every 10 mL (M) or 20 mL (L), with their tops pointing to the dial centre.
  - Index ▲ on the drawer front, in front of the dial (toward the user).
- **Colors:** body (warm white), accent (charcoal) for ring, dial, jaws, plunger, name plate and stir post, ink = accent. TPU dark grey.
- **Hide every screw head.** No logos except a small "DOSE BAR" deboss on the base bottom.

## 7. Verify before you report

1. Render every module of yours in **both** posed and print modes:
   ```
   openscad -o /tmp/x.stl -D 'PART="<part>"' dosebar.scad
   openscad -o /tmp/x.stl -D 'PART="posed:<part>"' dosebar.scad
   ```
   Run from `cad/v5`. Zero CGAL errors. Load the STL with Python trimesh and confirm it is watertight with positive volume.
2. Repeat for `-D STATE_PULL=1` and for `-D DIAL_ML=0` and `-D DIAL_ML=40` where relevant. Also run the **pro** preset: pass its values with `-D`, or use `python3 tools/build.py --preset pro` once it exists.
3. Check for interference against mating parts that exist (posed STLs + `trimesh`/`manifold3d` intersection volume must be ≈ 0).
4. Look at your part: render a PNG.
   - `openscad --render --camera=... --imgsize=1200,900 -o x.png` (needs `xvfb-run -a`), **or**
   - the photo renderer: copy STLs into `tools/render/assets/`, write a scene JSON there, run `node tools/render/render.mjs tools/render/assets/scene.json out.png`.
   - Use the Read tool on the PNG to actually look at it, and fix what looks wrong or homemade.
