#!/bin/bash
# Create venv in WSL native filesystem for performance
# Then use that to run scripts on Windows files

WSL_PROJ="/root/shelfiq_venv"
WIN_PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"

echo "=== Setting up WSL-native venv ==="
mkdir -p "$WSL_PROJ"
cd "$WSL_PROJ"

# Create venv in WSL native filesystem
python3 -m venv venv
source venv/bin/activate

echo "=== Python version ==="
python3 --version
which python3

echo "=== Upgrading pip ==="
python3 -m pip install --upgrade pip -q

echo "=== Installing packages (this may take a few minutes) ==="
python3 -m pip install pandas==2.1.0 numpy==1.24.0 -q
echo "pandas+numpy done"
python3 -m pip install lightgbm==4.1.0 -q
echo "lightgbm done"
python3 -m pip install mlflow==2.8.0 -q
echo "mlflow done"
python3 -m pip install scikit-learn==1.3.0 -q
echo "sklearn done"
python3 -m pip install fastapi==0.104.0 uvicorn==0.24.0 -q
echo "fastapi+uvicorn done"
python3 -m pip install kaggle==1.5.16 -q
echo "kaggle done"
python3 -m pip install pyarrow==14.0.0 python-dotenv==1.0.0 -q
echo "pyarrow+dotenv done"

echo "=== Verifying imports ==="
python3 -c "import pandas; print('pandas', pandas.__version__)"
python3 -c "import numpy; print('numpy', numpy.__version__)"
python3 -c "import lightgbm; print('lightgbm ok')"
python3 -c "import mlflow; print('mlflow ok')"
python3 -c "import fastapi; print('fastapi ok')"
python3 -c "import uvicorn; print('uvicorn ok')"
python3 -c "import pyarrow; print('pyarrow ok')"
python3 -c "import dotenv; print('dotenv ok')"
python3 -c "import sklearn; print('sklearn ok')"
python3 -c "import kaggle; print('kaggle ok')"

echo "=== ALL PACKAGES INSTALLED SUCCESSFULLY ==="
