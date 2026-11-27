# Dose Bar v5: part build briefs

These are the exact briefs given to the CAD build agents, one per part group. Any AI or person continuing the work should implement each part to its brief and follow the contract in `cad/v5/README.md`. All dimensions come from `cad/v5/params.scad`.

## v5.1 OVERRIDES (apply to every unit) (read first; these win over anything below that conflicts)

The design review found real problems and the owner gave new requirements. All the numbers are already in `params.scad`.

**1. Sealed transit**
- The land from the strike-off edge to the drop hole is now ≥ `L_MAX` + `LAND`, and `STROKE` = `T_LEN` + `L_MAX` + `LAND` + `OVERTRAVEL` (≈72 mm std, ≈79 mm pro).
- The chamber is closed on top before any of it reaches the drop hole (`SEAL_WINDOW` ≥ 5).
- `REAR_L` = `STROKE` + 6.
- `T_LEN` ≥ 30 mm (S/M) / 40 mm (L) for flow.

**2. Push-pull drawer, no springs**
- Bands and stop pin are gone. Pull the handle out to its stop (the dose drops), then push it home.
- **Stops:** two M4 screws from below wear TPU `stop_sleeve`s in the side channels (`STOP_X`, `STOP_U_FRONT`, `STOP_U_REAR`). A lug on each rear corner of the slide (`STOP_LUG`) stops on them at full pull and at home. Remove the front screws to take the slide out.
- **Home detent:** about 3 N so the handle stays home.

**3. Stir post is gone**
- It can't work with a 72 mm stroke.
- Replaced by the optional **rocker wand** (`wand` + `wand_arm`, DECK unit). It is driven by an M3 screw-head pin on the slide side at `WAND_PIN`.
- It dwells while the throat is open (u ∈ [0, `T_LEN`]) and swings about `WAND_SWING` only while the throat is covered.

**4. Pill footprint**
- Base, deck lower skin and pedestal share `pill_2d()`: semicircles of `PUCK_R` at `PILL_YC_FRONT` and `PILL_YC_REAR`.
- The round chuck collar (ring Ø `PUCK_D` = `RING_OD`) sits centred on the jar axis on top of the pill.

**5. Slide in two parts:** `slide` (body) + `drawer_front` (handle with dial seat), joined at slide-local u = `SLIDE_SPLIT_U` by a dovetail + 2 × M3 from below.

**6. Drawer front**
- Its rear face is concave: radius `PUCK_R` + `REVEAL`, concentric with the pill's front semicircle, so the gap is uniform.
- One visible gap everywhere: `REVEAL` = 1.0.

**7. Locking dial (DRIVE)**
- The dial knob, its Ø`DIAL_SHAFT_D` shaft and the pinion are ONE part. The pinion fits inside the shaft's outline and drops in from above.
- A 48-tooth face crown (`LOCK_TOOTH_H` 1.0, flanks `LOCK_FLANK` = 5° off axial, `LOCK_CHAMFER` 0.4) meshes with the PLA `lock_ring` in the dial well. Lift `LOCK_LIFT` = 1.6 to turn.
- **Spring:** a TPU `dial_spring` crush tube (`CRUSH_TUBE`) under the M3 retaining screw (from below, washer, captive nut or self-tap) pulls it down.
- **Stops:** the dial stop (`STOP_POST`, ≥ 4 mm tall) works lifted or not. At 0 the plunger stays `DIAL_ZERO_GAP` off the rear wall; at max it stays ≥ 1 mm short.
- Pinion face `PIN_FW` = rack face + lift + 0.5.
- One dial Ø36 × 13 on every head. Numerals Inter Bold cap 4.0–4.4 via `txt_size(cap)`.
- **Change the dose with the handle PULLED OUT** (chamber empty). Put a tiny "PULL TO SET" hint by the index.

**8. Plunger**
- Hangs on `PLUNGER_TONGUE` side tongues in slot-wall grooves (`CL_PLUNGER` 0.15/side). Bottom 0.2 mm above the slide's bottom plane.
- Hollow 1.2 mm shell, 1.0 × 45° front-bottom chamfer.

**9. Chuck (rigid self-locking fixture)**
- Closing turns COUNTER-clockwise about +z in head coordinates (`CHUCK_CLOSE_DIR` +1, `RING_PHI` positive when closing). That is clockwise for the user in the refill pose, like a lid.
- `TWIST` 110°. `GROOVE_W` 6.5 × `SCROLL_DEPTH` 5.0. `PIN_D` 6 D-section pins; jaws printed on their side with a T-foot under the guide plate (0.20 vertical / 0.15 per side).
- `PAD_T` 1.2 TPU slip-on boots instead of soft pads. `RING_T` 14, ring play 0.4 axial / 0.3 radial.
- Deboss "LOCK ↻ / OPEN ↺" (as seen in the refill pose) on the base bottom.

**10. Gasket:** 1.2 mm flange in a `GASKET_POCKET` with a 0.3 mm undercut lip, plus a `GASKET_LIP` 0.8 × 3.0 mm sealing lip at 30° outward.

