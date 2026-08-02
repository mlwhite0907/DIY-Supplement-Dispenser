"""Calibration helpers for scale factor and pump flow rate."""

from __future__ import annotations

import time
from dataclasses import dataclass
from typing import Any

from dispenser.control.scale_service import ScaleService
from dispenser.hardware.base import Pump, Scale


@dataclass
class ScaleCalibrationResult:
    """Result of a scale calibration step."""

    known_grams: float
    raw_delta: float
    scale_factor: float
    message: str


@dataclass
class PumpCalibrationResult:
    """Result of a pump flow calibration."""

    run_seconds: float
    measured_ml: float
    ml_per_second: float
    message: str


class CalibrationService:
    """Interactive / scripted calibration utilities.

    Args:
        scale: Optional scale backend (may be HX711Scale with calibrate()).
        scale_service: Optional scale service for averaged reads.
        pump: Optional pump backend.
    """

    def __init__(
        self,
        scale: Scale | None = None,
        scale_service: ScaleService | None = None,
        pump: Pump | None = None,
    ) -> None:
        self.scale = scale
        self.scale_service = scale_service or (ScaleService(scale) if scale else None)
        self.pump = pump

    def tare_scale(self) -> None:
        """Tare the scale (empty platform)."""
        if self.scale_service is None:
            raise RuntimeError("No scale configured")
        self.scale_service.tare()

    def calibrate_scale_with_known_mass(self, known_grams: float) -> ScaleCalibrationResult:
        """Compute scale_factor from a reference weight already on the platform.

        For HX711Scale, updates ``scale.scale_factor``. For sim, reports a
        synthetic factor based on current reading.
        """
        if self.scale is None or self.scale_service is None:
            raise RuntimeError("No scale configured")
        known_grams = float(known_grams)
        if known_grams <= 0:
            raise ValueError("known_grams must be > 0")

        if hasattr(self.scale, "calibrate"):
            factor = float(self.scale.calibrate(known_grams))  # type: ignore[attr-defined]
            return ScaleCalibrationResult(
                known_grams=known_grams,
                raw_delta=factor * known_grams,
                scale_factor=factor,
                message="HX711 scale_factor updated",
            )

        # Generic path: assume current reading should equal known_grams
        reading = self.scale_service.read_stable(samples=10)
        if abs(reading) < 1e-9:
            return ScaleCalibrationResult(
                known_grams=known_grams,
                raw_delta=0.0,
                scale_factor=1.0,
                message="reading is zero; place mass after tare, or use hardware calibrate",
            )
        # If scale already reports grams, factor is reading/known relative tweak
        factor = reading / known_grams
        if hasattr(self.scale, "scale_factor"):
            old = float(getattr(self.scale, "scale_factor"))
            setattr(self.scale, "scale_factor", old * factor if old else factor)
            factor = float(getattr(self.scale, "scale_factor"))
        return ScaleCalibrationResult(
            known_grams=known_grams,
            raw_delta=reading,
            scale_factor=factor,
            message="scale factor adjusted from stable reading",
        )

    def calibrate_pump(
        self,
        run_seconds: float = 2.0,
        measured_ml: float | None = None,
    ) -> PumpCalibrationResult:
        """Run pump for *run_seconds* and compute ml/s from *measured_ml*.

        If *measured_ml* is None (sim), uses pump-reported volume.
        """
        if self.pump is None:
            raise RuntimeError("No pump configured")
        run_seconds = float(run_seconds)
        if run_seconds <= 0:
            raise ValueError("run_seconds must be > 0")
        delivered = float(self.pump.run(run_seconds))
        ml = float(measured_ml) if measured_ml is not None else delivered
        rate = ml / run_seconds
        if hasattr(self.pump, "_ml_per_second"):
            setattr(self.pump, "_ml_per_second", rate)
        return PumpCalibrationResult(
            run_seconds=run_seconds,
            measured_ml=ml,
            ml_per_second=rate,
            message="pump ml_per_second updated" if measured_ml is not None else "sim rate measured",
        )

    def read_scale_loop(self, seconds: float = 3.0, interval: float = 0.2) -> list[float]:
        """Read scale repeatedly for diagnostics."""
        if self.scale_service is None:
            raise RuntimeError("No scale configured")
        readings: list[float] = []
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            readings.append(self.scale_service.read())
            time.sleep(interval)
        return readings

    def apply_to_config_dict(self, cfg: dict[str, Any]) -> dict[str, Any]:
        """Write current scale_factor / pump rate into a config dict (in place)."""
        if self.scale is not None and hasattr(self.scale, "scale_factor"):
            cfg.setdefault("hardware", {}).setdefault("scale", {})["scale_factor"] = float(
                getattr(self.scale, "scale_factor")
            )
        if self.pump is not None:
            cfg.setdefault("hardware", {}).setdefault("pump", {})["ml_per_second"] = float(
                self.pump.ml_per_second
            )
        return cfg
