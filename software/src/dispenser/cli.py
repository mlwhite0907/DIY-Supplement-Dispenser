"""Command-line interface: ``python -m dispenser …`` / ``dispenser …``."""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Optional

import typer

from dispenser import __version__

app = typer.Typer(
    name="dispenser",
    help="DIY Supplement Dispenser control CLI (Phase 1).",
    add_completion=False,
    no_args_is_help=True,
)


def _ensure_sim_default() -> None:
    """Default to sim on non-Pi if DISPENSER_SIM unset (Mac-friendly)."""
    if "DISPENSER_SIM" not in os.environ:
        # Leave config-driven; default.yaml is already mode: sim
        pass


def _runtime(config: Optional[Path]) -> "DispenserRuntime":  # noqa: F821
    from dispenser.main import DispenserRuntime

    _ensure_sim_default()
    return DispenserRuntime(config_path=config)


def _persist_calibration(rt: Any, config_opt: Optional[Path]) -> Path:
    """Write scale/pump factors back to user config or ``config/local.yaml``.

    Prefer ``--config`` path when given; otherwise merge into
    ``software/config/local.yaml`` (gitignored).
    """
    from dispenser.config import deep_merge, dump_yaml, local_config_path

    if config_opt is not None:
        target = Path(config_opt)
    else:
        target = local_config_path()

    existing: dict[str, Any] = {}
    if target.is_file():
        import yaml

        with open(target, encoding="utf-8") as fh:
            existing = yaml.safe_load(fh) or {}
        if not isinstance(existing, dict):
            existing = {}

    # Only persist calibration-related hardware keys into the target file
    cal_slice = rt.calibration.apply_to_config_dict({})
    merged = deep_merge(existing, cal_slice)
    dump_yaml(target, merged)
    return target


@app.callback()
def main_callback(
    ctx: typer.Context,
    config: Optional[Path] = typer.Option(
        None,
        "--config",
        "-c",
        help="Path to YAML config (default: config/default.yaml + config/local.yaml)",
        exists=False,
    ),
    sim: bool = typer.Option(
        False,
        "--sim",
        help="Force simulation mode (sets DISPENSER_SIM=1)",
    ),
) -> None:
    """DIY Supplement Dispenser."""
    if sim:
        os.environ["DISPENSER_SIM"] = "1"
    ctx.ensure_object(dict)
    ctx.obj["config"] = config


@app.command("version")
def version_cmd() -> None:
    """Print package version."""
    typer.echo(__version__)


@app.command("calibrate")
def calibrate_cmd(
    ctx: typer.Context,
    known_grams: Optional[float] = typer.Option(
        None,
        "--known-grams",
        help="Reference mass on scale after tare (updates scale_factor on HX711)",
    ),
    pump_seconds: Optional[float] = typer.Option(
        None,
        "--pump-seconds",
        help="Run pump this many seconds for flow check",
    ),
    measured_ml: Optional[float] = typer.Option(
        None,
        "--measured-ml",
        help="Measured volume from pump run (sets ml_per_second). Required on Pi.",
    ),
    tare: bool = typer.Option(True, "--tare/--no-tare", help="Tare scale first"),
    persist: bool = typer.Option(
        True,
        "--persist/--no-persist",
        help="Write factors to --config or config/local.yaml after success",
    ),
) -> None:
    """Calibration helpers for scale and pump.

    Successful scale/pump calibrations are written to the user ``--config``
    file if provided, otherwise to ``config/local.yaml`` (merged on load).
    """
    config_opt: Optional[Path] = ctx.obj.get("config")
    rt = _runtime(config_opt)
    did_calibrate = False
    try:
        if tare:
            rt.calibration.tare_scale()
            typer.echo("Scale tared.")
        if known_grams is not None:
            result = rt.calibration.calibrate_scale_with_known_mass(known_grams)
            typer.echo(
                f"Scale calibration: factor={result.scale_factor:.6f} ({result.message})"
            )
            did_calibrate = True
        if pump_seconds is not None:
            mode = str(rt.mode).lower()
            if measured_ml is None:
                if mode == "pi":
                    typer.echo(
                        "ERROR: --measured-ml is required for real pump calibration "
                        "on Pi hardware (open-loop flow depends on measured volume).",
                        err=True,
                    )
                    raise typer.Exit(code=2)
                typer.echo(
                    "Note: no --measured-ml; using pump-reported volume "
                    "(sim estimate-only — not a real flow calibration)."
                )
            result = rt.calibration.calibrate_pump(pump_seconds, measured_ml)
            typer.echo(
                f"Pump calibration: {result.ml_per_second:.3f} ml/s "
                f"(ran {result.run_seconds}s → {result.measured_ml:.1f} ml) "
                f"[{result.message}]"
            )
            did_calibrate = True
        if known_grams is None and pump_seconds is None:
            readings = rt.calibration.read_scale_loop(seconds=1.0, interval=0.2)
            typer.echo(f"Mode={rt.mode}; scale samples: {[round(r, 3) for r in readings]}")
            typer.echo("Hint: --known-grams N  or  --pump-seconds S [--measured-ml M]")
        elif did_calibrate and persist:
            path = _persist_calibration(rt, config_opt)
            typer.echo(f"Calibration saved to {path}")
            # Also update in-memory runtime config for this process
            rt.calibration.apply_to_config_dict(rt.config)
    finally:
        rt.close()