**11. Seals**
- Rear + both sides of the throat get one TPU U-seal blade (`WIPER_BLADE`), retained by a bulb in a dovetail `WIPER_GROOVE` (thicken the ceiling locally).
- The strike-off (front) edge stays rigid and sharp: no bed chamfer on it.
- Reliefs 0.6 mm, vented. Drop-hole edges get a 0.6 mm chamfer.

**12. Z grid:** every Z datum and every part's height sits on the 0.2 mm layer grid. Use `zq()`; `CL_VT` = 0.20.

**13. Text**
- Use the bundled fonts (params `use`s `cad/v5/fonts/*.otf`) and `txt_size(cap)`: Inter cap = 1.0105 × size.
- Ink 1.2 mm deep for ivory on charcoal, 0.6 for charcoal on ivory. Min stroke and tick width 0.8 mm.

**14. No ironing** (print guide). Top surfaces use monotonic lines parallel to the pull.

**15. Base ↔ deck:** a tool-free 3-lug bayonet is preferred (or 2 × M4×12 into captive nuts). No screws longer than 16 mm.

**16. Pedestal + dose drawer:** pill footprint, `PED_H`. The dose drawer runs from `CUP_Y_REAR` to `CUP_Y_FRONT` under the (new, forward) drop hole.

## Shared instructions (all groups)

```text
You are a senior mechanical/industrial designer and OpenSCAD expert building part of "Dose Bar v5": a manual, no-electronics powder-supplement dispenser.
Each glass jar is flipped upside down onto a round "head" (puck). A twist ring with a 3-jaw scroll chuck grips the jar neck, so the lid is never drilled.
A drawer (the slide) carries a volumetric dose chamber. Pulling it moves one struck-level dose over a drop hole into a cup. TPU bands return it.
The dose is set by a single-turn dial marked in mL (40 clicks over 300 degrees; 0 = off). It moves the plunger through a rack and pinion.
Heads dock on a modular bar.
The user prints on a Bambu Lab P2S with PLA and TPU 95A only. It has to look like a premium product ("every detail matters, uniform and perfect"), and above all it must WORK.

READ FIRST:
- cad/v5/README.md: the build contract (coordinates, datums, ownership, module contract, printability rules, interfaces, design language, verification). Follow it exactly.
- cad/v5/params.scad: every shared dimension. Never hard-code a mating dimension; use these variables.
- cad/v5/lib/style.scad, cad/v5/lib/gears.scad, cad/v5/lib/scroll.scad: helpers you should use.
- cad/v5/dosebar.scad: the entry, which shows how parts are dispatched and colored.
- <repo>/docs/v5/DESIGN.md: the design intent. It predates some decisions: the pivoting "stir wand" is now a slide-mounted STIR POST, and the drivetrain is shared by all dose classes.

HARD RULES:
- Edit ONLY the files your group owns (listed below). Never edit params.scad, lib/, dosebar.scad, presets/, README.md, docs/ or another group's files.
- Do NOT run git commit, push, or any git command that changes state.
- If you need a shared value that a mating part must also use, define a clearly-named constant at the top of YOUR file and list it under params_requests in your result.
- Put scratch files under <your scratch dir> (create it). OpenSCAD is 2021.01: no manifold backend, so keep CGAL-friendly geometry. Avoid minkowski on complex shapes; prefer hull, offset, rotate_extrude and linear_extrude of 2D profiles. A part should render in under about 3 minutes.
- Fonts: Inter, which is installed ("Inter:style=SemiBold").
- Run OpenSCAD from cad/v5 so the relative includes resolve.
  Example: cd cad/v5 && openscad -o /tmp/x.stl -D 'PART="slide"' dosebar.scad
  Posed: -D 'PART="posed:slide"' -D STATE_PULL=1 -D DIAL_ML=40
- Pro preset: add -D NECK_OD=121 -D MOUTH_ID=108 -D BODY_OD=160 -D JAR_H=292 -D NECK_H=16 -D 'DOSE_CLASS="L"'.
  Template (small jar): -D NECK_OD=86 -D MOUTH_ID=74 -D BODY_OD=100 -D JAR_H=150 -D NECK_H=12 -D 'DOSE_CLASS="auto"'.
- Python 3 with trimesh and manifold3d is available for watertightness and interference checks:
  import trimesh, manifold3d
  m = trimesh.load(path); m.is_watertight
  Intersection volume: convert to manifold3d.Manifold(mesh=manifold3d.Mesh(vert_properties=np.array(m.vertices, dtype=np.float32), tri_verts=np.array(m.faces, dtype=np.uint32))), then (a ^ b).volume() is the intersection.
- LOOK at your parts. Render PNGs with: cd cad/v5 && xvfb-run -a openscad --render --camera=<eye x,y,z,center x,y,z> --imgsize=1200,900 --colorscheme=Tomorrow -o out.png <file>.scad
  Or use the photo renderer: copy STLs into cad/v5/tools/render/assets/<yourgroup>/, write a scene JSON there, and run node cad/v5/tools/render/render.mjs <scene.json> <out.png>.
  Scene JSON looks like {"width":1400,"height":1000,"parts":[{"file":"assets/<yourgroup>/a.stl","color":"#ECE8DF","rough":0.6}],"camera":{"pos":[x,y,z],"target":[x,y,z]},"fov":28}, with file paths relative to tools/render.
  Then open the PNG with the Read tool and critically judge it. Fix anything that looks wrong, clumsy or homemade.
- Function first, fit second, looks third, but all three matter. Uniform design language per the contract.
```

