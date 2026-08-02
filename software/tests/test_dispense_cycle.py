"""Full dispense cycle tests in simulation."""

from __future__ import annotations

import threading
from pathlib import Path

import pytest

from dispenser.control.dispense_cycle import DispenseBusyError, DispenseCycle
from dispenser.control.powder_dose import PowderDoser
from dispenser.control.scale_service import ScaleService
from dispenser.control.water_dose import WaterDoser
from dispenser.db import Database
from dispenser.hardware.sim import (
    SimDigitalSensor,
    SimPump,
    SimScale,
    SimStepper,
    SimVibration,
)
from dispenser.models import Ingredient, IngredientKind, InventoryItem, Recipe


def _powder_cfg() -> dict:
    return {
        "dosing": {
            "powder": {
                "tolerance_g": 0.15,
                "approach_band_g": 0.15,
                "burst_seconds": 0.08,
                "settle_seconds": 0.0,
                "final_settle_seconds": 0.0,
                "timeout_seconds": 15.0,
                "jam_window_seconds": 3.0,
            }
        }
    }


@pytest.fixture()
def cycle(tmp_path: Path) -> DispenseCycle:
    db = Database(tmp_path / "cycle.db")
    db.upsert_inventory(
        InventoryItem("creatine", IngredientKind.POWDER, 100.0, 200.0, unit="g")
    )
    db.upsert_inventory(
        InventoryItem("water", IngredientKind.WATER, 1000.0, 2000.0, unit="ml")
    )
    scale = SimScale(noise_g=0.0, grams_per_second=5.0)
    stepper = SimStepper(scale=scale)
    vibe = SimVibration(scale=scale)
    pump = SimPump(ml_per_second=50.0)
    cup = SimDigitalSensor("cup", initial=True)
    level = SimDigitalSensor("level", initial=True)
    estop = SimDigitalSensor("estop", initial=False)
    powder = PowderDoser(
        ScaleService(scale, samples=1),
        stepper,
        vibe,
        config=_powder_cfg(),
        estop_sensor=estop,
    )
    water = WaterDoser(
        pump,
        config={"dosing": {"water": {"tolerance_ml": 5.0}}},
        level_sensor=level,
        estop_sensor=estop,
    )
    return DispenseCycle(
        powder=powder,
        water=water,
        db=db,
        config={"dosing": {"cycle": {"mix_delay_seconds": 0.0, "require_cup": True}}},
        cup_sensor=cup,
        estop_sensor=estop,
    )


def test_run_recipe_success(cycle: DispenseCycle) -> None:
    recipe = Recipe(
        name="creatine_water",
        ingredients=[
            Ingredient("creatine", IngredientKind.POWDER, 2.0),
            Ingredient("water", IngredientKind.WATER, 40.0),
        ],
    )
    result = cycle.run_recipe(recipe)
    assert result.success, result.message
    assert len(result.steps) == 2
    assert result.steps[0].kind == "powder"
    assert result.steps[1].kind == "water"
    assert result.log_id is not None

    inv = cycle.db.get_inventory("creatine")  # type: ignore[union-attr]
    assert inv is not None
    assert inv.remaining < 100.0


def test_cup_interlock(cycle: DispenseCycle) -> None:
    assert cycle.cup_sensor is not None
    cycle.cup_sensor.set(False)  # type: ignore[attr-defined]
    recipe = Recipe(
        name="x",
        ingredients=[Ingredient("creatine", IngredientKind.POWDER, 1.0)],
    )
    result = cycle.run_recipe(recipe)
    assert not result.success
    assert "cup" in result.message.lower()


def test_cup_interlock_adhoc_powder(cycle: DispenseCycle) -> None:
    """Ad-hoc powder dose respects require_cup + cup sensor."""
    assert cycle.cup_sensor is not None
    cycle.cup_sensor.set(False)  # type: ignore[attr-defined]
    result = cycle.dose_powder(1.0, ingredient="creatine")
    assert not result.success
    assert "cup" in result.message.lower()


