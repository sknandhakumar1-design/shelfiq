"""
ShelfIQ Phase 2 — API Tests
Tests for GET /health and POST /predict endpoints.
"""

import pytest
import pytest_asyncio
import httpx
from httpx import ASGITransport

# Import the FastAPI app — model loads on startup via lifespan
from api.main import app, _load_model


# ─── Fixtures ────────────────────────────────────────────────────────────────
@pytest.fixture(scope="module")
def valid_predict_payload():
    return {
        "store_nbr": 1,
        "item_nbr": 103665,
        "date": "2017-08-15",
        "lag_1": 5.0,
        "lag_7": 4.5,
        "lag_14": 4.0,
        "rolling_mean_7": 4.8,
        "rolling_mean_14": 4.5,
        "rolling_mean_30": 4.2,
    }


# ─── Tests ───────────────────────────────────────────────────────────────────
# Manually load the model once for the test session
_load_model()

@pytest.mark.anyio
async def test_health_endpoint():
    """GET /health should return 200 with model_loaded=True."""
    async with httpx.AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.get("/health")

    assert resp.status_code == 200, f"Expected 200, got {resp.status_code}: {resp.text}"
    data = resp.json()
    assert data["model_loaded"] is True, (
        f"model_loaded is False. model_path={data.get('model_path')} "
        f"— ensure champion_model.pkl exists and was saved with joblib."
    )
    assert data["status"] == "ok"
    assert "timestamp" in data


@pytest.mark.anyio
async def test_predict_endpoint(valid_predict_payload):
    """POST /predict with valid input should return predicted_sales >= 0."""
    async with httpx.AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        resp = await client.post("/predict", json=valid_predict_payload)

    assert resp.status_code == 200, f"Expected 200, got {resp.status_code}: {resp.text}"
    data = resp.json()
    assert "predicted_sales" in data, "Response missing 'predicted_sales'"
    assert "model_version" in data, "Response missing 'model_version'"
    assert isinstance(data["predicted_sales"], float), (
        f"predicted_sales should be float, got {type(data['predicted_sales'])}"
    )
    assert data["predicted_sales"] >= 0.0, (
        f"predicted_sales should be >= 0, got {data['predicted_sales']}"
    )


@pytest.mark.anyio
async def test_predict_invalid_input():
    """POST /predict with missing required fields should return 422."""
    async with httpx.AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # Missing all lag/rolling fields
        resp = await client.post("/predict", json={
            "store_nbr": 1,
            "item_nbr": 103665,
            "date": "2017-08-15",
        })

    assert resp.status_code == 422, (
        f"Expected 422 for missing fields, got {resp.status_code}"
    )


@pytest.mark.anyio
async def test_predict_negative_lags():
    """POST /predict with all lag values = 0.0 should still return 200."""
    payload = {
        "store_nbr": 1,
        "item_nbr": 103665,
        "date": "2017-01-01",
        "lag_1": 0.0,
        "lag_7": 0.0,
        "lag_14": 0.0,
        "rolling_mean_7": 0.0,
        "rolling_mean_14": 0.0,
        "rolling_mean_30": 0.0,
    }
    async with httpx.AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        resp = await client.post("/predict", json=payload)

    assert resp.status_code == 200, (
        f"Expected 200 for zero lags, got {resp.status_code}: {resp.text}"
    )
    data = resp.json()
    assert data["predicted_sales"] >= 0.0