## BODY

Files: `parts/base.scad`, `parts/deck.scad`, `parts/stir_post.scad`, `parts/stop_pin.scad`, `parts/wiper.scad`

```text
YOUR GROUP: BODY. You own base, deck, stir_post, stop_pin and wiper.

BASE (PLA, prints UPRIGHT: the floor's underside is the puck's bottom face on the bed, and the floor's top is ironed):
- Round puck lower shell: outer radius PUCK_R, from z=0 to Z_CEIL (the joint plane). Outer skin SKIN_T thick.
  - C_BED chamfer on the bottom edge.
  - At the top edge, half of a 1 mm "reveal" V-groove (the deck carries the other half).
- Floor plate z in [0, FLOOR_T] across the inside. Its top (Z_FLOOR) is the slide's running surface.
  - Keep it dead flat in the sealing zone: body u in [-4, HOLE_U1 + 4], x within +/-(CH_W/2 + 3).
  - Elsewhere under the slide's footprint, relieve it 0.4 mm so stray powder can't jam the slide.
- DROP HOLE through the floor: body u in [HOLE_U0, HOLE_U1] (head y via hy()), x in +/-CH_W/2, corner radius HOLE_R.
  - Powder falls straight from it into the cup below. Put a 0.8 mm drip chamfer on its bottom edge.
- CHANNEL WALLS: x = +/-CHAN_HW inner faces, RAIL_W thick, full height Z_FLOOR..Z_CEIL.
  - They run from the rear wall (head y = Y_REAR_WALL; close the channel there) to the front skin.
  - Each wall has a horizontal HOOK SLOT HOOK_SLOT_H tall, centred on Z_ROD, spanning the slide hook's travel plus 4 mm each end. The hook sits at slide-local u = U_HOOK_S and travels STROKE toward the front.
- Drawer opening through the front skin: the channel cross-section + 0.5 mm all round, with crisp, consistent edges. It is the visible "mouth" of the drawer.
- STOP PIN: hole Diameter STOP_D + CL_PIN through the floor at body u = U_STOP, x = 0.
  - Counterbore and bayonet/twist-lock recess on the bottom face for the stop_pin's head, so it can't fall out when the head is lifted, yet comes out tool-free to remove the slide for cleaning.
- BAND POSTS (two sides):
  - REAR post: Diameter BAND_POST_D centred at x = +/-(BAND_X + BAND_POST_D/2), head y = Y_BAND_ANCHOR. It acts as a pulley, so give it a smooth round section and a retaining lip near the top.
  - FRONT anchor: Diameter 6 at x = +/-BAND_X_OUT, head y = Y_BAND_FRONT.
  - Both run from the floor to about Z_CEIL - 0.5 (the deck ceiling above caps them).
  - Routing: a TPU loop goes slide hook -> around the rear post -> front anchor. A hair tie goes slide hook <-> rear post directly. Make sure both routings have clear paths that never touch the slide.
- 4 JOIN SCREW columns at JOIN_SCREWS: M3 clearance, head counterbore Diameter 6.5 x 3.5 from the bottom, column OD >= 8. Keep them clear of the band paths and the slide.
- 2 DOCK holes Diameter DOCK_PIN_D + CL_PIN, 3 deep, in the bottom face at DOCK_PINS.
- A small debossed "DOSE BAR" and the preset name JAR_NAME on the bottom (0.6 deep, Inter Medium 5 mm).
- Ribs as needed for stiffness. No supports. Check that the slide (all states) never touches anything except the floor and the channel walls.

DECK (PLA, prints UPRIGHT: the ceiling underside is on the bed, so the strike-off edge is a crisp first-layer edge):
- Ceiling plate z in [Z_CEIL, Z_CEIL_TOP] over the inside.
  - THROAT through it: body u in [0, T_LEN], x in +/-T_WID/2. Its FRONT edge (body u = T_LEN, the edge nearest the user) is the strike-off edge: sharp, rigid, no chamfer on the underside.
  - POST SLOT behind it: body u in [SLOT_U0, 0], x in +/-SLOT_HW.
- WIPER GROOVE in the ceiling underside: 2 x 2 mm, 1.0 mm behind the throat's rear edge, following the rear edge and the post slot's outline (a U path around the slot). The TPU wiper presses into it.
- Underside relief: within the slide's travel footprint, keep a flat land (gap CL_VT to the slide) around the throat (+/-5 mm), along the chamber transport path to the drop hole, and around the slot. Elsewhere relieve 0.4 mm.
- FUNNEL: inner surface = hull of the throat rectangle at Z_CEIL_TOP and a circle of radius MOUTH_R at Z_FUNNEL_TOP. Wall 2.0 mm. The minimum wall angle is FUNNEL_ANGLE from horizontal.
  - KEYWAY for the stir post: union a box x in +/-SLOT_HW, body u in [SLOT_U0, 0], z in [Z_CEIL, Z_CEIL_TOP + KEYWAY_H] into the funnel void, with the funnel wall continuing around it.
  - Above Z_FUNNEL_TOP the bore is a plain cylinder of radius MOUTH_R (through the hub).
- Outer skin: radius PUCK_R, SKIN_T thick, from Z_CEIL up to Z_RING_BOT, with the other half of the reveal V-groove at the joint.
- FLANGE: annular top face at Z_RING_BOT, from HUB_OD/2 out to the skin. This is the ring's bearing face, so make it flat and ironed. Support it with a 45-degree conical/ribbed structure (no bridges over 25 mm).
- HUB: tube OD HUB_OD from Z_RING_BOT up to Z_GP_BOT, bore = 2*MOUTH_R. 3 M3 pilot holes (2.6 mm, 9 deep) in the hub top at radius GP_SCREW_R, angles GP_SCREW_ANGLES.
- Join bosses at JOIN_SCREWS with M3 pilots (2.6, >= 9 deep) from the ceiling underside up.
- Ribs tie the funnel to the skin. Everything prints without supports (overhangs <= 45 deg).

STIR POST (PLA, removable; prints lying flat with its stem cross-section square or diamond so it prints clean):
- Foot: square peg POST_PEG, length POST_SOCKET_DEPTH - 0.5, into the slide's socket at slide-local u = POST_U0.
- Stem: <= 2*SLOT_HW - 1 wide through the ceiling slot and the keyway, up to Z_CEIL_TOP + KEYWAY_H.
- Above that, a slim RAKE that breaks bridges and rat-holes: for example a crossbar in the funnel plus a taller tine reaching about 50 mm above Z_RIM into the jar neck.
  - Every point must clear the funnel walls, the bore and the jar mouth (radius MOUTH_ID/2) by >= 3 mm over the whole stroke (rest to full pull).
- Strong enough to plow powder (>= 3.5 mm sections), no sharp tips, elegant (accent color).

STOP PIN (PLA): Diameter STOP_D pin from below with a flanged head and a twist-lock that matches your base recess. It must reach 3.5 mm into the slide's underside groove (groove depth 4).

WIPER (TPU 95A): a strip that fills the U-shaped wiper groove.
- Section: 2.0 wide x (2.0 + CL_VT + 0.35) tall, tapering at the bottom to a 0.8 mm lip, so it stands 0.35 mm proud of the slide-top contact plane (a light interference).
- Print it standing on its flat back.
```