@app.command("dose-powder")
def dose_powder_cmd(
    ctx: typer.Context,
    grams: float = typer.Option(..., "--grams", "-g", help="Target grams"),
    ingredient: str = typer.Option("powder", "--ingredient", "-i"),
) -> None:
    """Closed-loop powder dose."""
    rt = _runtime(ctx.obj.get("config"))
    try:
        result = rt.cycle.dose_powder(grams, ingredient=ingredient)
        typer.echo(json.dumps(result.to_dict(), indent=2))
        raise typer.Exit(code=0 if result.success else 1)
    finally:
        rt.close()


@app.command("dose-water")
def dose_water_cmd(
    ctx: typer.Context,
    ml: float = typer.Option(..., "--ml", "-m", help="Target millilitres"),
) -> None:
    """Timed (open-loop) water dose using calibrated ml/s."""
    rt = _runtime(ctx.obj.get("config"))
    try:
        result = rt.cycle.dose_water(ml)
        typer.echo(json.dumps(result.to_dict(), indent=2))
        raise typer.Exit(code=0 if result.success else 1)
    finally:
        rt.close()


@app.command("run-recipe")
def run_recipe_cmd(
    ctx: typer.Context,
    name: str = typer.Argument(..., help="Recipe name (e.g. creatine_water)"),
) -> None:
    """Run a full recipe from the database."""
    rt = _runtime(ctx.obj.get("config"))
    try:
        recipe = rt.db.get_recipe(name)
        if recipe is None:
            typer.echo(f"Recipe not found: {name}", err=True)
            names = [r.name for r in rt.db.list_recipes()]
            typer.echo(f"Available: {', '.join(names) or '(none)'}", err=True)
            raise typer.Exit(code=2)
        result = rt.cycle.run_recipe(recipe)
        typer.echo(json.dumps(result.to_dict(), indent=2))
        raise typer.Exit(code=0 if result.success else 1)
    finally:
        rt.close()


@app.command("serve")
def serve_cmd(
    ctx: typer.Context,
    host: Optional[str] = typer.Option(None, "--host", help="Bind host (default: 127.0.0.1)"),
    port: Optional[int] = typer.Option(None, "--port", "-p", help="Bind port"),
) -> None:
    """Start the FastAPI server (uvicorn).

    Default bind is localhost (127.0.0.1). Set ``api.token`` or
    ``DISPENSER_API_TOKEN`` to require auth on POST /dispense and POST /recipes.
    Lifespan closes the runtime (GPIO/hardware) on shutdown.
    """
    import uvicorn

    from dispenser.api.app import create_app
    from dispenser.main import DispenserRuntime

    config_path = ctx.obj.get("config")
    rt = DispenserRuntime(config_path=config_path)
    api_cfg = rt.config.get("api", {})
    bind_host = host or str(api_cfg.get("host", "127.0.0.1"))
    bind_port = int(port or api_cfg.get("port", 8000))
    fastapi_app = create_app(runtime=rt)
    token = str(api_cfg.get("token", "") or "").strip() or os.environ.get(
        "DISPENSER_API_TOKEN", ""
    )
    auth_note = "token required" if token else "token disabled"
    typer.echo(
        f"Serving dispenser API on http://{bind_host}:{bind_port} "
        f"(mode={rt.mode}, {auth_note})"
    )
    uvicorn.run(fastapi_app, host=bind_host, port=bind_port, log_level="info")


@app.command("list-recipes")
def list_recipes_cmd(ctx: typer.Context) -> None:
    """List recipes in the database."""
    rt = _runtime(ctx.obj.get("config"))
    try:
        for r in rt.db.list_recipes():
            typer.echo(f"{r.name}: {r.description or '(no description)'}")
            for ing in r.ingredients:
                typer.echo(f"  - {ing.kind.value} {ing.name}: {ing.amount}")
    finally:
        rt.close()


if __name__ == "__main__":
    app()
