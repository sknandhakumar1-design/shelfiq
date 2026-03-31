"""
ShelfIQ FastAPI Inference Server
Serves demand forecasting predictions from the champion LightGBM model.
"""

import joblib
import os
import logging
from contextlib import asynccontextmanager
from datetime import datetime
from calendar import monthrange
from typing import Optional

import numpy as np
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# ─── Logging ─────────────────────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("shelfiq.api")

# ─── Resolve paths relative to this file, not CWD ────────────────────────────
# This ensures the model loads correctly regardless of where uvicorn is launched.
_API_DIR     = os.path.dirname(os.path.abspath(__file__))
_PROJECT_DIR = os.path.dirname(_API_DIR)

_DEFAULT_MODEL_PATH = os.path.join(_PROJECT_DIR, "models", "champion_model.pkl")
MODEL_PATH = os.environ.get("MODEL_PATH", _DEFAULT_MODEL_PATH)

# ─── Global model object (module-level for reliability) ───────────────────────
_model         = None
_model_loaded  = False
_model_version = "unknown"
_load_time     = None


def _load_model() -> None:
    """Load champion_model.pkl into the module-level _model variable."""
    global _model, _model_loaded, _model_version, _load_time

    logger.info(f"Loading model from: {MODEL_PATH}")

    if not os.path.exists(MODEL_PATH):
        logger.error(f"Model file NOT found at: {MODEL_PATH}")
        _model_loaded = False
        return

    try:
        loaded = joblib.load(MODEL_PATH)

        # Sanity-check: must be callable via .predict()
        if not callable(getattr(loaded, "predict", None)):
            raise TypeError(f"Loaded object has no callable .predict(): {type(loaded)}")

        _model         = loaded
        _model_loaded  = True
        mtime          = os.path.getmtime(MODEL_PATH)
        _model_version = f"champion_v1_{mtime:.0f}"
        _load_time     = datetime.utcnow().isoformat()

        # Warm-up prediction to confirm the model works end-to-end
        test_features = [[5.0, 4.5, 4.0, 4.8, 4.5, 4.2, 2, 8, 15, 0, 0, 0, 1, 103665]]
        test_pred = _model.predict(test_features)
        logger.info(f"Model loaded OK — warm-up prediction: {test_pred[0]:.4f}")

    except Exception as exc:
        logger.error(f"Failed to load model: {exc}", exc_info=True)
        _model        = None
        _model_loaded = False


# ─── Lifespan (replaces deprecated @app.on_event) ────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("ShelfIQ API starting up…")
    _load_model()
    if _model_loaded:
        logger.info(f"Startup complete — model version: {_model_version}")
    else:
        logger.warning("Startup complete — model NOT loaded. /predict will return 503.")
    yield
    logger.info("ShelfIQ API shutting down.")


# ─── App ─────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="ShelfIQ — Demand Forecasting API",
    description=(
        "Autonomous Retail Demand Forecasting API powered by LightGBM. "
        "Predicts unit sales for a given store, item, and date."
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Schemas ─────────────────────────────────────────────────────────────────
class PredictRequest(BaseModel):
    store_nbr:       int   = Field(..., ge=1, le=54,   description="Store number (1–54)")
    item_nbr:        int   = Field(..., ge=1,           description="Item number")
    date:            str   = Field(...,                 description="Date YYYY-MM-DD", example="2017-08-15")
    lag_1:           float = Field(..., description="Unit sales 1 day ago")
    lag_7:           float = Field(..., description="Unit sales 7 days ago")
    lag_14:          float = Field(..., description="Unit sales 14 days ago")
    rolling_mean_7:  float = Field(..., description="7-day rolling mean of unit sales")
    rolling_mean_14: float = Field(..., description="14-day rolling mean of unit sales")
    rolling_mean_30: float = Field(..., description="30-day rolling mean of unit sales")

    model_config = {
        "json_schema_extra": {
            "example": {
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
        }
    }


class PredictResponse(BaseModel):
    predicted_sales: float = Field(..., description="Predicted unit sales (clipped ≥ 0)")
    model_version:   str   = Field(..., description="Model version identifier")


class HealthResponse(BaseModel):
    status:        str           = Field(..., description="'ok' or 'degraded'")
    model_loaded:  bool          = Field(..., description="Whether the model is ready")
    timestamp:     str           = Field(..., description="Current UTC timestamp")
    model_version: Optional[str] = Field(None, description="Loaded model version")
    model_path:    str           = Field(..., description="Resolved model file path")


# ─── Endpoints ───────────────────────────────────────────────────────────────
@app.get("/", tags=["Root"])
async def root():
    return {"name": "ShelfIQ Demand Forecasting API", "version": "1.0.0",
            "docs": "/docs", "health": "/health", "predict": "/predict"}


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Returns API status and model load state."""
    return HealthResponse(
        status        = "ok" if _model_loaded else "degraded",
        model_loaded  = _model_loaded,
        timestamp     = datetime.utcnow().isoformat() + "Z",
        model_version = _model_version if _model_loaded else None,
        model_path    = MODEL_PATH,
    )


@app.post("/predict", response_model=PredictResponse, tags=["Prediction"])
async def predict(request: PredictRequest):
    """
    Predict unit sales for a given store × item × date.
    All lag/rolling features must be pre-computed by the caller.
    """
    if not _model_loaded or _model is None:
        raise HTTPException(
            status_code=503,
            detail=(
                f"Model not loaded. Path checked: {MODEL_PATH}. "
                "Check server logs for details."
            ),
        )

    try:
        dt             = datetime.strptime(request.date, "%Y-%m-%d")
        day_of_week    = int(dt.weekday())
        month          = int(dt.month)
        day            = int(dt.day)
        is_weekend     = int(day_of_week >= 5)
        is_month_start = int(dt.day == 1)
        is_month_end   = int(dt.day == monthrange(dt.year, dt.month)[1])

        # Feature order must exactly match training: FEATURE_COLS in train.py
        features = np.array([[
            request.lag_1,
            request.lag_7,
            request.lag_14,
            request.rolling_mean_7,
            request.rolling_mean_14,
            request.rolling_mean_30,
            day_of_week,
            month,
            day,
            is_weekend,
            is_month_start,
            is_month_end,
            float(request.store_nbr),
            float(request.item_nbr),
        ]], dtype=np.float32)

        raw_prediction  = _model.predict(features)[0]
        predicted_sales = float(max(0.0, raw_prediction))

        return PredictResponse(
            predicted_sales=predicted_sales,
            model_version=_model_version,
        )

    except ValueError as exc:
        raise HTTPException(status_code=422, detail=f"Invalid input: {exc}")
    except Exception as exc:
        logger.error(f"Prediction error: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}")
