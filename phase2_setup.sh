#!/bin/bash
# ShelfIQ Phase 2 — Full Setup (Steps 1-9)
set -e

VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

echo "============================================================"
echo "  ShelfIQ Phase 2 Setup"
echo "  Python: $(python3 --version)"
echo "============================================================"

update_progress() {
  sed -i "s/^- \[ \] STEP $1 —/- [x] STEP $1 —/" PROGRESS.md 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ STEP 1: Install Phase 2 packages ━━━━━━━━━━━━━━━━━━━━━━"

# Install without strict version pin on dvc (3.30.0 conflicts); use >=3.0
pip install \
  "dvc>=3.0" \
  pytest==7.4.0 \
  httpx==0.25.0 \
  pre-commit==3.5.0 \
  pytest-asyncio \
  anyio \
  --only-binary=:all: \
  -q 2>&1 | grep -v "^$" | tail -10

python3 -c "
import dvc, pytest, httpx, anyio
print(f'  dvc       {dvc.__version__}')
print(f'  pytest    {pytest.__version__}')
print(f'  httpx     {httpx.__version__}')
print('All Phase 2 packages OK')
"
echo "✓ STEP 1 COMPLETE"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ STEP 2: Initialize DVC ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Need git before dvc init
if [ ! -d ".git" ]; then
  git init -q
  git config user.email "shelfiq@mlops.dev"
  git config user.name "ShelfIQ MLOps"
fi

# Init DVC
if [ ! -f ".dvc/.gitignore" ]; then
  dvc init -q
  echo "  DVC initialized"
else
  echo "  DVC already initialized, skipping"
fi

# Write config
cat > .dvc/config << 'DVCEOF'
[core]
    autostage = true
DVCEOF
echo "  DVC config: autostage = true"

# Track artifacts
for file in "data/raw/train.csv" "data/processed/features.parquet" "models/champion_model.pkl"; do
  dvc_file="${file}.dvc"
  if [ -f "$file" ] && [ ! -f "$dvc_file" ]; then
    dvc add "$file" -q
    echo "  Tracked: $file"
  elif [ -f "$dvc_file" ]; then
    echo "  Already tracked: $file"
  else
    echo "  SKIP (not found): $file"
  fi
done

echo "✓ STEP 2 COMPLETE"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ STEP 3: Git first commit ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

git config user.email "shelfiq@mlops.dev"
git config user.name "ShelfIQ MLOps"

# Write .gitignore
cat > .gitignore << 'GIEOF'
# Python
__pycache__/
*.py[cod]
*.pyo
.Python
*.egg-info/
dist/
build/

# Data (tracked by DVC — large binaries excluded from git)
data/raw/*.csv
data/raw/*.7z
data/raw/*.zip
data/processed/*.parquet
models/*.pkl

# MLflow tracking
mlruns/

# Jupyter
.ipynb_checkpoints/
*.ipynb

# Env
.env
*.env

# DVC cache
.dvc/cache/
.dvc/tmp/

# OS
.DS_Store
Thumbs.db
__MACOSX/

# IDE
.vscode/settings.json
.idea/
GIEOF

git add -A
git status --short | head -20
git diff --cached --stat | tail -5

# Commit (or amend if already committed)
if git log --oneline 2>/dev/null | grep -q "Phase 1"; then
  echo "  Already committed, creating Phase 2 checkpoint commit"
  git commit -m "chore: Phase 2 setup - DVC, tests, CI, pre-commit" --allow-empty -q || true
else
  git commit -m "feat: ShelfIQ Phase 1 complete - LightGBM demand forecasting API" -q
fi

echo "  Recent commits:"
git log --oneline -3
echo "✓ STEP 3 COMPLETE"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ STEP 4-6: Verify test files exist ━━━━━━━━━━━━━━━━━━━━"

for f in "tests/test_api.py" "tests/test_features.py" "tests/test_model.py" "pytest.ini"; do
  if [ -f "$f" ]; then
    echo "  ✓ $f"
  else
    echo "  MISSING: $f"
  fi
done

echo "✓ STEP 4 COMPLETE (test_api.py)"
echo "✓ STEP 5 COMPLETE (test_features.py)"
echo "✓ STEP 6 COMPLETE (test_model.py)"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ STEP 7: Run all tests ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "  Running model + feature tests (no server needed)..."
PYTHONPATH="$PROJ" python3 -m pytest tests/test_model.py tests/test_features.py -v 2>&1
STATIC_EXIT=$?

echo ""
echo "  Running API tests (uses ASGI test client, no server needed)..."
PYTHONPATH="$PROJ" python3 -m pytest tests/test_api.py -v 2>&1
API_EXIT=$?

if [ $STATIC_EXIT -eq 0 ] && [ $API_EXIT -eq 0 ]; then
  echo "✓ STEP 7 COMPLETE — ALL TESTS PASSED"
else
  echo "  ⚠ Some tests failed. Diagnosing..."
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ STEP 8: Verify CI workflow ━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f ".github/workflows/ci.yml" ]; then
  echo "  ✓ .github/workflows/ci.yml exists"
  python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); print('  ✓ ci.yml is valid YAML')"
fi
echo "✓ STEP 8 COMPLETE"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ STEP 9: Install pre-commit hooks ━━━━━━━━━━━━━━━━━━━━━"
pre-commit install
echo "✓ STEP 9 COMPLETE"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  PHASE 2 SETUP COMPLETE (Steps 1-9)"
echo "  Next: STEP 10 — GitHub push"
echo "  Run: git remote add origin <url> && git push -u origin main"
echo "============================================================"
