"""Full dispense cycle: powders → water → optional mix delay; log to SQLite."""

from __future__ import annotations

import threading
import time
from typing import Any, Callable

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


class DispenseBusyError(RuntimeError):
    """Raised when a non-blocking dispense is requested while another is running."""


class DispenseCycle:
    """Orchestrate a complete recipe dispense.

    Concurrent dispenses are serialized with a process-local lock.

    Args:
        powder: Powder dosing controller.
        water: Water dosing controller.
        db: Database for logging and inventory updates.
        config: Full app config (uses ``dosing.cycle``).
        cup_sensor: Optional cup-present interlock.
        estop_sensor: Optional E-stop (True when pressed).
        all_stop: Optional emergency stop callback (motors/pump off).
    """

    def __init__(
        self,
        powder: PowderDoser,
        water: WaterDoser,
        db: Database | None = None,
        config: dict[str, Any] | None = None,
        cup_sensor: DigitalSensor | None = None,
        estop_sensor: DigitalSensor | None = None,
        all_stop: Callable[[], None] | None = None,
    ) -> None:
        self.powder = powder
        self.water = water
        self.db = db
        self.cup_sensor = cup_sensor
        self.estop_sensor = estop_sensor
        self.all_stop = all_stop
        self._lock = threading.Lock()
        cfg = config or {}
        cycle = cfg.get("dosing", {}).get("cycle", {}) if "dosing" in cfg else cfg.get("cycle", cfg)
        self.mix_delay_seconds = float(cycle.get("mix_delay_seconds", 1.0))
        self.require_cup = bool(cycle.get("require_cup", True))

    @property
    def busy(self) -> bool:
        """True if a dispense currently holds the cycle lock."""
        return self._lock.locked()

    def try_acquire(self) -> bool:
        """Non-blocking lock acquire for external busy checks. Pair with :meth:`release`."""
        return self._lock.acquire(blocking=False)

    def release(self) -> None:
        """Release the cycle lock acquired via :meth:`try_acquire`."""
        self._lock.release()

    def _estop_pressed(self) -> bool:
        if self.estop_sensor is None:
            return False
        try:
            return bool(self.estop_sensor.read())
        except Exception:
            return False

    def _fail_estop(self, recipe_name: str, t0: float, steps: list[DispenseResult] | None = None) -> CycleResult:
        if self.all_stop is not None:
            try:
                self.all_stop()
            except Exception:
                pass
        result = CycleResult(
            recipe_name=recipe_name,
            steps=list(steps or []),
            success=False,
            message="estop",
            duration_s=time.monotonic() - t0,
        )
        self._log(result)
        return result

    def _check_cup(self) -> str | None:
        """Return error message if cup interlock fails, else None."""
        if self.require_cup and self.cup_sensor is not None and not self.cup_sensor.read():
            return "cup not present"
        return None

    def run_recipe(self, recipe: Recipe, *, blocking: bool = True) -> CycleResult:
        """Execute all ingredients in *recipe* (powders then water).

        Inventory is decremented on successful steps when a DB is configured.

        Args:
            recipe: Recipe to run.
            blocking: If True (default), wait for the cycle lock. If False,
                raise :class:`DispenseBusyError` when another dispense holds it.
        """
        if blocking:
            with self._lock:
                return self._run_recipe_locked(recipe)
        if not self._lock.acquire(blocking=False):
            raise DispenseBusyError("dispense already in progress")
        try:
            return self._run_recipe_locked(recipe)
        finally:
            self._lock.release()

    def _run_recipe_locked(self, recipe: Recipe) -> CycleResult:
        t0 = time.monotonic()
        steps: list[DispenseResult] = []

        if self._estop_pressed():
            return self._fail_estop(recipe.name, t0)

        cup_err = self._check_cup()
        if cup_err is not None:
            result = CycleResult(
                recipe_name=recipe.name,
                steps=[],
                success=False,
                message=cup_err,
                duration_s=time.monotonic() - t0,
            )
            self._log(result)
            return result

        # Pills are Phase 2 — fail early if any pill ingredient present
        for ing in recipe.ingredients:
            if ing.kind == IngredientKind.PILL:
                result = CycleResult(
                    recipe_name=recipe.name,
                    steps=[],
                    success=False,
                    message="pill dispensing not implemented (Phase 2)",
                    duration_s=time.monotonic() - t0,
                )
                self._log(result)
                return result

        powder_ings = [i for i in recipe.ingredients if i.kind == IngredientKind.POWDER]
        water_ings = [i for i in recipe.ingredients if i.kind == IngredientKind.WATER]

        # Empty recipe (no powder/water steps)
        if not powder_ings and not water_ings:
            result = CycleResult(
                recipe_name=recipe.name,
                steps=[],
                success=False,
                message="empty recipe",
                duration_s=time.monotonic() - t0,
            )
            self._log(result)
            return result

        # Powders first
        for ing in powder_ings:
            if self._estop_pressed():
                return self._fail_estop(recipe.name, t0, steps)
            step = self.powder.dose(ing.amount, ingredient=ing.name, tare=True)
            steps.append(step)
            if step.success and self.db is not None:
                self.db.adjust_inventory(ing.name, -step.actual)
            if not step.success:
                # Surface estop message from doser as cycle message "estop"
                msg = step.message
                if msg == "estop" or msg.lower().startswith("estop"):
                    return self._fail_estop(recipe.name, t0, steps)
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
        for ing in water_ings:
            if self._estop_pressed():
                return self._fail_estop(recipe.name, t0, steps)
            step = self.water.dose(ing.amount, ingredient=ing.name)
            steps.append(step)
            if step.success and self.db is not None:
                self.db.adjust_inventory(ing.name, -step.actual)
            if not step.success:
                msg = step.message
                if msg == "estop" or msg.lower().startswith("estop"):
                    return self._fail_estop(recipe.name, t0, steps)
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

        if self._estop_pressed():
            return self._fail_estop(recipe.name, t0, steps)

        result = CycleResult(
            recipe_name=recipe.name,
            steps=steps,
            success=all(s.success for s in steps),
            message="ok",
            duration_s=time.monotonic() - t0,
        )
        self._log(result)
        return result

    def dose_powder(self, grams: float, ingredient: str = "powder") -> DispenseResult:
        """Convenience: single powder dose (logged as ad-hoc cycle)."""
        with self._lock:
            t0 = time.monotonic()
            if self._estop_pressed():
                if self.all_stop is not None:
                    try:
                        self.all_stop()
                    except Exception:
                        pass
                step = DispenseResult(
                    target=float(grams),
                    actual=0.0,
                    error_g=-float(grams),
                    success=False,
                    message="estop",
                    ingredient=ingredient,
                    kind="powder",
                    duration_s=time.monotonic() - t0,
                )
                if self.db is not None:
                    self._log(
                        CycleResult(
                            recipe_name=f"adhoc_powder:{ingredient}",
                            steps=[step],
                            success=False,
                            message="estop",
                            duration_s=step.duration_s,
                        )
                    )
                return step

            cup_err = self._check_cup()
            if cup_err is not None:
                step = DispenseResult(
                    target=float(grams),
                    actual=0.0,
                    error_g=-float(grams),
                    success=False,
                    message=cup_err,
                    ingredient=ingredient,
                    kind="powder",
                    duration_s=time.monotonic() - t0,
                )
                if self.db is not None:
                    self._log(
                        CycleResult(
                            recipe_name=f"adhoc_powder:{ingredient}",
                            steps=[step],
                            success=False,
                            message=cup_err,
                            duration_s=step.duration_s,
                        )
                    )
                return step

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
        with self._lock:
            t0 = time.monotonic()
            if self._estop_pressed():
                if self.all_stop is not None:
                    try:
                        self.all_stop()
                    except Exception:
                        pass
                step = DispenseResult(
                    target=float(ml),
                    actual=0.0,
                    error_g=-float(ml),
                    success=False,
                    message="estop",
                    ingredient=ingredient,
                    kind="water",
                    duration_s=time.monotonic() - t0,
                )
                if self.db is not None:
                    self._log(
                        CycleResult(
                            recipe_name=f"adhoc_water:{ingredient}",
                            steps=[step],
                            success=False,
                            message="estop",
                            duration_s=step.duration_s,
                        )
                    )
                return step

            cup_err = self._check_cup()
            if cup_err is not None:
                step = DispenseResult(
                    target=float(ml),
                    actual=0.0,
                    error_g=-float(ml),
                    success=False,
                    message=cup_err,
                    ingredient=ingredient,
                    kind="water",
                    duration_s=time.monotonic() - t0,
                )
                if self.db is not None:
                    self._log(
                        CycleResult(
                            recipe_name=f"adhoc_water:{ingredient}",
                            steps=[step],
                            success=False,
                            message=cup_err,
                            duration_s=step.duration_s,
                        )
                    )
                return step

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
