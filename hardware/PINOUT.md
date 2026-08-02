# Phase 1 GPIO Pinout (BCM)

**Controller:** Raspberry Pi 5 preferred; Raspberry Pi 4 Model B fully compatible for this map.  
**Numbering:** **BCM** (Broadcom SoC GPIO numbers), not physical pin numbers and not WiringPi.  
**Header:** 40-pin classic header (same pinout Pi 4 / Pi 5 for these signals).

---

## 1. Suggested Phase 1 Assignment

| Function | BCM | Physical pin | Direction | Electrical | Notes |
|----------|-----|--------------|-----------|------------|-------|
| HX711 DT (DOUT) | **5** | 29 | IN | 3.3 V logic | HX711 data; pull-up often on module |
| HX711 SCK | **6** | 31 | OUT | 3.3 V | Keep short; avoid sharing with clocks |
| Stepper STEP | **12** | 32 | OUT | 3.3 V → TMC | Hardware PWM capable (PWM0) |
| Stepper DIR | **13** | 33 | OUT | 3.3 V → TMC | Hardware PWM capable (PWM1) |
| Stepper EN | **16** | 36 | OUT | 3.3 V → TMC | Usually **active-LOW** enable |
| Vibe MOSFET gate | **17** | 11 | OUT | 3.3 V | Low-side N-MOSFET; default **5 V** motor |
| Pump MOSFET gate | **27** | 13 | OUT | 3.3 V | Low-side N-MOSFET or relay IN |
| Flow sensor pulse | **22** | 15 | IN | 3.3 V safe / level shift if 5 V | Edge interrupt (rising) |
| Level float | **23** | 16 | IN | Pull-up; dry contact to GND | LOW = water OK or LOW = empty — define in SW |
| Cup present (IR) | **24** | 18 | IN | Module dependent | Debounce in software |
| E-stop (optional) | **25** | 22 | IN | Pull-up; NC switch to GND | LOW = halt all motion |
| Pi GND | GND | 6, 9, 14, 20, 25, 30, 34, 39 | — | Common with 12 V return | Star ground recommended |
| Pi 3.3 V | 3V3 | 1, 17 | OUT | **Logic only** | HX711 VCC if run at 3.3 V; TMC VIO |
| Pi 5 V | 5V | 2, 4 | OUT | Limited current | Optional sensor / vibe **only if budgeted** |

### Why this map

| Choice | Rationale |
|--------|-----------|
| STEP on GPIO12 | Hardware PWM for smoother step rates without bit-bang jitter |
| DIR on GPIO13 | Same PWM block pair; convenient if software ever uses dual PWM |
| EN on GPIO16 | Nearby on header; free of I2C/SPI |
| HX711 on 5/6 | Stable pair, not on SPI/I2C; common community default for scales |
| Actuators 17/27 | Clear of reserved buses; easy to remember |
| Sensors 22–25 | Contiguous block for interrupt/input config |
| Avoid 2,3 | I2C for future HAT / display / sensors |
| Avoid 7–11 | SPI0 free for future ADCs, displays, expanders |
| Avoid 14,15 | UART for console or future TMC2209 UART mode |

---

## 2. Full 40-Pin Header Reference (Phase 1 Usage)

Physical pin 1 is the end nearest the SD card / with the 3V3 square pad on most boards. Looking at the header with USB ports down / Ethernet away varies by case — always verify silk or a pin map photo for your Pi revision.

| Phys | BCM | Phase 1 use | Phys | BCM | Phase 1 use |
|------|-----|-------------|------|-----|-------------|
| 1 | 3V3 | Logic / HX711 (if 3.3 V) | 2 | 5V | Optional 5 V sensors / vibe supply |
| 3 | 2 (SDA1) | **RESERVED I2C** | 4 | 5V | Same 5 V rail |
| 5 | 3 (SCL1) | **RESERVED I2C** | 6 | GND | Common GND |
| 7 | 4 | Free | 8 | 14 (TXD) | **RESERVED UART** |
| 9 | GND | Common GND | 10 | 15 (RXD) | **RESERVED UART** |
| 11 | **17** | **Vibe MOSFET** | 12 | 18 | Free (PWM alt) |
| 13 | **27** | **Pump MOSFET** | 14 | GND | Common GND |
| 15 | **22** | **Flow sensor** | 16 | **23** | **Level float** |
| 17 | 3V3 | Logic | 18 | **24** | **Cup present** |
| 19 | 10 (MOSI) | **RESERVED SPI** | 20 | GND | Common GND |
| 21 | 9 (MISO) | **RESERVED SPI** | 22 | **25** | **E-stop (opt)** |
| 23 | 11 (SCLK) | **RESERVED SPI** | 24 | 8 (CE0) | **RESERVED SPI** |
| 25 | GND | Common GND | 26 | 7 (CE1) | **RESERVED SPI** |
| 27 | 0 (ID_SD) | **HAT EEPROM — leave** | 28 | 1 (ID_SC) | **HAT EEPROM — leave** |
| 29 | **5** | **HX711 DT** | 30 | GND | Common GND |
| 31 | **6** | **HX711 SCK** | 32 | **12** | **STEP** |
| 33 | **13** | **DIR** | 34 | GND | Common GND |
| 35 | 19 | Free | 36 | **16** | **EN** |
| 37 | 26 | Free (alt spare) | 38 | 20 | Free |
| 39 | GND | Common GND | 40 | 21 | Free |

**Free GPIOs for Phase 1 expansion:** 4, 18, 19, 20, 21, 26 (and 7–11 / 14–15 only if you intentionally consume SPI/UART).

