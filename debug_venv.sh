#!/bin/bash
source /tmp/shelfiq_venv/bin/activate
echo "Python executable: $(which python3)"
echo "Python sys.path:"
python3 -c "import sys; [print(p) for p in sys.path]"
echo ""
echo "Pip show pandas:"
pip show pandas 2>&1
echo ""
echo "ls site-packages (pandas):"
ls /tmp/shelfiq_venv/lib/python3.12/site-packages/ | grep pandas
echo ""
echo "Actual import error:"
python3 -c "import pandas" 2>&1
echo ""
echo "Try alternative import approach:"
python3 -c "import sys; sys.path.insert(0, '/tmp/shelfiq_venv/lib/python3.12/site-packages'); import pandas; print('pandas:', pandas.__version__)" 2>&1
