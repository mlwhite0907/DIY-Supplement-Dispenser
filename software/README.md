# Software Architecture

## Stack
- Raspberry Pi OS
- Python 3
- HX711 library for the load cell
- RPi.GPIO or gpiozero + stepper libraries (or pigpio for better timing)
- Flask or FastAPI for the web UI / remote control
- SQLite for recipes, schedules, inventory, and logs
- Optional: Kivy or tkinter for local touchscreen UI

## Core Concepts
- **Recipe** = list of (supplement, amount or count)
- **Schedule** = when to run which recipe
- **Dispense Cycle**:
  1. Zero the scale
  2. For each powder: run auger while reading weight until target reached (with vibration assist)
  3. For each pill type: drop and confirm count
  4. Final total weight verification
  5. Log result and update inventory

## Reliability Features to Implement
- Timeout + reverse-auger on jam detection
- Low / empty detection
- Calibration mode
- Soft limits and safety interlocks (cup present, etc.)

Code will be added in this folder as we move into Phase 1 and beyond.
