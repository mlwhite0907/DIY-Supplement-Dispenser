# Dose Bar v5: handoff / continuation guide

> Read this first if you are picking up the project (person or AI). It records what was decided, what exists, what is in progress, and exactly what to do next. Updated on every push.

## 1. The goal

A **manual, no-electronics powder dispenser** for 10+ supplement powders, built around the owner's existing **glass jars**.

| Requirement | Detail |
|---|---|
| Jar use | Jars are used **upside down**. Lids are **never drilled**. |
| Dosing | One pull of a drawer gives one exact dose. |
| Adjustment | A preset **dose dial** in mL. It is universal, nothing product-specific. 0 = off. |
| Build at home | **Bambu Lab P2S**, **PLA + TPU 95A only**, a general M3/M4 screw assortment, no metal springs, nothing to buy. |
| Look | It must look like a premium product: uniform, modern, every detail considered. It must work. |
| Expandable | A head for any jar size, and bar bays that bolt on. |

### Jars

| Preset | Qty | Lid OD | Height (lid on) | Neck OD (est.) | Mouth ID (est.) |
|---|---|---|---|---|---|
| `std` | 9 | 4.5 in ≈ 114 mm | 165 mm (7 jars), ≈117 mm (2 jars) | ≈108 | ≈96 |
| `pro` | 1 | 5 in ≈ 127 mm | 292 mm | ≈121 | ≈108 |

Neck OD and mouth ID are **unmeasured estimates**. The chuck grips ±10 mm around the neck estimate. The owner's shaker height and under-cabinet clearance are also unknown, so `SHAKER_H` is a parameter.

## 2. Architecture (decided)

- **Head = round "puck"** under each jar: Ø ≈157 mm (std) / ≈170 mm (pro).
  - Stack, from the bottom: base (floor, channel, drop hole, band posts) → deck (ceiling with throat + strike-off edge, funnel, hub, flange) → twist ring → guide plate → 3 jaws → TPU gasket → upside-down jar.
- **Chuck:** 3-jaw scroll chuck, drill-chuck style.
  - A knurled ring with a 3-start Archimedean scroll on its top drives jaw pins through radial slots in the guide plate.
  - Clockwise from above closes it. 150° twist. Lead angle ≈ 4°, so it self-locks.
- **Doser:** volumetric slide (drawer).
  - The chamber is a through-pocket in the slide. Its fixed rear wall and a **plunger** front wall set its length.
  - Pulling moves the chamber under the strike-off edge, across a 5 mm land, and over the drop hole. The solid rear section keeps the throat covered the whole time.
- **Dial:** single turn, 300°, 40 clicks.
  - It turns a **pinion (m1, z12, PA25, stub teeth)** that drives a **rack rod** on the plunger. The rack runs inside the drawer front.
  - The pinion is a separate part keyed on the dial shaft's hex, held by an M3 screw from below. TPU detent.
- **One drivetrain for every head** (same pinion, rack, stroke 37.4 mm and dial travel). Only the chamber cross-section changes per dose class:

| Class | Dial range | Per click | Chamber W × H (mm) |
|---|---|---|---|
| S | 0–20 mL | 0.5 mL | ≈35 × 18 |
| M | 0–40 mL | 1 mL | ≈53 × 24 |
| L | 0–80 mL | 2 mL | ≈75 × 34 |

- **Stir post:** a slim PLA rake that plugs into the slide's rear section. It rises through a slot behind the throat and a keyway in the funnel into the jar neck. It sweeps about 37 mm on every pull and every return to stop bridging and rat-holing of cohesive powders (whey, collagen, BCAA, pre-workout). It replaced the earlier pivoting "stir wand" idea.
- **Return:** two TPU 95A bands. Routing: slide side hook → around a rear post (pulley) → front anchor, ≈+18 % strain. A hair tie or rubber band can loop hook ↔ rear post directly.
- **v5.1 (after the design review):**
  - Sealed transit: stroke ≈72 mm (std), land ≥ L_MAX + 5.
  - Push-pull drawer with TPU-sleeved M4 stops and no springs.
  - Stir post removed; an optional rocker wand replaces it.
  - Pill-shaped body under the round chuck collar.
  - Two-part slide: body + drawer front.
  - One-piece locking dial: lift to turn, 5° crown, TPU crush-tube spring.
  - Mirrored chuck: closes like a lid in the refill pose.
  - Rigid jaws with TPU boots, gasket lip, 0.2 mm Z grid, bundled Inter fonts.
  - See `cad/v5/README.md` "v5.1 OVERRIDES".
