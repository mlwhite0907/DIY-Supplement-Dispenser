"""Open-loop timed water dosing using calibrated pump ml/s (Phase 1).

Phase 1 does **not** verify delivered volume with a flow meter. Actual volume
is an estimate: ``rate * seconds``. Messages must say "estimated (timed)" /
"open-loop estimate" — never claim measured verification vs tolerance.
"""

from __future__ import annotations

import time
from typing import Any, Callable

from dispenser.hardware.base import DigitalSensor, Pump
from dispenser.models import DispenseResult


class WaterDoser:
    """Dispense water by open-loop timed pump run (Phase 1).

    ``success`` means: pump ran without error for the planned duration AND
    tank level was OK at start. It does **not** mean measured volume is
    within ``tolerance_ml`` of target (no closed-loop flow verification).

    Level sensor polarity: ``level_sensor.read() == True`` means water is
    present / OK to pump. ``False`` means tank low or empty.

    Args:
        pump: Pump backend.
        config: Full config or ``dosing.water`` section.
        level_sensor: Optional tank-level sensor (True = water present / OK).
        estop_sensor: Optional E-stop (True when pressed / asserted).
        all_stop: Optional emergency stop callback.
    """

    def __init__(
        self,
        pump: Pump,
        config: dict[str, Any] | None = None,
        level_sensor: DigitalSensor | None = None,
        estop_sensor: DigitalSensor | None = None,
        all_stop: Callable[[], None] | None = None,
    ) -> None:
        self.pump = pump
        self.level_sensor = level_sensor
        self.estop_sensor = estop_sensor
        self.all_stop = all_stop
        cfg = config or {}
        if "dosing" in cfg:
            water = cfg["dosing"].get("water", {})
        elif "water" in cfg:
            water = cfg["water"]
        else:
            water = cfg
        self.timeout_factor = float(water.get("timeout_factor", 1.5))
        # Kept for config compatibility; Phase 1 open-loop does not gate success on it
        self.tolerance_ml = float(water.get("tolerance_ml", 5.0))

    def _estop_pressed(self) -> bool:
        if self.estop_sensor is None:
            return False
        try:
            return bool(self.estop_sensor.read())
        except Exception:
            return False

    def _handle_estop(self, target_ml: float, ingredient: str, t0: float) -> DispenseResult:
        if self.all_stop is not None:
            try:
                self.all_stop()
            except Exception:
                pass
        else:
            try:
                self.pump.stop()
            except Exception:
                pass
        return DispenseResult(
            target=target_ml,
            actual=0.0,
            error_g=-target_ml,
            success=False,
            message="estop",
            ingredient=ingredient,
            kind="water",
            duration_s=time.monotonic() - t0,
        )

    def dose(
        self,
        target_ml: float,
        *,
        ingredient: str = "water",
    ) -> DispenseResult:
        """Dispense approximately *target_ml* millilitres (open-loop timed).

        Returns:
            :class:`DispenseResult` where ``actual`` is rate×seconds estimate.
            ``error_g`` field holds ml error for API stability.
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

        if self._estop_pressed():
            return self._handle_estop(target_ml, ingredient, t0)

        # read()==True means water present / OK
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
        # Phase 1: open-loop timed only
        run_s = min(seconds, max_seconds)
        try:
            if self._estop_pressed():
                return self._handle_estop(target_ml, ingredient, t0)
            # Prefer estimate from planned rate×time; pump.run may also return ml
            self.pump.run(run_s)
            if self._estop_pressed():
                return self._handle_estop(target_ml, ingredient, t0)
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

        # Open-loop estimate (not flow-meter verified)
        actual = rate * run_s
        error = actual - target_ml
        # success = pump completed planned duration without error AND level was OK
        success = True
        message = (
            f"ok; estimated (timed) {actual:.1f} ml "
            f"(open-loop estimate, rate={rate:.1f} ml/s × {run_s:.2f}s)"
        )
        return DispenseResult(
            target=target_ml,
            actual=actual,
            error_g=error,
            success=success,
            message=message,
            ingredient=ingredient,
            kind="water",
            duration_s=time.monotonic() - t0,
        )
