"""Water pump GPIO driver (MOSFET / relay switched)."""

from __future__ import annotations

import time
from typing import Any

from dispenser.hardware.base import Pump


def _import_gpio() -> Any:
    try:
        import RPi.GPIO as GPIO  # type: ignore[import-untyped]

        return GPIO
    except ImportError as exc:
        raise ImportError(
            "Pump requires RPi.GPIO on the Pi.\n"
            "  pip install RPi.GPIO\n"
            "Or set DISPENSER_SIM=1."
        ) from exc


class GpioPump(Pump):
    """Timed pump control using calibrated ml/s.

    Args:
        pin: BCM pin controlling the pump switch (default 27).
        ml_per_second: Calibrated flow rate.
        active_high: If True, GPIO HIGH turns pump on.
    """

    def __init__(
        self,
        pin: int = 27,
        ml_per_second: float = 25.0,
        active_high: bool = True,
    ) -> None:
        self.pin = int(pin)
        self._ml_per_second = float(ml_per_second)
        self.active_high = bool(active_high)
        self._gpio = _import_gpio()
        self._gpio.setmode(self._gpio.BCM)
        self._gpio.setwarnings(False)
        off = self._gpio.LOW if active_high else self._gpio.HIGH
        self._gpio.setup(self.pin, self._gpio.OUT, initial=off)

    @property
    def ml_per_second(self) -> float:
        return self._ml_per_second

    def run(self, seconds: float) -> float:
        """Run pump for *seconds*; return estimated ml."""
        seconds = max(0.0, float(seconds))
        on = self._gpio.HIGH if self.active_high else self._gpio.LOW
        off = self._gpio.LOW if self.active_high else self._gpio.HIGH
        self._gpio.output(self.pin, on)
        try:
            time.sleep(seconds)
        finally:
            self._gpio.output(self.pin, off)
        return self._ml_per_second * seconds

    def stop(self) -> None:
        off = self._gpio.LOW if self.active_high else self._gpio.HIGH
        self._gpio.output(self.pin, off)

    def close(self) -> None:
        try:
            self.stop()
            if hasattr(self._gpio, "cleanup"):
                self._gpio.cleanup(self.pin)
        except Exception:
            pass
