"""Configuration loading from YAML with environment overrides."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import yaml

# software/ package root (…/software)
_SOFTWARE_ROOT = Path(__file__).resolve().parents[2]
_DEFAULT_CONFIG = _SOFTWARE_ROOT / "config" / "default.yaml"


def default_config_path() -> Path:
    """Return the path to the bundled default YAML config."""
    return _DEFAULT_CONFIG


def is_sim_mode(cfg: dict[str, Any] | None = None) -> bool:
    """Return True if simulation hardware should be used.

    Precedence:
      1. Environment ``DISPENSER_SIM`` truthy (1/true/yes/on)
      2. ``hardware.mode`` in config equals ``\"sim\"`` (case-insensitive)
      3. Default True when no config provided (safe for Mac dev)
    """
    env = os.environ.get("DISPENSER_SIM", "").strip().lower()
    if env in ("1", "true", "yes", "on"):
        return True
    if env in ("0", "false", "no", "off"):
        # Explicit disable of env force; still honour config
        pass
    if cfg is None:
        return True
    mode = str(cfg.get("hardware", {}).get("mode", "sim")).lower()
    return mode == "sim"


def deep_merge(base: dict[str, Any], override: dict[str, Any]) -> dict[str, Any]:
    """Recursively merge *override* into a copy of *base*."""
    result = dict(base)
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = deep_merge(result[key], value)
        else:
            result[key] = value
    return result


def load_config(path: str | Path | None = None) -> dict[str, Any]:
    """Load YAML config, optionally merging a user file over defaults.

    Args:
        path: Optional path to a YAML file. If None, uses
            ``DISPENSER_CONFIG`` env var or the bundled ``config/default.yaml``.

    Returns:
        Nested configuration dictionary.
    """
    default_path = default_config_path()
    with open(default_path, encoding="utf-8") as fh:
        cfg: dict[str, Any] = yaml.safe_load(fh) or {}

    user_path: Path | None = None
    if path is not None:
        user_path = Path(path)
    else:
        env_path = os.environ.get("DISPENSER_CONFIG")
        if env_path:
            user_path = Path(env_path)

    if user_path is not None and user_path.is_file() and user_path.resolve() != default_path.resolve():
        with open(user_path, encoding="utf-8") as fh:
            user_cfg = yaml.safe_load(fh) or {}
        cfg = deep_merge(cfg, user_cfg)

    # Force sim when env says so
    if is_sim_mode(cfg) or os.environ.get("DISPENSER_SIM", "").strip().lower() in (
        "1",
        "true",
        "yes",
        "on",
    ):
        cfg.setdefault("hardware", {})["mode"] = "sim"

    # Resolve relative database path against software root
    db_path = cfg.get("database", {}).get("path", "data/dispenser.db")
    p = Path(db_path)
    if not p.is_absolute():
        p = _SOFTWARE_ROOT / p
    cfg.setdefault("database", {})["path"] = str(p)

    return cfg


def resolve_db_path(cfg: dict[str, Any]) -> Path:
    """Return absolute Path to the SQLite database file."""
    return Path(cfg["database"]["path"])
