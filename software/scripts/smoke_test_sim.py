#!/usr/bin/env python3
"""End-to-end smoke test in simulation mode (no hardware).

Run::

    python scripts/smoke_test_sim.py
"""

from __future__ import annotations

import os
import sys
import tempfile
from pathlib import Path

_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(_ROOT / "src"))

os.environ["DISPENSER_SIM"] = "1"


def main() -> int:
    from dispenser.config import load_config
    from dispenser.main import DispenserRuntime

    with tempfile.TemporaryDirectory() as tmp:
        cfg = load_config()
        cfg["hardware"]["mode"] = "sim"
        cfg["database"]["path"] = str(Path(tmp) / "smoke.db")
        # Speed up mix delay for smoke
        cfg.setdefault("dosing", {}).setdefault("cycle", {})["mix_delay_seconds"] = 0.0
        cfg["dosing"]["powder"]["final_settle_seconds"] = 0.05
        cfg["dosing"]["powder"]["settle_seconds"] = 0.01
        cfg["dosing"]["powder"]["burst_seconds"] = 0.08
        cfg["dosing"]["powder"]["timeout_seconds"] = 30.0

        rt = DispenserRuntime(config=cfg, seed=True)
        try:
            print("mode:", rt.mode)
            assert rt.mode == "sim"

            powder = rt.cycle.dose_powder(3.0, ingredient="creatine")
            print("powder:", powder.to_dict())
            assert powder.success, powder.message
            assert abs(powder.error_g) <= 0.15

            water = rt.cycle.dose_water(50.0)
            print("water:", water.to_dict())
            assert water.success, water.message

            recipe = rt.db.get_recipe("creatine_water")
            assert recipe is not None
            # Smaller water for speed in smoke if we re-seed — use existing
            cycle = rt.cycle.run_recipe(recipe)
            print("cycle:", cycle.to_dict())
            assert cycle.success, cycle.message

            logs = rt.db.list_logs(limit=5)
            assert len(logs) >= 1
            print("smoke_test_sim: OK")
            return 0
        finally:
            rt.close()


if __name__ == "__main__":
    raise SystemExit(main())
