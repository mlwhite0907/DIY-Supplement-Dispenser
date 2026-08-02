# 3D Models – Phase 1 Powder Module

Parametric OpenSCAD sources for the single-powder feeder: hopper, auger, housing, test stand, and load-cell platform. Target printer: **Bambu Lab** (Bambu Studio). Preferred material: **PETG**.

**Design authority:** [docs/PHASE1_DESIGN_HANDOFF.md](../docs/PHASE1_DESIGN_HANDOFF.md)

---

## Catalog (v0.1)

| Part | Source | Expected STL | Role |
|------|--------|--------------|------|
| Powder hopper | [`openscad/powder_hopper_v01.scad`](openscad/powder_hopper_v01.scad) | `stl/powder_hopper_v01.stl` | Conical mass-flow hopper, 65° walls, top flange, bottom spigot + M3 flange |
| Auger screw | [`openscad/auger_screw_v01.scad`](openscad/auger_screw_v01.scad) | `stl/auger_screw_v01.stl` | Single-start Archimedes screw + NEMA17 coupler |
| Auger housing | [`openscad/auger_housing_v01.scad`](openscad/auger_housing_v01.scad) | `stl/auger_housing_v01.stl` | Barrel, NEMA17 plate, inlet mate, outlet nozzle, vibe pocket |
| Test stand | [`openscad/test_stand_v01.scad`](openscad/test_stand_v01.scad) | `stl/test_stand_v01.stl` | Raises outlet ~55 mm for cup + scale under outlet |
| Scale platform | [`openscad/scale_platform_v01.scad`](openscad/scale_platform_v01.scad) | `stl/scale_platform_v01.stl` | Deck for 5 kg bar load cell + cup recess |
| NEMA17 lib | [`openscad/lib/nema17.scad`](openscad/lib/nema17.scad) | — | Shared hole pattern / plate |
| Constants | [`openscad/lib/constants.scad`](openscad/lib/constants.scad) | — | Shared dimensions (edit here first) |

Print settings and orientation: **[PRINT_GUIDE.md](PRINT_GUIDE.md)**.

---

## Locked dimensions (v0.1)

| Feature | Value |
|---------|--------|
| Hopper top ID | 90 mm |
| Hopper bottom ID | 22 mm |
| Hopper wall angle | 65° from horizontal |
| Cylindrical head | 40 mm |
| Wall thickness | 2.2 mm (range 2.0–2.4) |
| Top flange | 7 mm wide, 4× M3 on 100 mm BCD |
| Hopper↔housing mate | Spigot + 4× M3 on 34 mm BCD |
| Auger OD / root / pitch | 16.8 / 8.5 / 11 mm |
| Barrel ID / length | 18.0 / 70 mm |
| NEMA17 | 42 mm face, 31 mm hole spacing |
| Vibe motor pocket | Ø12 × ~3.2 mm coin motor |
| Load cell | 80 × 12.7 mm bar style |

Edit [`openscad/lib/constants.scad`](openscad/lib/constants.scad) and re-export to iterate.

---

## Interfaces

```
[hopper bottom flange + spigot]
        │  4× M3 on 34 mm BCD
        ▼
[housing inlet counterbore + flange]
        │  barrel → auger screw
        ▼
[outlet nozzle] ──drops──► [cup on scale_platform on load cell]
```

- **Hopper → housing:** registration spigot seats in housing counterbore; four M3 screws clamp flanges (easy to open for cleaning). Bayonet can replace screws in a later revision.
- **Auger → NEMA17:** printed coupler on screw (5 mm bore + M3 set-screw). Optional commercial coupling if preferred.
- **Vibration:** coin motor in housing side pocket near inlet; wire channel toward motor end.
- **Stand:** barrel drops into two U-cradles; outlet clears ~55 mm above table.

---

## Versioning

| Tag | Meaning |
|-----|---------|
| `v01` | First printable geometry from design handoff |
| `v02+` | Dimension or interface changes after powder tests |

- Filenames: `partname_vNN.scad` / `.stl`
- Bump version when mating interfaces or critical flow dims change
- Keep previous STLs until the new set is printed and verified
- Note changes in this README under **Changelog**

### Changelog

- **v01 (2026-08):** Initial parametric set — hopper, auger, housing, stand, scale platform, libs, export script, print guide.

---

## Generating STLs

### Option A – export script (preferred)

```bash
cd 3d_models
./scripts/export_stls.sh
```

Requires OpenSCAD CLI on `PATH` as `openscad`, or macOS app at  
`/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`.

### Option B – manual GUI

1. Open a `.scad` file in OpenSCAD  
2. **F6** (render)  
3. **File → Export → Export as STL** into `3d_models/stl/`

### Option C – one-liner

```bash
openscad -o stl/powder_hopper_v01.stl openscad/powder_hopper_v01.scad
```

If OpenSCAD is not installed, install from [openscad.org](https://openscad.org/) or `brew install --cask openscad`, then re-run the script. Sources remain fully editable without the CLI.

---

## Bambu Studio (quick start)

1. Export or copy STLs from `stl/`  
2. New project → Import  
3. Profile base: **PETG** (or Bambu PETG HF)  
4. Layer height **0.16–0.20 mm**, walls **3–4**, see [PRINT_GUIDE.md](PRINT_GUIDE.md) for per-part orientation  
5. Slow outer walls ~40–50 mm/s on hopper for smoother interior  

---

## Food-adjacent notes

- PETG is preferred for prototype powder contact (cleanable, tough).  
- Higher wall counts; avoid sparse top surfaces on powder paths.  
- This is **not** a certified food-contact design. For long-term use, consider food-safe coating or commercial food-grade liners after flow is proven.  
- Do not use abrasive cleaners that pit the print surface.

---

## Out of scope (v0.1)

- Multi-module frame, pill module, lids with desiccant, WiFi enclosures  
- Full aesthetic polish — function and cleanability first  

After first powder tests, feed bridging / accuracy data back into `constants.scad` and cut `v02`.
