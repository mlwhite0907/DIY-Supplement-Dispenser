"""Abstract hardware interfaces for the dispenser.

Control code depends only on these protocols so simulation and Pi backends
are interchangeable.
"""

from __future__ import annotations

from abc import ABC, abstractmethod


class Scale(ABC):
    """Load-cell scale interface (grams)."""

    @abstractmethod
    def read_grams(self) -> float:
        """Return current weight in grams (absolute, after any tare offset)."""

    @abstractmethod
    def tare(self) -> None:
        """Zero the scale at the current load."""

    def close(self) -> None:
        """Release resources (optional)."""


class StepperMotor(ABC):
    """Auger / stepper drive interface."""

    @abstractmethod
    def enable(self) -> None:
        """Enable the driver (deassert EN if active-low)."""

    @abstractmethod
    def disable(self) -> None:
        """Disable the driver / free motor."""

    @abstractmethod
    def run(self, seconds: float, *, reverse: bool = False) -> None:
        """Run the motor for *seconds* (blocking)."""

    def close(self) -> None:
        """Release resources (optional)."""


class VibrationMotor(ABC):
    """Hopper vibration assist."""

    @abstractmethod
    def on(self) -> None:
        """Start vibration."""

    @abstractmethod
    def off(self) -> None:
        """Stop vibration."""

    def close(self) -> None:
        """Release resources (optional)."""


class Pump(ABC):
    """Water pump interface."""

    @abstractmethod
    def run(self, seconds: float) -> float:
        """Run pump for *seconds*. Return estimated millilitres delivered."""

    @abstractmethod
    def stop(self) -> None:
        """Immediately stop the pump."""

    @property
    @abstractmethod
    def ml_per_second(self) -> float:
        """Calibrated flow rate."""

    def close(self) -> None:
        """Release resources (optional)."""


class DigitalSensor(ABC):
    """Simple digital input (cup present, tank level, flow pulse, …)."""

    @abstractmethod
    def read(self) -> bool:
        """Return True when the sensor is active / asserted."""

    def close(self) -> None:
        """Release resources (optional)."""
