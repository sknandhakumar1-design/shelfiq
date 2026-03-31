#!/bin/bash
source $HOME/shelfiq_venv/venv/bin/activate
echo "Which python: $(which python3)"
echo "Which pip: $(which pip)"
echo "Pip list (kaggle):"
pip list 2>&1 | grep -i kaggle
echo "Pip install kaggle (force):"
pip install kaggle==1.5.16 --force-reinstall 2>&1 | tail -10
echo "After reinstall:"
pip list 2>&1 | grep -i kaggle
echo "Check site-packages:"
python3 -c "import site; print(site.getsitepackages())"
echo "ls kaggle in site:"
python3 -c "import site; import os; [print(os.listdir(p)) for p in site.getsitepackages() if os.path.exists(p)]" 2>&1 | grep -i kaggle
echo "Try import:"
python3 -c "import kaggle; print('kaggle ok')" 2>&1
