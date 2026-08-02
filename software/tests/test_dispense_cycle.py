"""Full dispense cycle tests in simulation."""

from __future__ import annotations

from pathlib import Path

import pytest

from dispenser.control.dispense_cycle import DispenseCycle
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
    powder = PowderDoser(
        ScaleService(scale, samples=1),
        stepper,
        vibe,
        config={
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
        },
    )
    water = WaterDoser(pump, config={"dosing": {"water": {"tolerance_ml": 5.0}}}, level_sensor=level)
    return DispenseCycle(
        powder=powder,
        water=water,
        db=db,
        config={"dosing": {"cycle": {"mix_delay_seconds": 0.0, "require_cup": True}}},
        cup_sensor=cup,
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
