#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"

export KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle"

cd "$PROJ"
mkdir -p data/raw

echo "=== Testing Kaggle Auth ==="
python3 << 'PYEOF'
import os
os.environ['KAGGLE_CONFIG_DIR'] = '/home/nandhu/.kaggle'
import traceback
try:
    from kaggle import KaggleApi
    api = KaggleApi()
    api.authenticate()
    print('Authenticated OK')
except Exception as e:
    print(f'Error: {e}')
    traceback.print_exc()
PYEOF

echo ""
echo "=== Downloading via CLI ==="
KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle" python3 -m kaggle competitions download \
    -c favorita-grocery-sales-forecasting \
    -p data/raw/ 2>&1
DL_EXIT=$?
echo "Download exit: $DL_EXIT"

echo "Files in data/raw:"
ls -lh data/raw/ 2>&1

if [ "$DL_EXIT" -ne 0 ] || [ -z "$(ls data/raw/ 2>/dev/null)" ]; then
    echo ""
    echo "=== Download failed, checking error details ==="
    KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle" python3 -m kaggle competitions list 2>&1 | head -5
fi
