#!/bin/bash
# Use compatible package versions with pre-built wheels for Python 3.12
VENV_DIR="/tmp/shelfiq_venv"
rm -rf "$VENV_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo "Python: $(python3 --version)"

# Check Python version - need to use compatible versions
PYVER=$(python3 --version | awk '{print $2}')
echo "Python version: $PYVER"

# Use versions with Python 3.12 wheels
echo "=== Installing with compatible versions ==="
pip3 install --upgrade pip -q

echo "Installing numpy first (older numpy 1.24 has no py312 wheel, use newer)..."
pip3 install "numpy>=1.26.0" --no-cache-dir 2>&1 | tail -3

echo "Installing pandas..."
pip3 install "pandas>=2.1.0" --no-cache-dir 2>&1 | tail -3

echo "Installing lightgbm..."
pip3 install lightgbm --no-cache-dir 2>&1 | tail -3

echo "Installing mlflow..."
pip3 install mlflow --no-cache-dir 2>&1 | tail -3

echo "Installing sklearn..."
pip3 install scikit-learn --no-cache-dir 2>&1 | tail -3

echo "Installing fastapi uvicorn..."
pip3 install fastapi uvicorn --no-cache-dir 2>&1 | tail -3

echo "Installing pyarrow..."
pip3 install pyarrow --no-cache-dir 2>&1 | tail -3

echo "Installing dotenv..."
pip3 install python-dotenv --no-cache-dir 2>&1 | tail -3

echo "=== Testing imports ==="
python3 -c "
packages = ['pandas','numpy','lightgbm','mlflow','fastapi','uvicorn','pyarrow','dotenv','sklearn']
for p in packages:
    try:
        m = __import__(p)
        ver = getattr(m, '__version__', 'n/a')
        print(f'  OK {p} ({ver})')
    except Exception as e:
        print(f'  FAIL {p}: {e}')
"
echo "=== STEP 3 COMPLETE ==="
