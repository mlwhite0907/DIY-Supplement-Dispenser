# DIY Supplement Dispenser

Custom Raspberry Pi-powered multi-supplement dispenser for powders **and** pills.

**Goal**: A reliable, accurate, cabinet-friendly machine that automatically dispenses the exact daily amounts of your powdered supplements and pills.

## Key Features
- Closed-loop powder dispensing (load cell + auger)
- Pill counting with confirmation
- Vibration anti-clog system for reliable powder flow
- Modular 3D-printable hoppers and mechanisms
- Central collection cup with final weight verification
- Touchscreen UI + WiFi remote control from phone
- Inventory tracking and low-stock alerts

## Hybrid Approach
- **Buy** the proven electronics (Pi, screen, motors, load cells, drivers)
- **3D print** all the custom mechanical parts (hoppers, frames, augers, mounts)

This keeps cost reasonable while giving us full control and reliability.

## Repository Structure
```
├── docs/                  # Plans, BOM, guides
├── hardware/              # Mechanical design notes & future STLs
├── software/              # Python code, architecture
├── 3d_models/             # STL / 3MF files (coming soon)
└── README.md
```

## Current Status
- Architecture defined
- Parts list (BOM) ready
- Project plan with risk-first phases written
- Ready to start Phase 1 prototype

## Quick Start
1. Read [docs/PROJECT_PLAN.md](docs/PROJECT_PLAN.md) — this is the roadmap
2. Check [docs/BOM.md](docs/BOM.md) for what to order
3. Clone the repo and follow Phase 1 instructions

## License
MIT — see [LICENSE](LICENSE)

Built for reliability. Let’s make this work.