---

## 3. Reserved Buses (HAT-Safe Policy)

| Bus | Pins (BCM) | Policy for Phase 1 |
|-----|------------|--------------------|
| I2C1 | 2, 3 | **Do not assign actuators.** Keep for OLED, RTC, temp, future multi-HX711 I2C ADCs |
| SPI0 | 7, 8, 9, 10, 11 | **Keep free** unless an SPI device is added deliberately |
| UART0 | 14, 15 | **Keep free** for serial console or later TMC2209 UART |
| HAT ID | 0, 1 | **Never repurpose** if any HAT may be stacked |
| Hardware PWM | 12, 13 (primary) | Assigned to STEP/DIR; do not steal for unrelated PWM without remapping STEP |

Common HAT conflicts avoided by this map:

- Official PoE / fan HATs often use I2C — free here.
- Many display HATs use SPI + a few DC/RST pins on 24/25 territory — we use 24/25 for sensors; if a specific SPI display is added later, remount cup/E-stop to free pins (18/26 recommended).

---

## 4. Electrical Levels Per Pin Class

| Class | Pins | Level rules |
|-------|------|-------------|
| Outputs to TMC2209 | 12, 13, 16 | 3.3 V CMOS into TMC **VIO = 3.3 V**. Do **not** set VIO to 5 V while driving from Pi. |
| Outputs to MOSFET gates | 17, 27 | 3.3 V is enough for logic-level MOSFETs (e.g. IRLZ44N, IRLZ34N, AO3400 on modules). Prefer modules labeled “3.3 V compatible”. |
| HX711 | 5, 6 | Module VCC = 3.3 V **or** 5 V. If VCC = 5 V, confirm DT is 3.3 V-safe (many modules are open-drain / have level compatibility; if DT peaks at 5 V, use a divider or run HX711 at 3.3 V). **Recommended: power HX711 from 3.3 V** for simplicity. |
| Flow sensor | 22 | Many YF-S201-style sensors are open-collector or 5 V pulse. Use voltage divider or level shifter to 3.3 V if HIGH exceeds ~3.3 V. |
| Float / E-stop | 23, 25 | Dry contact to GND with `GPIO.PUD_UP` (or external 10 kΩ to 3.3 V). |
| Cup IR | 24 | If module is 5 V only, level-shift OUT to 3.3 V. |

---

## 5. TMC2209 Control Pins (Logic Side)

Phase 1 uses **standalone STEP/DIR mode** (no UART required).

| TMC board label | Pi signal | Polarity / note |
|-----------------|-----------|-----------------|
| STEP | GPIO12 | Rising edge advances one microstep (config dependent) |
| DIR | GPIO13 | Level selects direction |
| EN / ENN | GPIO16 | **ENN active LOW** on most BigTreeTech / Fysetc style boards — drive LOW to enable motor current |
| VIO / VDD_IO | 3.3 V | Must match Pi GPIO |
| GND | Pi GND + PSU GND | Common |
| VM / MOT V+ | **12 V** only | **Never** from Pi |
| A1/A2/B1/B2 | NEMA17 coils | Motor power path |

MS1/MS2 microstep jumpers: set on the driver board (e.g. 1/8 or 1/16 for quiet Phase 1). UART pins (PDN/UART) left unconnected or pulled per board default.

---

## 6. Software Configuration Hints

```text
# Example constants (BCM) — software lives elsewhere; this is the hardware contract
HX711_DT   = 5
HX711_SCK  = 6
STEP       = 12
DIR        = 13
EN         = 16   # active low
VIBE       = 17
PUMP       = 27
FLOW       = 22
LEVEL      = 23
CUP        = 24
ESTOP      = 25   # optional, active low
```

**Default safe boot state (software must enforce):**

- EN = HIGH (motor disabled)
- VIBE = LOW (off)
- PUMP = LOW (off)
- STEP idle LOW

On E-stop assert (GPIO25 LOW): force EN high, vibe/pump low, stop step generation.

---

## 7. Optional Remap Notes

| If you need… | Suggestion |
|--------------|------------|
| Hardware PWM for pump soft-start | Move pump gate to GPIO18; free GPIO27 |
| Second powder station (Phase 2) | STEP2=GPIO19, DIR2=GPIO20, EN2=GPIO21, VIBE2=GPIO26 |
| TMC UART instead of STEP/DIR | Free 12/13/16 for other use; use GPIO14/15 carefully or USB-UART |
| SPI ADC for more load cells | Claim SPI0; keep this Phase 1 map for station 1 |

---

## 8. Quick Continuity Checklist

Before software bring-up:

1. Continuity: each BCM pin above → correct module pad (no solder bridges).
2. Confirm **no** continuity from VM (12 V) to any GPIO pin.
3. Confirm GND continuity: Pi pin 6 ↔ TMC GND ↔ MOSFET source returns ↔ PSU −.
4. Multimeter: TMC VIO ≈ 3.3 V, VM ≈ 12 V with motor disconnected first.

---

## See Also

- [WIRING.md](WIRING.md) — colors, connectors, harness lengths  
- [ELECTRICAL_SCHEMATIC.md](ELECTRICAL_SCHEMATIC.md) — full signal + power diagrams  
- [POWER_BUDGET.md](POWER_BUDGET.md) — current limits  
- [modules/powder_station.md](modules/powder_station.md) · [modules/scale_platform.md](modules/scale_platform.md) · [modules/water_system.md](modules/water_system.md)
