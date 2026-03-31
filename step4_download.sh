#!/bin/bash
# MASTER SETUP + DOWNLOAD SCRIPT
# Run as: bash '/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq/step4_download.sh'

PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
VENV="/home/nandhu/shelfiq_venv"  # Persistent location in WSL home

echo "=== Setting up persistent venv at $VENV ==="
if [ ! -f "$VENV/bin/activate" ]; then
  echo "Creating new venv..."
  mkdir -p /home/nandhu
  python3 -m venv "$VENV"
  source "$VENV/bin/activate"
  pip3 install --upgrade pip -q
  echo "Installing packages..."
  pip3 install "pandas>=2.1.0" "numpy>=1.26.0" lightgbm mlflow scikit-learn fastapi uvicorn "pyarrow>=14.0.0" python-dotenv kaggle --no-cache-dir -q
  echo "Packages installed"
fi

source "$VENV/bin/activate"
echo "Python: $(python3 --version)"

# Quick verify packages
python3 -c "
import pandas, numpy, lightgbm, mlflow, fastapi, uvicorn, pyarrow, dotenv, sklearn, kaggle
print('All packages OK')
" || {
  echo "Some packages missing, reinstalling..."
  pip3 install "pandas>=2.1.0" "numpy>=1.26.0" lightgbm mlflow scikit-learn fastapi uvicorn "pyarrow>=14.0.0" python-dotenv kaggle --no-cache-dir -q
}

# Set up kaggle credentials
export KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle"
echo "=== Testing kaggle auth ==="
python3 -c "
import os
os.environ['KAGGLE_CONFIG_DIR'] = '/home/nandhu/.kaggle'
from kaggle.api.kaggle_api_extended import KaggleApiExtended
api = KaggleApiExtended()
api.authenticate()
print('Kaggle authenticated successfully')
" 2>&1

echo "=== Downloading Favorita dataset ==="
cd "$PROJ"
mkdir -p data/raw
KAGGLE_CONFIG_DIR="/home/nandhu/.kaggle" python3 -m kaggle competitions download \
    -c favorita-grocery-sales-forecasting -p data/raw/ 2>&1
echo "Download exit: $?"

echo "=== Files in data/raw ==="
ls -lh data/raw/

echo "=== Extracting zip using Python ==="
python3 << 'PYEOF'
import zipfile, os, sys

raw_dir = "data/raw"
zip_path = os.path.join(raw_dir, "favorita-grocery-sales-forecasting.zip")

if not os.path.exists(zip_path):
    # Check for other zip files
    files = os.listdir(raw_dir)
    print(f"Files in data/raw: {files}")
    zips = [f for f in files if f.endswith('.zip')]
    if zips:
        zip_path = os.path.join(raw_dir, zips[0])
        print(f"Found zip: {zip_path}")
    else:
        print("No zip file found! Download may have failed.")
        sys.exit(1)

print(f"Extracting {zip_path}...")
file_size = os.path.getsize(zip_path)
print(f"Zip size: {file_size/1024/1024:.1f} MB")

with zipfile.ZipFile(zip_path, 'r') as z:
    names = z.namelist()
    print(f"Files in zip: {len(names)}")
    for name in names[:10]:
        info = z.getinfo(name)
        print(f"  {name}: {info.file_size/1024/1024:.1f} MB")
    z.extractall(raw_dir)

print("Extraction complete!")
print("Files in data/raw:")
for f in sorted(os.listdir(raw_dir)):
    size = os.path.getsize(os.path.join(raw_dir, f)) / 1024 / 1024
    print(f"  {f}: {size:.1f} MB")
PYEOF

echo "✓ STEP 4 COMPLETE"
