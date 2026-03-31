#!/bin/bash
# Initialize DVC and Git robustly with spaces in paths
set -e
VENV="/home/nandhu/shelfiq_venv"
source "$VENV/bin/activate"

# Current directory should be right
PROJ="$(pwd)"
echo "Project root: $PROJ"

if [ ! -d ".git" ]; then
    echo "Initializing Git..."
    git init
else
    echo "Git already initialized."
fi

if [ ! -d ".dvc" ]; then
    echo "Initializing DVC..."
    dvc init --no-scm || dvc init
else
    echo "DVC already initialized."
fi

echo "Setting up local DVC remote..."
REMOTE_PATH="$PROJ/dvc_remote"
mkdir -p "$REMOTE_PATH"

if dvc remote list | grep -q "myremote"; then
    echo "Remote 'myremote' already exists."
else
    dvc remote add -d myremote "$REMOTE_PATH"
fi

echo "Configuring DVC autostage..."
dvc config core.autostage true

echo "Tracking data files with DVC..."
# Use relative paths to avoid space issues with dvc add
dvc add data/raw/train.csv || echo "Already tracked?"
dvc add data/processed/features.parquet || echo "Already tracked?"
dvc add models/champion_model.pkl || echo "Already tracked?"

echo "Staging Git changes..."
git add .
git status

echo "Making first commit..."
git config user.email "shelfiq@mlops.dev"
git config user.name "ShelfIQ MLOps"
git commit -m "feat: ShelfIQ Phase 1 complete - LightGBM demand forecasting API" || echo "Already committed?"
