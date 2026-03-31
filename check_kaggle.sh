#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
source "$VENV/bin/activate"
echo "Kaggle version:"
python3 -c "import kaggle; print(dir(kaggle))" 2>&1
echo ""
echo "Kaggle package:"
pip3 show kaggle 2>&1
echo ""
echo "Kaggle CLI:"
kaggle --version 2>&1 || python3 -m kaggle --version 2>&1
echo ""
echo "Kaggle help:"
kaggle competitions download --help 2>&1 | head -15 || python3 -m kaggle competitions download --help 2>&1 | head -15
