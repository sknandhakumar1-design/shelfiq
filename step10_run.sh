#!/bin/bash
# Step 10: Run the feature engineering script
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"

echo "=== ShelfIQ — Step 10: Feature Engineering ==="

# Check venv
if [ ! -f "$VENV/bin/activate" ]; then
  echo "Venv not found, rebuilding..."
  bash "$PROJ/step4_download.sh" 2>&1 | tail -5
fi
source "$VENV/bin/activate"

# Make sure py7zr is installed too
pip3 install py7zr -q 2>&1

# Verify train.csv exists
if [ ! -f "$PROJ/data/raw/train.csv" ]; then
  echo "ERROR: data/raw/train.csv not found!"
  echo "Run step4_python.sh and step4_extract_7z.sh first"
  exit 1
fi

echo "train.csv size: $(du -sh "$PROJ/data/raw/train.csv" 2>&1)"
echo "Running feature engineering (this will take 10-20 minutes for the full 4.7GB dataset)..."
echo ""

cd "$PROJ"
time python3 src/features/feature_engineering.py 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo "=== Feature engineering succeeded! ==="
  echo "Output:"
  ls -lh data/processed/
  echo "✓ STEP 10 COMPLETE"
else
  echo "ERROR: Feature engineering failed with exit code $EXIT_CODE"
  exit $EXIT_CODE
fi
