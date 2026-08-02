"""SQLite database tests."""

from __future__ import annotations

from pathlib import Path

import pytest

from dispenser.db import Database
from dispenser.models import Ingredient, IngredientKind, InventoryItem, Recipe


@pytest.fixture()
def db(tmp_path: Path) -> Database:
    return Database(tmp_path / "test.db")


def test_recipe_crud(db: Database) -> None:
    recipe = Recipe(
        name="test_mix",
        description="unit test",
        ingredients=[
            Ingredient("creatine", IngredientKind.POWDER, 5.0),
            Ingredient("water", IngredientKind.WATER, 100.0),
        ],
    )
    saved = db.upsert_recipe(recipe)
    assert saved.id is not None
    got = db.get_recipe("test_mix")
    assert got is not None
    assert len(got.ingredients) == 2
    assert got.ingredients[0].amount == 5.0

    # update
    got.ingredients[0].amount = 6.0
    db.upsert_recipe(got)
    again = db.get_recipe("test_mix")
    assert again is not None
    assert again.ingredients[0].amount == 6.0
    assert again.id == saved.id

    assert db.delete_recipe("test_mix") is True
    assert db.get_recipe("test_mix") is None


def test_inventory_adjust(db: Database) -> None:
    db.upsert_inventory(
        InventoryItem(
            name="creatine",
            kind=IngredientKind.POWDER,
            remaining=50.0,
            capacity=100.0,
        )
    )
    updated = db.adjust_inventory("creatine", -12.5)
    assert updated is not None
    assert updated.remaining == pytest.approx(37.5)
    # clamp at zero
    db.adjust_inventory("creatine", -1000)
    item = db.get_inventory("creatine")
    assert item is not None
    assert item.remaining == 0.0


def test_logs(db: Database) -> None:
    log_id = db.add_log(
        "creatine_water",
        success=True,
        message="ok",
        duration_s=1.2,
        steps=[{"target": 3.0, "actual": 3.0}],
    )
    assert log_id >= 1
    logs = db.list_logs(limit=10)
    assert len(logs) == 1
    assert logs[0]["recipe_name"] == "creatine_water"
    assert logs[0]["success"] is True
    assert logs[0]["steps"][0]["target"] == 3.0


def test_seed_defaults(db: Database) -> None:
    db.seed_defaults()
    names = {r.name for r in db.list_recipes()}
    assert "creatine_water" in names
    inv = {i.name for i in db.list_inventory()}
    assert "creatine" in inv
    assert "water" in inv
    # idempotent
    db.seed_defaults()
    assert len(db.list_recipes()) == len(names)