## DRAWER

Files: `parts/slide.scad`, `parts/plunger.scad`, `parts/dial.scad`, `parts/pinion.scad`, `parts/detent.scad`, `parts/band.scad`, `parts/name_plate.scad`

```text
GROUP DRAWER: split into two units. SLIDE owns slide, band, name_plate (+ name_inlay). DRIVE owns plunger (with rack rod), dial (+ dial_inlay), pinion, lock_ring, dial_spring and pinion_cap.
Everything on the slide is placed with translate([0, SLIDE_Y0, 0]) from the slide-local frame. In that frame the chamber's fixed rear wall is at local y = 0, and the slide extends toward -y (front). Slide-local u = -local y.

SLIDE (PLA, prints UPRIGHT: the bottom is on the bed; the top is ironed. The top slides under the ceiling and is the "live bottom" of the powder):
- Body: x in +/-SLIDE_W/2, slide-local u in [-REAR_L, U_HANDLE0], z in [Z_FLOOR, Z_SLIDE_TOP].
  - Rear corners chamfered SLIDE_REAR_CHAMFER in plan.
  - Vertical edges R_V, except the chamber's top edges, which stay sharp.
- CHAMBER + PLUNGER SLOT: through (open top and bottom), x in +/-CH_W/2, u in [0, SLOT_L].
- BULKHEAD u in [SLOT_L, SLOT_L + BULK_T], with a hole for the rack rod (rod section + ROD_CL).
- ROD TUNNEL from the bulkhead forward to u = U_ROD_FRONT0 + L_MAX + 1.
  - The plunger's rod runs full height from Z_FLOOR + 0.2 up to Z_ROD + ROD_H/2 (so the rod prints on the bed), x in [ROD_X0, ROD_X1].
  - So the tunnel is a slot OPEN AT THE BOTTOM, x in [ROD_X0 - ROD_CL, ROD_X1 + ROD_CL], z up to Z_ROD + ROD_H/2 + ROD_CL. Keep at least 1.6 mm of roof above it.
- PINION CAVITY under the dial at u = U_DIAL, x = 0: clears the pinion tip radius pinion_ra(G_M, G_Z, 0, G_ADD) + 0.8 at z = Z_ROD +/- (PIN_FW/2 + 0.5), and opens into the rod tunnel on the +x side where the teeth mesh.
  - Open to the BOTTOM of the drawer front so the pinion can be inserted from below and the M3 screw can reach the shaft.
- Dial seat on the top at u = U_DIAL: shaft hole DIAL_SHAFT_D + 0.4, a recess for the detent part, and a dial hard-stop post that the dial's tab hits at 0 mL and at max (STOP_TAB_ANGLE sits in the unused 60 degrees).
- POST SOCKET: square POST_SOCKET, POST_SOCKET_DEPTH deep, at u = POST_U0, x = 0.
- STOP GROOVE in the underside: x = 0, u in STOP_GROOVE, width STOP_D + 0.6, depth 4.
- BAND HOOKS on both sides at u = U_HOOK_S, centred z = Z_ROD.
  - They protrude to |x| = BAND_X + 1.8 so they catch the band strand at |x| = BAND_X, with a retaining lip and a 45-degree underside (printable).
  - Height <= HOOK_SLOT_H - 1.5 so they pass through the base's wall slots.
- DRAWER FRONT (the handle), outside the puck: u in [U_HANDLE0, U_HANDLE0 + HANDLE_L], width HANDLE_W, z in [HANDLE_Z0, Z_HANDLE_TOP].
  - Calm rounded "tongue" plan shape (front corners about R12, sides R_V), top flush with the slide top.
  - Index triangle engraved 0.6 mm on the top, just in front of the dial (toward the user).
  - NAME PLATE recess on the front face: NAME_PLATE [w, h, t].
  - An ergonomic FINGER PULL: the bottom sits only 0.8 mm above the bar, so you can't reach under it. Design a comfortable scoop or undercut on the lower front face for 2-3 fingertips, rounded edges.
  - The neck (u in [SLOT_L + BULK_T, U_HANDLE0]) is SLIDE_W wide and passes through the puck's opening.

PLUNGER + RACK ROD (PLA, ONE part, prints UPRIGHT with everything on the bed):
- Block: x in +/-(CH_W/2 - CL_PLUNGER), u in [CH_L, CH_L + PLUNGER_L], z in [Z_FLOOR + 0.15, Z_SLIDE_TOP - 0.15].
  - Its rear face is the chamber's movable front wall: flat, square, crisp edges. The top is flush and smooth.
- Rod from the block's front face to u = U_ROD_FRONT0 + CH_L: x in [ROD_X0, ROD_X1], z from Z_FLOOR + 0.2 to Z_ROD + ROD_H/2.
  - Involute rack teeth (rack_2d from lib/gears.scad: m G_M, PA G_PA, add G_ADD, ck G_CK, BACKLASH) face -x, over a length of 2*RACK_FWD + L_MAX ending at the rod's front.
  - Phase them so the rack meshes with the posed pinion at EVERY dial setting; verify with intersections at DIAL_ML = 0, mid and max.
- Posed: honors CH_L.

DIAL + DIAL_INLAY (PLA multi-color; prints TOP FACE DOWN on the textured plate, so the numerals are inlaid flush and crisp):
- Knob: diameter DIAL_D, height DIAL_H, sitting at Z_DIAL_BOT on the drawer top, axis at slide-local u = U_DIAL, x = 0.
  - Side: scallop flutes (fluted_circle; about 28-36 flutes).
  - Top: a soft 1.2 mm chamfer and a slightly recessed centre with an "mL" label.
- Numerals inlaid 0.6 deep, Inter SemiBold, cap height >= 3.5 mm, tops pointing to the centre, every 5 clicks:
  - M class: 0, 5, 10 ... 40.
  - L class: 0, 10 ... 80.
  - S class: 0, 5, 10, 15, 20, every 10 clicks.
  They sit on a 300-degree arc; numbers INCREASE COUNTER-CLOCKWISE on the dial face, so turning the dial clockwise brings higher numbers to the front index.
- Ticks: a long tick at each numeral, and a short engraved (0.3 mm) tick for every click. The inlay minimum feature is 0.7 mm.
- At DIAL_ANGLE = 0, the "0" sits at the front index (toward the user, -y).
- Shaft: diameter DIAL_SHAFT_D down through the drawer top, ending in a hex key DIAL_KEY_AF across flats, with an M3 pilot hole (2.6, 10 deep) up its end.
- Underside: the detent features (pair them with your detent part) and a stop tab.
- dial_inlay() = the ink bodies only (numerals, long ticks, "mL"), in the same pose.

PINION (PLA, prints flat): pinion_2d(m=G_M, z=G_Z, pa=G_PA, add=G_ADD, ck=G_CK), face width PIN_FW, hex bore DIAL_KEY_AF + 2*PINION_BORE_CL. It slides onto the dial key from below and is held by an M3 x 12 screw + washer. Posed: rotated DIAL_ANGLE.

LOCKING DIAL (replaces the click detent: the user wants "set it and forget it"):
- LOCK RING (PLA, prints flat with the teeth up): sits keyed in the slide's dial well (DIAL_WELL_D x DIAL_WELL_DEPTH, keys DIAL_WELL_KEYS / DIAL_WELL_KEY).
  - Top face carries DETENT_TEETH radial V-teeth, LOCK_TOOTH_H tall, 90 deg included angle.
- DIAL underside: matching V-teeth, so the dial sits LOCKED in one of 40 positions (the 0..40 click positions, CLICK_DEG apart) and cannot turn when you pull the handle or bump it.
- TO CHANGE THE DOSE: lift the dial LOCK_LIFT (2.4 mm), turn, release. The teeth are V-shaped, so it self-centres into the nearest position with a solid "clack".
- PINION: axially captured in the drawer front's pinion cavity (max 0.4 mm play). The dial's hex key SLIDES through the pinion's hex bore when the dial lifts, so the pinion only ever turns and never lifts.
- PINION CAP (PLA, prints flat): closes the pinion cavity from below with 2 x M3. It is the floor the dial spring pushes against.
- DIAL SPRING (TPU 95A): a compression bushing or wave ring on the dial shaft's lower end, between the pinion cap and a washer held by an M3 screw in the shaft end.
  - It pulls the dial down into the lock with about 6-10 N, and lifting the dial compresses it by LOCK_LIFT.
  - Size it so the dial can't over-lift: hard stop at LOCK_LIFT + 0.4.
- The dial's hard-stop tab still hits STOP_POST at 0 mL and at max, so the gears and plunger are never the stop. The stop works whether the dial is lifted or not.

BAND (TPU 95A): two return bands.
- Default routing: slide hook -> around the rear post (diameter BAND_POST_D) -> front anchor post (diameter 6). Path length at rest BAND_PATH_REST, plus STROKE more at full pull.
- Make it an open strip with an eyelet loop at each end, free length = path / 1.08 (8% preload).
- Section about 1.25 wide x 0.8 thick (medium). Provide variants via a local constant BAND_T = 0.6 / 0.8 / 1.0 (light/medium/firm).
- Must print flat in one piece. Posed: draw it along its path (an approximate polyline sweep is fine) for the current pull state.

NAME PLATE + NAME_INLAY (PLA multi-color, prints FACE DOWN): plate NAME_PLATE[0] x NAME_PLATE[1] x NAME_PLATE[2] that presses into the drawer-front recess (friction ribs + 0.1 mm interference), corners R2.
- Text inlaid 0.6 deep, Inter SemiBold, letter-spaced 1.15, auto-sized to fit (cap height <= 6 mm), centred. Default text NAME.
- Posed on the drawer front.

Before you finish, verify: at STATE_PULL 0 and 1 and DIAL_ML 0 / mid / max, the plunger never intersects the slide, the rack meshes (tiny intersection at most) with the pinion, the dial's stop tab stops before the plunger hits either end, and nothing on the drawer pokes outside the puck's skin opening.
```

