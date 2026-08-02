"""Vibration motor GPIO driver (coin / pancake motor via MOSFET or transistor)."""

from __future__ import annotations

from typing import Any

from dispenser.hardware.base import VibrationMotor


def _import_gpio() -> Any:
    try:
        import RPi.GPIO as GPIO  # type: ignore[import-untyped]

        return GPIO
    except ImportError as exc:
        raise ImportError(
            "Vibration motor requires RPi.GPIO on the Pi.\n"
            "  pip install RPi.GPIO\n"
            "Or set DISPENSER_SIM=1."
        ) from exc


class GpioVibration(VibrationMotor):
    """Digital (or soft-PWM) vibration motor on a single GPIO pin.

    Args:
        pin: BCM pin number (default 17).
        duty_percent: If > 0 and PWM available, use software PWM duty cycle.
    """

    def __init__(self, pin: int = 17, duty_percent: float = 80.0) -> None:
        self.pin = int(pin)
        self.duty_percent = max(0.0, min(100.0, float(duty_percent)))
        self._gpio = _import_gpio()
        self._pwm: Any = None
        self._gpio.setmode(self._gpio.BCM)
        self._gpio.setwarnings(False)
        self._gpio.setup(self.pin, self._gpio.OUT, initial=self._gpio.LOW)
        if self.duty_percent < 100.0 and hasattr(self._gpio, "PWM"):
            self._pwm = self._gpio.PWM(self.pin, 200)  # 200 Hz
            self._pwm.start(0)

    def on(self) -> None:
        if self._pwm is not None:
            self._pwm.ChangeDutyCycle(self.duty_percent)
        else:
            self._gpio.output(self.pin, self._gpio.HIGH)

    def off(self) -> None:
        if self._pwm is not None:
            self._pwm.ChangeDutyCycle(0)
        else:
            self._gpio.output(self.pin, self._gpio.LOW)

    def close(self) -> None:
        try:
            self.off()
            if self._pwm is not None:
                self._pwm.stop()
            if hasattr(self._gpio, "cleanup"):
                self._gpio.cleanup(self.pin)
        except Exception:
            pass
