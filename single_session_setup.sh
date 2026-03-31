#!/bin/bash
# Full setup in one script - runs in single WSL session
VENV_DIR="/tmp/shelfiq_venv"

echo "=== Creating venv in $VENV_DIR ==="
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo "Python: $(which python3) - $(python3 --version)"

echo "=== Upgrading pip ==="
pip3 install --upgrade pip -q

echo "=== Installing all packages ==="
pip3 install pandas==2.1.0 numpy==1.24.0 lightgbm==4.1.0 mlflow==2.8.0 scikit-learn==1.3.0 \
    fastapi==0.104.0 uvicorn==0.24.0 pyarrow==14.0.0 python-dotenv==1.0.0 kaggle -q

echo "=== After install, sys.path ==="
python3 -c "import sys; [print(p) for p in sys.path]"

echo "=== Testing imports from same shell ==="
python3 << 'PYEOF'
import sys, os
print("sys.version:", sys.version)
print("sys.executable:", sys.executable)
print("sys.path[:3]:", sys.path[:3])

packages = ['pandas','numpy','lightgbm','mlflow','fastapi','uvicorn','pyarrow','dotenv','sklearn','kaggle']
for p in packages:
    try:
        m = __import__(p)
        ver = getattr(m, '__version__', 'n/a')
        print(f"  OK: {p} ({ver})")
    except Exception as e:
        print(f"  FAIL: {p} => {e}")
PYEOF
echo "=== DONE ==="