## CHUCK

Files: `parts/ring.scad`, `parts/guide_plate.scad`, `parts/jaw.scad`, `parts/jaw_pad.scad`, `parts/gasket.scad`

```text
YOUR GROUP: CHUCK. You own ring, guide_plate, jaw, jaw_pad and gasket. This is the drill-chuck-style twist lock that grips the upside-down jar's glass neck (the lid is never drilled). Twisting the knurled ring clockwise (seen from above) closes all 3 jaws together.

RING (PLA, prints UPRIGHT: the bottom is on the bed and slides on the deck flange; the scroll grooves are open on top):
- Annulus ID RING_ID, OD RING_OD, z in [Z_RING_BOT, Z_RING_TOP]. Rides on the deck's flange; its bore rides on the hub OD (clearance CL_ROT built into RING_ID).
- OUTER BAND: scallop flutes (fluted_circle, FLUTE_DEPTH, FLUTE_W, about 110-140 flutes) over the middle, with C_TOP/C_BED chamfers.
  - This is the grip: it should feel like a premium camera lens ring.
  - Engrave one small index dot on its upper chamfer.
- SCROLL: 3 starts, GROOVE_W wide, SCROLL_DEPTH deep, from radius R_PIN_MAX (open) down to R_PIN_MIN over TWIST degrees, with 12-degree run-outs.
  - Orientation: rotating the ring CLOCKWISE seen from above (RING_PHI negative) must move the pins INWARD.
  - Posed: rotate by RING_PHI so each jaw pin (at JAW_ANGLES[i], radius R_PIN) sits centred in its groove for any CHUCK_CLOSE. Verify at CHUCK_CLOSE 0, 0.5 and 1.
  - Lead angle is SCROLL_LEAD_ANGLE (about 4 degrees), so it self-locks.

GUIDE PLATE (PLA, prints TOP FACE DOWN on the textured plate, since the top is visible around the jar):
- Annulus ID 2*MOUTH_R (continues the bore), OD GP_OD, z in [Z_GP_BOT, Z_GP_TOP].
- Fixed to the hub top with 3 x M3 at GP_SCREW_R / GP_SCREW_ANGLES. Counterbored so the heads are flush and hidden under the gasket.
- 3 radial DOVETAIL tracks in its top at JAW_ANGLES (DOVETAIL = [top width, bottom width, depth]), running from just outside the gasket pocket to near the OD.
- PIN SLOTS through the plate along each track centreline, from R_PIN_MIN - PIN_D/2 - 0.6 to R_PIN_MAX + PIN_D/2 + 0.6, width PIN_D + CL_PIN.
- GASKET POCKET in the top: OD GASKET_OD + 0.4, ID GASKET_ID - 0.4, depth GASKET_T - GASKET_PROUD.
- Two tiny engraved arrow marks near the edge showing the lock and open directions (minimal, elegant).

JAW (PLA, x3 identical, prints TOP FACE DOWN; the pin points up in print):
- Rides in a dovetail track with a matching dovetail tongue (0.25 mm clearance per side).
- Pin diameter PIN_D, reaching down through the slot into the ring groove to 0.4 mm short of the groove floor.
- Radial length JAW_L, width JAW_W, height JAW_H above the plate.
- Grip face: concave cylinder of radius NECK_OD/2 + PAD_T at nominal, with a dovetail or keyed pocket that holds the TPU pad.
- Top and outer edges softly rounded (visible, accent color). The PLA face sits at radius R_PIN - PIN_OFF.
- Posed: jaw(i) at JAW_ANGLES[i], with the pin at radius R_PIN.

JAW PAD (TPU 95A, x3): PAD_T thick, matching the jaw face curvature, keyed into the jaw. Fine horizontal ribs (0.4 mm) on the gripping face to bite into the glass thread.

GASKET (TPU 95A): flat annulus GASKET_ID..GASKET_OD, GASKET_T thick, sitting in the pocket (GASKET_PROUD proud), with a soft 0.5 mm sealing bead on top under the jar rim.

Verify:
- At CHUCK_CLOSE = 1 the pads touch a NECK_OD cylinder (jar_ghost neck) with less than 0.3 mm interference.
- At CHUCK_CLOSE = 0 they clear a cylinder of NECK_OD + 2*CH_RANGE_D/4 + 2.
- Pins never hit groove walls.
- The ring never intersects the guide plate, the deck hub or the flange (posed deck may still be a stub).
- Everything works for the std, pro and template presets.
```

