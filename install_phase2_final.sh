#!/bin/bash
# Install Phase 2 packages based on user guidance
set -e
VENV="/home/nandhu/shelfiq_venv"
source "$VENV/bin/activate"

echo "Installing dvc (no-deps)..."
pip install dvc --no-deps --only-binary=:all:

echo "Installing dvc essential dependencies..."
pip install colorama configobj distro dvc-data dvc-http dvc-render dvc-studio-client dpath funcy pathspec scmrepo shortuuid tqdm voluptuous dvc-objects kombu --only-binary=:all:

echo "Installing other Phase 2 tools..."
pip install pytest==7.4.0 httpx==0.25.0 pre-commit==3.5.0 pytest-asyncio anyio --only-binary=:all:

echo "Verifying installation..."
python3 -c "import dvc; import pytest; import httpx; print('All Phase 2 packages OK')"
