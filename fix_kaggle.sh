#!/bin/bash
source $HOME/shelfiq_venv/venv/bin/activate
echo "Reinstalling kaggle..."
pip install kaggle --upgrade 2>&1 | tail -5
python3 -c "import kaggle; print('kaggle ok')" 2>&1
echo "Done"
