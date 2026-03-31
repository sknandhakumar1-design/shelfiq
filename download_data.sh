#!/bin/bash
# Download Favorita dataset using Kaggle API
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
VENV="/tmp/shelfiq_venv"

# Ensure venv is active
if [ ! -f "$VENV/bin/activate" ]; then
  echo "Venv not found, recreating..."
  bash "$PROJ/install_compat.sh"
fi
source "$VENV/bin/activate"

# Verify kaggle credentials
KAGGLE_JSON="$HOME/.kaggle/kaggle.json"
# Try WSL home locations
for DIR in "/home/nandhu" "/root"; do
  if [ -f "$DIR/.kaggle/kaggle.json" ]; then
    KAGGLE_JSON="$DIR/.kaggle/kaggle.json"
    echo "Found kaggle.json at $KAGGLE_JSON"
    break
  fi
done

# Also check Windows profile
WIN_KAGGLE="/mnt/c/Users/Nandha Kumar S K/.kaggle/kaggle.json"
if [ -f "$WIN_KAGGLE" ]; then
  echo "Found Windows kaggle.json"
  mkdir -p /home/nandhu/.kaggle  
  cp "$WIN_KAGGLE" /home/nandhu/.kaggle/kaggle.json
  chmod 600 /home/nandhu/.kaggle/kaggle.json
  KAGGLE_JSON="/home/nandhu/.kaggle/kaggle.json"
fi

if [ ! -f "$KAGGLE_JSON" ]; then
  echo "ERROR: kaggle.json not found! Checked:"
  echo "  /home/nandhu/.kaggle/kaggle.json"
  echo "  /root/.kaggle/kaggle.json"
  echo "  $WIN_KAGGLE"
  echo "Please ensure kaggle.json is at ~/.kaggle/kaggle.json in WSL"
  exit 1
fi

echo "Using kaggle.json: $KAGGLE_JSON"
cat "$KAGGLE_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print('username:', d.get('username','?'))"

# Set kaggle env vars
export KAGGLE_CONFIG_DIR="$(dirname $KAGGLE_JSON)"

cd "$PROJ"
echo "Downloading Favorita dataset..."
python3 -m kaggle competitions download -c favorita-grocery-sales-forecasting -p data/raw/ 2>&1

echo "Checking downloaded files..."
ls -lh data/raw/ 2>&1

echo "Unzipping..."
cd data/raw
unzip -o favorita-grocery-sales-forecasting.zip 2>&1 | tail -20
echo "Files after unzip:"
ls -lh
cd ../..
echo "✓ STEP 4 COMPLETE"
