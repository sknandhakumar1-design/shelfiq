#!/bin/bash
# Final automated Phase 2 execution script (verified env)
set -e
VENV="/home/nandhu/shelfiq_venv"
source "$VENV/bin/activate"

PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
cd "$PROJ"

echo "==== STEP 2 & 3: DVC and Git Init ===="
if [ ! -d ".git" ]; then
    git init
fi

dvc init --no-scm || dvc init || true

echo "Setting up local DVC remote..."
mkdir -p "$PROJ/dvc_remote"
dvc remote add -d myremote "$PROJ/dvc_remote" || true

dvc config core.autostage true

echo "Tracking data files with DVC..."
dvc add data/raw/train.csv || true
dvc add data/processed/features.parquet || true
dvc add models/champion_model.pkl || true

echo "==== STEP 3: Git first commit ===="
git config user.email "sknandhakumar1@design.local"
git config user.name "Nandha Kumar"
git add .
git commit -m "feat: ShelfIQ Phase 1 complete - LightGBM demand forecasting API" || echo "Already committed"

echo "==== STEP 4-6: Automated tests (already created) ===="
# Verified: tests/test_api.py, tests/test_features.py, tests/test_model.py exist.

echo "==== STEP 7: Run all tests ===="
PYTHONPATH=. python3 -m pytest tests/ -v

echo "==== STEP 8: CI Workflow (already created) ===="
# Verified: .github/workflows/ci.yml exists.

echo "==== STEP 9: pre-commit install ===="
pre-commit install

echo "==== STEP 10: Push everything to GitHub ===="
git remote add origin https://github.com/sknandhakumar1-design/shelfiq.git || git remote set-url origin https://github.com/sknandhakumar1-design/shelfiq.git
git branch -M main
# We don't push yet as the user has to handle auth or token
echo "Git remote added. Skipping push command as it might require user interaction (token/auth)."
echo "Manual push: git push -u origin main"
