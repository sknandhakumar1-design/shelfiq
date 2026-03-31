#!/bin/bash
# Use WSL's pip3 directly to install - fresh approach in /tmp
VENV_DIR="/tmp/shelfiq_venv"
rm -rf "$VENV_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo "Python: $(which python3) $(python3 --version)"
pip3 install --upgrade pip -q
echo "Installing pandas..."
pip3 install pandas==2.1.0 -q && echo "pandas installed" || echo "pandas FAILED"
python3 -c "import pandas; print('pandas import OK:', pandas.__version__)" 2>&1
echo "---"
echo "Installing all packages..."
pip3 install numpy==1.24.0 lightgbm==4.1.0 mlflow==2.8.0 scikit-learn==1.3.0 fastapi==0.104.0 uvicorn==0.24.0 pyarrow==14.0.0 python-dotenv==1.0.0 -q
pip3 install kaggle -q
echo "Testing all imports..."
python3 << 'EOF'
packages = ['pandas','numpy','lightgbm','mlflow','fastapi','uvicorn','pyarrow','dotenv','sklearn']
for p in packages:
    try:
        m = __import__(p)
        print(f"  OK: {p}")
    except Exception as e:
        print(f"  FAIL: {p} - {e}")
EOF
echo "VENV_DIR=$VENV_DIR"
echo "ALL DONE"
