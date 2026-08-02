"""STEP/DIR stepper driver for TMC2208/A4988-style modules (Raspberry Pi).

GPIO libraries are imported lazily; missing hardware raises ImportError with
install guidance. Use simulation mode on non-Pi hosts.
"""

from __future__ import annotations

import time
from typing import Any

from dispenser.hardware.base import StepperMotor


def _import_gpio() -> Any:
    try:
        import RPi.GPIO as GPIO  # type: ignore[import-untyped]

        return GPIO
    except ImportError:
        try:
            import lgpio  # type: ignore[import-untyped]

            return lgpio
        except ImportError as exc:
            raise ImportError(
                "Stepper requires RPi.GPIO or lgpio on the Pi.\n"
                "  pip install RPi.GPIO\n"
                "Or set DISPENSER_SIM=1."
            ) from exc


class TmcStepper(StepperMotor):
    """Bit-banged STEP/DIR driver.

    Args:
        step_pin: BCM pin for STEP.
        dir_pin: BCM pin for DIR.
        en_pin: BCM pin for ENABLE (optional; -1 to skip).
        steps_per_sec: Pulse rate while running.
        reverse: Invert forward direction.
        enable_active_low: If True, EN low enables the driver.
    """

    def __init__(
        self,
        step_pin: int = 12,
        dir_pin: int = 13,
        en_pin: int = 16,
        steps_per_sec: float = 800.0,
        reverse: bool = False,
        enable_active_low: bool = True,
    ) -> None:
        self.step_pin = int(step_pin)
        self.dir_pin = int(dir_pin)
        self.en_pin = int(en_pin)
        self.steps_per_sec = max(1.0, float(steps_per_sec))
        self.reverse = bool(reverse)
        self.enable_active_low = bool(enable_active_low)
        self._gpio = _import_gpio()
        self._setup()

    def _setup(self) -> None:
        GPIO = self._gpio
        if hasattr(GPIO, "setmode"):
            GPIO.setmode(GPIO.BCM)
            GPIO.setwarnings(False)
            GPIO.setup(self.step_pin, GPIO.OUT, initial=GPIO.LOW)
            GPIO.setup(self.dir_pin, GPIO.OUT, initial=GPIO.LOW)
            if self.en_pin >= 0:
                initial = GPIO.HIGH if self.enable_active_low else GPIO.LOW
                GPIO.setup(self.en_pin, GPIO.OUT, initial=initial)
        else:
            raise ImportError("Unsupported GPIO backend for stepper")

    def enable(self) -> None:
        if self.en_pin < 0:
            return
        level = self._gpio.LOW if self.enable_active_low else self._gpio.HIGH
        self._gpio.output(self.en_pin, level)

    def disable(self) -> None:
        if self.en_pin < 0:
            return
        level = self._gpio.HIGH if self.enable_active_low else self._gpio.LOW
        self._gpio.output(self.en_pin, level)

    def run(self, seconds: float, *, reverse: bool = False) -> None:
        """Emit STEP pulses for *seconds* (blocking)."""
        seconds = max(0.0, float(seconds))
        if seconds <= 0:
            return
        self.enable()
        direction = reverse ^ self.reverse
        self._gpio.output(self.dir_pin, self._gpio.HIGH if direction else self._gpio.LOW)
        period = 1.0 / self.steps_per_sec
        half = period / 2.0
        n_steps = int(self.steps_per_sec * seconds)
        for _ in range(max(1, n_steps)):
            self._gpio.output(self.step_pin, self._gpio.HIGH)
            time.sleep(half)
            self._gpio.output(self.step_pin, self._gpio.LOW)
            time.sleep(half)

    def close(self) -> None:
        try:
            self.disable()
            if hasattr(self._gpio, "cleanup"):
                pins = [self.step_pin, self.dir_pin]
                if self.en_pin >= 0:
                    pins.append(self.en_pin)
                self._gpio.cleanup(pins)
        except Exception:
            pass
