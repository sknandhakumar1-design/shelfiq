#!/bin/bash
VENV_DIR="/tmp/shelfiq_venv"
rm -rf "$VENV_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo "Python: $(which python3)"
echo "Pip: $(which pip3)"

echo "Installing pandas (verbose)..."
pip3 install pandas==2.1.0 --no-cache-dir 2>&1
echo "Exit code: $?"
echo "check site-packages:"
ls /tmp/shelfiq_venv/lib/python3.12/site-packages/ | head -20
