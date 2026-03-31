"""
ShelfIQ Phase 2 — Feature Engineering Tests
Validates the features.parquet artifact.
"""

import os
import pytest
import pandas as pd


FEATURES_PATH = "data/processed/features.parquet"

REQUIRED_COLUMNS = [
    "lag_1", "lag_7", "lag_14",
    "rolling_mean_7", "rolling_mean_14", "rolling_mean_30",
    "day_of_week", "month", "day",
    "is_weekend", "store_nbr", "item_nbr", "unit_sales",
]


@pytest.fixture(scope="module")
def features_df():
    """Load features.parquet once for all tests in this module."""
    assert os.path.exists(FEATURES_PATH), (
        f"features.parquet not found at {FEATURES_PATH}. "
        "Run src/features/feature_engineering.py first."
    )
    return pd.read_parquet(FEATURES_PATH, engine="pyarrow")


def test_features_file_exists():
    """data/processed/features.parquet must exist."""
    assert os.path.exists(FEATURES_PATH), (
        f"Missing: {FEATURES_PATH}"
    )
    size_mb = os.path.getsize(FEATURES_PATH) / 1024 / 1024
    assert size_mb > 1.0, f"features.parquet is too small ({size_mb:.2f} MB) — likely empty"


def test_features_columns(features_df):
    """All required columns must be present in features.parquet."""
    missing = [c for c in REQUIRED_COLUMNS if c not in features_df.columns]
    assert not missing, (
        f"Missing columns in features.parquet: {missing}\n"
        f"Available columns: {list(features_df.columns)}"
    )


def test_features_no_nulls(features_df):
    """Lag and rolling columns must have no null values."""
    lag_rolling_cols = [
        "lag_1", "lag_7", "lag_14",
        "rolling_mean_7", "rolling_mean_14", "rolling_mean_30",
    ]
    null_counts = features_df[lag_rolling_cols].isnull().sum()
    cols_with_nulls = null_counts[null_counts > 0]
    assert cols_with_nulls.empty, (
        f"Null values found in lag/rolling columns:\n{cols_with_nulls.to_dict()}"
    )


def test_features_row_count(features_df):
    """features.parquet must have more than 100,000 rows."""
    row_count = len(features_df)
    assert row_count > 100_000, (
        f"Expected > 100,000 rows, got {row_count:,}. "
        "The feature engineering may have filtered too aggressively."
    )
