# Development plan

Historical five-per-tier plan. Current count is six per tier, twelve total. Follow [HANDOFF.md](HANDOFF.md) and [prototype-v01](prototype-v01/README.md) for current geometry and unresolved work.

## Experience and architecture

**Countertop:** Rotate either tier, read the label/window, release a cartridge, hold it above a cup on a scale, unlock its dial and turn until the scale reaches the desired amount. Close the dial, replace the cartridge, and confirm its latch. The base stays on the counter; the cup is separate from the rotating assembly so hand forces do not disturb the reading.

**Separate tier:** Remove the top tier only after its five cartridges are latched. Its own bearing and hub remain assembled. Fit it to either an independently stable countertop base or a separately engineered under-cabinet mount. The lower tier remains complete on its own base. The connector must prevent accidental separation when carrying or turning. Exact latch geometry and load path are to be designed, not assumed.

## Candidate cartridge mechanics

| Candidate | Advantage | Main uncertainty | First experiment |
|---|---|---|---|
| Captive removable rotor with measured pocket | Familiar click and compact front dial | A fine or cohesive powder can bridge, smear, leak, or vary with packing; pocket size cannot serve every dose | Transparent bench housing with interchangeable pocket volumes, positive closed position and full cleaning access |
| Short manually driven auger | Smaller increments and continuous feed | Torque, bridging, residual flow and cleanable shaft seal | One openable barrel and interchangeable screws; measure grams per quarter turn |

Start with the rotor if a large enough opening and powder flow can be demonstrated. Compare against the auger before committing to ten copies. Both are **volumetric**, so a scale verifies mass. Do not claim one click equals a precise mass.

## Interfaces to design

1. **Cartridge to tier:** guided radial slide or lift-out cradle, positive retention with visible engaged indicator, glove-friendly release, and clearance for one cartridge without disturbing its neighbors. Confirm retention with full simulated weight in all orientations intended for use. The latch and load path are not designed yet.
2. **Cartridge closure:** a positive closed detent independent of the carousel latch, with a sealed or capped outlet during transport. Prevent accidental rotation during handling; provide disassembly without trapped powder or loose parts falling into the cup.
3. **Tier bearing and rotation:** bearing retained on both sides and sized for fully loaded, unevenly distributed cartridges; deliberate detents at five positions should resist casual drift without requiring excessive turning force. No bearing is selected.
4. **Tier-to-tier joint:** keyed alignment, positive mechanical lock and independent tier structure. Specify and test pull-out, tipping, cyclic wear and unlock procedure before use; no actual coupling dimensions are defined yet.
5. **Base:** determine worst-case center of gravity with one tier empty and cartridges removed asymmetrically. Test push, rotation, accidental bumps and full loading. Add a counterweight or footprint only after calculations and physical test.
6. **Under-cabinet mount:** separate engineered mounting plate with real fasteners into a suitable structural substrate, retention lock and secondary retention. Determine cabinet capacity and safe working load with appropriate margins from actual test loads. Do not hang the concept or trust adhesive-only support.

## Test in stages

1. Measure actual counter and cabinet dimensions, powders, desired amounts, and refill interval. Weigh representative powder per known volume, loosely and after settling. Check realistic total filled weight.
2. Make one cartridge flow rig, using non-consumable test material initially. Trial representative powders at full, half and near-empty levels; repeat after vibration/settling and humidity exposure. Record blockages, leakage, rotor torque and recovery. A calibrated external scale records each dose; measure repeatability and overrun after stopping.
3. Print a small latch and retention coupon. Cycle it, check accidental release and test its grip when the cartridge is full. Refine clearances for the actual printer and material.
4. Assemble one five-station ring. Test bearing, cartridge removal access, neighboring clearance, turning effort and tipping. Verify all cartridges remain latched.
5. Prototype the keyed two-tier connection and countertop base. Test full and uneven loads, carrying, accidental bumps and repeated locking. Check the complete height against the cabinet and access to top-tier cartridges.
6. Engineer and test an independent overhead mount only after the loaded tier and actual cabinet structure are known. Verify the entire support chain before placing it overhead.
7. Establish a suitable food-contact construction and cleaning method, then repeat hygiene and wear checks. Physical print quality, assembly and real-powder performance are required before claiming readiness.

## Open choices

- Which ten ingredients, target dose ranges, refill volumes and allergen separations?
- Can one cartridge size meet protein and small-dose supplements, or should the five stations accept different depths and capacities?
- Preferred cup/scale and whether the dial should be used in hand or in a future fixed docking station?
- Available counter width, cabinet clearance, mounting substrate and maximum acceptable height?
- Window and color preferences; whether the base should store the scale or leave it separate?

## Status

Concept and approximate visual layout only. No engineered fasteners, working latches, powder-path geometry, food-contact certification, structural rating, finished electronics, physical print or dosing validation exist here. The repository's existing Phase 1 files and Claude's active branch retain their own design authority.
