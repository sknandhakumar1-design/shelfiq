#!/bin/bash
# Initialize DVC and Git
set -e
VENV="/home/nandhu/shelfiq_venv"
source "$VENV/bin/activate"

# Use local workspace
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
cd "$PROJ"

echo "Initializing Git..."
git init

echo "Initializing DVC..."
dvc init

echo "Setting up local DVC remote..."
mkdir -p "$PROJ/dvc_remote"
dvc remote add -d myremote "$PROJ/dvc_remote"

echo "Configuring DVC..."
cat > .dvc/config << 'EOF'
[core]
    autostage = true
['remote "myremote"']
    url = /mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq/dvc_remote
EOF

echo "Tracking data files with DVC..."
dvc add data/raw/train.csv
dvc add data/processed/features.parquet
dvc add models/champion_model.pkl

echo "Staging Git changes..."
git add .
git add .dvc/config .gitignore

echo "Making first commit..."
git config user.email "shelfiq@mlops.dev"
git config user.name "ShelfIQ MLOps"
git commit -m "feat: ShelfIQ Phase 1 complete - LightGBM demand forecasting API"
