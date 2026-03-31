#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"

cd "$PROJ"
mkdir -p data/raw

echo "=== Downloading Favorita via Kaggle API (Python) ==="
python3 << 'PYEOF'
import os, sys
os.environ['KAGGLE_CONFIG_DIR'] = '/home/nandhu/.kaggle'

from kaggle import KaggleApi
api = KaggleApi()
api.authenticate()
print("Authenticated!")

print("Downloading competition files...")
try:
    api.competition_download_files(
        competition='favorita-grocery-sales-forecasting',
        path='data/raw/',
        quiet=False
    )
    print("Download complete!")
except Exception as e:
    print(f"competition_download_files failed: {e}")
    # Try individual file
    try:
        files = api.competition_list_files('favorita-grocery-sales-forecasting')
        print(f"Competition files: {[f.name for f in files]}")
    except Exception as e2:
        print(f"list_files also failed: {e2}")
        # Try list files differently
        print("Trying alternative...")
        import traceback
        traceback.print_exc()

import os
print("Files in data/raw:", os.listdir('data/raw/'))
PYEOF
echo "Exit: $?"
ls -lh data/raw/