## PEDESTAL

Files: `parts/pedestal.scad` (pedestal, joiner, row_assembly), `parts/dose_drawer.scad`, `parts/foot.scad`

```text
YOUR GROUP: PEDESTAL. It replaces the old tall bar. The user keeps the heads inside a cabinet or lined up on a table, so nothing goes under a head.
Each head sits on its own low PEDESTAL that holds a DOSE DRAWER:
- Pull the dose handle (the slide's drawer front) and let go: one dose drops through the head's drop hole into the dose drawer.
- Slide the dose drawer out, pour it into a cup, slide it back.
- Pedestals line up side by side, ROW_PITCH apart.

PEDESTAL (PLA):
- Round, diameter PUCK_D (flush with the head above), from z = -PED_H to 0 in head coordinates.
- The top plate z in [-PED_TOP_T, 0] is the head's seat.
  - Two DOCK pins (diameter DOCK_PIN_D, 2.5 tall, chamfered) at DOCK_PINS. They mate with the holes in the head's bottom.
  - Opening PED_HOLE centred at (0, PED_HOLE_Y) under the drop hole, with a 0.8 mm drip edge.
- A DRAWER BAY: a tunnel open to the FRONT (-y) for the dose drawer.
  - Smooth runners, 0.4 mm clearance per side, a gentle TPU-free stop (the drawer front block hits the pedestal face).
  - A soft PLA snap bump so the drawer stays put but slides out with a light pull.
- Feet recesses for 4 TPU feet (FEET_T).
- JOINER pockets on both sides (x = +/-PUCK_R) at y = JOINER_Y, so an optional joiner keeps a row of pedestals aligned with PED_GAP between them.
- Print orientation: choose one that needs NO supports. For example print it upside down with the top plate on the bed (the flattest, most important face), with the bay walls rising and the runners shaped as 45-degree ledges.
  - If a closed floor is needed, make it a separate flat part and add it to your files and report.
- The visible skin continues the head's design language: same diameter, same reveal V-groove at the joint with the head, C_BED / C_TOP chamfers.

DOSE DRAWER (PLA, prints upright, open top; the inner floor is a top surface, so iron it):
- Outer width CUP_W (it lines up under the dose handle), wall CUP_WALL, floor CUP_FLOOR_T.
- Rim at CUP_TOP_Z, bottom at CUP_BOT_Z. Length from CUP_Y_REAR (rear, behind the drop hole) to CUP_Y_FRONT (front face aligned with the handle's front).
- The FRONT BLOCK outside the pedestal rises to CUP_FRONT_TOP_Z (1.8 mm reveal under the handle). It has a comfortable finger pull: a recessed scoop or undercut on its lower front.
- Interior: big smooth radii (>= R10 vertical corners, R5 floor fillets), so powder pours out completely with no corners to trap it.
- A POUR SPOUT at the front: a shaped lip, about 30-40 mm wide, that aims into a shaker mouth (about 50-60 mm).
  - Tilting the drawer forward must empty it completely.
- It must slide out smoothly and fast and look like a premium kitchen object.

FOOT (TPU): 4 grippy pads per pedestal.

row_assembly(n): n heads (call head_assembly(), which already includes pedestal, drawer and feet via the PARTS list) at x = i*ROW_PITCH, plus joiners between them.

TIP-OVER: one head on its pedestal with a full jar (about 2 kg total), with someone pulling the dose handle at about 10 N at handle height (about PED_H + 15 mm above the table).
- Compute the tipping margin and make sure a single pedestal is stable (footprint, feet).
- Put the numbers in a comment at the top of pedestal.scad.
```

