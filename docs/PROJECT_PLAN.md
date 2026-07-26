# Project Plan – Vending-Style Supplement Drink Machine

## Target
A self-contained unit that looks like a modern beverage machine.  
User selects supplements on the touchscreen → machine makes a complete mixed drink using powders + water from a refillable tank (and can also dispense pills).

Capacity: ~12 supplement stations.

## Core Requirements (Locked)
- Refillable water tank (no permanent water-line connection)
- Visual design similar to the latest concept render (white/black, tall touchscreen, dispensing area)
- Automatic selection of which modules to activate based on touchscreen choice
- Accurate powder dosing + water dosing + mixing

## Recommended Build Order (Risk-First)

### Phase 1 – Core Drink Capability (Start Here)
Prove one powder station + water + mixing works reliably.
- Single powder hopper + auger + vibration + load cell
- Refillable water tank + pump + flow control
- Simple mixing into a cup
- Basic touchscreen or serial control for testing

Success = consistent, tasty, accurately dosed drinks with real powder.

### Phase 2 – Multi-Module + Pills
- Expand to multiple powder stations
- Add pill dispensing modules
- Shared collection / mixing area
- Frame that matches the vending visual style

### Phase 3 – Full Vending Experience
- Complete 12-station layout
- Polished touchscreen UI with recipes
- Inventory, alerts, WiFi control
- Enclosure matching the concept look
- Hygiene / easy-clean design

### Phase 4 – Polish & Reliability
- Calibration, jam recovery, low-water detection
- Long-term testing

## Why This Order
Mixing water + powder accurately and cleanly is the new highest risk. We validate that first before building the full 12-station cabinet-style machine.
