"""HX711 load-cell scale driver (Raspberry Pi).

Optional dependencies (install on the Pi only)::

    pip install RPi.GPIO hx711
    # or: pip install pi-hx711

If libraries are missing, import still succeeds but instantiation raises
``ImportError`` with install hints. Simulation mode never imports this module
for runtime dosing.
"""

from __future__ import annotations

import time
from typing import Any

from dispenser.hardware.base import Scale


class ScaleError(RuntimeError):
    """Raised when the load cell cannot produce a valid reading."""


def _try_import_gpio() -> Any:
    try:
        import RPi.GPIO as GPIO  # type: ignore[import-untyped]

        return GPIO
    except ImportError:
        try:
            import lgpio as GPIO  # type: ignore[import-untyped]

            return GPIO
        except ImportError as exc:
            raise ImportError(
                "No GPIO backend found. On Raspberry Pi OS install one of:\n"
                "  pip install RPi.GPIO\n"
                "  pip install lgpio\n"
                "Or run with DISPENSER_SIM=1 for simulation mode."
            ) from exc


class HX711Scale(Scale):
    """Thin wrapper around a common HX711 Python library.

    Tries ``hx711.HX711`` (package ``hx711``) first, then falls back to a
    minimal bit-bang reader if only RPi.GPIO is available.

    Args:
        dt_pin: Data pin (BCM numbering). Default 5.
        sck_pin: Clock pin (BCM numbering). Default 6.
        scale_factor: Grams per raw ADC unit (from calibration).
        samples: Averaging count for :meth:`read_grams`.
    """

    def __init__(
        self,
        dt_pin: int = 5,
        sck_pin: int = 6,
        scale_factor: float = 1.0,
        samples: int = 5,
    ) -> None:
        self.dt_pin = int(dt_pin)
        self.sck_pin = int(sck_pin)
        self.scale_factor = float(scale_factor)
        self.samples = max(1, int(samples))
        self._offset = 0.0
        self._hx: Any = None
        self._gpio: Any = None
        self._init_backend()

    def _init_backend(self) -> None:
        # Preferred: hx711 package
        try:
            from hx711 import HX711  # type: ignore[import-untyped]

            self._gpio = _try_import_gpio()
            if hasattr(self._gpio, "setmode"):
                self._gpio.setmode(self._gpio.BCM)
                self._gpio.setwarnings(False)
            self._hx = HX711(dout_pin=self.dt_pin, pd_sck_pin=self.sck_pin)
            if hasattr(self._hx, "reset"):
                self._hx.reset()
            self._backend = "hx711"
            return
        except ImportError:
            pass

        # Fallback: bit-bang with RPi.GPIO only
        self._gpio = _try_import_gpio()
        if not hasattr(self._gpio, "setmode"):
            raise ImportError(
                "HX711 support requires the 'hx711' package or RPi.GPIO bit-bang.\n"
                "  pip install hx711 RPi.GPIO\n"
                "Or run with DISPENSER_SIM=1."
            )
        self._gpio.setmode(self._gpio.BCM)
        self._gpio.setwarnings(False)
        self._gpio.setup(self.dt_pin, self._gpio.IN)
        self._gpio.setup(self.sck_pin, self._gpio.OUT)
        self._gpio.output(self.sck_pin, 0)
        self._backend = "bitbang"

    def _raw_once(self) -> int:
        if self._backend == "hx711" and self._hx is not None:
            if hasattr(self._hx, "get_raw_data_mean"):
                val = self._hx.get_raw_data_mean(times=1)
                if val is None:
                    raise ScaleError("HX711 library returned None (no data)")
                return int(val)
            if hasattr(self._hx, "get_value"):
                val = self._hx.get_value(1)
                if val is None:
                    raise ScaleError("HX711 library returned None (get_value)")
                return int(val)
            if hasattr(self._hx, "read"):
                val = self._hx.read()
                if val is None:
                    raise ScaleError("HX711 library returned None (read)")
                return int(val)
            raise ScaleError("HX711 backend has no supported read method")

        # Bit-bang HX711 (24-bit two's complement)
        GPIO = self._gpio
        # Wait for data ready (DT goes low)
        deadline = time.time() + 0.5
        while GPIO.input(self.dt_pin) == 1:
            if time.time() > deadline:
                raise ScaleError(
                    f"HX711 DT timeout on pin {self.dt_pin} (data not ready)"
                )
            time.sleep(0.0001)

        count = 0
        try:
            for _ in range(24):
                GPIO.output(self.sck_pin, 1)
                count = count << 1
                GPIO.output(self.sck_pin, 0)
                if GPIO.input(self.dt_pin):
                    count += 1
            # Channel A, gain 128: one extra pulse
            GPIO.output(self.sck_pin, 1)
            GPIO.output(self.sck_pin, 0)
        finally:
            # Always leave SCK low so the chip can convert the next sample
            try:
                GPIO.output(self.sck_pin, 0)
            except Exception:
                pass

        # Sign extend 24-bit
        if count & 0x800000:
            count |= ~0xFFFFFF
        return int(count)

    def read_raw(self) -> float:
        """Average raw ADC readings. Raises :class:`ScaleError` on failure."""
        total = 0.0
        for _ in range(self.samples):
            total += float(self._raw_once())
        return total / self.samples

    def read_grams(self) -> float:
        """Return weight in grams after offset and scale_factor.

        Raises:
            ScaleError: If the ADC cannot be read or scale_factor is invalid.
        """
        if not self.scale_factor:
            raise ScaleError("scale_factor is zero; calibrate the scale first")
        raw = self.read_raw()
        return (raw - self._offset) / self.scale_factor

    def tare(self) -> None:
        """Capture current raw reading as zero offset."""
        self._offset = self.read_raw()

    def calibrate(self, known_grams: float) -> float:
        """Set scale_factor from a known reference mass. Returns new factor.

        Call :meth:`tare` with empty scale first, place *known_grams*, then
        call this method.
        """
        if known_grams == 0:
            raise ValueError("known_grams must be non-zero")
        raw = self.read_raw()
        self.scale_factor = (raw - self._offset) / float(known_grams)
        return self.scale_factor

    def close(self) -> None:
        if self._gpio is not None and hasattr(self._gpio, "cleanup"):
            try:
                self._gpio.cleanup([self.dt_pin, self.sck_pin])
            except Exception:
                pass
