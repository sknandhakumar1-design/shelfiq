#!/bin/bash
# Start uvicorn and run live health + predict tests
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

# Kill any existing uvicorn on 8000
fuser -k 8000/tcp 2>/dev/null || true
sleep 1

echo "=== Starting uvicorn server ==="
uvicorn api.main:app --host 0.0.0.0 --port 8000 --log-level info &
SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# Wait for startup
echo "Waiting for server to start..."
for i in $(seq 1 15); do
  sleep 1
  if python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=2)" 2>/dev/null; then
    echo "Server is up after ${i}s"
    break
  fi
  echo "  waiting... ${i}s"
done

echo ""
echo "=== GET /health ==="
python3 << 'PYEOF'
import urllib.request, json
try:
    resp = urllib.request.urlopen("http://localhost:8000/health", timeout=5)
    data = json.loads(resp.read())
    print(json.dumps(data, indent=2))
    assert data["model_loaded"] == True, f"model_loaded is False! model_path={data.get('model_path')}"
    print("✓ /health OK — model_loaded=True")
except Exception as e:
    print(f"ERROR: {e}")
PYEOF

echo ""
echo "=== POST /predict ==="
python3 << 'PYEOF'
import urllib.request, json
body = json.dumps({
    "store_nbr": 1,
    "item_nbr": 103665,
    "date": "2017-08-15",
    "lag_1": 5.0,
    "lag_7": 4.5,
    "lag_14": 4.0,
    "rolling_mean_7": 4.8,
    "rolling_mean_14": 4.5,
    "rolling_mean_30": 4.2
}).encode()

req = urllib.request.Request(
    "http://localhost:8000/predict",
    data=body,
    headers={"Content-Type": "application/json"},
    method="POST"
)
try:
    resp = urllib.request.urlopen(req, timeout=10)
    data = json.loads(resp.read())
    print(json.dumps(data, indent=2))
    assert "predicted_sales" in data, "Missing predicted_sales"
    assert data["predicted_sales"] >= 0, "predicted_sales is negative"
    print(f"✓ /predict OK — predicted_sales={data['predicted_sales']:.4f}")
except urllib.error.HTTPError as e:
    body = e.read().decode()
    print(f"HTTP {e.code}: {body}")
except Exception as e:
    print(f"ERROR: {e}")
PYEOF

echo ""
echo "=== Stopping server ==="
kill $SERVER_PID 2>/dev/null
wait $SERVER_PID 2>/dev/null
echo "Server stopped."
echo "✓ API verification complete"
