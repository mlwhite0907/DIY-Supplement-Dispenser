"""Closed-loop powder dosing with vibration assist and jam recovery."""

from __future__ import annotations

import time
from typing import Any, Callable

from dispenser.control.scale_service import ScaleService
from dispenser.hardware.base import DigitalSensor, StepperMotor, VibrationMotor
from dispenser.models import DispenseResult


class PowderDoser:
    """Closed-loop auger dosing against a load cell.

    Algorithm:
      1. Tare scale
      2. Run auger in short bursts with vibration ON only during bursts
         (vibe OFF during settle/reads; vibe stays OFF in final approach band)
      3. Read scale; stop when within approach band of target
      4. Final settle + verify within tolerance
      5. On overshoot: best-effort short reverse bursts
      6. On no weight progress → reverse-auger (jam clear) and retry

    Scale errors are propagated / reported — never treated as zero weight.

    Args:
        scale_service: Scale helper.
        stepper: Auger motor.
        vibration: Hopper vibration motor.
        config: ``dosing.powder`` section (or full config; nested lookup used).
        estop_sensor: Optional E-stop (True when pressed / asserted).
        all_stop: Optional emergency stop callback (disable motors).
    """

    def __init__(
        self,
        scale_service: ScaleService,
        stepper: StepperMotor,
        vibration: VibrationMotor,
        config: dict[str, Any] | None = None,
        estop_sensor: DigitalSensor | None = None,
        all_stop: Callable[[], None] | None = None,
    ) -> None:
        self.scale = scale_service
        self.stepper = stepper
        self.vibration = vibration
        self.estop_sensor = estop_sensor
        self.all_stop = all_stop
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
        self.overshoot_reverse_seconds = float(
            powder.get("overshoot_reverse_seconds", 0.08)
        )
        self.max_overshoot_reverses = int(powder.get("max_overshoot_reverses", 3))

    def _estop_pressed(self) -> bool:
        if self.estop_sensor is None:
            return False
        try:
            return bool(self.estop_sensor.read())
        except Exception:
            return False

    def _handle_estop(self, target_g: float, ingredient: str, t0: float) -> DispenseResult:
        if self.all_stop is not None:
            try:
                self.all_stop()
            except Exception:
                pass
        else:
            try:
                self.vibration.off()
            except Exception:
                pass
            try:
                self.stepper.disable()
            except Exception:
                pass
        actual = 0.0
        try:
            actual = self.scale.read()
        except Exception:
            pass
        return self._result(
            target_g,
            actual,
            False,
            "estop",
            ingredient,
            t0,
        )

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

        if self._estop_pressed():
            return self._handle_estop(target_g, ingredient, t0)

        try:
            if tare:
                self.scale.tare()
            last_progress_weight = self.scale.read_stable(samples=3)
        except Exception as exc:
            return self._result(
                target_g,
                0.0,
                False,
                f"scale error: {exc}",
                ingredient,
                t0,
            )

        jam_retries = 0
        last_progress_time = time.monotonic()
        stopped_for_approach = False

        try:
            self.stepper.enable()
            # Vibration is pulsed only during bursts — start OFF
            self.vibration.off()

            while True:
                if self._estop_pressed():
                    return self._handle_estop(target_g, ingredient, t0)

                elapsed = time.monotonic() - t0
                if elapsed > self.timeout_seconds:
                    try:
                        actual = self.scale.wait_settle(self.final_settle_seconds)
                    except Exception as exc:
                        return self._result(
                            target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
                        )
                    return self._result(
                        target_g,
                        actual,
                        False,
                        f"timeout after {elapsed:.1f}s",
                        ingredient,
                        t0,
                    )

                try:
                    weight = self.scale.read()
                except Exception as exc:
                    return self._result(
                        target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
                    )
                remaining = target_g - weight

                # Near target: stop bursts, settle, verify (vibe already off for reads)
                if remaining <= self.approach_band_g:
                    stopped_for_approach = True
                    break

                # Adaptive burst: shorter when close
                burst = self.burst_seconds
                if remaining < self.approach_band_g * 3:
                    burst = max(0.04, self.burst_seconds * 0.4)

                # Vibration ON only during stepper burst; OFF when remaining is
                # within 2× approach band (final approach) and during settle/reads.
                use_vibe = remaining >= (self.approach_band_g * 2)
                if use_vibe:
                    self.vibration.on()
                else:
                    self.vibration.off()

                try:
                    self.stepper.run(burst, reverse=False)
                finally:
                    self.vibration.off()

                if self.settle_seconds > 0:
                    time.sleep(self.settle_seconds)

                try:
                    weight_after = self.scale.read()
                except Exception as exc:
                    return self._result(
                        target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
                    )
                now = time.monotonic()
                if weight_after - last_progress_weight >= self.jam_min_progress_g:
                    last_progress_weight = weight_after
                    last_progress_time = now
                elif now - last_progress_time >= self.jam_window_seconds:
                    # Jam: reverse and retry (vibe off during reverse clear)
                    if jam_retries >= self.max_jam_retries:
                        try:
                            actual = self.scale.wait_settle(self.final_settle_seconds)
                        except Exception as exc:
                            return self._result(
                                target_g,
                                0.0,
                                False,
                                f"scale error: {exc}",
                                ingredient,
                                t0,
                            )
                        return self._result(
                            target_g,
                            actual,
                            False,
                            f"jam: no progress after {jam_retries} reverse attempts",
                            ingredient,
                            t0,
                        )
                    self.vibration.off()
                    self.stepper.run(self.jam_reverse_seconds, reverse=True)
                    jam_retries += 1
                    last_progress_time = time.monotonic()
                    try:
                        last_progress_weight = self.scale.read()
                    except Exception as exc:
                        return self._result(
                            target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
                        )

        finally:
            try:
                self.vibration.off()
            except Exception:
                pass
            try:
                self.stepper.disable()
            except Exception:
                pass

        # Final settle and optional fine-adjust bursts if still short (vibe OFF)
        try:
            actual = self.scale.wait_settle(self.final_settle_seconds)
        except Exception as exc:
            return self._result(
                target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
            )

        under_target = actual < (target_g - min(self.tolerance_g * 0.5, 0.05))
        if under_target and stopped_for_approach:
            if self._estop_pressed():
                return self._handle_estop(target_g, ingredient, t0)
            fine_deadline = time.monotonic() + min(5.0, self.timeout_seconds)
            try:
                self.stepper.enable()
                self.vibration.off()  # final approach: vibe stays OFF
                while (
                    actual < (target_g - min(self.tolerance_g * 0.25, 0.03))
                    and time.monotonic() < fine_deadline
                ):
                    if self._estop_pressed():
                        return self._handle_estop(target_g, ingredient, t0)
                    self.stepper.run(max(0.02, self.burst_seconds * 0.25), reverse=False)
                    try:
                        actual = self.scale.wait_settle(self.settle_seconds)
                    except Exception as exc:
                        return self._result(
                            target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
                        )
            finally:
                try:
                    self.stepper.disable()
                except Exception:
                    pass
            try:
                actual = self.scale.wait_settle(self.final_settle_seconds * 0.5)
            except Exception as exc:
                return self._result(
                    target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
                )

        # Overshoot recovery: best-effort reverse bursts (may not remove powder
        # already in the cup — report honestly if still high).
        overshoot_msg = ""
        if actual > (target_g + self.tolerance_g):
            try:
                self.stepper.enable()
                self.vibration.off()
                for _ in range(self.max_overshoot_reverses):
                    if self._estop_pressed():
                        return self._handle_estop(target_g, ingredient, t0)
                    if actual <= (target_g + self.tolerance_g):
                        break
                    self.stepper.run(self.overshoot_reverse_seconds, reverse=True)
                    try:
                        actual = self.scale.wait_settle(self.settle_seconds)
                    except Exception as exc:
                        return self._result(
                            target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
                        )
            finally:
                try:
                    self.stepper.disable()
                except Exception:
                    pass
            try:
                actual = self.scale.wait_settle(self.final_settle_seconds * 0.5)
            except Exception as exc:
                return self._result(
                    target_g, 0.0, False, f"scale error: {exc}", ingredient, t0
                )
            if actual > (target_g + self.tolerance_g):
                overshoot_msg = (
                    "; reverse attempted but powder may remain in cup"
                )

        error = actual - target_g
        # Epsilon avoids float-edge failures at exact tolerance boundary
        success = abs(error) <= (self.tolerance_g + 1e-9)
        msg = "ok" if success else f"out of tolerance (err={error:+.3f} g)"
        if overshoot_msg and not success:
            msg = f"{msg}{overshoot_msg}"
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
