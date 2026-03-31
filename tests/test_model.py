"""
ShelfIQ Phase 2 — Model Tests
Validates the champion LightGBM model artifact.
"""

import os
import pytest
import numpy as np
import joblib


MODEL_PATH = "models/champion_model.pkl"

# These 14 features must match FEATURE_COLS in src/models/train.py exactly
FEATURE_COLS = [
    "lag_1", "lag_7", "lag_14",
    "rolling_mean_7", "rolling_mean_14", "rolling_mean_30",
    "day_of_week", "month", "day",
    "is_weekend", "is_month_start", "is_month_end",
    "store_nbr", "item_nbr",
]

SAMPLE_FEATURES = np.array(
    [[5.0, 4.5, 4.0, 4.8, 4.5, 4.2, 2, 8, 15, 0, 0, 0, 1, 103665]],
    dtype=np.float32,
)


def test_model_file_exists():
    """models/champion_model.pkl must exist."""
    assert os.path.exists(MODEL_PATH), (
        f"Model file not found: {MODEL_PATH}. "
        "Run src/models/train.py to generate it."
    )
    size_kb = os.path.getsize(MODEL_PATH) / 1024
    assert size_kb > 10, f"Model file is suspiciously small ({size_kb:.1f} KB) — likely corrupt."


def test_model_loads():
    """champion_model.pkl must load via joblib and not be None."""
    assert os.path.exists(MODEL_PATH), f"Model not found: {MODEL_PATH}"
    model = joblib.load(MODEL_PATH)
    assert model is not None, "joblib.load returned None"
    assert callable(getattr(model, "predict", None)), (
        f"Loaded object has no callable .predict(). Got type: {type(model)}"
    )


def test_model_predicts():
    """Model must return a valid float prediction for a 14-feature input."""
    model = joblib.load(MODEL_PATH)

    assert SAMPLE_FEATURES.shape == (1, len(FEATURE_COLS)), (
        f"Expected shape (1, {len(FEATURE_COLS)}), got {SAMPLE_FEATURES.shape}"
    )

    result = model.predict(SAMPLE_FEATURES)

    assert result is not None, "model.predict() returned None"
    assert len(result) == 1, f"Expected 1 prediction, got {len(result)}"

    predicted = float(result[0])
    assert np.isfinite(predicted), f"Prediction is not finite: {predicted}"

    # Clipped prediction must be >= 0
    clipped = max(0.0, predicted)
    assert isinstance(clipped, float), f"Prediction should be float, got {type(clipped)}"
