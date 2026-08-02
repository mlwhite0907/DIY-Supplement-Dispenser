"""Simulation backends for Mac/desktop development without GPIO hardware.

The simulated scale accumulates mass while the auger (stepper) runs. Vibration
slightly boosts the effective feed rate. Pump delivers volume by time × rate.
"""

from __future__ import annotations

import random
import time
from typing import TYPE_CHECKING

from dispenser.hardware.base import (
    DigitalSensor,
    Pump,
    Scale,
    StepperMotor,
    VibrationMotor,
)

if TYPE_CHECKING:
    pass


class SimScale(Scale):
    """Software scale with optional noise and external mass injection.

    Attributes:
        grams_per_second: Base feed rate used when linked stepper runs.
    """

    def __init__(
        self,
        noise_g: float = 0.02,
        grams_per_second: float = 2.5,
        initial_grams: float = 0.0,
    ) -> None:
        self._noise_g = float(noise_g)
        self.grams_per_second = float(grams_per_second)
        self._true_grams = float(initial_grams)
        self._tare_offset = 0.0
        self._vibration_boost = 1.0  # multiplier while vibe is on

    def read_grams(self) -> float:
        """Return tared weight with small Gaussian noise."""
        noise = random.gauss(0.0, self._noise_g) if self._noise_g > 0 else 0.0
        return (self._true_grams - self._tare_offset) + noise

    def tare(self) -> None:
        """Zero at current true mass."""
        self._true_grams  # keep mass; only offset changes
        self._tare_offset = self._true_grams

    def add_grams(self, grams: float) -> None:
        """Inject mass (used by sim stepper)."""
        self._true_grams += float(grams)

    def set_vibration_boost(self, factor: float) -> None:
        """Set feed-rate multiplier while vibration is active."""
        self._vibration_boost = max(0.0, float(factor))

    @property
    def true_grams(self) -> float:
        """Noise-free absolute mass (for tests)."""
        return self._true_grams

    def close(self) -> None:
        pass


class SimStepper(StepperMotor):
    """Simulated auger: advances linked :class:`SimScale` mass while running."""

    def __init__(self, scale: SimScale | None = None) -> None:
        self._scale = scale
        self._enabled = False
        self._total_run_s = 0.0

    def attach_scale(self, scale: SimScale) -> None:
        """Link a scale that receives dispensed mass."""
        self._scale = scale

    def enable(self) -> None:
        self._enabled = True

    def disable(self) -> None:
        self._enabled = False

    def run(self, seconds: float, *, reverse: bool = False) -> None:
        """Simulate motion; sleep a shortened wall time for fast tests.

        In sim we sleep a fraction of real time so unit tests stay quick, but
        mass added uses the full *seconds* × rate so dosing math stays realistic.
        """
        seconds = max(0.0, float(seconds))
        if seconds <= 0:
            return
        self._enabled = True
        if self._scale is not None:
            rate = self._scale.grams_per_second * self._scale._vibration_boost
            delta = rate * seconds
            if reverse:
                # reverse slightly reduces pile (jam clear); clamp at tare floor
                self._scale.add_grams(-min(delta * 0.15, max(0.0, self._scale.true_grams)))
            else:
                self._scale.add_grams(delta)
        self._total_run_s += seconds
        # Speedy sim: max ~5 ms wall sleep so tests are fast
        time.sleep(min(seconds * 0.01, 0.005))

    def close(self) -> None:
        self._enabled = False


class SimVibration(VibrationMotor):
    """Sim vibration boosts linked scale feed rate while on."""

    def __init__(self, scale: SimScale | None = None, boost: float = 1.25) -> None:
        self._scale = scale
        self._boost = float(boost)
        self._on = False

    def attach_scale(self, scale: SimScale) -> None:
        self._scale = scale

    def on(self) -> None:
        self._on = True
        if self._scale is not None:
            self._scale.set_vibration_boost(self._boost)

    def off(self) -> None:
        self._on = False
        if self._scale is not None:
            self._scale.set_vibration_boost(1.0)

    def close(self) -> None:
        self.off()


class SimPump(Pump):
    """Timed pump simulation."""

    def __init__(self, ml_per_second: float = 25.0) -> None:
        self._ml_per_second = float(ml_per_second)
        self._running = False
        self.total_ml = 0.0

    @property
    def ml_per_second(self) -> float:
        return self._ml_per_second

    def run(self, seconds: float) -> float:
        seconds = max(0.0, float(seconds))
        self._running = True
        ml = self._ml_per_second * seconds
        self.total_ml += ml
        time.sleep(min(seconds * 0.01, 0.005))
        self._running = False
        return ml

    def stop(self) -> None:
        self._running = False

    def close(self) -> None:
        self.stop()


class SimDigitalSensor(DigitalSensor):
    """Mutable digital sensor for tests and sim interlocks."""

    def __init__(self, name: str = "sensor", initial: bool = False) -> None:
        self.name = name
        self._value = bool(initial)

    def read(self) -> bool:
        return self._value

    def set(self, value: bool) -> None:
        """Force sensor state (test helper)."""
        self._value = bool(value)

    def close(self) -> None:
        pass
