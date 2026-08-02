# Phase 1 Design Handoff – Single Powder Module

**For Grok Build / CAD generation / Bambu Studio**  
**Date**: 2026-07-26 (doc links updated 2026-08-02)  
**Status**: Ready for first CAD iteration and printable STLs

This document is a complete handoff. It contains every constraint, decision, dimension target, material preference, interface requirement, and success criterion needed to design and generate the first printable powder module so it can be opened directly in Bambu Studio, sliced, and tested.

**Related docs (do not override geometry locks below):**

| Doc | Role |
|-----|------|
| [PROJECT_PLAN.md](PROJECT_PLAN.md) | Phase exit criteria and schedule |
| [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) | Control loop, water, faults |
| [ASSEMBLY_GUIDE.md](ASSEMBLY_GUIDE.md) | Bench assembly steps |
| [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md) | ±0.1 g campaigns |
| [SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md) | Food-path cleaning |
| [SOFTWARE_ARCHITECTURE.md](SOFTWARE_ARCHITECTURE.md) | Software layers (no code here) |

---

## 1. Project Context (Do Not Re-decide These)

- Existing Raspberry Pi + Bambu Lab 3D printer
- Hybrid: buy electronics, 3D-print *all* mechanical parts
- Risk-first: **only** the single powder module right now
- Accuracy method: closed-loop load cell under collection cup + final verification
- WiFi remote later; not needed for Phase 1
- Goal of Phase 1: prove reliable flow + ±0.1 g accuracy with real powders before any multi-module frame

Success criteria for this module:

- Multiple common supplement powders (creatine monohydrate, magnesium citrate/glycinate, protein blends, vitamin C, etc.) flow without permanent bridging or ratholing
- Repeated dispenses of 1–10 g targets land within ±0.1 g (after vibration settle)
- Easy to empty, wipe clean, and refill
- Parts print without supports where possible or with easily removable ones
- Module can sit on a bench next to a load-cell platform for testing

Formal pass/fail matrices: [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md).

---

## 2. Core Architecture of the Module

```
[ Hopper (conical, steep) ]
          |
          v
[ Auger inlet / throat ]
          |
   [ Auger barrel + screw ]  <-- NEMA17 on rear, vibration motor on side
          |
          v
[ Outlet nozzle ]  --> drops into collection cup sitting on HX711 5 kg load cell
```

No intermediate chute yet. Keep the drop short and direct for Phase 1 accuracy testing.

System-level powder + water + mix context: [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) and [diagrams/system_overview.mmd](diagrams/system_overview.mmd).

---

## 3. Key Design Decisions (Locked for v0.1)

| Decision | Choice | Reason |
|----------|--------|--------|
| Hopper wall angle | **65° from horizontal** (25° from vertical) | Strong mass-flow tendency for most free-flowing and moderately cohesive supplement powders + vibration will handle the rest. Steeper than many commercial hoppers but still printable and capacity-friendly. |
| Hopper shape | Conical (circular) preferred over pyramidal | Smoother flow, fewer corners for powder to stick, easier to clean, better for Bambu surface finish when printed upright or at angle. |
| Outlet diameter | 20–22 mm | Large enough to prevent bridging for typical particle sizes, small enough for controlled auger feed. |
| Auger type | 3D-printed single-start Archimedes screw | Full control over pitch and clearance. Can be iterated quickly. |
| Auger diameter | ~16–18 mm OD | Matches common small feeder practice; fits in a compact barrel. |
| Clearance (auger to barrel) | 0.6–0.9 mm radial | Enough for free rotation and powder particles, not so large that accuracy suffers. |
| Motor | NEMA17 (42×42 mm face, 31 mm hole spacing, 5 mm shaft) | Already in BOM. Direct mount or short flexible coupling. |
| Vibration | Coin/pancake motor (typically Ø10–12 mm × 3 mm) | Mounted on hopper wall or barrel. Low mass, high frequency. |
| Material | PETG (preferred) or smooth PLA | Food-contact friendly, chemical resistant enough for supplements, good layer adhesion, easy to clean. Avoid ABS for first prototypes (fumes + more warping). |
| Collection | Separate platform for load cell + removable cup | Not part of the hopper module itself for Phase 1. |

---

## 4. Target Dimensions (v0.1 – use these as starting point)

> **Geometry lock:** Do not change the core targets in this section (65° hopper, 90 mm top ID, 22 mm outlet, auger/barrel ranges) without an explicit design revision note and new version suffix (`_v02`, etc.).

### 4.1 Hopper

- Top inner diameter: **90 mm** (easy pour from most tubs/scoops)
- Bottom inner diameter (outlet): **22 mm**
- Cone wall angle: **65° from horizontal**
- Calculated cone height: ≈ 73 mm
- Add a short cylindrical top section: **40 mm** tall for extra capacity and a flat mounting flange
- Wall thickness: **2.0–2.4 mm** (strong enough, still flexible slightly for vibration transmission)
- Top flange: 6–8 mm wide flat ring with 4× M3 holes on ~100 mm bolt circle (for lid or future lid with desiccant)
- Bottom interface: short cylindrical or square flange / registration features that mate cleanly with the auger housing inlet
- Internal surface: as smooth as possible (print orientation priority)

Approximate volume: ~250–320 ml → roughly 150–250 g of typical creatine/protein depending on density and packing.

### 4.2 Auger Housing / Barrel

- Inner diameter: **17.5–18.5 mm** (to give 0.6–0.9 mm clearance around 16–17 mm OD auger)
- Length of active barrel: **60–80 mm**
- Inlet: matched to hopper outlet (22 mm) with a short vertical or slightly angled throat
- Outlet: simple downward nozzle, 15–18 mm ID, 10–15 mm long, positioned so powder falls cleanly into the cup
- Motor end: NEMA17 mounting face with 31 mm hole pattern + 22 mm pilot recess if possible
- Provision for shaft seal or simple bushing (printed or later add PTFE)