## TOOLS

Files: `tools/build.py`, `tools/fitcheck.py`, `tools/render_all.py`, `tools/render/scenes/`

```text
YOUR GROUP: TOOLS. You own cad/v5/tools/ (build.py, fitcheck.py, render_all.py, render/scenes/). Do NOT write part geometry.
Other agents are writing the parts in parallel right now, and many part modules are still empty stubs. Build the tools to work with whatever exists, skip empty outputs gracefully, then test them for real once parts appear. Re-check every few minutes; if parts are still stubs, finish with tests on what exists.

1) tools/build.py: export printable STLs for a preset.
- Usage: python3 cad/v5/tools/build.py --preset std|pro|<name>|all [--parts a,b] [--name WHEY] [--jobs 3] [--out cad/v5/build].
- Read presets/<name>.scad and pass each NAME = value; line as -D NAME=value. Use an argument list, NO shell, and keep string values quoted.
- Export every printed part from the PARTS registry in dosebar.scad (parse it) via -D 'PART="<part>"'. Run in parallel with a process pool. Write to build/<preset>/<part>.stl.
- For each STL with trimesh, check watertight, volume and bbox (must fit 250 x 250 x 250), and estimate grams:
  - PLA 1.24 g/cm3, TPU 1.21.
  - Shell = min(V, surface_area * 1.2 mm); grams = density * (shell + 0.15 * (V - shell)).
- Write build/<preset>/manifest.json and build/<preset>/PARTS.md (part, material, color role, qty per head, grams each/total, bbox, status), plus totals per head.
- Skip empty stub outputs with a clear "not implemented" status (OpenSCAD errors on empty top-level objects; handle that).

2) tools/fitcheck.py: interference matrix.
- Export each part in its ASSEMBLED pose (-D 'PART="posed:<part>"') for a matrix of states: STATE_PULL in {0, 0.5, 1} x DIAL_ML in {0, V_MAX/2, V_MAX} x CHUCK_CLOSE in {0, 1}. Allow --quick for a reduced matrix.
- Compute pairwise intersection volumes with manifold3d.
- Use an ALLOWLIST of intended contacts with max volumes:
  - wiper vs slide (slight interference)
  - jaw_pad vs jar
  - stir_post vs slide (peg in socket: 0)
  - pinion vs plunger (mesh, tiny)
  - dial vs pinion (keyed)
  - detent vs dial (preload)
  - gasket vs guide_plate (pocket)
- Print a table and exit non-zero on unexpected interference > 0.5 mm3.
- Also check the slide never pokes outside the puck skin (vs a cylinder of radius PUCK_R from z=0 to Z_RING_TOP), except the drawer front, which is outside by design.
- Cache posed STLs by (part, state, preset) under build/fit/.

3) tools/render_all.py + tools/render/scenes/: beautiful photo renders using the existing three.js renderer (tools/render/render.mjs, run with node; it serves only files inside tools/render, so copy STLs to tools/render/assets/).
- Export colored groups per the PARTS color roles (body #ECE8DF warm white, accent #2F3237 charcoal, tpu #3A3D42) plus a glass jar from jar_ghost().
  - Glass: render.html supports "glass": true. Add a powder-fill option: an opaque, slightly rough off-white cylinder inside the jar.
- Scenes:
  a. hero: one std head with jar, 3/4 front-left view, soft shadow.
  b. pulled: drawer pulled with the dial at 25 mL.
  c. dial close-up from above-front.
  d. exploded view: parts offset along z.
  e. bar: 3 heads on bays.
  f. pro head next to a std head.
- Tune lighting/exposure so the renders look like premium product photography: warm neutral background, gentle shadows, no blown highlights. render.html currently looks washed out, so you MAY edit tools/render/render.html and render.mjs (they are yours) to improve tone mapping, add an ACES exposure parameter, SSAO-like contact shadows via a ShadowMaterial plane, and so on.
- Output: cad/v5/renders/*.png.
- Look at every render with the Read tool and iterate until it looks great with whatever parts exist.

Document usage at the top of each script. Test with the std preset.
```
