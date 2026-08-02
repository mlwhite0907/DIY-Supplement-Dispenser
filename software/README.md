# Software – DIY Supplement Dispenser (Phase 1)

Python 3.11+ control stack for a single powder station + water + closed-loop load cell.

- **Raspberry Pi OS**: real GPIO (TMC/A4988 stepper, vibration, pump, sensors) + HX711 scale  
- **Mac / desktop**: full **simulation mode** (no RPi.GPIO) for development and CI

Package version: **0.2.0**

## Layout

```
software/
  config/default.yaml          # GPIO map + dosing parameters (source of truth)
  config/local.yaml            # gitignored; calibration factors (auto-merged)
  src/dispenser/
    default_config.yaml        # packaged fallback when tree config is missing
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
| GET | `/health` | Status, version, hardware mode (no auth) |
| GET | `/recipes` | List recipes |
| POST | `/recipes` | Create/update recipe (auth if token set) |
| POST | `/dispense` | `{"recipe": "creatine_water"}` (auth if token set; **409** if busy) |
| GET | `/inventory` | Hopper / tank levels |
| GET | `/logs` | Recent dispense logs |

## API security

- **Default bind host is `127.0.0.1`** (localhost only). Override with `api.host` in config or `dispenser serve --host 0.0.0.0` if you intentionally expose the LAN.
- **Optional API token** for mutating routes (`POST /dispense`, `POST /recipes`):
  - Config: `api.token: "your-secret"` in YAML, or
  - Env: `DISPENSER_API_TOKEN=your-secret`
  - Empty token = auth disabled (convenient for local sim).
  - Send either header:
    - `X-API-Token: your-secret`
    - `Authorization: Bearer your-secret`
- `GET /health` and other read routes stay open when a token is configured.
- On process shutdown, the FastAPI lifespan calls `runtime.close()` to release hardware.

Example:

```bash
export DISPENSER_API_TOKEN=dev-secret
python -m dispenser serve --port 8000
curl -H "X-API-Token: dev-secret" -X POST http://127.0.0.1:8000/dispense \
  -H "Content-Type: application/json" \
  -d '{"recipe":"creatine_water"}'
```

## Configuration

Default file: [`config/default.yaml`](config/default.yaml).

Load order:

1. Bundled / tree `default.yaml` (see packaging note below)
2. `config/local.yaml` if present (gitignored calibration overrides)
3. Explicit `--config` / `DISPENSER_CONFIG` user file

| Env | Effect |
|-----|--------|
| `DISPENSER_SIM=1` | Force simulation backends |
| `DISPENSER_SIM=0` | Prefer config `hardware.mode` (use `pi` on real hardware) |
| `DISPENSER_CONFIG=/path/to.yaml` | User config path (merged over defaults + local) |
| `DISPENSER_API_TOKEN=…` | API token for mutating routes |

### Packaging / default config resolution

`default_config_path()` searches:

1. `DISPENSER_CONFIG` if that path exists
2. `software/config/default.yaml` relative to package parents (editable checkout)
3. Packaged `dispenser/default_config.yaml` (installed wheel / sdist fallback)

Keep editing `software/config/default.yaml` as the source of truth; the copy under `src/dispenser/default_config.yaml` is the install-time fallback (keep them in sync when changing API/host defaults).

### `config/local.yaml`

After a successful `dispenser calibrate` (scale and/or pump), factors are written to:

- the path given with `--config`, **or**
- `config/local.yaml` (created if needed)

That file is **gitignored**. `load_config()` merges it after `default.yaml` so calibrated `hardware.scale.scale_factor` and `hardware.pump.ml_per_second` survive restarts without dirtying the shared default.

### Sim vs Pi

| Mode | How | Behaviour |
|------|-----|-----------|
| **sim** | `hardware.mode: sim` or `DISPENSER_SIM=1` (default on Mac) | In-memory scale/stepper/pump; no GPIO |
| **pi** | `hardware.mode: pi` and `DISPENSER_SIM=0` | Real HX711, TMC/A4988, pump, sensors |

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

### Water dosing honesty (open-loop)

Phase 1 water is **open-loop timed**: run time = `target_ml / ml_per_second`. There is no closed-loop volume verification from a flow meter yet (a flow pin exists in config for future use). Accuracy depends entirely on a good pump calibration (`--measured-ml`). Sim mode can estimate without a measurement; on Pi, `calibrate --pump-seconds` **requires** `--measured-ml`.

### E-stop / safety

- **E-stop GPIO** (`hardware.sensors.estop_pin`, default BCM 25): when pressed, dosing aborts, motors/pump stop via `runtime.all_stop()`, and cycle message is `"estop"`. Sim exposes an `estop` digital sensor. Still **not** a certified safety system — use a hard-wired kill path for real machines.
- **Cup present** interlock: when `dosing.cycle.require_cup: true` and a cup sensor is wired, dispense aborts if no cup.
- **Tank level** sensor: water dose fails if level reads empty.
- Concurrent dispenses are serialized: second `POST /dispense` returns **409 Conflict** while a cycle holds the lock.
- Always supervise the machine; treat software interlocks as best-effort, not certified safety.

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

### HX711 / pump calibration

```bash
python -m dispenser calibrate --tare
# place known mass, then:
python -m dispenser calibrate --known-grams 100 --no-tare
# pump: run N seconds, measure volume in a graduated cup:
python -m dispenser calibrate --pump-seconds 2 --measured-ml 50
# factors are written to config/local.yaml (or --config path)
```

Use `--no-persist` to skip writing. On Pi, omitting `--measured-ml` for pump cal is refused.

## CLI reference

```text
python -m dispenser calibrate [--known-grams N] [--pump-seconds S] [--measured-ml M]
                              [--persist/--no-persist]
python -m dispenser dose-powder --grams 3
python -m dispenser dose-water --ml 200
python -m dispenser run-recipe creatine_water
python -m dispenser serve [--host 127.0.0.1] [--port 8000]
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
