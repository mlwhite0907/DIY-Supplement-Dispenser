"""Full dispense cycle: powders → water → optional mix delay; log to SQLite."""

from __future__ import annotations

import time
from typing import Any

from dispenser.control.powder_dose import PowderDoser
from dispenser.control.water_dose import WaterDoser
from dispenser.db import Database
from dispenser.hardware.base import DigitalSensor
from dispenser.models import (
    CycleResult,
    DispenseResult,
    IngredientKind,
    Recipe,
)


class DispenseCycle:
    """Orchestrate a complete recipe dispense.

    Args:
        powder: Powder dosing controller.
        water: Water dosing controller.
        db: Database for logging and inventory updates.
        config: Full app config (uses ``dosing.cycle``).
        cup_sensor: Optional cup-present interlock.
    """

    def __init__(
        self,
        powder: PowderDoser,
        water: WaterDoser,
        db: Database | None = None,
        config: dict[str, Any] | None = None,
        cup_sensor: DigitalSensor | None = None,
    ) -> None:
        self.powder = powder
        self.water = water
        self.db = db
        self.cup_sensor = cup_sensor
        cfg = config or {}
        cycle = cfg.get("dosing", {}).get("cycle", {}) if "dosing" in cfg else cfg.get("cycle", cfg)
        self.mix_delay_seconds = float(cycle.get("mix_delay_seconds", 1.0))
        self.require_cup = bool(cycle.get("require_cup", True))

    def run_recipe(self, recipe: Recipe) -> CycleResult:
        """Execute all ingredients in *recipe* (powders then water).

        Inventory is decremented on successful steps when a DB is configured.
        """
        t0 = time.monotonic()
        steps: list[DispenseResult] = []

        if self.require_cup and self.cup_sensor is not None and not self.cup_sensor.read():
            result = CycleResult(
                recipe_name=recipe.name,
                steps=[],
                success=False,
                message="cup not present",
                duration_s=time.monotonic() - t0,
            )
            self._log(result)
            return result

        # Powders first
        for ing in recipe.ingredients:
            if ing.kind != IngredientKind.POWDER:
                continue
            step = self.powder.dose(ing.amount, ingredient=ing.name, tare=True)
            steps.append(step)
            if step.success and self.db is not None:
                self.db.adjust_inventory(ing.name, -step.actual)
            if not step.success:
                result = CycleResult(
                    recipe_name=recipe.name,
                    steps=steps,
                    success=False,
                    message=f"powder step failed: {ing.name}: {step.message}",
                    duration_s=time.monotonic() - t0,
                )
                self._log(result)
                return result

        # Water next
        for ing in recipe.ingredients:
            if ing.kind != IngredientKind.WATER:
                continue
            step = self.water.dose(ing.amount, ingredient=ing.name)
            steps.append(step)
            if step.success and self.db is not None:
                self.db.adjust_inventory(ing.name, -step.actual)
            if not step.success:
                result = CycleResult(
                    recipe_name=recipe.name,
                    steps=steps,
                    success=False,
                    message=f"water step failed: {step.message}",
                    duration_s=time.monotonic() - t0,
                )
                self._log(result)
                return result

        # Optional mix delay
        if self.mix_delay_seconds > 0:
            time.sleep(self.mix_delay_seconds)

        result = CycleResult(
            recipe_name=recipe.name,
            steps=steps,
            success=all(s.success for s in steps) if steps else True,
            message="ok" if steps else "empty recipe",
            duration_s=time.monotonic() - t0,
        )
        self._log(result)
        return result

    def dose_powder(self, grams: float, ingredient: str = "powder") -> DispenseResult:
        """Convenience: single powder dose (logged as ad-hoc cycle)."""
        step = self.powder.dose(grams, ingredient=ingredient, tare=True)
        if self.db is not None:
            cycle = CycleResult(
                recipe_name=f"adhoc_powder:{ingredient}",
                steps=[step],
                success=step.success,
                message=step.message,
                duration_s=step.duration_s,
            )
            self._log(cycle)
            if step.success:
                self.db.adjust_inventory(ingredient, -step.actual)
        return step

    def dose_water(self, ml: float, ingredient: str = "water") -> DispenseResult:
        """Convenience: single water dose."""
        step = self.water.dose(ml, ingredient=ingredient)
        if self.db is not None:
            cycle = CycleResult(
                recipe_name=f"adhoc_water:{ingredient}",
                steps=[step],
                success=step.success,
                message=step.message,
                duration_s=step.duration_s,
            )
            self._log(cycle)
            if step.success:
                self.db.adjust_inventory(ingredient, -step.actual)
        return step

    def _log(self, result: CycleResult) -> None:
        if self.db is None:
            return
        log_id = self.db.add_log(
            recipe_name=result.recipe_name,
            success=result.success,
            message=result.message,
            duration_s=result.duration_s,
            steps=[s.to_dict() for s in result.steps],
        )
        result.log_id = log_id
