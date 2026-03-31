#!/bin/bash
set -e
cd /mnt/c/Users/Nandha\ Kumar\ S\ K/Desktop/shelfiq
echo "Activating venv..."
source venv/bin/activate
echo "Pip version:"
pip --version
echo "Installing packages..."
pip install --upgrade pip
pip install pandas==2.1.0 numpy==1.24.0 lightgbm==4.1.0 mlflow==2.8.0 scikit-learn==1.3.0 fastapi==0.104.0 uvicorn==0.24.0 kaggle==1.5.16 pyarrow==14.0.0 python-dotenv==1.0.0
echo "INSTALL DONE"
pip list | grep -E "pandas|numpy|lightgbm|mlflow|scikit|fastapi|uvicorn|kaggle|pyarrow|dotenv"
