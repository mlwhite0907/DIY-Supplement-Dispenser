# Print Guide – Phase 1 Powder Module (Bambu Studio + PETG)

Use with OpenSCAD sources in `openscad/` and STLs in `stl/`.  
Geometry: **v0.2 stack-up** (closed free end, coupler pocket). Filenames remain `*_v01`.

Design basis: [docs/PHASE1_DESIGN_HANDOFF.md](../docs/PHASE1_DESIGN_HANDOFF.md) · Catalog: [README.md](README.md)

---

## Global PETG baseline (Bambu Studio)

| Setting | Recommendation |
|---------|----------------|
| Filament | PETG (Bambu PETG-HF or Generic PETG) |
| Nozzle | 0.4 mm |
| Layer height | 0.16–0.20 mm (0.20 OK for stand / fixed base) |
| Walls / perimeters | 3–4 |
| Top / bottom shells | 5 / 4 |
| Infill | 25–40 % gyroid or cubic (**auger: 80–100 %**) |
| Bed | Textured PEI or smooth PEI with glue if needed |
| Bed temp | Profile default (~70–80 °C) |
| Nozzle temp | Profile default; +5 °C if layer adhesion looks weak |
| Outer wall speed | 40–50 mm/s on powder-contact parts |
| Overhangs | Enable “slow down for overhangs” |
| Cooling | Moderate; avoid full-blast on PETG small features |
| Ironing | Optional on lid deck / platform top |

**Food-adjacent:** prefer more walls over sparse shells for powder paths; wipe with damp cloth only for early tests.

---

## STL catalog (print set)

| STL | Typical use |
|-----|-------------|
| `powder_hopper_v01.stl` | ~455 ml powder body |
| `hopper_lid_v01.stl` | Top cover / dust lid |
| `auger_screw_v01.stl` | Drive screw (coupler + flights) |
| `auger_housing_v01.stl` | Barrel + motor plate + closed end |
| `test_stand_v01.stl` | Bench cradle |
| `scale_platform_v01.stl` | Cup deck on load-cell live end |
| `loadcell_fixed_base_v01.stl` | Load-cell fixed end on table |

---

## Part-by-part

### 1. `powder_hopper_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | **Preferred:** **top flange on the bed** (wide end down). That puts a large flat flange on the build plate and builds the cone upward. **Alt:** on side only if supports are manageable. |
| **Do not assume** | Printing “point-down” (outlet/spigot on bed) does **not** put the powder **interior** on the bed. The bed touches the **outside** of the outlet; the cavity is still formed by walls/overhangs. Point-down is optional for other reasons (outlet flatness), not for a “smooth interior on bed” myth. |
| **Supports** | Underside of bottom flange / spigot features as needed when flange-down; **avoid supports inside the powder cavity**. |
| **Walls** | 4 |
| **Infill** | 30–40 % gyroid |
| **Layer** | 0.16–0.20 mm |
| **Volume** | Internal capacity **~450+ ml** (≈ 455 ml from frustum + cylinder), not 250–320 ml. |
| **Notes** | Slow outer walls. Light sand interior only if layer lines catch powder. Check M3 holes with a 3 mm bit / tap as needed. |

### 2. `hopper_lid_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | Flat deck on bed (as modelled); lip up or flip so lip prints as overhang with supports if needed. Deck-down is usually fine. |
| **Supports** | Lip underside if it droops; tree or normal outside powder contact. |
| **Walls** | 3–4 |
| **Infill** | 20–30 % |
| **Layer** | 0.20 mm OK |
| **Notes** | 4× M3 align with hopper top flange (100 mm BCD). Optional desiccant pocket on underside. |

### 3. `auger_screw_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | **Vertical** — coupler on bed, tip up (axis = Z). Best flight roundness and strength. |
| **Supports** | Usually none for single-start; enable only if flights droop. |
| **Walls** | 3–4 |
| **Infill** | **80–100 %** (stiffness; NEMA17 torque) |
| **Layer** | 0.16 mm preferred |
| **Notes** | Ream 5 mm shaft bore to slip fit. M3 set-screw: 2.5 mm tap drill then M3 tap. Hand-spin in barrel before motor power. |

### 4. `auger_housing_v01`

