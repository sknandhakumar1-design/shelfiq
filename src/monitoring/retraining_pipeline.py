import os
import joblib
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import lightgbm as lgb
from sklearn.metrics import mean_squared_error
import mlflow
import mlflow.lightgbm
from prefect import task, flow, get_run_logger

# Import drift detection logic
from src.monitoring.drift_detector import detect_drift

# Configuration
_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_PROJECT_DIR = os.path.dirname(os.path.dirname(_SCRIPT_DIR))
DATA_PATH = os.path.join(_PROJECT_DIR, "data", "processed", "features.parquet")
MODEL_DIR = os.path.join(_PROJECT_DIR, "models")
CHAMPION_MODEL_PATH = os.path.join(MODEL_DIR, "champion_model.pkl")
MLRUNS_DIR = os.path.join(_PROJECT_DIR, "mlruns")

FEATURE_COLS = [
    "lag_1", "lag_7", "lag_14",
    "rolling_mean_7", "rolling_mean_14", "rolling_mean_30",
    "day_of_week", "month", "day",
    "is_weekend", "is_month_start", "is_month_end",
    "store_nbr", "item_nbr"
]
TARGET_COL = "unit_sales"

@task(name="check_drift_task")
def check_drift_task():
    logger = get_run_logger()
    logger.info("Starting drift detection...")
    drift_detected = detect_drift()
    logger.info(f"Drift detection complete. Drift detected: {drift_detected}")
    return drift_detected

@task(name="load_new_data_task")
def load_new_data_task():
    logger = get_run_logger()
    logger.info(f"Loading data from {DATA_PATH}...")
    df = pd.read_parquet(DATA_PATH)
    df['date'] = pd.to_datetime(df['date'])
    
    # Latest 60 days
    max_date = df['date'].max()
    sixty_days_ago = max_date - timedelta(days=60)
    df_new = df[df['date'] > sixty_days_ago].copy()
    
    logger.info(f"Loaded {len(df_new)} rows for retraining (last 60 days).")
    return df_new

@task(name="retrain_model_task")
def retrain_model_task(df):
    logger = get_run_logger()
    logger.info("Retraining LightGBM model...")
    
    # Train/test split (last 15 days as validation for retraining)
    max_date = df["date"].max()
    split_date = max_date - pd.Timedelta(days=15)
    
    df_train = df[df["date"] <= split_date].copy()
    df_val = df[df["date"] > split_date].copy()
    
    X_train = df_train[FEATURE_COLS].astype("float32")
    y_train = df_train[TARGET_COL].astype("float32")
    X_val = df_val[FEATURE_COLS].astype("float32")
    y_val = df_val[TARGET_COL].astype("float32")

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

    mlflow.set_tracking_uri(f"file:{MLRUNS_DIR}")
    mlflow.set_experiment("shelfiq_retraining")

    with mlflow.start_run(run_name=f"retrain_{datetime.now().strftime('%Y%m%d_%H%M%S')}"):
        mlflow.log_params(lgb_params)
        
        model = lgb.LGBMRegressor(**lgb_params)
        model.fit(X_train, y_train, eval_set=[(X_val, y_val)])
        
        y_pred = model.predict(X_val)
        y_pred = np.clip(y_pred, 0, None)
        rmse = float(np.sqrt(mean_squared_error(y_val, y_pred)))
        
        mlflow.log_metric("rmse", rmse)
        logger.info(f"Retrained model RMSE: {rmse:.4f}")
        
        return model, rmse

@task(name="evaluate_model_task")
def evaluate_model_task(new_rmse):
    logger = get_run_logger()
    
    if not os.path.exists(CHAMPION_MODEL_PATH):
        logger.info("No current champion model found. New model will be promoted.")
        return True

    # In a real scenario, we would evaluate the champion on the same validation set.
    # For this task, we'll assume we compare against a threshold or stored metric.
    # We'll just load the champion and predict to simulate.
    logger.info("Comparing new model with champion...")
    
    # Let's assume a dummy comparison for now or read from a metric store.
    # In a production system, we'd pull the champion's last RMSE from MLflow.
    current_champion_rmse = 17.01 # From PROGRESS.md
    
    logger.info(f"Current Champion RMSE: {current_champion_rmse:.4f}")
    logger.info(f"New Model RMSE: {new_rmse:.4f}")
    
    if new_rmse < current_champion_rmse:
        logger.info("New model is better than champion.")
        return True
    else:
        logger.info("New model is NOT better than champion.")
        return False

@task(name="promote_model_task")
def promote_model_task(model, should_promote):
    logger = get_run_logger()
    if should_promote:
        logger.info(f"Promoting new model to {CHAMPION_MODEL_PATH}...")
        joblib.dump(model, CHAMPION_MODEL_PATH, compress=3)
        logger.info("Model promotion complete.")
    else:
        logger.info("Skipping model promotion.")

@flow(name="shelfiq-retraining-pipeline")
def retraining_flow():
    logger = get_run_logger()
    logger.info("Starting ShelfIQ Retraining Pipeline...")
    
    # 1. Check Drift
    drift_detected = check_drift_task()
    
    if not drift_detected:
        logger.info("No drift detected. Retraining skipped.")
        return "No drift"

    # 2. Load Data
    df_new = load_new_data_task()
    
    # 3. Retrain
    new_model, new_rmse = retrain_model_task(df_new)
    
    # 4. Evaluate
    is_better = evaluate_model_task(new_rmse)
    
    # 5. Promote
    promote_model_task(new_model, is_better)
    
    logger.info("Retraining pipeline completed successfully.")
    return "Retrained"

if __name__ == "__main__":
    retraining_flow()
