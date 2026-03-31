#!/bin/bash
set -e
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

echo "============================================================"
echo "STEP 1 CHECK: Confirm model file is gone"
echo "============================================================"
if [ -f "models/champion_model.pkl" ]; then
  echo "ERROR: models/champion_model.pkl still exists — deleting now"
  rm -f models/champion_model.pkl
fi
echo "  models/ contents: $(ls models/ 2>/dev/null || echo '(empty)')"

echo ""
echo "============================================================"
echo "STEP 2: Run training (joblib save)"
echo "============================================================"
python3 src/models/train.py
echo ""

echo "============================================================"
echo "STEP 3: Verify saved model — load + predict in Python"
echo "============================================================"
python3 << 'PYEOF'
import joblib, os, sys, numpy as np

MODEL_PATH = "models/champion_model.pkl"

print(f"  File exists : {os.path.exists(MODEL_PATH)}")
print(f"  File size   : {os.path.getsize(MODEL_PATH) / 1024:.0f} KB")

print("  Loading with joblib.load()...")
model = joblib.load(MODEL_PATH)

print(f"  Model type  : {type(model)}")
print(f"  Has predict : {callable(getattr(model, 'predict', None))}")
print(f"  n_estimators: {model.n_estimators}")
print(f"  n_features  : {model.n_features_in_}")

# Test prediction with realistic feature vector
feature_names = [
    "lag_1","lag_7","lag_14",
    "rolling_mean_7","rolling_mean_14","rolling_mean_30",
    "day_of_week","month","day",
    "is_weekend","is_month_start","is_month_end",
    "store_nbr","item_nbr"
]
X = np.array([[5.0, 4.5, 4.0, 4.8, 4.5, 4.2, 2, 8, 15, 0, 0, 0, 1, 103665]], dtype=np.float32)
pred = model.predict(X)
print(f"  Test predict: {pred[0]:.6f} (must be a finite float)")

assert np.isfinite(pred[0]), "Prediction is NaN or Inf!"
assert pred[0] > 0,          "Prediction is zero or negative — suspicious"
print("")
print("  ✓ Model loaded and predicted correctly via joblib")
PYEOF

echo ""
echo "============================================================"
echo "STEP 4: Confirm api/main.py uses joblib (not pickle)"
echo "============================================================"
grep -n "joblib\|pickle" "$PROJ/api/main.py"
echo ""
if grep -q "import pickle" "$PROJ/api/main.py"; then
  echo "  ERROR: api/main.py still imports pickle!"
  exit 1
fi
if grep -q "import joblib" "$PROJ/api/main.py"; then
  echo "  ✓ api/main.py uses joblib.load"
else
  echo "  ERROR: joblib not found in api/main.py!"
  exit 1
fi

echo ""
echo "============================================================"
echo "ALL STEPS COMPLETE"
echo "============================================================"
