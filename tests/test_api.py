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
    """GET /health should return 200 even if model is not loaded (status degraded)."""
    async with httpx.AsyncClient(app=app, base_url="http://test") as client:
        resp = await client.get("/health")
    
    assert resp.status_code == 200, f"Expected 200, got {resp.status_code}: {resp.text}"
    data = resp.json()
    assert data["status"] in ["ok", "degraded"]
    assert "model_loaded" in data
    assert "timestamp" in data


@pytest.mark.anyio
async def test_predict_endpoint(valid_predict_payload):
    """POST /predict should return 200 (OK) or 503 (Model Not Loaded)."""
    async with httpx.AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        resp = await client.post("/predict", json=valid_predict_payload)

    # In CI, the model file is missing so we expect 503. Locally we expect 200.
    assert resp.status_code in [200, 503], f"Expected 200 or 503, got {resp.status_code}: {resp.text}"
    
    if resp.status_code == 200:
        data = resp.json()
        assert "predicted_sales" in data
        assert isinstance(data["predicted_sales"], float)
        assert data["predicted_sales"] >= 0.0


@pytest.mark.anyio
async def test_predict_invalid_input():
    """POST /predict with missing required fields should strictly return 422 (Schema error)."""
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
    """POST /predict with zero values should return 200 (OK) or 503 (Model Not Loaded)."""
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

    assert resp.status_code in [200, 503], f"Expected 200 or 503, got {resp.status_code}: {resp.text}"
    
    if resp.status_code == 200:
        data = resp.json()
        assert data["predicted_sales"] >= 0.0
