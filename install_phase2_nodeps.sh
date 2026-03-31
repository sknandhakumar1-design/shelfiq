#!/bin/bash
# Install Phase 2 packages with --no-deps to bypass resolution-too-deep
set -e
VENV="/home/nandhu/shelfiq_venv"
source "$VENV/bin/activate"

echo "Installing Phase 2 dependencies (no-deps mode)..."

# Pinned tools (standard installs)
pip install pytest==7.4.0 httpx==0.25.0 pre-commit==3.5.0 pytest-asyncio anyio --only-binary=:all: --quiet

# DVC and its manifest of core dependencies (no-deps)
# This list is from a standard DVC 3.x install
DEPS="dvc dvc-data dvc-http dvc-objects dvc-render dvc-studio-client dvc-task dvclive flufl.lock funcy pathspec scmrepo shtab sqltrie tqdm voluptuous zc.lockfile kombu colorama configobj distro dpath networkx omegaconf pydot rich ruamel.yaml tabulate tomlkit grandalf atpublic billiard click click-didyoumean click-plugins click-repl dictdiffer diskcache entrypoints fsspec gitdb gitpython iterative-telemetry markdown-it-py mdurl platformdirs ply prompt-toolkit pydantic-settings python-benedict python-dateutil requests scikit-learn semver six vine"

echo "Installing DVC and deps without resolver..."
for pkg in $DEPS; do
    echo "  Installing $pkg..."
    pip install $pkg --no-deps --only-binary=:all: --quiet || echo "  FAILED: $pkg"
done

echo "Verifying DVC version and basic import..."
dvc --version
python3 -c "import dvc; print('DVC OK')"