- **Use (decided with the owner on 2026-11-27):**
  1. Set the locking dial once (lift, turn, release).
  2. Pull the dose handle out to its stop: one dose drops into the **dose drawer** in the head's pedestal. Push the handle home again; that refills the chamber.
  3. Slide the drawer out and pour into a cup.
  - Heads live in a cabinet or lined up on a table, so nothing goes under a head. The old tall bar was removed.
- **Pedestal:** a low round base per head (Ø = head) with dock pins, the dose-drawer bay and TPU feet. Optional joiners line up a row.
- **Locking dial:** a PLA lock ring with 48 V-teeth plus matching teeth under the dial. Lift 2.4 mm to turn; a TPU spring under the pinion cap pulls it back down. The pinion is axially captured and the dial's hex key slides through it.

## 3. Files

| Path | What it is |
|---|---|
| `docs/v5/DESIGN.md` | Original design intent (draft 0). Superseded where it conflicts with this file: stir post, unified drivetrain. |
| `docs/v5/BUILD_BRIEFS.md` | **Exact per-part implementation briefs** (BODY / DRAWER / CHUCK / BAR / TOOLS) |
| `cad/v5/README.md` | **CAD build contract**: coordinates, datums, ownership, module contract, printability rules, interfaces, design language, verification |
| `cad/v5/params.scad` | Master parameters and every interface datum, derived from a jar preset |
| `cad/v5/dosebar.scad` | Entry. `PART=assembly`, `<part>` (print pose), `posed:<part>`, `bar` |
| `cad/v5/lib/` | Style tokens and helpers, involute gears, scroll |
| `cad/v5/presets/` | `std`, `pro`, `_template` |
| `cad/v5/parts/*.scad` | One file per part. Stubs until implemented (see status). |
| `cad/v5/parts/coupon.scad` | Tolerance test coupon (done, watertight) |
| `cad/v5/tools/` | `build.py` (STL export + grams), `fitcheck.py` (interference matrix), `render_all.py`, `render/` (three.js photo renderer) |
| `docs/v5/MEASURE_YOUR_JAR.md`, `CALIBRATION.md`, `PRINT_GUIDE.md` | User guides (done) |

## 4. Status (update on every push)

| Area | Status |
|---|---|
| Design intent, contract, params, libs, presets, coupon, guides | ✅ done |
| Design review panel (5 lenses + research + red team) | 🔄 running; findings will land in `docs/v5/reviews/` |
| Parts: base, deck, ring, jaws | 🔄 first versions in repo; review + fix running |
| Parts: slide, drive (plunger, dial, pinion, lock ring, dial spring, pinion cap) | 🔄 rebuilding for the locking dial |
| Parts: pedestal, dose drawer, feet, joiner | 🔄 being built (replaced the tall bar) |
| Tools: build.py / fitcheck.py / render_all.py | 🔄 work in progress (first versions committed) |
| Integration: fit check across states, renders, interactive 3D viewer | ⏳ next |
| Docs: DIAL_SETTINGS (generic chart), ASSEMBLY, README front page, archive v0.2 | ⏳ next |

## 5. How to continue

1. Read `cad/v5/README.md` and `cad/v5/params.scad`, then `docs/v5/BUILD_BRIEFS.md`.
2. For any part still a stub, implement it to its brief. Keep the exact module signatures and take every mating dimension from `params.scad`.
3. Verify (contract §7):
   ```bash
   cd cad/v5
   openscad -o /tmp/p.stl -D 'PART="<part>"' dosebar.scad
   openscad -o /tmp/p.stl -D 'PART="posed:<part>"' -D STATE_PULL=1 -D DIAL_ML=40 dosebar.scad
   python3 tools/build.py --preset std
   python3 tools/fitcheck.py --preset std
   ```
4. Render: `python3 tools/render_all.py` writes to `cad/v5/renders/`.
5. Tests that matter physically: print `coupon` first, then one std head; calibrate per `docs/v5/CALIBRATION.md`.

## 6. Open questions for the owner

- With the lid off: neck OD, mouth ID and body OD of one 4.5" jar and of the protein jar.
- Shaker height with the lid off (sets `SHAKER_H`). Whether the bar goes under wall cabinets: the tall jars stack to ≈50 cm.
- PLA colors on hand (default palette: warm white body + charcoal accent).
