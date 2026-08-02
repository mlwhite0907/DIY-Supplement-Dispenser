"""Digital sensors: cup present, tank level, flow meter input, e-stop."""

from __future__ import annotations

from typing import Any

from dispenser.hardware.base import DigitalSensor


def _import_gpio() -> Any:
    try:
        import RPi.GPIO as GPIO  # type: ignore[import-untyped]

        return GPIO
    except ImportError as exc:
        raise ImportError(
            "Sensors require RPi.GPIO on the Pi.\n"
            "  pip install RPi.GPIO\n"
            "Or set DISPENSER_SIM=1."
        ) from exc


class GpioDigitalSensor(DigitalSensor):
    """BCM digital input with optional pull-up/down and active level.

    ``read()`` returns True when the logical condition is asserted:

    * **Cup**: True = cup present
    * **Level**: True = water present / OK to pump (``level_active_high`` selects
      whether a HIGH or LOW GPIO level means water is present — adjust for your
      float switch wiring)
    * **E-stop**: True = stop pressed / asserted (typically NC to GND with
      pull-up and ``active_high=False`` so pressed opens the circuit or pulls low)

    Args:
        pin: BCM pin number.
        active_high: If True, GPIO HIGH means asserted (``read()`` True).
            If False, GPIO LOW means asserted.
        pull_up: If True, enable internal pull-up; else pull-down.
        name: Label for logs.
    """

    def __init__(
        self,
        pin: int,
        active_high: bool = True,
        pull_up: bool = True,
        name: str = "sensor",
    ) -> None:
        self.pin = int(pin)
        self.active_high = bool(active_high)
        self.name = name
        self._gpio = _import_gpio()
        self._gpio.setmode(self._gpio.BCM)
        self._gpio.setwarnings(False)
        pud = self._gpio.PUD_UP if pull_up else self._gpio.PUD_DOWN
        self._gpio.setup(self.pin, self._gpio.IN, pull_up_down=pud)

    def read(self) -> bool:
        """Return True when the sensor condition is asserted (see class doc)."""
        level = self._gpio.input(self.pin)
        high = level == self._gpio.HIGH
        return high if self.active_high else not high

    def close(self) -> None:
        try:
            if hasattr(self._gpio, "cleanup"):
                self._gpio.cleanup(self.pin)
        except Exception:
            pass
