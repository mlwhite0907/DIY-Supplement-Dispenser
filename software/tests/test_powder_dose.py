"""Closed-loop powder dosing tests (simulation only)."""

from __future__ import annotations

import pytest

from dispenser.control.powder_dose import PowderDoser
from dispenser.control.scale_service import ScaleService
from dispenser.hardware.sim import SimScale, SimStepper, SimVibration


def _fast_powder_cfg() -> dict:
    return {
        "dosing": {
            "powder": {
                "approach_band_g": 0.15,
                "tolerance_g": 0.12,
                "burst_seconds": 0.08,
                "settle_seconds": 0.0,
                "final_settle_seconds": 0.0,
                "timeout_seconds": 20.0,
                "jam_min_progress_g": 0.02,
                "jam_window_seconds": 2.0,
                "jam_reverse_seconds": 0.1,
                "max_jam_retries": 2,
                "sim_grams_per_second": 4.0,
            }
        }
    }


@pytest.fixture()
def doser() -> PowderDoser:
    scale = SimScale(noise_g=0.0, grams_per_second=4.0)
    stepper = SimStepper(scale=scale)
    vibe = SimVibration(scale=scale, boost=1.2)
    svc = ScaleService(scale, samples=1)
    return PowderDoser(svc, stepper, vibe, config=_fast_powder_cfg())


def test_dose_reaches_target(doser: PowderDoser) -> None:
    result = doser.dose(3.0, ingredient="creatine")
    assert result.success, result.message
    assert abs(result.error_g) <= 0.12
    assert result.kind == "powder"
    assert result.ingredient == "creatine"
    assert result.actual > 0


def test_dose_small_target(doser: PowderDoser) -> None:
    result = doser.dose(1.0)
    assert result.success, result.message
    assert abs(result.error_g) <= 0.12


def test_dose_rejects_non_positive(doser: PowderDoser) -> None:
    result = doser.dose(0.0)
    assert not result.success
    result = doser.dose(-1.0)
    assert not result.success


def test_jam_detection_when_no_progress() -> None:
    """Scale that never gains mass → jam after retries."""

    class StuckScale(SimScale):
        def add_grams(self, grams: float) -> None:
            # ignore forward feed to simulate jam; allow reverse slightly
            if grams < 0:
                super().add_grams(grams)

    scale = StuckScale(noise_g=0.0, grams_per_second=4.0)
    stepper = SimStepper(scale=scale)
    vibe = SimVibration(scale=scale)
    svc = ScaleService(scale, samples=1)
    cfg = _fast_powder_cfg()
    cfg["dosing"]["powder"]["jam_window_seconds"] = 0.05
    cfg["dosing"]["powder"]["timeout_seconds"] = 5.0
    cfg["dosing"]["powder"]["max_jam_retries"] = 1
    doser = PowderDoser(svc, stepper, vibe, config=cfg)
    result = doser.dose(5.0)
    assert not result.success
    assert "jam" in result.message.lower() or "timeout" in result.message.lower()
