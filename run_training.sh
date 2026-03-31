#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

echo "=== ShelfIQ — Model Training ==="
echo "features.parquet:"
ls -lh data/processed/features.parquet

echo ""
echo "Running training..."
time python3 src/models/train.py 2>&1
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo ""
  echo "Model saved:"
  ls -lh models/
  echo "✓ STEP 6 (training) COMPLETE"
else
  echo "ERROR: Training failed with exit code $EXIT_CODE"
  exit $EXIT_CODE
fi
