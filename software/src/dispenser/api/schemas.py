"""Pydantic request/response schemas for the REST API."""

from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """GET /health"""

    status: str = "ok"
    version: str
    mode: str
    timestamp: str


class IngredientIn(BaseModel):
    """Ingredient payload for recipe create/update."""

    name: str
    kind: str = Field(description="powder | water | pill")
    amount: float = Field(gt=0)
    station: int = 0


class RecipeIn(BaseModel):
    """Create/update recipe body."""

    name: str
    description: str = ""
    ingredients: list[IngredientIn] = Field(default_factory=list)


class RecipeOut(BaseModel):
    """Recipe response."""

    id: int | None = None
    name: str
    description: str = ""
    ingredients: list[dict[str, Any]] = Field(default_factory=list)


class DispenseRequest(BaseModel):
    """POST /dispense body."""

    recipe: str = Field(description="Recipe name to run")


class DispenseStepOut(BaseModel):
    """Single step in a dispense response."""

    target: float
    actual: float
    error_g: float
    success: bool
    message: str = ""
    ingredient: str = ""
    kind: str = ""
    duration_s: float = 0.0


class DispenseResponse(BaseModel):
    """POST /dispense response."""

    recipe_name: str
    success: bool
    message: str = ""
    duration_s: float = 0.0
    steps: list[DispenseStepOut] = Field(default_factory=list)
    log_id: int | None = None


class InventoryItemOut(BaseModel):
    """Inventory row."""

    id: int | None = None
    name: str
    kind: str
    remaining: float
    capacity: float
    unit: str = "g"
    station: int = 0


class LogEntryOut(BaseModel):
    """Dispense log row."""

    id: int
    recipe_name: str
    success: bool
    message: str
    duration_s: float
    steps: list[dict[str, Any]]
    created_at: str
