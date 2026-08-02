"""FastAPI integration tests (simulation mode)."""

from __future__ import annotations

import os
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

# Force sim before importing runtime
os.environ["DISPENSER_SIM"] = "1"

from dispenser.api.app import create_app  # noqa: E402
from dispenser.config import load_config  # noqa: E402
from dispenser.main import DispenserRuntime  # noqa: E402


@pytest.fixture()
def client(tmp_path: Path) -> TestClient:
    cfg = load_config()
    cfg["hardware"]["mode"] = "sim"
    cfg["database"]["path"] = str(tmp_path / "api.db")
    cfg.setdefault("dosing", {}).setdefault("cycle", {})["mix_delay_seconds"] = 0.0
    cfg["dosing"]["powder"]["settle_seconds"] = 0.0
    cfg["dosing"]["powder"]["final_settle_seconds"] = 0.0
    cfg["dosing"]["powder"]["burst_seconds"] = 0.08
    cfg["dosing"]["powder"]["timeout_seconds"] = 20.0
    cfg["dosing"]["powder"]["tolerance_g"] = 0.15
    cfg["hardware"]["scale"]["sim_noise_g"] = 0.0
    # Faster sim feed
    cfg["dosing"]["powder"]["sim_grams_per_second"] = 5.0

    rt = DispenserRuntime(config=cfg, seed=True)
    # Re-bind sim rate from config into scale
    scale = rt.hardware["scale"]
    if hasattr(scale, "grams_per_second"):
        scale.grams_per_second = 5.0

    app = create_app(runtime=rt)
    with TestClient(app) as c:
        yield c
    rt.close()


def test_health(client: TestClient) -> None:
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert body["mode"] == "sim"
    assert "version" in body


def test_list_recipes(client: TestClient) -> None:
    r = client.get("/recipes")
    assert r.status_code == 200
    names = {x["name"] for x in r.json()}
    assert "creatine_water" in names


def test_create_recipe(client: TestClient) -> None:
    r = client.post(
        "/recipes",
        json={
            "name": "vitc_water",
            "description": "test",
            "ingredients": [
                {"name": "vitamin_c", "kind": "powder", "amount": 1.0},
                {"name": "water", "kind": "water", "amount": 100.0},
            ],
        },
    )
    assert r.status_code == 201
    assert r.json()["name"] == "vitc_water"
    r2 = client.get("/recipes/vitc_water")
    assert r2.status_code == 200


def test_inventory_and_logs(client: TestClient) -> None:
    inv = client.get("/inventory")
    assert inv.status_code == 200
    assert len(inv.json()) >= 1

    logs = client.get("/logs")
    assert logs.status_code == 200
    assert isinstance(logs.json(), list)


def test_dispense_recipe(client: TestClient) -> None:
    # Use creatine_only for simpler powder path if present, else creatine_water
    recipes = {x["name"] for x in client.get("/recipes").json()}
    name = "creatine_only" if "creatine_only" in recipes else "creatine_water"
    r = client.post("/dispense", json={"recipe": name})
    assert r.status_code == 200
    body = r.json()
    assert body["success"] is True, body
    assert body["log_id"] is not None

    logs = client.get("/logs?limit=5").json()
    assert len(logs) >= 1


def test_dispense_missing_recipe(client: TestClient) -> None:
    r = client.post("/dispense", json={"recipe": "no_such_recipe"})
    assert r.status_code == 404


def test_create_recipe_invalid_kind(client: TestClient) -> None:
    r = client.post(
        "/recipes",
        json={
            "name": "bad_kind",
            "description": "invalid kind",
            "ingredients": [
                {"name": "x", "kind": "not_a_kind", "amount": 1.0},
            ],
        },
    )
    assert r.status_code == 422
    detail = r.json()["detail"]
    assert "invalid ingredient kind" in str(detail).lower() or "not_a_kind" in str(detail)


def test_dispense_busy_returns_409(client: TestClient) -> None:
    # Hold the cycle lock so POST /dispense (blocking=False) cannot acquire → 409
    app = client.app
    rt = app.state.runtime
    assert rt is not None
    assert rt.cycle._lock.acquire(blocking=False) is True
    try:
        recipes = {x["name"] for x in client.get("/recipes").json()}
        name = "creatine_only" if "creatine_only" in recipes else "creatine_water"
        r = client.post("/dispense", json={"recipe": name})
        assert r.status_code == 409
        detail = str(r.json().get("detail", "")).lower()
        assert "progress" in detail or "busy" in detail or "already" in detail
    finally:
        rt.cycle._lock.release()


def test_api_token_required_on_mutate(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("DISPENSER_SIM", "1")
    monkeypatch.setenv("DISPENSER_API_TOKEN", "secret-token")

    cfg = load_config()
    cfg["hardware"]["mode"] = "sim"
    cfg["database"]["path"] = str(tmp_path / "token.db")
    cfg.setdefault("api", {})["token"] = ""  # env should still win
    cfg.setdefault("dosing", {}).setdefault("cycle", {})["mix_delay_seconds"] = 0.0

    rt = DispenserRuntime(config=cfg, seed=True)
    app = create_app(runtime=rt)
    try:
        with TestClient(app) as c:
            # Health stays open
            assert c.get("/health").status_code == 200

            # Mutating without token → 401
            r = c.post(
                "/recipes",
                json={
                    "name": "tok_test",
                    "ingredients": [{"name": "water", "kind": "water", "amount": 10.0}],
                },
            )
            assert r.status_code == 401

            # With token → 201
            r2 = c.post(
                "/recipes",
                headers={"X-API-Token": "secret-token"},
                json={
                    "name": "tok_test",
                    "ingredients": [{"name": "water", "kind": "water", "amount": 10.0}],
                },
            )
            assert r2.status_code == 201
    finally:
        rt.close()
