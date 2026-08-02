"""SQLite persistence for recipes, inventory, and dispense logs."""

from __future__ import annotations

import json
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Generator, Iterable

from dispenser.models import (
    Ingredient,
    IngredientKind,
    InventoryItem,
    Recipe,
)


SCHEMA = """
CREATE TABLE IF NOT EXISTS recipes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    ingredients_json TEXT NOT NULL DEFAULT '[]'
);

CREATE TABLE IF NOT EXISTS inventory (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    kind TEXT NOT NULL,
    remaining REAL NOT NULL,
    capacity REAL NOT NULL,
    unit TEXT NOT NULL DEFAULT 'g',
    station INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    recipe_name TEXT NOT NULL,
    success INTEGER NOT NULL,
    message TEXT NOT NULL DEFAULT '',
    duration_s REAL NOT NULL DEFAULT 0,
    steps_json TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
"""


class Database:
    """Thin SQLite wrapper for dispenser state.

    Args:
        path: Filesystem path to the SQLite file (created if missing).
    """

    def __init__(self, path: str | Path) -> None:
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._init_schema()

    def _connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(self.path))
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON")
        return conn

    @contextmanager
    def connection(self) -> Generator[sqlite3.Connection, None, None]:
        """Context manager yielding a connection that commits on success."""
        conn = self._connect()
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def _init_schema(self) -> None:
        with self.connection() as conn:
            conn.executescript(SCHEMA)

    # ------------------------------------------------------------------ recipes

    def list_recipes(self) -> list[Recipe]:
        """Return all recipes ordered by name."""
        with self.connection() as conn:
            rows = conn.execute(
                "SELECT id, name, description, ingredients_json FROM recipes ORDER BY name"
            ).fetchall()
        return [self._row_to_recipe(r) for r in rows]

    def get_recipe(self, name: str) -> Recipe | None:
        """Fetch a recipe by unique name, or None."""
        with self.connection() as conn:
            row = conn.execute(
                "SELECT id, name, description, ingredients_json FROM recipes WHERE name = ?",
                (name,),
            ).fetchone()
        return self._row_to_recipe(row) if row else None

    def get_recipe_by_id(self, recipe_id: int) -> Recipe | None:
        """Fetch a recipe by primary key."""
        with self.connection() as conn:
            row = conn.execute(
                "SELECT id, name, description, ingredients_json FROM recipes WHERE id = ?",
                (recipe_id,),
            ).fetchone()
        return self._row_to_recipe(row) if row else None

    def upsert_recipe(self, recipe: Recipe) -> Recipe:
        """Insert or replace a recipe by name. Returns recipe with id set."""
        payload = json.dumps([i.to_dict() for i in recipe.ingredients])
        with self.connection() as conn:
            existing = conn.execute(
                "SELECT id FROM recipes WHERE name = ?", (recipe.name,)
            ).fetchone()
            if existing:
                conn.execute(
                    "UPDATE recipes SET description = ?, ingredients_json = ? WHERE id = ?",
                    (recipe.description, payload, existing["id"]),
                )
                recipe.id = int(existing["id"])
            else:
                cur = conn.execute(
                    "INSERT INTO recipes (name, description, ingredients_json) VALUES (?, ?, ?)",
                    (recipe.name, recipe.description, payload),
                )
                recipe.id = int(cur.lastrowid)
        return recipe

    def delete_recipe(self, name: str) -> bool:
        """Delete recipe by name. Returns True if a row was removed."""
        with self.connection() as conn:
            cur = conn.execute("DELETE FROM recipes WHERE name = ?", (name,))
            return cur.rowcount > 0

    @staticmethod
    def _row_to_recipe(row: sqlite3.Row) -> Recipe:
        ingredients_data = json.loads(row["ingredients_json"] or "[]")
        ingredients = [Ingredient.from_dict(i) for i in ingredients_data]
        return Recipe(
            id=int(row["id"]),
            name=row["name"],
            description=row["description"] or "",
            ingredients=ingredients,
        )

    # ---------------------------------------------------------------- inventory

    def list_inventory(self) -> list[InventoryItem]:
        """Return all inventory items."""
        with self.connection() as conn:
            rows = conn.execute(
                "SELECT id, name, kind, remaining, capacity, unit, station "
                "FROM inventory ORDER BY station, name"
            ).fetchall()
        return [self._row_to_inventory(r) for r in rows]

    def get_inventory(self, name: str) -> InventoryItem | None:
        """Fetch inventory by ingredient name."""
        with self.connection() as conn:
            row = conn.execute(
                "SELECT id, name, kind, remaining, capacity, unit, station "
                "FROM inventory WHERE name = ?",
                (name,),
            ).fetchone()
        return self._row_to_inventory(row) if row else None

    def upsert_inventory(self, item: InventoryItem) -> InventoryItem:
        """Insert or update inventory by name."""
        kind = item.kind.value if isinstance(item.kind, IngredientKind) else item.kind
        with self.connection() as conn:
            existing = conn.execute(
                "SELECT id FROM inventory WHERE name = ?", (item.name,)
            ).fetchone()
            if existing:
                conn.execute(
                    "UPDATE inventory SET kind=?, remaining=?, capacity=?, unit=?, station=? "
                    "WHERE id=?",
                    (kind, item.remaining, item.capacity, item.unit, item.station, existing["id"]),
                )
                item.id = int(existing["id"])
            else:
                cur = conn.execute(
                    "INSERT INTO inventory (name, kind, remaining, capacity, unit, station) "
                    "VALUES (?, ?, ?, ?, ?, ?)",
                    (item.name, kind, item.remaining, item.capacity, item.unit, item.station),
                )
                item.id = int(cur.lastrowid)
        return item

    def adjust_inventory(self, name: str, delta: float) -> InventoryItem | None:
        """Add *delta* to remaining (negative for consumption). Clamps at 0."""
        item = self.get_inventory(name)
        if item is None:
            return None
        item.remaining = max(0.0, item.remaining + delta)
        return self.upsert_inventory(item)

    @staticmethod
    def _row_to_inventory(row: sqlite3.Row) -> InventoryItem:
        return InventoryItem(
            id=int(row["id"]),
            name=row["name"],
            kind=IngredientKind(row["kind"]),
            remaining=float(row["remaining"]),
            capacity=float(row["capacity"]),
            unit=row["unit"] or "g",
            station=int(row["station"]),
        )

    # --------------------------------------------------------------------- logs

    def add_log(
        self,
        recipe_name: str,
        success: bool,
        message: str = "",
        duration_s: float = 0.0,
        steps: Iterable[dict[str, Any]] | None = None,
    ) -> int:
        """Insert a dispense log entry. Returns new row id."""
        steps_json = json.dumps(list(steps or []))
        with self.connection() as conn:
            cur = conn.execute(
                "INSERT INTO logs (recipe_name, success, message, duration_s, steps_json) "
                "VALUES (?, ?, ?, ?, ?)",
                (recipe_name, 1 if success else 0, message, duration_s, steps_json),
            )
            return int(cur.lastrowid)

    def list_logs(self, limit: int = 50) -> list[dict[str, Any]]:
        """Return most recent log entries (newest first)."""
        with self.connection() as conn:
            rows = conn.execute(
                "SELECT id, recipe_name, success, message, duration_s, steps_json, created_at "
                "FROM logs ORDER BY id DESC LIMIT ?",
                (limit,),
            ).fetchall()
        out: list[dict[str, Any]] = []
        for r in rows:
            out.append(
                {
                    "id": int(r["id"]),
                    "recipe_name": r["recipe_name"],
                    "success": bool(r["success"]),
                    "message": r["message"],
                    "duration_s": float(r["duration_s"]),
                    "steps": json.loads(r["steps_json"] or "[]"),
                    "created_at": r["created_at"],
                }
            )
        return out

    def seed_defaults(self) -> None:
        """Insert starter recipe and inventory if the database is empty."""
        if not self.list_recipes():
            self.upsert_recipe(
                Recipe(
                    name="creatine_water",
                    description="3 g creatine + 200 ml water",
                    ingredients=[
                        Ingredient("creatine", IngredientKind.POWDER, 3.0, station=0),
                        Ingredient("water", IngredientKind.WATER, 200.0, station=0),
                    ],
                )
            )
            self.upsert_recipe(
                Recipe(
                    name="creatine_only",
                    description="3 g creatine powder only",
                    ingredients=[
                        Ingredient("creatine", IngredientKind.POWDER, 3.0, station=0),
                    ],
                )
            )
        if not self.list_inventory():
            self.upsert_inventory(
                InventoryItem(
                    name="creatine",
                    kind=IngredientKind.POWDER,
                    remaining=200.0,
                    capacity=250.0,
                    unit="g",
                    station=0,
                )
            )
            self.upsert_inventory(
                InventoryItem(
                    name="water",
                    kind=IngredientKind.WATER,
                    remaining=1500.0,
                    capacity=2000.0,
                    unit="ml",
                    station=0,
                )
            )
