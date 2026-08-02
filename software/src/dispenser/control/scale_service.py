"""Scale service – stable reads, tare, and simple filtering."""

from __future__ import annotations

import time
from typing import Sequence

from dispenser.hardware.base import Scale


class ScaleService:
    """Higher-level scale operations on top of a :class:`Scale` backend.

    Args:
        scale: Hardware or simulation scale.
        samples: Number of readings to average for :meth:`read_stable`.
        sample_delay_s: Pause between samples.
    """

    def __init__(
        self,
        scale: Scale,
        samples: int = 5,
        sample_delay_s: float = 0.0,
    ) -> None:
        self.scale = scale
        self.samples = max(1, int(samples))
        self.sample_delay_s = max(0.0, float(sample_delay_s))

    def tare(self) -> None:
        """Zero the scale."""
        self.scale.tare()

    def read(self) -> float:
        """Single reading in grams."""
        return float(self.scale.read_grams())

    def read_stable(self, samples: int | None = None) -> float:
        """Average several readings for a more stable value."""
        n = self.samples if samples is None else max(1, int(samples))
        total = 0.0
        for i in range(n):
            total += self.read()
            if self.sample_delay_s and i + 1 < n:
                time.sleep(self.sample_delay_s)
        return total / n

    def wait_settle(self, seconds: float) -> float:
        """Sleep *seconds* then return a stable reading."""
        if seconds > 0:
            time.sleep(seconds)
        return self.read_stable()

    @staticmethod
    def median(values: Sequence[float]) -> float:
        """Return median of *values* (for calibration helpers)."""
        if not values:
            return 0.0
        ordered = sorted(values)
        mid = len(ordered) // 2
        if len(ordered) % 2:
            return float(ordered[mid])
        return float(ordered[mid - 1] + ordered[mid]) / 2.0
