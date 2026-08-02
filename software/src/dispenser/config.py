"""Configuration loading from YAML with environment overrides."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import yaml

# Package directory (…/dispenser)
_PACKAGE_DIR = Path(__file__).resolve().parent


def software_root() -> Path:
    """Best-effort path to the ``software/`` tree (config/, data/, etc.).

    Walks parents of this module looking for ``config/default.yaml`` or a
    ``config/`` directory. Falls back to ``parents[2]`` (editable src layout).
    """
    for parent in _PACKAGE_DIR.parents:
        if (parent / "config" / "default.yaml").is_file():
            return parent
        if (parent / "config").is_dir() and (parent / "pyproject.toml").is_file():
            return parent
    # Editable install: software/src/dispenser/config.py → parents[2] = software/
    return _PACKAGE_DIR.parents[2]


def _bundled_default_yaml() -> Path | None:
    """Return path to package-bundled ``default_config.yaml`` if present."""
    candidate = _PACKAGE_DIR / "default_config.yaml"
    if candidate.is_file():
        return candidate
    try:
        import importlib.resources as resources

        ref = resources.files("dispenser").joinpath("default_config.yaml")
        # Traversable may be in a zip; prefer on-disk path when available
        if hasattr(ref, "is_file") and ref.is_file():  # type: ignore[attr-defined]
            return Path(str(ref))
    except Exception:
        pass
    return None


def default_config_path() -> Path:
    """Resolve path to the default YAML config.

    Search order:
      1. ``DISPENSER_CONFIG`` env var (if set and file exists)
      2. ``software/config/default.yaml`` relative to package parents
      3. Package data ``dispenser/default_config.yaml`` (pip install fallback)
    """
    env = os.environ.get("DISPENSER_CONFIG", "").strip()
    if env:
        p = Path(env)
        if p.is_file():
            return p

    root = software_root()
    tree_default = root / "config" / "default.yaml"
    if tree_default.is_file():
        return tree_default

    # Also try common relative locations from CWD
    cwd_default = Path.cwd() / "config" / "default.yaml"
    if cwd_default.is_file():
        return cwd_default

    bundled = _bundled_default_yaml()
    if bundled is not None:
        return bundled

    # Last resort: expected tree path (may raise on open)
    return tree_default


def local_config_path() -> Path:
    """Path for gitignored local calibration overrides (``config/local.yaml``)."""
    return software_root() / "config" / "local.yaml"


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


def _load_yaml(path: Path) -> dict[str, Any]:
    with open(path, encoding="utf-8") as fh:
        data = yaml.safe_load(fh) or {}
    if not isinstance(data, dict):
        raise ValueError(f"Config root must be a mapping: {path}")
    return data


def dump_yaml(path: Path, data: dict[str, Any]) -> None:
    """Write *data* as YAML to *path* (creates parent dirs)."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        yaml.safe_dump(data, fh, default_flow_style=False, sort_keys=False)


def load_config(path: str | Path | None = None) -> dict[str, Any]:
    """Load YAML config, merging defaults → local.yaml → user file.

    Args:
        path: Optional path to a YAML file. If None, uses
            ``DISPENSER_CONFIG`` env var (as a user override after defaults)
            when it was not already consumed as the default file itself.

    Merge order:
      1. Bundled / tree ``default.yaml``
      2. ``config/local.yaml`` (gitignored calibration overrides) if present
      3. Explicit *path* or ``DISPENSER_CONFIG`` user file (if different from default)

    Returns:
        Nested configuration dictionary.
    """
    default_path = default_config_path()
    cfg = _load_yaml(default_path)

    # Merge gitignored local overrides (calibration factors, etc.)
    local_path = local_config_path()
    if local_path.is_file() and local_path.resolve() != default_path.resolve():
        cfg = deep_merge(cfg, _load_yaml(local_path))

    user_path: Path | None = None
    if path is not None:
        user_path = Path(path)
    else:
        env_path = os.environ.get("DISPENSER_CONFIG", "").strip()
        if env_path:
            candidate = Path(env_path)
            # If DISPENSER_CONFIG was already used as the default file, skip re-merge
            if candidate.resolve() != default_path.resolve():
                user_path = candidate

    if user_path is not None and user_path.is_file() and user_path.resolve() != default_path.resolve():
        cfg = deep_merge(cfg, _load_yaml(user_path))

    # Force sim when env says so
    if is_sim_mode(cfg) or os.environ.get("DISPENSER_SIM", "").strip().lower() in (
        "1",
        "true",
        "yes",
        "on",
    ):
        cfg.setdefault("hardware", {})["mode"] = "sim"

    # Resolve relative database path against software root
    root = software_root()
    db_path = cfg.get("database", {}).get("path", "data/dispenser.db")
    p = Path(db_path)
    if not p.is_absolute():
        p = root / p
    cfg.setdefault("database", {})["path"] = str(p)

    return cfg


def resolve_db_path(cfg: dict[str, Any]) -> Path:
    """Return absolute Path to the SQLite database file."""
    return Path(cfg["database"]["path"])


def api_token_from_config(cfg: dict[str, Any] | None = None) -> str:
    """Return configured API token (env ``DISPENSER_API_TOKEN`` wins if set)."""
    env = os.environ.get("DISPENSER_API_TOKEN")
    if env is not None and env != "":
        return env.strip()
    if cfg is None:
        return ""
    return str(cfg.get("api", {}).get("token", "") or "").strip()
