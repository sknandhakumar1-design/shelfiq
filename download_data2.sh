#!/bin/bash
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
VENV="/tmp/shelfiq_venv"

if [ ! -f "$VENV/bin/activate" ]; then
  echo "Recreating venv..."
  bash "$PROJ/install_compat.sh" 2>&1 | tail -5
fi
source "$VENV/bin/activate"

# Install unzip if not present
echo "Installing unzip..."
sudo apt-get install -y unzip 2>&1 | tail -3 || apt-get install -y unzip 2>&1 | tail -3

echo "Checking kaggle.json..."
if [ -f "/home/nandhu/.kaggle/kaggle.json" ]; then
  echo "Found kaggle.json at /home/nandhu/.kaggle/"
  export KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle"
else
  echo "ERROR: kaggle.json not found!"
  exit 1
fi

cd "$PROJ"
echo "Downloading dataset..."
python3 -m kaggle competitions download -c favorita-grocery-sales-forecasting -p data/raw/ 2>&1
echo "Download exit: $?"

echo "Files in data/raw:"
ls -lh data/raw/

# Install unzip via Python if system unzip not available
if ! command -v unzip &>/dev/null; then
  echo "unzip not found in system, using Python zipfile..."
  python3 -c "
import zipfile, os
zip_path = 'data/raw/favorita-grocery-sales-forecasting.zip'
if os.path.exists(zip_path):
    print(f'Extracting {zip_path}...')
    with zipfile.ZipFile(zip_path, 'r') as z:
        z.extractall('data/raw/')
    print('Extraction complete')
    print('Files:', os.listdir('data/raw/'))
else:
    print('zip file not found!')
    print('Available files:', os.listdir('data/raw/'))
" 2>&1
else
  cd data/raw
  echo "Unzipping..."
  unzip -o favorita-grocery-sales-forecasting.zip 2>&1 | tail -20
  echo "Files after unzip:"
  ls -lh | head -20
  cd ../..
fi
echo "✓ STEP 4 COMPLETE"
