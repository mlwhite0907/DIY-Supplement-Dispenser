# Software – DIY Supplement Dispenser (Phase 1)

Python 3.11+ control stack for a single powder station + water + closed-loop load cell.

- **Raspberry Pi OS**: real GPIO (TMC/A4988 stepper, vibration, pump, sensors) + HX711 scale  
- **Mac / desktop**: full **simulation mode** (no RPi.GPIO) for development and CI

## Layout

```
software/
  config/default.yaml          # GPIO map + dosing parameters
  src/dispenser/
    models.py                  # Recipe, Ingredient, DispenseResult
    db.py                      # SQLite recipes / inventory / logs
    hardware/                  # abstract + sim + Pi drivers
    control/                   # closed-loop powder, water, cycle
    api/                       # FastAPI REST
    cli.py                     # typer CLI
  tests/                       # pytest (sim only)
  scripts/                     # calibrate_scale, smoke_test_sim
```

## Quick start (simulation – Mac)

```bash
cd software
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# Force sim (also default in config/default.yaml)
export DISPENSER_SIM=1

pytest -q
python scripts/smoke_test_sim.py

# CLI
python -m dispenser list-recipes
python -m dispenser dose-powder --grams 3
python -m dispenser dose-water --ml 50
python -m dispenser run-recipe creatine_water
python -m dispenser serve --port 8000
```

Open API docs at `http://127.0.0.1:8000/docs`.

### REST endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Status, version, hardware mode |
| GET | `/recipes` | List recipes |
| POST | `/recipes` | Create/update recipe |
| POST | `/dispense` | `{"recipe": "creatine_water"}` |
| GET | `/inventory` | Hopper / tank levels |
| GET | `/logs` | Recent dispense logs |

## Configuration

Default file: [`config/default.yaml`](config/default.yaml).

| Env | Effect |
|-----|--------|
| `DISPENSER_SIM=1` | Force simulation backends |
| `DISPENSER_CONFIG=/path/to.yaml` | Override config path |

### GPIO map (BCM)

| Function | Pin |
|----------|-----|
| HX711 DT | 5 |
| HX711 SCK | 6 |
| Stepper STEP | 12 |
| Stepper DIR | 13 |
| Stepper EN | 16 |
| Vibration | 17 |
| Pump | 27 |
| Flow | 22 |
| Level | 23 |
| Cup present | 24 |

## Closed-loop powder dosing

1. Tare scale  
2. Short auger bursts + vibration assist  
3. Stop near target (`approach_band_g`)  
4. Settle + verify within `tolerance_g` (±0.1 g default)  
5. If weight stalls → reverse-auger jam clear, retry  

Water dosing uses timed pump run with `ml_per_second` calibration (sim uses the same path).

## Raspberry Pi install

```bash
sudo apt update
sudo apt install -y python3-venv python3-dev
cd software
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

# GPIO + HX711 (Pi only)
pip install RPi.GPIO
pip install hx711
# alternatives: lgpio, pi-hx711

# Real hardware mode
export DISPENSER_SIM=0
# set hardware.mode: pi in config (or omit sim env)
```

Real drivers live under `hardware/scale_hx711.py`, `stepper_tmc.py`, `vibration.py`, `pump.py`, `sensors.py`. They import `RPi.GPIO` / `hx711` lazily and raise a clear `ImportError` if missing — the package still installs and tests on a Mac.

### HX711 note

The wrapper tries the `hx711` package first, then a minimal bit-bang reader via `RPi.GPIO`. Calibrate with:

```bash
python -m dispenser calibrate --tare
# place known mass, then:
python -m dispenser calibrate --known-grams 100 --no-tare
# or:
python scripts/calibrate_scale.py --known-grams 100
```

Write the resulting `scale_factor` into `config/default.yaml` → `hardware.scale.scale_factor`.

## CLI reference

```text
python -m dispenser calibrate [--known-grams N] [--pump-seconds S] [--measured-ml M]
python -m dispenser dose-powder --grams 3
python -m dispenser dose-water --ml 200
python -m dispenser run-recipe creatine_water
python -m dispenser serve [--host 0.0.0.0] [--port 8000]
python -m dispenser list-recipes
```

## Tests

```bash
cd software
source .venv/bin/activate
export DISPENSER_SIM=1
pytest -q
```

All tests run without Pi hardware.

## License

MIT (see repository root `LICENSE`).
