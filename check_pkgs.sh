#!/bin/bash
cd /mnt/c/Users/Nandha\ Kumar\ S\ K/Desktop/shelfiq
source venv/bin/activate
pip list | grep -iE 'pandas|numpy|lightgbm|mlflow|fastapi|uvicorn|kaggle|pyarrow|dotenv|scikit'
