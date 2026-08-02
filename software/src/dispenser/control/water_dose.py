"""Timed water dosing using calibrated pump ml/s (or sim flow)."""

from __future__ import annotations

import time
from typing import Any

from dispenser.hardware.base import DigitalSensor, Pump
from dispenser.models import DispenseResult


class WaterDoser:
    """Dispense water by time using the pump's calibrated flow rate.

    Args:
        pump: Pump backend.
        config: Full config or ``dosing.water`` section.
        level_sensor: Optional tank-level sensor (True = water present).
    """

    def __init__(
        self,
        pump: Pump,
        config: dict[str, Any] | None = None,
        level_sensor: DigitalSensor | None = None,
    ) -> None:
        self.pump = pump
        self.level_sensor = level_sensor
        cfg = config or {}
        if "dosing" in cfg:
            water = cfg["dosing"].get("water", {})
        elif "water" in cfg:
            water = cfg["water"]
        else:
            water = cfg
        self.timeout_factor = float(water.get("timeout_factor", 1.5))
        self.tolerance_ml = float(water.get("tolerance_ml", 5.0))

    def dose(
        self,
        target_ml: float,
        *,
        ingredient: str = "water",
    ) -> DispenseResult:
        """Dispense approximately *target_ml* millilitres.

        Returns:
            :class:`DispenseResult` (``error_g`` field holds ml error for API stability).
        """
        t0 = time.monotonic()
        target_ml = float(target_ml)
        if target_ml <= 0:
            return DispenseResult(
                target=target_ml,
                actual=0.0,
                error_g=-target_ml,
                success=False,
                message="target_ml must be > 0",
                ingredient=ingredient,
                kind="water",
                duration_s=0.0,
            )

        if self.level_sensor is not None and not self.level_sensor.read():
            return DispenseResult(
                target=target_ml,
                actual=0.0,
                error_g=-target_ml,
                success=False,
                message="tank level low / empty",
                ingredient=ingredient,
                kind="water",
                duration_s=time.monotonic() - t0,
            )

        rate = self.pump.ml_per_second
        if rate <= 0:
            return DispenseResult(
                target=target_ml,
                actual=0.0,
                error_g=-target_ml,
                success=False,
                message="pump ml_per_second is not calibrated (must be > 0)",
                ingredient=ingredient,
                kind="water",
                duration_s=time.monotonic() - t0,
            )

        seconds = target_ml / rate
        max_seconds = seconds * self.timeout_factor
        # Timed dose (primary Phase 1 method)
        run_s = min(seconds, max_seconds)
        try:
            actual = float(self.pump.run(run_s))
        except Exception as exc:
            self.pump.stop()
            return DispenseResult(
                target=target_ml,
                actual=0.0,
                error_g=-target_ml,
                success=False,
                message=f"pump error: {exc}",
                ingredient=ingredient,
                kind="water",
                duration_s=time.monotonic() - t0,
            )

        error = actual - target_ml
        success = abs(error) <= self.tolerance_ml
        return DispenseResult(
            target=target_ml,
            actual=actual,
            error_g=error,
            success=success,
            message="ok" if success else f"out of tolerance (err={error:+.1f} ml)",
            ingredient=ingredient,
            kind="water",
            duration_s=time.monotonic() - t0,
        )
