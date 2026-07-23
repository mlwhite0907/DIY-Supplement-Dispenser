# Project Plan – DIY Supplement Dispenser

## Guiding Principle
We will only scale up after we prove the hard parts work in the real world with actual powders.

Powder flow, accuracy, and reliability are the highest risks. Everything else is easier once those are solved.

## Recommended Order of Work (What Will For Sure Work)

### Phase 1 – Single Powder Module Prototype (Start Here)
**Goal**: Prove we can reliably and accurately dispense one powder to within ±0.1 g.

What we build:
- One 3D-printed conical hopper with steep walls
- Auger driven by NEMA17 stepper
- Vibration motor for anti-clog
- HX711 load cell under a collection cup
- Simple test code on the Pi that dispenses to a target weight

Success criteria:
- Multiple different powders flow without jamming
- Repeated dispenses hit the target weight consistently
- Easy to clean and reload

This phase is small, cheap, and gives us high confidence before we invest in the full cabinet system.

### Phase 2 – Pill Module + Multi-Module Frame
- Design and print one reliable pill dropper (rotary disk or flapper + optical sensor)
- Design the main frame that holds multiple modules
- Test simultaneous or sequential dispensing into one cup

### Phase 3 – Full System Integration
- Add remaining modules
- Cabinet-friendly enclosure / mounts
- Central scale verification
- Power distribution and wiring

### Phase 4 – Software & User Experience
- Touchscreen UI
- Recipe / schedule system
- WiFi web interface + phone control
- Inventory tracking and alerts

### Phase 5 – Polish & Reliability
- Calibration routines
- Jam detection & recovery
- Empty detection
- Long-term testing

## Why This Order Works
Starting with a single powder module lets us validate the hardest mechanical and control problems first. Once that works, adding more modules and software becomes much lower risk.

## Next Immediate Action
Order the Phase 1 parts (see BOM) and start designing the first hopper + auger housing in CAD.
