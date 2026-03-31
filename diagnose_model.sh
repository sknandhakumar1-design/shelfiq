#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

echo "=== Diagnosing model load issue ==="
python3 << 'PYEOF'
import pickle, os, sys

# Simulate exactly what the API does
MODEL_PATH = os.environ.get("MODEL_PATH", "models/champion_model.pkl")
print(f"CWD:        {os.getcwd()}")
print(f"MODEL_PATH: {MODEL_PATH}")
print(f"Exists:     {os.path.exists(MODEL_PATH)}")

if os.path.exists(MODEL_PATH):
    with open(MODEL_PATH, "rb") as f:
        model = pickle.load(f)
    print(f"Model type: {type(model)}")
    print(f"Model:      {model}")
    print(f"predict fn: {model.predict}")
    print(f"Has predict: {callable(getattr(model, 'predict', None))}")
    
    # Test predict
    features = [[5.0, 4.5, 4.0, 4.8, 4.5, 4.2, 2, 8, 15, 0, 0, 0, 1, 103665]]
    result = model.predict(features)
    print(f"Prediction: {result}")
else:
    print("ERROR: model file not found!")
    sys.exit(1)
PYEOF
