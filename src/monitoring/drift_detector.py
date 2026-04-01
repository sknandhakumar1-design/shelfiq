import pandas as pd
import numpy as np
import os
import sys
from datetime import datetime, timedelta

from evidently.report import Report
from evidently.metric_preset import DataDriftPreset

def detect_drift():
    print("=" * 60)
    print("ShelfIQ — Data Drift Detection")
    print("=" * 60)

    # 1. Load data
    _SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    _PROJECT_DIR = os.path.dirname(os.path.dirname(_SCRIPT_DIR))
    feature_path = os.path.join(_PROJECT_DIR, "data", "processed", "features.parquet")
    
    if not os.path.exists(feature_path):
        print(f"ERROR: {feature_path} not found.")
        return False

    print(f"Loading data from {feature_path}...")
    df = pd.read_parquet(feature_path)
    df['date'] = pd.to_datetime(df['date'])
    
    # 2. Split into Reference and Current
    max_date = df['date'].max()
    current_start = max_date - timedelta(days=30)
    reference_start = current_start - timedelta(days=30)

    # Last 30 days as current
    current_data = df[df['date'] > current_start].copy()
    # Previous 30 days as reference
    reference_data = df[(df['date'] <= current_start) & (df['date'] > reference_start)].copy()

    print(f"Reference data: {len(reference_data)} rows ({reference_start.date()} to {current_start.date()})")
    print(f"Current data:   {len(current_data)} rows ({current_start.date()} to {max_date.date()})")

    if len(reference_data) == 0 or len(current_data) == 0:
        print("ERROR: Not enough data for drift detection.")
        return False

    # 3. Drift detection
    # Columns to check drift on
    columns_to_check = ['unit_sales', 'lag_1', 'lag_7', 'rolling_mean_7']
    
    # Ensure columns exist
    available_cols = [c for c in columns_to_check if c in df.columns]
    print(f"Checking drift for columns: {available_cols}")

    report = Report(metrics=[
        DataDriftPreset(columns=available_cols)
    ])

    report.run(reference_data=reference_data, current_data=current_data)

    # 4. Save report
    reports_dir = os.path.join(_PROJECT_DIR, "reports")
    os.makedirs(reports_dir, exist_ok=True)
    report_path = os.path.join(reports_dir, "drift_report.html")
    report.save_html(report_path)
    print(f"Drift report saved to: {report_path}")

    # 5. Check status
    result = report.as_dict()
    # In evidently 0.4.x, the structure for DataDriftPreset is:
    # result['metrics'][0]['result']['dataset_drift']
    drift_detected = result['metrics'][0]['result']['dataset_drift']

    if drift_detected:
        print("\n[!] DRIFT DETECTED!")
    else:
        print("\n[+] No significant drift detected.")

    return drift_detected

def main():
    try:
        drift_status = detect_drift()
        print(f"Drift status: {drift_status}")
    except Exception as e:
        print(f"CRITICAL ERROR in drift detection: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
