"""Tests for domain models."""

from __future__ import annotations

from dispenser.models import (
    CycleResult,
    DispenseResult,
    Ingredient,
    IngredientKind,
    InventoryItem,
    Recipe,
)


def test_ingredient_roundtrip() -> None:
    ing = Ingredient("creatine", IngredientKind.POWDER, 3.0, station=1)
    data = ing.to_dict()
    assert data["kind"] == "powder"
    restored = Ingredient.from_dict(data)
    assert restored.name == "creatine"
    assert restored.kind == IngredientKind.POWDER
    assert restored.amount == 3.0
    assert restored.station == 1


def test_recipe_powders_and_water() -> None:
    recipe = Recipe(
        name="creatine_water",
        ingredients=[
            Ingredient("creatine", IngredientKind.POWDER, 3.0),
            Ingredient("water", IngredientKind.WATER, 200.0),
        ],
    )
    assert len(recipe.powders()) == 1
    assert len(recipe.water()) == 1
    d = recipe.to_dict()
    r2 = Recipe.from_dict(d)
    assert r2.name == "creatine_water"
    assert len(r2.ingredients) == 2


def test_dispense_result_roundtrip() -> None:
    res = DispenseResult(
        target=3.0,
        actual=2.95,
        error_g=-0.05,
        success=True,
        message="ok",
        ingredient="creatine",
        kind="powder",
    )
    data = res.to_dict()
    r2 = DispenseResult.from_dict(data)
    assert r2.success
    assert abs(r2.error_g - (-0.05)) < 1e-9


def test_cycle_result_to_dict() -> None:
    c = CycleResult(recipe_name="x", success=True, message="ok")
    assert c.to_dict()["recipe_name"] == "x"


def test_inventory_roundtrip() -> None:
    item = InventoryItem(
        name="creatine",
        kind=IngredientKind.POWDER,
        remaining=100.0,
        capacity=250.0,
    )
    item2 = InventoryItem.from_dict(item.to_dict())
    assert item2.remaining == 100.0
    assert item2.unit == "g"
