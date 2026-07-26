# 3D Models – Phase 1 Powder Module

**Status**: Design handoff complete. First parametric STLs generated and available for import into Bambu Studio.

## Design Handoff
See the full thinking and locked dimensions here:  
**[docs/PHASE1_DESIGN_HANDOFF.md](../docs/PHASE1_DESIGN_HANDOFF.md)**

That document contains every decision, exact target dimensions, print orientation recommendations, and success criteria so the design can be iterated cleanly.

## Current Printable Files (v0.1)

These are starting-point geometry generated from the handoff dimensions. They are intentionally simple so you can open them in Bambu Studio immediately, inspect, and refine.

| File | Description | Notes |
|------|-------------|-------|
| `powder_hopper_v01.stl` | Conical hopper, 65° walls, 90 mm top ID → 22 mm bottom ID, 40 mm cylindrical top section + flange | ~113 mm tall. Print point-down or on side. PETG recommended. |
| `auger_housing_v01.stl` | Basic barrel + NEMA17-ish mount plate (simplified) | Early placeholder. Needs proper inlet port, outlet nozzle, and vibration pocket in next iteration. |

## How to Use in Bambu Studio
1. Download the STLs (from this repo or the project artifacts).
2. Open Bambu Studio → New Project → Import the STLs.
3. Arrange on the build plate.
4. Recommended starting profile: **PETG** (or Bambu PETG HF if you have it).
5. For the hopper: 0.16–0.20 mm layer height, 3–4 walls, 30–40 % infill, slow outer walls (~40–50 mm/s) for smoother interior surface.
6. Orient the hopper so the critical inner cone surface gets the best finish possible.

## Next CAD Iterations Needed
- Proper mating features between hopper outlet and housing inlet (bayonet or screws preferred for cleaning)
- Real downward outlet nozzle that clears a collection cup
- Vibration motor pocket + wire channel
- Accurate NEMA17 mounting holes (31 mm spacing) + pilot
- Printed auger screw (multiple pitch variants)
- Simple test stand / feet so the outlet sits at the right height above the load cell

Once you print and test the hopper + a temporary auger (or even a commercial screw), we iterate the geometry based on real powder behavior.

## Print & Test Feedback Loop
After the first print:
- Does powder flow cleanly with light vibration?
- Any residual rings or dead zones?
- How easy is cleaning?

Bring that data back and we tighten the design.
