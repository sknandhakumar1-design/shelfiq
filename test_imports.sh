#!/bin/bash
WSL_PROJ="$HOME/shelfiq_venv"
source "$WSL_PROJ/venv/bin/activate"
echo "=== Testing all imports ==="
python3 -c "
import sys
print('Python:', sys.version)
try:
    import pandas; print('pandas:', pandas.__version__)
except Exception as e: print('FAIL pandas:', e)
try:
    import numpy; print('numpy:', numpy.__version__)
except Exception as e: print('FAIL numpy:', e)
try:
    import lightgbm; print('lightgbm OK')
except Exception as e: print('FAIL lightgbm:', e)
try:
    import mlflow; print('mlflow OK')
except Exception as e: print('FAIL mlflow:', e)
try:
    import fastapi; print('fastapi OK')
except Exception as e: print('FAIL fastapi:', e)
try:
    import uvicorn; print('uvicorn OK')
except Exception as e: print('FAIL uvicorn:', e)
try:
    import pyarrow; print('pyarrow OK')
except Exception as e: print('FAIL pyarrow:', e)
try:
    import dotenv; print('dotenv OK')
except Exception as e: print('FAIL dotenv:', e)
try:
    import sklearn; print('sklearn OK')
except Exception as e: print('FAIL sklearn:', e)
"
echo "=== done ==="
