"""
Model Training for ShelfIQ — Autonomous Retail Demand Forecasting Platform
Trains LightGBM with MLflow tracking and saves champion model.
"""

import pandas as pd
import numpy as np
import os
import sys
import joblib
import warnings
warnings.filterwarnings("ignore")

import lightgbm as lgb
from sklearn.metrics import mean_squared_error, mean_absolute_error

# MLflow
import mlflow
import mlflow.lightgbm


FEATURE_COLS = [
    "lag_1", "lag_7", "lag_14",
    "rolling_mean_7", "rolling_mean_14", "rolling_mean_30",
    "day_of_week", "month", "day",
    "is_weekend", "is_month_start", "is_month_end",
    "store_nbr", "item_nbr"
]
TARGET_COL = "unit_sales"


def mean_absolute_percentage_error(y_true, y_pred):
    """Compute MAPE, avoiding division by zero."""
    mask = y_true != 0
    return np.mean(np.abs((y_true[mask] - y_pred[mask]) / y_true[mask])) * 100


def main():
    print("=" * 60)
    print("ShelfIQ — Model Training Pipeline")
    print("=" * 60)

    # ─── Step 1: Load features ───────────────────────────────────
    # Resolve paths relative to this script so training works from any CWD
    _SCRIPT_DIR  = os.path.dirname(os.path.abspath(__file__))
    _PROJECT_DIR = os.path.dirname(os.path.dirname(_SCRIPT_DIR))
    feature_path = os.path.join(_PROJECT_DIR, "data", "processed", "features.parquet")
    print(f"\n[1/4] Loading features from {feature_path}...")
    if not os.path.exists(feature_path):
        print(f"ERROR: {feature_path} not found! Run feature_engineering.py first.")
        sys.exit(1)

    df = pd.read_parquet(feature_path, engine="pyarrow")
    print(f"  Loaded {len(df):,} rows, {df.shape[1]} columns")
    print(f"  Date range: {df['date'].min()} → {df['date'].max()}")

    # ─── Step 2: Train/test split (last 30 days as test) ─────────
    print("\n[2/4] Splitting train/test (last 30 days as test)...")
    max_date = df["date"].max()
    split_date = max_date - pd.Timedelta(days=30)

    df_train = df[df["date"] <= split_date].copy()
    df_test  = df[df["date"] >  split_date].copy()

    X_train = df_train[FEATURE_COLS].astype("float32")
    y_train = df_train[TARGET_COL].astype("float32")
    X_test  = df_test[FEATURE_COLS].astype("float32")
    y_test  = df_test[TARGET_COL].astype("float32")

    print(f"  Train: {len(df_train):,} rows (up to {split_date.date()})")
    print(f"  Test:  {len(df_test):,} rows (after {split_date.date()})")

    # ─── Step 3: Train LightGBM with MLflow ──────────────────────
    lgb_params = {
        "n_estimators": 500,
        "learning_rate": 0.05,
        "num_leaves": 63,
        "random_state": 42,
        "objective": "regression",
        "metric": "rmse",
        "verbose": -1,
        "n_jobs": -1,
    }

    print("\n[3/4] Training LightGBM model with MLflow tracking...")
    print(f"  Params: {lgb_params}")

    models_dir   = os.path.join(_PROJECT_DIR, "models")
    mlruns_dir   = os.path.join(_PROJECT_DIR, "mlruns")
    os.makedirs(models_dir, exist_ok=True)
    mlflow.set_tracking_uri(f"file:{mlruns_dir}")
    mlflow.set_experiment("shelfiq_demand_forecasting")

    with mlflow.start_run(run_name="lightgbm_champion"):
        # Log params
        mlflow.log_params(lgb_params)
        mlflow.log_param("train_size", len(df_train))
        mlflow.log_param("test_size", len(df_test))
        mlflow.log_param("feature_cols", FEATURE_COLS)

        # Train model
        model = lgb.LGBMRegressor(**lgb_params)
        model.fit(
            X_train, y_train,
            eval_set=[(X_test, y_test)],
        )

        # Evaluate
        y_pred = model.predict(X_test)
        y_pred = np.clip(y_pred, 0, None)  # clip negatives

        rmse = float(np.sqrt(mean_squared_error(y_test, y_pred)))
        mae  = float(mean_absolute_error(y_test, y_pred))
        mape = float(mean_absolute_percentage_error(y_test.values, y_pred))

        # Log metrics
        mlflow.log_metric("rmse", rmse)
        mlflow.log_metric("mae",  mae)
        mlflow.log_metric("mape", mape)

        # Log model
        mlflow.lightgbm.log_model(model, "lightgbm_model")

        # Save champion model using joblib (more reliable for numpy/sklearn objects)
        model_path = os.path.join(models_dir, "champion_model.pkl")
        joblib.dump(model, model_path, compress=3)
        mlflow.log_artifact(model_path)

        # Verify the saved model loads and predicts correctly
        _verify = joblib.load(model_path)
        _test   = _verify.predict([[5.0, 4.5, 4.0, 4.8, 4.5, 4.2, 2, 8, 15, 0, 0, 0, 1, 103665]])
        print(f"  Joblib save verified — test prediction: {_test[0]:.4f}")

        run_id = mlflow.active_run().info.run_id

    # ─── Step 4: Report ──────────────────────────────────────────
    print("\n[4/4] Training complete!")
    print(f"  MLflow run_id: {run_id}")
    print("\n" + "=" * 60)
    print("  FINAL METRICS")
    print("=" * 60)
    print(f"  RMSE : {rmse:.4f}")
    print(f"  MAE  : {mae:.4f}")
    print(f"  MAPE : {mape:.2f}%")
    print("=" * 60)
    print(f"\n  Model saved to: {model_path}")
    print("✓ STEP 6 COMPLETE")


if __name__ == "__main__":
    main()