### 4.3 Auger Screw

- Outer diameter: **16.5–17.2 mm**
- Core / root diameter: **8–9 mm**
- Pitch: **10–12 mm** (good for powders; not too aggressive)
- Helix angle roughly 20–28°
- Length: match active barrel + a little over-travel into the inlet
- Drive end: 5 mm hex or D-shaft interface, or printed coupling that accepts NEMA17 5 mm shaft with set-screw flats
- Leading edge of flights slightly radiused or tapered to reduce packing

### 4.4 Vibration Motor Mount

- Pocket or clip sized for common Ø10–12 × 2.5–3.5 mm coin vibration motor
- Location: mid-height on the hopper cone or on the side of the barrel near the inlet
- Oriented so the vibration vector helps break arches toward the outlet
- Wire exit channel so the motor can be replaced without disassembling the whole module

### 4.5 Mounting / Footprint

- Overall height of assembled module (hopper + barrel): aim < 220 mm so it sits comfortably on a bench
- Base of the barrel or a simple printed stand that keeps the outlet **~40–60 mm** above the table so a cup + load cell can slide underneath
- Later: add mounting holes or T-slots for the multi-module frame (Phase 2)

---

## 5. Print Orientation & Bambu Studio Guidance

**Hopper**  

- Preferred: print cone **point-down** (outlet on the bed) if the slicer can handle the overhang with supports only on the outside. This gives the best internal surface finish (the critical sliding surface is against the bed or has clean layers).  
- Alternative: print on its side if supports become too hard to remove.  
- Layer height: 0.16–0.20 mm for good strength and surface.  
- Walls: 3–4 perimeters.  
- Infill: 25–40 % gyroid or cubic.  
- Material: PETG. Use Bambu’s PETG profile as base, then slow outer walls to ~40–50 mm/s for smoother finish.

**Auger**  

- Print vertically (axis along Z) for best flight strength and circularity.  
- Supports only if the flights need them; many single-start screws print cleanly with bridging.  
- 100 % infill or high density for stiffness.  
- Consider printing two pitches / diameters and testing which feeds more consistently.

**Barrel / Housing**  

- Print with the motor face on the bed or vertical depending on features.  
- Critical: the internal bore should be as round and smooth as possible. Post-process with light sanding or a reamer if needed after first prints.

General Bambu notes:

- Use textured PEI or smooth plate depending on adhesion needs.
- Enable “slow down for overhangs”.
- For food-contact parts, prefer higher wall counts and consider a light food-safe coating later if desired (not required for prototype). Wash before first edible use — [SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md).

---

## 6. Interfaces That Must Be Defined in CAD

1. Hopper bottom ↔ Auger housing inlet (snap, screw, or bayonet preferred for easy cleaning)
2. Auger shaft ↔ NEMA17 shaft (set-screw coupling printed or commercial)
3. Vibration motor retention (clip that doesn’t rattle loose under vibration)
4. Optional top lid with living hinge or separate print
5. Wire routing channels so nothing hangs loosely

---

## 7. What to Generate First (Priority Order for Grok Build)

1. **powder_hopper_v01.stl** – the conical hopper with top flange and bottom interface
2. **auger_housing_v01.stl** – barrel + motor mount + outlet nozzle + vibration pocket
3. **auger_screw_v01.stl** – the helical screw (generate 2–3 pitch variants if easy)
4. Simple **test_stand.stl** or feet so the outlet is at a useful height above the load cell platform
5. Optional: collection_cup_holder that bolts to a standard 5 kg bar load cell (12.7×80 mm style)

After these exist, the user can open the whole set in Bambu Studio, arrange, slice, and print the first physical prototype.

---

## 8. Testing Plan Once Printed (for reference)

1. Dry-fit all parts + motor — [ASSEMBLY_GUIDE.md](ASSEMBLY_GUIDE.md)
2. Calibrate HX711 with known weights — [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md) §1
3. Fill hopper with creatine or similar, run open-loop steps while watching weight increase
4. Implement simple closed-loop: run auger + vibrate in short bursts until target weight reached, then settle and verify — [diagrams/dispense_sequence.mmd](diagrams/dispense_sequence.mmd)
5. Log consistency over 20–50 dispenses of 3 g and 5 g targets
6. Note any residual powder, bridging, or accuracy drift → feed back into CAD revisions (`_v02` only if geometry must change)

---

## 9. Explicit Non-Goals for This Handoff

- Do **not** design the full multi-module frame yet
- Do **not** design the pill module yet
- Do **not** spend time on the touchscreen UI or WiFi
- Do **not** over-optimize aesthetics; function and cleanability first
- Keep part count low so the first print run is fast
- Do **not** change locked core dimensions in §3–§4 without versioning

---

## 10. Next Actions After This Document

1. Generate the STLs listed in section 7 (parametric preferred so dimensions can be tweaked within lock ranges)
2. Commit them to `3d_models/` with clear versioning (`_v01`)
3. Update `3d_models/README.md` with print notes and recommended Bambu settings
4. User prints, assembles per [ASSEMBLY_GUIDE.md](ASSEMBLY_GUIDE.md), tests with real powder + load cell per [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md), reports results
5. Iterate geometry based on real flow behavior only after control tuning is exhausted (project plan decision D4)

This handoff is intentionally complete so any subsequent design session (or human CAD work) can start printing parts within one focused session.

Let’s make the first powder module actually work.
