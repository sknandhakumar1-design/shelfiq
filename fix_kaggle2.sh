#!/bin/bash
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
VENV="/tmp/shelfiq_venv"

if [ ! -f "$VENV/bin/activate" ]; then
  echo "Recreating venv..."
  bash "$PROJ/install_compat.sh" 2>&1 | tail -3
fi
source "$VENV/bin/activate"

# Install kaggle properly
echo "Installing kaggle..."
pip3 install kaggle --no-cache-dir 2>&1 | tail -5

# Check what error prevents kaggle import
python3 -c "
try:
    import kaggle
    print('kaggle OK')
except Exception as e:
    print('kaggle error:', e)
    import traceback
    traceback.print_exc()
" 2>&1

echo "Kaggle installed packages:"
pip3 list | grep -i kaggle 2>&1

echo "Kaggle package location:"
python3 -c "import importlib.util; s = importlib.util.find_spec('kaggle'); print(s)" 2>&1