def test_cup_interlock_adhoc_water(cycle: DispenseCycle) -> None:
    """Ad-hoc water dose respects require_cup + cup sensor."""
    assert cycle.cup_sensor is not None
    cycle.cup_sensor.set(False)  # type: ignore[attr-defined]
    result = cycle.dose_water(25.0)
    assert not result.success
    assert "cup" in result.message.lower()


def test_estop_fails_cycle(cycle: DispenseCycle) -> None:
    """E-stop asserted (sim sensor) aborts cycle with estop message."""
    assert cycle.estop_sensor is not None
    cycle.estop_sensor.set(True)  # type: ignore[attr-defined]
    recipe = Recipe(
        name="estop_test",
        ingredients=[Ingredient("creatine", IngredientKind.POWDER, 1.0)],
    )
    result = cycle.run_recipe(recipe)
    assert not result.success
    assert "estop" in result.message.lower()


def test_estop_fails_adhoc_powder(cycle: DispenseCycle) -> None:
    assert cycle.estop_sensor is not None
    cycle.estop_sensor.set(True)  # type: ignore[attr-defined]
    result = cycle.dose_powder(1.0, ingredient="creatine")
    assert not result.success
    assert "estop" in result.message.lower()


def test_empty_recipe_fails(cycle: DispenseCycle) -> None:
    recipe = Recipe(name="empty", ingredients=[])
    result = cycle.run_recipe(recipe)
    assert result.success is False
    assert "empty" in result.message.lower()


def test_pill_recipe_fails_phase2(cycle: DispenseCycle) -> None:
    recipe = Recipe(
        name="pills",
        ingredients=[Ingredient("vitamin_d", IngredientKind.PILL, 1.0)],
    )
    result = cycle.run_recipe(recipe)
    assert result.success is False
    msg = result.message.lower()
    assert "phase 2" in msg or "pill" in msg
    assert "not implemented" in msg or "phase 2" in msg


def test_water_dose_message_mentions_open_loop(cycle: DispenseCycle) -> None:
    """Phase 1 water is open-loop timed; message must say estimated/open-loop/timed."""
    result = cycle.dose_water(25.0)
    assert result.success, result.message
    msg = result.message.lower()
    assert any(k in msg for k in ("estimated", "open-loop", "open loop", "timed")), result.message


def test_adhoc_doses(cycle: DispenseCycle) -> None:
    p = cycle.dose_powder(1.5, ingredient="creatine")
    assert p.success, p.message
    w = cycle.dose_water(25.0)
    assert w.success, w.message


def test_water_low_level(cycle: DispenseCycle) -> None:
    assert cycle.water.level_sensor is not None
    cycle.water.level_sensor.set(False)  # type: ignore[attr-defined]
    result = cycle.dose_water(10.0)
    assert not result.success
    assert "level" in result.message.lower() or "empty" in result.message.lower()


def test_concurrent_dispense_busy_error(cycle: DispenseCycle) -> None:
    """Non-blocking second run raises DispenseBusyError while first holds the lock."""
    held = threading.Event()
    release = threading.Event()
    errors: list[BaseException] = []

    def hold() -> None:
        # Acquire lock via non-blocking API then sleep inside a dummy cycle path
        acquired = cycle._lock.acquire(blocking=False)
        assert acquired
        try:
            held.set()
            release.wait(timeout=5.0)
        finally:
            cycle._lock.release()

    t = threading.Thread(target=hold, daemon=True)
    t.start()
    assert held.wait(timeout=2.0)

    recipe = Recipe(
        name="busy",
        ingredients=[Ingredient("water", IngredientKind.WATER, 10.0)],
    )
    try:
        with pytest.raises(DispenseBusyError):
            cycle.run_recipe(recipe, blocking=False)
    except BaseException as exc:  # pragma: no cover
        errors.append(exc)
        raise
    finally:
        release.set()
        t.join(timeout=2.0)
        assert not errors
