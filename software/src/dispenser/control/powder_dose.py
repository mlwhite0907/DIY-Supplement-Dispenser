"""Closed-loop powder dosing with vibration assist and jam recovery."""

from __future__ import annotations

import time
from typing import Any

from dispenser.control.scale_service import ScaleService
from dispenser.hardware.base import StepperMotor, VibrationMotor
from dispenser.models import DispenseResult


class PowderDoser:
    """Closed-loop auger dosing against a load cell.

    Algorithm:
      1. Tare scale
      2. Enable vibration + run auger in short bursts
      3. Read scale; stop when within approach band of target
      4. Final settle + verify within tolerance
      5. On no weight progress → reverse-auger (jam clear) and retry

    Args:
        scale_service: Scale helper.
        stepper: Auger motor.
        vibration: Hopper vibration motor.
        config: ``dosing.powder`` section (or full config; nested lookup used).
    """

    def __init__(
        self,
        scale_service: ScaleService,
        stepper: StepperMotor,
        vibration: VibrationMotor,
        config: dict[str, Any] | None = None,
    ) -> None:
        self.scale = scale_service
        self.stepper = stepper
        self.vibration = vibration
        cfg = config or {}
        powder = cfg.get("dosing", cfg).get("powder", cfg) if "dosing" in cfg or "powder" in cfg else cfg
        if "powder" in cfg:
            powder = cfg["powder"]
        elif "dosing" in cfg:
            powder = cfg["dosing"].get("powder", {})
        self.approach_band_g = float(powder.get("approach_band_g", 0.15))
        self.tolerance_g = float(powder.get("tolerance_g", 0.10))
        self.burst_seconds = float(powder.get("burst_seconds", 0.12))
        self.settle_seconds = float(powder.get("settle_seconds", 0.25))
        self.final_settle_seconds = float(powder.get("final_settle_seconds", 0.6))
        self.timeout_seconds = float(powder.get("timeout_seconds", 45.0))
        self.jam_min_progress_g = float(powder.get("jam_min_progress_g", 0.05))
        self.jam_window_seconds = float(powder.get("jam_window_seconds", 3.0))
        self.jam_reverse_seconds = float(powder.get("jam_reverse_seconds", 0.4))
        self.max_jam_retries = int(powder.get("max_jam_retries", 2))

    def dose(
        self,
        target_g: float,
        *,
        ingredient: str = "",
        tare: bool = True,
    ) -> DispenseResult:
        """Dispense approximately *target_g* grams of powder.

        Args:
            target_g: Desired mass in grams (must be > 0).
            ingredient: Optional name for logging.
            tare: If True, zero scale before dosing.

        Returns:
            :class:`DispenseResult` with measured actual and success flag.
        """
        t0 = time.monotonic()
        target_g = float(target_g)
        if target_g <= 0:
            return DispenseResult(
                target=target_g,
                actual=0.0,
                error_g=0.0 - target_g,
                success=False,
                message="target_g must be > 0",
                ingredient=ingredient,
                kind="powder",
                duration_s=0.0,
            )

        if tare:
            self.scale.tare()

        jam_retries = 0
        last_progress_weight = self.scale.read_stable(samples=3)
        last_progress_time = time.monotonic()
        stopped_for_approach = False

        try:
            self.stepper.enable()
            self.vibration.on()

            while True:
                elapsed = time.monotonic() - t0
                if elapsed > self.timeout_seconds:
                    actual = self.scale.wait_settle(self.final_settle_seconds)
                    return self._result(
                        target_g,
                        actual,
                        False,
                        f"timeout after {elapsed:.1f}s",
                        ingredient,
                        t0,
                    )

                weight = self.scale.read()
                remaining = target_g - weight

                # Near target: stop bursts, settle, verify
                if remaining <= self.approach_band_g:
                    stopped_for_approach = True
                    break

                # Adaptive burst: shorter when close
                burst = self.burst_seconds
                if remaining < self.approach_band_g * 3:
                    burst = max(0.04, self.burst_seconds * 0.4)

                self.stepper.run(burst, reverse=False)
                if self.settle_seconds > 0:
                    time.sleep(self.settle_seconds)

                weight_after = self.scale.read()
                now = time.monotonic()
                if weight_after - last_progress_weight >= self.jam_min_progress_g:
                    last_progress_weight = weight_after
                    last_progress_time = now
                elif now - last_progress_time >= self.jam_window_seconds:
                    # Jam: reverse and retry
                    if jam_retries >= self.max_jam_retries:
                        actual = self.scale.wait_settle(self.final_settle_seconds)
                        return self._result(
                            target_g,
                            actual,
                            False,
                            f"jam: no progress after {jam_retries} reverse attempts",
                            ingredient,
                            t0,
                        )
                    self.stepper.run(self.jam_reverse_seconds, reverse=True)
                    jam_retries += 1
                    last_progress_time = time.monotonic()
                    last_progress_weight = self.scale.read()

        finally:
            self.vibration.off()
            try:
                self.stepper.disable()
            except Exception:
                pass

        # Final settle and optional fine-adjust bursts if still short
        actual = self.scale.wait_settle(self.final_settle_seconds)
        # Top up while clearly under target (leave a small headroom below overshoot)
        under_target = actual < (target_g - min(self.tolerance_g * 0.5, 0.05))
        if under_target and stopped_for_approach:
            fine_deadline = time.monotonic() + min(5.0, self.timeout_seconds)
            try:
                self.stepper.enable()
                while (
                    actual < (target_g - min(self.tolerance_g * 0.25, 0.03))
                    and time.monotonic() < fine_deadline
                ):
                    # Short top-up; scale sim adds mass proportional to time
                    self.stepper.run(max(0.02, self.burst_seconds * 0.25), reverse=False)
                    actual = self.scale.wait_settle(self.settle_seconds)
            finally:
                try:
                    self.stepper.disable()
                except Exception:
                    pass
            actual = self.scale.wait_settle(self.final_settle_seconds * 0.5)

        error = actual - target_g
        # Epsilon avoids float-edge failures at exact tolerance boundary
        success = abs(error) <= (self.tolerance_g + 1e-9)
        msg = "ok" if success else f"out of tolerance (err={error:+.3f} g)"
        if jam_retries:
            msg = f"{msg}; jam_retries={jam_retries}"
        return self._result(target_g, actual, success, msg, ingredient, t0)

    def _result(
        self,
        target: float,
        actual: float,
        success: bool,
        message: str,
        ingredient: str,
        t0: float,
    ) -> DispenseResult:
        return DispenseResult(
            target=target,
            actual=actual,
            error_g=actual - target,
            success=success,
            message=message,
            ingredient=ingredient,
            kind="powder",
            duration_s=time.monotonic() - t0,
        )
