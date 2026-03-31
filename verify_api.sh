#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

echo "=== Verifying FastAPI server syntax ==="
python3 -c "
import sys
sys.path.insert(0, '.')
# Check the API can be imported (syntax check)
import importlib.util
spec = importlib.util.spec_from_file_location('main', 'api/main.py')
mod = importlib.util.module_from_spec(spec)
try:
    spec.loader.exec_module(mod)
    print('api/main.py syntax OK')
except Exception as e:
    print(f'api/main.py ERROR: {e}')
    import traceback; traceback.print_exc()
    sys.exit(1)
" 2>&1

echo ""
echo "=== Verifying model loads ==="
python3 -c "
import pickle, os
model_path = 'models/champion_model.pkl'
print(f'Model size: {os.path.getsize(model_path)/1024:.0f} KB')
with open(model_path, 'rb') as f:
    model = pickle.load(f)
print(f'Model type: {type(model).__name__}')
print(f'Features: {model.n_features_in_}')

# Test prediction
features = [[5.0, 4.5, 4.0, 4.8, 4.5, 4.2, 2, 8, 15, 0, 0, 0, 1, 103665]]
pred = model.predict(features)
print(f'Test prediction: {pred[0]:.4f} units')
print('Model load and predict: OK')
" 2>&1

echo ""
echo "=== Starting API server (background, 5s test) ==="
uvicorn api.main:app --host 0.0.0.0 --port 8000 &
SERVER_PID=$!
sleep 5

echo "Testing /health endpoint..."
python3 -c "
import urllib.request, json
try:
    resp = urllib.request.urlopen('http://localhost:8000/health', timeout=5)
    data = json.loads(resp.read())
    print('Health:', data)
except Exception as e:
    print(f'health check error: {e}')
" 2>&1

echo "Testing /predict endpoint..."
python3 -c "
import urllib.request, json
body = json.dumps({
    'store_nbr': 1, 'item_nbr': 103665, 'date': '2017-08-15',
    'lag_1': 5.0, 'lag_7': 4.5, 'lag_14': 4.0,
    'rolling_mean_7': 4.8, 'rolling_mean_14': 4.5, 'rolling_mean_30': 4.2
}).encode()
req = urllib.request.Request(
    'http://localhost:8000/predict',
    data=body,
    headers={'Content-Type': 'application/json'},
    method='POST'
)
try:
    resp = urllib.request.urlopen(req, timeout=5)
    data = json.loads(resp.read())
    print('Predict:', data)
except Exception as e:
    print(f'predict error: {e}')
" 2>&1

kill $SERVER_PID 2>/dev/null
echo ""
echo "✓ API verification complete"
