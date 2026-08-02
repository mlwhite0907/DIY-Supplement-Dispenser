"""Domain models for recipes, ingredients, and dispense results."""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any


class IngredientKind(str, Enum):
    """Type of ingredient in a recipe step."""

    POWDER = "powder"
    WATER = "water"
    PILL = "pill"  # reserved for Phase 2


@dataclass
class Ingredient:
    """A single dose step within a recipe.

    Attributes:
        name: Human-readable name (e.g. ``\"creatine\"``, ``\"water\"``).
        kind: Ingredient type.
        amount: Grams for powder, millilitres for water, count for pills.
        station: Optional station/hopper index (Phase 1 uses 0).
    """

    name: str
    kind: IngredientKind
    amount: float
    station: int = 0

    def to_dict(self) -> dict[str, Any]:
        """Serialize to a plain dict suitable for JSON/SQLite."""
        return {
            "name": self.name,
            "kind": self.kind.value if isinstance(self.kind, IngredientKind) else self.kind,
            "amount": self.amount,
            "station": self.station,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Ingredient:
        """Deserialize from a plain dict."""
        kind = data["kind"]
        if not isinstance(kind, IngredientKind):
            kind = IngredientKind(kind)
        return cls(
            name=str(data["name"]),
            kind=kind,
            amount=float(data["amount"]),
            station=int(data.get("station", 0)),
        )


@dataclass
class Recipe:
    """Named list of ingredients to dispense in order.

    Convention: powders first, then water. Mix delay is applied by the cycle
    controller after water (if configured).
    """

    name: str
    ingredients: list[Ingredient] = field(default_factory=list)
    description: str = ""
    id: int | None = None

    def powders(self) -> list[Ingredient]:
        """Return powder ingredients only."""
        return [i for i in self.ingredients if i.kind == IngredientKind.POWDER]

    def water(self) -> list[Ingredient]:
        """Return water ingredients only."""
        return [i for i in self.ingredients if i.kind == IngredientKind.WATER]

    def to_dict(self) -> dict[str, Any]:
        """Serialize recipe including nested ingredients."""
        return {
            "id": self.id,
            "name": self.name,
            "description": self.description,
            "ingredients": [i.to_dict() for i in self.ingredients],
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Recipe:
        """Deserialize recipe from a plain dict."""
        ingredients = [Ingredient.from_dict(i) for i in data.get("ingredients", [])]
        return cls(
            id=data.get("id"),
            name=str(data["name"]),
            description=str(data.get("description", "")),
            ingredients=ingredients,
        )


@dataclass
class DispenseResult:
    """Outcome of a single powder or water dose, or a full cycle summary step.

    Attributes:
        target: Requested amount (g or ml).
        actual: Measured or estimated amount delivered.
        error_g: ``actual - target`` (named ``error_g`` even for water ml for API stability).
        success: Whether delivery was within tolerance and no fatal error.
        message: Human-readable status / error detail.
        ingredient: Optional ingredient name.
        kind: Optional ingredient kind string.
        duration_s: Wall time for the operation.
        timestamp: UTC time of completion.
    """

    target: float
    actual: float
    error_g: float
    success: bool
    message: str = ""
    ingredient: str = ""
    kind: str = ""
    duration_s: float = 0.0
    timestamp: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    def to_dict(self) -> dict[str, Any]:
        """Serialize to a plain dict."""
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> DispenseResult:
        """Deserialize from a plain dict."""
        return cls(
            target=float(data["target"]),
            actual=float(data["actual"]),
            error_g=float(data["error_g"]),
            success=bool(data["success"]),
            message=str(data.get("message", "")),
            ingredient=str(data.get("ingredient", "")),
            kind=str(data.get("kind", "")),
            duration_s=float(data.get("duration_s", 0.0)),
            timestamp=str(data.get("timestamp", datetime.now(timezone.utc).isoformat())),
        )


@dataclass
class CycleResult:
    """Result of a full dispense cycle (one or more steps + overall success)."""

    recipe_name: str
    steps: list[DispenseResult] = field(default_factory=list)
    success: bool = False
    message: str = ""
    duration_s: float = 0.0
    timestamp: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )
    log_id: int | None = None

    def to_dict(self) -> dict[str, Any]:
        """Serialize cycle result."""
        return {
            "recipe_name": self.recipe_name,
            "steps": [s.to_dict() for s in self.steps],
            "success": self.success,
            "message": self.message,
            "duration_s": self.duration_s,
            "timestamp": self.timestamp,
            "log_id": self.log_id,
        }


@dataclass
class InventoryItem:
    """Tracked inventory for a hopper/tank ingredient."""

    name: str
    kind: IngredientKind
    remaining: float
    capacity: float
    unit: str = "g"  # "g" or "ml"
    station: int = 0
    id: int | None = None

    def to_dict(self) -> dict[str, Any]:
        """Serialize inventory item."""
        return {
            "id": self.id,
            "name": self.name,
            "kind": self.kind.value if isinstance(self.kind, IngredientKind) else self.kind,
            "remaining": self.remaining,
            "capacity": self.capacity,
            "unit": self.unit,
            "station": self.station,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> InventoryItem:
        """Deserialize inventory item."""
        kind = data["kind"]
        if not isinstance(kind, IngredientKind):
            kind = IngredientKind(kind)
        return cls(
            id=data.get("id"),
            name=str(data["name"]),
            kind=kind,
            remaining=float(data["remaining"]),
            capacity=float(data["capacity"]),
            unit=str(data.get("unit", "g")),
            station=int(data.get("station", 0)),
        )
