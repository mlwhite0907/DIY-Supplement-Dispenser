# 3D Models – Phase 1 Powder Module

Parametric OpenSCAD sources for the single-powder feeder: hopper, lid, auger, housing, test stand, scale platform, and load-cell fixed base. Target printer: **Bambu Lab** (Bambu Studio). Preferred material: **PETG**.

Geometry is **v0.2 stack-up** (closed free end, coupler pocket, shorter flights). Filenames stay `*_v01` for path stability; `PART_VERSION` in constants is `"v02"`.

**Design authority:** [docs/PHASE1_DESIGN_HANDOFF.md](../docs/PHASE1_DESIGN_HANDOFF.md)

---

## Catalog (all STLs)

| Part | Source | STL | Approx. size | Role |
|------|--------|-----|--------------|------|
| Powder hopper | [`openscad/powder_hopper_v01.scad`](openscad/powder_hopper_v01.scad) | `stl/powder_hopper_v01.stl` | ~632 KB | Conical mass-flow hopper, 65° walls, top flange, bottom spigot + M3 flange; **~450+ ml** internal volume |
| Hopper lid | [`openscad/hopper_lid_v01.scad`](openscad/hopper_lid_v01.scad) | `stl/hopper_lid_v01.stl` | ~250 KB | Top deck + lip into hopper mouth, 4× M3 on 100 mm BCD, optional desiccant well |
| Auger screw | [`openscad/auger_screw_v01.scad`](openscad/auger_screw_v01.scad) | `stl/auger_screw_v01.stl` | ~723 KB | Single-start screw, shorter flights (48 mm), hex coupler for NEMA17 5 mm shaft |
| Auger housing | [`openscad/auger_housing_v01.scad`](openscad/auger_housing_v01.scad) | `stl/auger_housing_v01.stl` | ~949 KB | Barrel, NEMA17 plate, coupler pocket, closed free-end bushing, inlet, outlet, vibe pocket, set-screw access |
| Test stand | [`openscad/test_stand_v01.scad`](openscad/test_stand_v01.scad) | `stl/test_stand_v01.stl` | ~164 KB | Two U-cradles; outlet clears ~55 mm for cup + scale |
| Scale platform | [`openscad/scale_platform_v01.scad`](openscad/scale_platform_v01.scad) | `stl/scale_platform_v01.stl` | ~117 KB | Live-end deck for 5 kg bar load cell + Ø70 cup recess |
| Load-cell fixed base | [`openscad/loadcell_fixed_base_v01.scad`](openscad/loadcell_fixed_base_v01.scad) | `stl/loadcell_fixed_base_v01.stl` | ~86 KB | Fixed end of bar cell; table → base → cell → platform → cup |
| NEMA17 lib | [`openscad/lib/nema17.scad`](openscad/lib/nema17.scad) | — | — | Shared hole pattern / plate helpers |
| Constants | [`openscad/lib/constants.scad`](openscad/lib/constants.scad) | — | — | Shared dimensions (edit here first) |

Print settings and orientation: **[PRINT_GUIDE.md](PRINT_GUIDE.md)**.

---

## v0.2 stack-up (critical)

The barrel is **70 mm** long and no longer open at both ends.

```
Motor end (x=0)                              Free end (x=70)
[NEMA plate 6 mm shaft hole]
    → coupler pocket (~13 mm ID × ~17.5 mm)
    → flight bore (Ø18)
    → closed endcap with root bushing (~9.4 mm ID)
```

| Feature | Value | Why |
|---------|--------|-----|
| Coupler pocket | Ø13 × ~17.5 mm at motor end | Hex coupler (OD 12) seats **inside** barrel; does not pass the plate |
| Plate shaft hole | Ø6 mm only | Motor shaft enters coupler; **never** slide full auger through plate |
| Active flights | 48 mm (was 70) | Leaves room for coupler zone + tip in 70 mm barrel |
| Free-end bushing | ID ≈ root + 0.9 mm (~9.4), depth 6 mm | Closes powder path; supports tip only |
| Set-screw access | Radial side hole into coupler zone | Tighten M3 after motor is mounted |
| Tiny end vent | Ø0.9 mm | Air escape; powder does not dump |

**Assembly rule:** insert auger from the **free end, tip first**. See [PRINT_GUIDE.md](PRINT_GUIDE.md).

---

## Locked dimensions

