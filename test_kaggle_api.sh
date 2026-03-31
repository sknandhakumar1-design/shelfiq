#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"

echo "=== Kaggle test ==="
export KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle"
python3 << 'PYEOF'
import os
os.environ['KAGGLE_CONFIG_DIR'] = '/home/nandhu/.kaggle'

import traceback
try:
    from kaggle.api.kaggle_api_extended import KaggleApiExtended
    api = KaggleApiExtended()
    api.authenticate()
    print('Authenticated OK')
    
    # Try downloading
    print('Downloading...')
    api.competition_download_files(
        'favorita-grocery-sales-forecasting',
        path='data/raw/',
        quiet=False
    )
    print('Download OK')
except Exception as e:
    print(f'Error: {e}')
    traceback.print_exc()
PYEOF