| Item | Guidance |
|------|----------|
| **Orientation A** | Motor plate flat on bed (barrel roughly vertical): good plate flatness. |
| **Orientation B** | Barrel on its side: sometimes better bore roundness. Try A first. |
| **Supports** | Inlet flange underside, outlet nozzle if horizontal, vibe pocket roof, endcap as needed. |
| **Walls** | 4 |
| **Infill** | 30–40 % |
| **Layer** | 0.20 mm OK; 0.16 if bore is rough |
| **v02 features** | Coupler pocket at motor end; **closed free end** with root-diameter **bushing** (not full barrel ID); radial **set-screw access** boss. |
| **Notes** | Bore smoothness matters. Light sand or wooden dowel + paper. Confirm NEMA17 holes with a spare motor. Spigot counterbore must take hopper freely (~0.4 mm design clearance). |

### 5. `test_stand_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | Base on bed (as modelled). |
| **Supports** | Usually none if cradles open upward. |
| **Walls** | 3 |
| **Infill** | 20–25 % |
| **Layer** | 0.20 mm |
| **Notes** | Fast print. Optional rubber feet in bottom recesses. Motor-plate stop keeps housing from sliding. |

### 6. `scale_platform_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | Top deck up (cup recess on top) for smooth recess surface. |
| **Supports** | None typical. |
| **Walls** | 4 |
| **Infill** | 40 % |
| **Layer** | 0.16–0.20 mm |
| **Notes** | **Measure your load cell hole spacing** before printing; edit `LOADCELL_HOLE_SPACE` if ≠ 15 mm. M4 clearance 4.2 mm. Live-end boss offset so Ø8 counterbores stay outside Ø70 cup recess. |

### 7. `loadcell_fixed_base_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | Flat base on bed. |
| **Supports** | None typical. |
| **Walls** | 3–4 |
| **Infill** | 30–40 % |
| **Layer** | 0.20 mm |
| **Notes** | Cell seat pocket on top; M4 through + bottom counterbores; optional table M3 mounts. Stack: table → **this** → cell fixed end → (live end) → `scale_platform` → cup. |

---

## Assembly order (CRITICAL – dry fit first)

**v0.2 closed-end housing. Do not assemble like an open tube.**

1. **Insert auger from the FREE END (bushing / endcap end), tip first.**  
   Flights enter first; coupler last. Coupler seats in the motor-end enlarged pocket.  
2. **Mount NEMA17** to the motor plate (M3×8–10). Shaft passes **only** through the Ø6 mm plate hole into the coupler bore.  
3. **Tighten the coupler set-screw** through the **side access hole** on the housing (align with shaft flat if present).  
4. **NEVER** try to slide the 16.8 mm auger (or coupler) **through the motor plate**. The plate is shaft-only; the free end is closed except for the root bushing.  
5. Seat hopper spigot into housing inlet; install 4× M3 on 34 mm BCD.  
6. Fit hopper lid (4× M3 on 100 mm BCD) when ready to store powder.  
7. Press coin vibe motor into pocket; route wires in channel toward motor end.  
8. Drop housing into test stand cradles (motor end against stop).  
9. Bolt `loadcell_fixed_base` to table (optional M3); bolt fixed end of cell to base; bolt live end to `scale_platform`; place cup in recess under nozzle.  

Check free rotation of auger with power off. No grind, no scrape. Tip should spin in the bushing; flights stay in the Ø18 bore.

### Why free-end insertion?

| Path | Result |
|------|--------|
| Free end → tip first | Coupler lands in pocket; tip in bushing; works |
| Motor plate → flights first | **Blocked** — plate hole is ~6 mm; flights are 16.8 mm |
| Motor plate → coupler first | Coupler will not pass plate; wrong direction |

---

## First-print risk list

| Risk | Mitigation |
|------|------------|
| Hopper bridging in real powder | Vibration duty cycle; steeper angle or liner later |
| Auger packs hard powders | Reduce pitch or OD slightly; short reverse pulse in firmware |
| Barrel ovality | Ream; or print plate-down and accept supports |
| Wrong assembly direction | Re-read free-end / tip-first rule above |
| Load cell hole mismatch | Measure cell; regenerate platform / fixed base only |
| PETG stringing in flights | Dry filament; temp tower; wipe auger before install |
| Powder dump from free end | Should not happen if bushing ID is root-sized (v02) |

---

## Export reminder

```bash
cd 3d_models && ./scripts/export_stls.sh
# or: make stl
```

All seven STLs listed above. See [README.md](README.md) if `openscad` is missing.
