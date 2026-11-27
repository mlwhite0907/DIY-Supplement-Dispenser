# Dose Bar v6 CAD

OpenSCAD source for the whole head. Everything is driven by `params.scad`.

| File | Role |
|---|---|
| `params.scad` | All dimensions and the coordinate convention (read its header first) |
| `dosebar.scad` | Entry point: `-D 'PART="assembly"'`, `"<part>"` (print pose) or `"posed:<part>"` |
| `parts/` | One file per group of parts; each defines `<part>()` (assembled pose) and `<part>_print()` |
| `presets/` | Jar measurements + dose class |
| `lib/` | Style tokens, stepped-chamfer extrude, involute gear and scroll helpers |
| `tools/` | `build.py`, `fitcheck.py`, `overhang.py`, optional fast renderer |

Rules that keep it printable and consistent:
- Heights sit on a 0.2 mm grid (`zq()`); chamfers are stepped per layer (`cx()`).
- No supports: overhangs at most 45° (one 60° relief cone that touches nothing), bridges under 25 mm.
- Parts never share coincident faces; added solids start inside their base.
- State variables (`STATE_PULL`, `DIAL_ML`, `CHUCK_CLOSE`, `DRAWER_OUT`) pose the assembly for checks and renders.

See `docs/v6/HANDOFF.md` for the design rationale and the verify/rebuild commands.