| Feature | Value |
|---------|--------|
| Hopper top ID | 90 mm |
| Hopper bottom ID | 22 mm |
| Hopper wall angle | 65° from horizontal |
| Cylindrical head | 40 mm |
| Cone height | ≈ 72.9 mm |
| **Hopper internal volume** | **~450+ ml** (frustum ≈ 200 ml + cylinder ≈ 254 ml ≈ **455 ml**) |
| Wall thickness | 2.2 mm (range 2.0–2.4) |
| Top flange | 7 mm wide, 4× M3 on 100 mm BCD |
| Hopper↔housing mate | Spigot + 4× M3 on 34 mm BCD |
| Auger OD / root / pitch | 16.8 / 8.5 / 11 mm |
| Auger active flights | 48 mm + tip + coupler 14 mm |
| Barrel ID / length | 18.0 / 70 mm |
| NEMA17 | 42 mm face, 31 mm hole spacing |
| Vibe motor pocket | Ø12 × ~3.2 mm coin motor |
| Load cell | 80 × 12.7 mm bar style (verify hole spacing) |

Edit [`openscad/lib/constants.scad`](openscad/lib/constants.scad) and re-export to iterate.

---

## Interfaces

```
[hopper lid] ── 4× M3 on 100 mm BCD ──► [hopper top flange]
[hopper bottom flange + spigot]
        │  4× M3 on 34 mm BCD
        ▼
[housing inlet counterbore + flange]
        │  barrel → auger (insert from free end)
        ▼
[outlet nozzle] ──drops──► [cup on scale_platform]
                                    │
table → loadcell_fixed_base → cell fixed end
                              cell live end → scale_platform
```

- **Hopper → housing:** registration spigot seats in housing counterbore; four M3 screws clamp flanges.
- **Auger → NEMA17:** printed hex coupler (5 mm bore + M3 set-screw) inside coupler pocket; shaft only through plate.
- **Vibration:** coin motor in housing side pocket near inlet; wire channel toward motor end.
- **Stand:** barrel in two U-cradles; motor-plate stop; outlet clears ~55 mm above table.
- **Scale:** fixed base under fixed end of cell; platform on live end with cup recess clear of M4 counterbores.

---

## Versioning

| Tag | Meaning |
|-----|---------|
| `v01` filenames | Path-stable names for SCAD/STL |
| geometry `v02` | Stack-up fix: closed end, bushing, coupler pocket, shorter flights, lid, fixed base |

### Changelog

- **v02 geometry (2026-08):** Closed free-end bushing; motor-end coupler pocket; flights 48 mm; set-screw access; hopper lid; load-cell fixed base; stand/platform stack-up; hopper volume documented ~455 ml; assembly from free end only.
- **v01 (2026-08):** Initial parametric set — hopper, auger, housing, stand, scale platform, libs, export script, print guide.

---

## Generating STLs

### Option A – export script (preferred)

```bash
cd 3d_models
./scripts/export_stls.sh
# or: make stl
```

Exports **all seven** printable parts:

`powder_hopper_v01`, `auger_screw_v01`, `auger_housing_v01`, `test_stand_v01`, `scale_platform_v01`, `hopper_lid_v01`, `loadcell_fixed_base_v01`

Requires OpenSCAD CLI on `PATH` as `openscad`, or macOS app at  
`/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD`.

### Option B – Makefile

```bash
cd 3d_models
make stl      # export all
make list     # list sources and STLs
make clean    # remove stl/*.stl
```

### Option C – manual GUI

1. Open a `.scad` file in OpenSCAD  
2. **F6** (render)  
3. **File → Export → Export as STL** into `3d_models/stl/`

### Option D – one-liner

```bash
openscad -o stl/powder_hopper_v01.stl openscad/powder_hopper_v01.scad
```

If OpenSCAD is not installed: [openscad.org](https://openscad.org/) or `brew install --cask openscad`.

---

## Bambu Studio + PETG (summary)

| Setting | Baseline |
|---------|----------|
| Filament | PETG (Bambu PETG-HF or Generic PETG) |
| Nozzle | 0.4 mm |
| Layer height | 0.16–0.20 mm |
| Walls | 3–4 (4 on powder shells) |
| Top / bottom | 5 / 4 |
| Infill | 25–40 % gyroid; **auger 80–100 %** |
| Outer wall speed | 40–50 mm/s on powder-contact parts |
| Bed / nozzle | Profile defaults (~70–80 °C bed) |

Full per-part orientation and assembly: **[PRINT_GUIDE.md](PRINT_GUIDE.md)**.

---

## Food-adjacent notes

- PETG is preferred for prototype powder contact (cleanable, tough).  
- Higher wall counts; avoid sparse top surfaces on powder paths.  
- This is **not** a certified food-contact design.  
- Do not use abrasive cleaners that pit the print surface.

---

## Out of scope (Phase 1)

- Multi-module frame, pill module, WiFi enclosures  
- Full aesthetic polish — function and cleanability first  

After first powder tests, feed bridging / accuracy data back into `constants.scad` and bump geometry as needed.
