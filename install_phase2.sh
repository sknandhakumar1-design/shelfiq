#!/bin/bash
# Install Phase 2 packages
set -e
VENV="/home/nandhu/shelfiq_venv"
source "$VENV/bin/activate"

echo "Installing Phase 2 dependencies..."
pip install dvc --no-deps --only-binary=:all:
pip install pytest==7.4.0 httpx==0.25.0 pre-commit==3.5.0 pytest-asyncio anyio --only-binary=:all:

echo "Verifying installation..."
python3 -c "import dvc; import pytest; import httpx; import anyio; print('All Phase 2 packages OK')"
