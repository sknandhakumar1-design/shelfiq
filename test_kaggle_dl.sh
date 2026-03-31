#!/bin/bash
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
VENV="/tmp/shelfiq_venv"

if [ ! -f "$VENV/bin/activate" ]; then
  echo "Recreating venv..."
  bash "$PROJ/install_compat.sh" 2>&1 | tail -3
fi
source "$VENV/bin/activate"

export KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle"
cd "$PROJ"

echo "=== Kaggle test ==="
python3 -c "
import os
os.environ['KAGGLE_CONFIG_DIR'] = '/home/nandhu/.kaggle'
try:
    import kaggle
    print('kaggle imported OK')
    from kaggle.api.kaggle_api_extended import KaggleApiExtended
    api = KaggleApiExtended()
    api.authenticate()
    print('Authenticated OK')
except Exception as e:
    import traceback
    traceback.print_exc()
" 2>&1

echo ""
echo "=== Direct download ==="
KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle" python3 -m kaggle competitions download -c favorita-grocery-sales-forecasting -p data/raw/ 2>&1
echo "Download exit: $?"
ls -lh data/raw/ 2>&1
