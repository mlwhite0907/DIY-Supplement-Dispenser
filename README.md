# DIY Supplement Dispenser (Vending Style)

Smart home vending machine for supplements that makes complete drinks.

**What it does**  
Select any combination of up to 12 supplements on the touchscreen → machine automatically dispenses the correct powders + pills, adds water from a refillable tank, mixes a ready-to-drink beverage, and delivers it in a cup.

Looks and feels like a modern coffee / beverage machine.

## Key Features
- Touchscreen recipe selection (automatic module activation)
- Up to 12 modular stations (powders + pills)
- Closed-loop powder weighing for accuracy
- Refillable water tank + precise water dosing
- Mixing system for complete drinks
- Vibration anti-clog on powder hoppers
- Inventory tracking and alerts
- WiFi / remote control option

## Hybrid Build Approach
- Buy: electronics, pumps, motors, load cells, screen, water system parts
- 3D print: hoppers, frames, mixing chamber, mounts, tank adapters

## Repository Structure
```
├── docs/                  # Plans, BOM, design handoff
├── hardware/              # Mechanical notes
├── software/              # Pi code architecture
├── 3d_models/             # STL files (coming)
└── README.md
```

## Current Direction (Locked)
- Visual style matches the modern white/black beverage machine concept
- Refillable water tank (no hard plumbing required)
- Full drink output (water + powder mixed)
- Touchscreen chooses which of the 12 supplements to use

## Getting Started
1. Read [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md)
2. Check [docs/BOM.md](docs/BOM.md)
3. Start with Phase 1 (single powder + water + mix test)

MIT License — see LICENSE
