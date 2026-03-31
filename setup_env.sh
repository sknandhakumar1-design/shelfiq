#!/bin/bash
set -e
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
cd "$PROJ"

echo "=== Python version ==="
python3 --version

echo "=== Creating fresh venv ==="
rm -rf venv
python3 -m venv venv

echo "=== Activating ==="
source venv/bin/activate

echo "=== Python in venv ==="
which python3
python3 --version

echo "=== Upgrading pip ==="
python3 -m pip install --upgrade pip

echo "=== Installing packages ==="
python3 -m pip install pandas==2.1.0 numpy==1.24.0
python3 -m pip install lightgbm==4.1.0
python3 -m pip install mlflow==2.8.0
python3 -m pip install scikit-learn==1.3.0
python3 -m pip install fastapi==0.104.0 uvicorn==0.24.0
python3 -m pip install kaggle==1.5.16
python3 -m pip install pyarrow==14.0.0 python-dotenv==1.0.0

echo "=== Verifying imports ==="
python3 -c "import pandas; print('pandas', pandas.__version__)"
python3 -c "import numpy; print('numpy', numpy.__version__)"
python3 -c "import lightgbm; print('lightgbm OK')"
python3 -c "import mlflow; print('mlflow OK')"
python3 -c "import fastapi; print('fastapi OK')"
python3 -c "import uvicorn; print('uvicorn OK')"
python3 -c "import pyarrow; print('pyarrow OK')"
python3 -c "import dotenv; print('dotenv OK')"
python3 -c "import sklearn; print('sklearn OK')"

echo "=== STEP 3 COMPLETE ==="
