"""FastAPI application factory."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import FastAPI, HTTPException, Request

from dispenser import __version__
from dispenser.api.schemas import (
    DispenseRequest,
    DispenseResponse,
    DispenseStepOut,
    HealthResponse,
    InventoryItemOut,
    LogEntryOut,
    RecipeIn,
    RecipeOut,
)
from dispenser.models import Ingredient, IngredientKind, Recipe


def create_app(runtime: Any | None = None) -> FastAPI:
    """Build the FastAPI app.

    Args:
        runtime: Optional :class:`dispenser.main.DispenserRuntime`. If None,
            a runtime is created lazily on first request (sim-friendly).
    """
    app = FastAPI(
        title="DIY Supplement Dispenser",
        version=__version__,
        description="Phase 1 REST API for powder + water dispensing",
    )
    app.state.runtime = runtime

    def get_runtime() -> Any:
        if app.state.runtime is None:
            from dispenser.main import DispenserRuntime

            app.state.runtime = DispenserRuntime()
        return app.state.runtime

    @app.get("/health", response_model=HealthResponse)
    def health() -> HealthResponse:
        """Liveness / mode probe."""
        rt = get_runtime()
        return HealthResponse(
            status="ok",
            version=__version__,
            mode=rt.mode,
            timestamp=datetime.now(timezone.utc).isoformat(),
        )

    @app.get("/recipes", response_model=list[RecipeOut])
    def list_recipes() -> list[RecipeOut]:
        """List all recipes."""
        rt = get_runtime()
        return [RecipeOut(**r.to_dict()) for r in rt.db.list_recipes()]

    @app.get("/recipes/{name}", response_model=RecipeOut)
    def get_recipe(name: str) -> RecipeOut:
        """Get a recipe by name."""
        rt = get_runtime()
        recipe = rt.db.get_recipe(name)
        if recipe is None:
            raise HTTPException(status_code=404, detail=f"recipe not found: {name}")
        return RecipeOut(**recipe.to_dict())

    @app.post("/recipes", response_model=RecipeOut, status_code=201)
    def create_recipe(body: RecipeIn) -> RecipeOut:
        """Create or update a recipe by name."""
        rt = get_runtime()
        ingredients = [
            Ingredient(
                name=i.name,
                kind=IngredientKind(i.kind),
                amount=i.amount,
                station=i.station,
            )
            for i in body.ingredients
        ]
        recipe = Recipe(name=body.name, description=body.description, ingredients=ingredients)
        saved = rt.db.upsert_recipe(recipe)
        return RecipeOut(**saved.to_dict())

    @app.post("/dispense", response_model=DispenseResponse)
    def dispense(body: DispenseRequest) -> DispenseResponse:
        """Run a full recipe dispense cycle."""
        rt = get_runtime()
        recipe = rt.db.get_recipe(body.recipe)
        if recipe is None:
            raise HTTPException(status_code=404, detail=f"recipe not found: {body.recipe}")
        result = rt.cycle.run_recipe(recipe)
        return DispenseResponse(
            recipe_name=result.recipe_name,
            success=result.success,
            message=result.message,
            duration_s=result.duration_s,
            steps=[DispenseStepOut(**s.to_dict()) for s in result.steps],
            log_id=result.log_id,
        )

    @app.get("/inventory", response_model=list[InventoryItemOut])
    def inventory() -> list[InventoryItemOut]:
        """List inventory levels."""
        rt = get_runtime()
        return [InventoryItemOut(**i.to_dict()) for i in rt.db.list_inventory()]

    @app.get("/logs", response_model=list[LogEntryOut])
    def logs(limit: int = 50) -> list[LogEntryOut]:
        """Recent dispense logs (newest first)."""
        rt = get_runtime()
        limit = max(1, min(int(limit), 500))
        return [LogEntryOut(**row) for row in rt.db.list_logs(limit=limit)]

    @app.get("/")
    def root() -> dict[str, str]:
        return {"service": "dispenser", "docs": "/docs", "health": "/health"}

    return app
