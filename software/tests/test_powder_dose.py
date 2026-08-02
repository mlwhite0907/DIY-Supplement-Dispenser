"""Closed-loop powder dosing tests (simulation only)."""

from __future__ import annotations

import pytest

from dispenser.control.powder_dose import PowderDoser
from dispenser.control.scale_service import ScaleService
from dispenser.control.water_dose import WaterDoser
from dispenser.hardware.sim import SimDigitalSensor, SimPump, SimScale, SimStepper, SimVibration


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
def vibe() -> SimVibration:
    return SimVibration(scale=None, boost=1.2)


@pytest.fixture()
def doser(vibe: SimVibration) -> PowderDoser:
    scale = SimScale(noise_g=0.0, grams_per_second=4.0)
    stepper = SimStepper(scale=scale)
    vibe.attach_scale(scale)
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


def test_vibe_off_after_dose(doser: PowderDoser, vibe: SimVibration) -> None:
    """Vibration must be off after a successful dose completes."""
    result = doser.dose(2.0, ingredient="creatine")
    assert result.success, result.message
    assert vibe._on is False


def test_vibe_off_after_jam() -> None:
    """Vibration must be off even when dosing fails on jam."""

    class StuckScale(SimScale):
        def add_grams(self, grams: float) -> None:
            if grams < 0:
                super().add_grams(grams)

    scale = StuckScale(noise_g=0.0, grams_per_second=4.0)
    stepper = SimStepper(scale=scale)
    vibe = SimVibration(scale=scale)
    svc = ScaleService(scale, samples=1)
    cfg = _fast_powder_cfg()
    cfg["dosing"]["powder"]["jam_window_seconds"] = 0.02
    cfg["dosing"]["powder"]["timeout_seconds"] = 10.0
    cfg["dosing"]["powder"]["max_jam_retries"] = 0
    doser = PowderDoser(svc, stepper, vibe, config=cfg)
    result = doser.dose(5.0)
    assert not result.success
    assert vibe._on is False
    assert "jam" in result.message.lower()


def test_jam_detection_when_no_progress() -> None:
    """Scale that never gains mass → jam after retries (message must say jam)."""

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
    # Fast jam: short window, no retries, long enough timeout so jam wins
    cfg["dosing"]["powder"]["jam_window_seconds"] = 0.02
    cfg["dosing"]["powder"]["timeout_seconds"] = 30.0
    cfg["dosing"]["powder"]["max_jam_retries"] = 0
    cfg["dosing"]["powder"]["jam_min_progress_g"] = 0.05
    doser = PowderDoser(svc, stepper, vibe, config=cfg)
    result = doser.dose(5.0)
    assert not result.success
    assert "jam" in result.message.lower(), result.message


def test_water_dose_open_loop_message() -> None:
    """Water dose success message mentions estimated / open-loop / timed."""
    pump = SimPump(ml_per_second=50.0)
    level = SimDigitalSensor("level", initial=True)
    water = WaterDoser(
        pump,
        config={"dosing": {"water": {"tolerance_ml": 5.0}}},
        level_sensor=level,
    )
    result = water.dose(40.0)
    assert result.success, result.message
    msg = result.message.lower()
    assert "estimated" in msg or "open-loop" in msg or "timed" in msg, result.message
    assert abs(result.actual - 40.0) < 0.01
