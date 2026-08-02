# Print Guide – Phase 1 Powder Module (Bambu Studio + PETG)

Use this with the OpenSCAD sources in `openscad/` and STLs in `stl/`.  
Design basis: [docs/PHASE1_DESIGN_HANDOFF.md](../docs/PHASE1_DESIGN_HANDOFF.md).

---

## Global PETG baseline (Bambu Studio)

| Setting | Recommendation |
|---------|----------------|
| Filament | PETG (Bambu PETG-HF or Generic PETG) |
| Nozzle | 0.4 mm |
| Layer height | 0.16–0.20 mm (0.20 OK for stand/platform) |
| Walls / perimeters | 3–4 |
| Top / bottom shells | 5 / 4 |
| Infill | 25–40 % gyroid or cubic (auger: 80–100 %) |
| Bed | Textured PEI or smooth PEI with glue if needed |
| Bed temp | Profile default (~70–80 °C) |
| Nozzle temp | Profile default; +5 °C if layer adhesion looks weak |
| Outer wall speed | 40–50 mm/s on powder-contact parts |
| Overhangs | Enable “slow down for overhangs” |
| Cooling | Moderate; avoid full-blast on PETG small features |
| Ironing | Optional on top flange / platform deck |

**Food-adjacent:** prefer more walls over dense infill for powder shells; wipe with damp cloth only for early tests.

---

## Part-by-part

### 1. `powder_hopper_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | **Preferred:** outlet / spigot on the bed (cone point-down). Interior becomes the clean Z-surface / short layers. **Alt:** flange-up or on side if support hell. |
| **Supports** | Outer flange underside and bottom flange if point-down; use tree or normal, **avoid supports inside the powder cavity** if possible. |
| **Walls** | 4 |
| **Infill** | 30–40 % gyroid |
| **Layer** | 0.16–0.20 mm |
| **Notes** | Slow outer walls. Light sand interior only if layer lines catch powder. Check M3 holes with a 3 mm bit / tap as needed. |

### 2. `auger_screw_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | **Vertical** — coupler on bed, tip up (axis = Z). Best flight roundness and strength. |
| **Supports** | Usually none for single-start; enable only if flights droop on your PETG profile. |
| **Walls** | 3–4 |
| **Infill** | **80–100 %** (stiffness; torque from NEMA17) |
| **Layer** | 0.16 mm preferred |
| **Notes** | Ream 5 mm shaft bore to slip fit. M3 set-screw hole may need a 2.5 mm tap drill then M3 tap. Test spin in barrel by hand before motor power. |

### 3. `auger_housing_v01`

| Item | Guidance |
|------|----------|
| **Orientation A** | Motor plate flat on bed (barrel vertical-ish): good plate flatness, worse barrel roundness. |
| **Orientation B** | Barrel on its side, outlet up or down: better bore roundness for some printers. Try A first. |
| **Supports** | Inlet flange underside, outlet nozzle bore if horizontal, vibe pocket roof. |
| **Walls** | 4 |
| **Infill** | 30–40 % |
| **Layer** | 0.20 mm OK; 0.16 if bore is rough |
| **Notes** | Critical: internal bore smoothness. Light sanding or a wooden dowel + paper. Confirm NEMA17 holes align with a spare motor. Spigot counterbore must accept hopper freely (0.4 mm design clearance). |

### 4. `test_stand_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | Base on bed (as modelled). |
| **Supports** | Usually none if cradle opens upward. |
| **Walls** | 3 |
| **Infill** | 20–25 % |
| **Layer** | 0.20 mm |
| **Notes** | Fast print. Optional rubber feet in bottom recesses. |

### 5. `scale_platform_v01`

| Item | Guidance |
|------|----------|
| **Orientation** | Top deck up (cup recess on top) for smooth recess surface. |
| **Supports** | None typical. |
| **Walls** | 4 |
| **Infill** | 40 % |
| **Layer** | 0.16–0.20 mm |
| **Notes** | **Measure your load cell hole spacing** before printing; edit `LOADCELL_HOLE_SPACE` / `hole_space` if ≠ 15 mm. M4 clearance 4.2 mm. Optional fixed base: set `render_fixed_base = true` in the `.scad` and export separately. |

---

## Assembly order (dry fit)

1. Mount NEMA17 to housing plate (M3×8–10).  
2. Slide auger in from motor end; secure set-screw on shaft flat.  
3. Seat hopper spigot into housing inlet; install 4× M3.  
4. Press coin vibe motor into pocket; route wires in channel.  
5. Drop assembly into test stand cradles.  
6. Bolt scale platform to live end of load cell; place cup in recess under nozzle.  

Check free rotation of auger with power off. No grind, no scrape.

---

## First-print risk list

| Risk | Mitigation |
|------|------------|
| Hopper bridging in real powder | Add vibration duty cycle; consider steeper angle or polished liner in v02 |
| Auger packs hard powders | Reduce pitch or OD slightly; short reverse pulse in firmware |
| Barrel ovality | Ream; or print barrel axis vertical and accept supports |
| Load cell hole mismatch | Measure cell; regenerate platform only |
| PETG stringing in flights | Dry filament; temp tower; wipe auger before install |

---

## Export reminder

```bash
cd 3d_models && ./scripts/export_stls.sh
```

See [README.md](README.md) if `openscad` is missing.
