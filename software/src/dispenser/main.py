"""Application runtime wiring: config → hardware → control → API."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from dispenser.config import load_config, resolve_db_path
from dispenser.control.calibration import CalibrationService
from dispenser.control.dispense_cycle import DispenseCycle
from dispenser.control.powder_dose import PowderDoser
from dispenser.control.scale_service import ScaleService
from dispenser.control.water_dose import WaterDoser
from dispenser.db import Database
from dispenser.hardware import create_hardware


class DispenserRuntime:
    """Holds shared services for CLI and API.

    Args:
        config_path: Optional YAML config path.
        config: Optional pre-loaded config dict (overrides path).
        seed: If True, seed default recipes/inventory when empty.
    """

    def __init__(
        self,
        config_path: str | Path | None = None,
        config: dict[str, Any] | None = None,
        seed: bool = True,
    ) -> None:
        self.config: dict[str, Any] = config if config is not None else load_config(config_path)
        self.db = Database(resolve_db_path(self.config))
        if seed:
            self.db.seed_defaults()

        self.hardware = create_hardware(self.config)
        self.mode: str = str(self.hardware.get("mode", "sim"))

        scale_samples = int(self.config.get("hardware", {}).get("scale", {}).get("samples", 5))
        self.scale_service = ScaleService(self.hardware["scale"], samples=scale_samples)
        self.powder = PowderDoser(
            self.scale_service,
            self.hardware["stepper"],
            self.hardware["vibration"],
            config=self.config,
            estop_sensor=self.hardware.get("estop"),
            all_stop=self.all_stop,
        )
        self.water = WaterDoser(
            self.hardware["pump"],
            config=self.config,
            level_sensor=self.hardware.get("level"),
            estop_sensor=self.hardware.get("estop"),
            all_stop=self.all_stop,
        )
        self.cycle = DispenseCycle(
            powder=self.powder,
            water=self.water,
            db=self.db,
            config=self.config,
            cup_sensor=self.hardware.get("cup"),
            estop_sensor=self.hardware.get("estop"),
            all_stop=self.all_stop,
        )
        self.calibration = CalibrationService(
            scale=self.hardware["scale"],
            scale_service=self.scale_service,
            pump=self.hardware["pump"],
        )

    def all_stop(self) -> None:
        """Emergency stop: disable stepper, vibration off, pump stop."""
        hw = self.hardware
        for key, method in (
            ("stepper", "disable"),
            ("vibration", "off"),
            ("pump", "stop"),
        ):
            obj = hw.get(key)
            if obj is None:
                continue
            fn = getattr(obj, method, None)
            if fn is None:
                continue
            try:
                fn()
            except Exception:
                pass

    def close(self) -> None:
        """Release hardware resources."""
        for key in ("scale", "stepper", "vibration", "pump", "cup", "level", "flow", "estop"):
            obj = self.hardware.get(key)
            if obj is not None and hasattr(obj, "close"):
                try:
                    obj.close()
                except Exception:
                    pass


def build_runtime(
    config_path: str | Path | None = None,
    **kwargs: Any,
) -> DispenserRuntime:
    """Factory used by CLI and ``python -m dispenser``."""
    return DispenserRuntime(config_path=config_path, **kwargs)
