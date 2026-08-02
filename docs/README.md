# Documentation index

Start here if you are new to the project.

| Doc | Purpose |
|-----|---------|
| [PROJECT_PLAN.md](PROJECT_PLAN.md) | Phases 1–4, exit criteria, schedule |
| [BOM.md](BOM.md) | Quantities, cost ranges, print vs buy |
| [BOM_AMAZON.md](BOM_AMAZON.md) | Amazon search keywords, example ASINs, cart strategy |
| [SHOPPING_CHECKLIST.md](SHOPPING_CHECKLIST.md) | Printable order checklist |
| [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) | Blocks, open-loop water, powder loop, failure modes |
| [SOFTWARE_ARCHITECTURE.md](SOFTWARE_ARCHITECTURE.md) | Layers, real modules (`PowderDoser`, `WaterDoser`, `DispenseCycle`) |
| [ASSEMBLY_GUIDE.md](ASSEMBLY_GUIDE.md) | Bench build through first full drink (BCM pin map, v0.2 auger) |
| [TESTING_PROTOCOL.md](TESTING_PROTOCOL.md) | Calibration and acceptance tests (±0.1 g goal; timed water) |
| [SAFETY_AND_HYGIENE.md](SAFETY_AND_HYGIENE.md) | Food-contact, cleaning, disclaimers |
| [PHASE1_DESIGN_HANDOFF.md](PHASE1_DESIGN_HANDOFF.md) | Locked CAD dimensions (~450+ ml hopper, v0.2 stack-up) |
| [images/README.md](images/README.md) | Assembly photos TBD |

## Diagrams (Mermaid sources)

| File | Content |
|------|---------|
| [diagrams/system_overview.mmd](diagrams/system_overview.mmd) | High-level system blocks |
| [diagrams/dispense_sequence.mmd](diagrams/dispense_sequence.mmd) | Dispense sequence |
| [diagrams/phase_roadmap.mmd](diagrams/phase_roadmap.mmd) | Phase roadmap |
| [diagrams/wiring_phase1.mmd](diagrams/wiring_phase1.mmd) | Phase 1 wiring overview |
| [diagrams/power_tree.mmd](diagrams/power_tree.mmd) | Power distribution tree |

Paste `.mmd` contents into [mermaid.live](https://mermaid.live) or rely on GitHub’s native Mermaid rendering in the markdown docs that embed the same diagrams.

## Hardware docs

See [`../hardware/`](../hardware/) for pinout, wiring, schematics, and power budget.

## Software docs

See [`../software/README.md`](../software/README.md).
