#!/usr/bin/env python3
"""Interactive scale calibration helper.

Usage (sim)::

    DISPENSER_SIM=1 python scripts/calibrate_scale.py --known-grams 100

On Pi: tare empty, place known mass, re-run with --known-grams.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

# Allow running without install when src is on path
_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_ROOT / "src"))


def main() -> int:
    parser = argparse.ArgumentParser(description="Calibrate HX711 / sim scale")
    parser.add_argument("--config", type=Path, default=None)
    parser.add_argument("--known-grams", type=float, default=None)
    parser.add_argument("--no-tare", action="store_true")
    parser.add_argument("--sim", action="store_true", help="Force DISPENSER_SIM=1")
    args = parser.parse_args()

    if args.sim:
        os.environ["DISPENSER_SIM"] = "1"

    from dispenser.main import DispenserRuntime

    rt = DispenserRuntime(config_path=args.config)
    try:
        print(f"mode={rt.mode}")
        if not args.no_tare:
            rt.calibration.tare_scale()
            print("tared")
        if args.known_grams is not None:
            result = rt.calibration.calibrate_scale_with_known_mass(args.known_grams)
            print(
                f"scale_factor={result.scale_factor:.6f} "
                f"raw_delta={result.raw_delta:.3f} — {result.message}"
            )
        else:
            readings = rt.calibration.read_scale_loop(seconds=2.0)
            print("readings_g:", [round(r, 3) for r in readings])
            print("Pass --known-grams after placing a reference weight.")
        return 0
    finally:
        rt.close()


if __name__ == "__main__":
    raise SystemExit(main())
