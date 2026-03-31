#!/bin/bash
source $HOME/shelfiq_venv/venv/bin/activate
echo "Which python3: $(which python3)"
echo "--- Checking kaggle package files ---"
python3 -c "import sys, os; [print(p) for p in sys.path]"
# Try to find kaggle in site-packages
python3 << 'PYEOF'
import sys, os
for p in sys.path:
    if os.path.exists(p):
        entries = os.listdir(p)
        matches = [e for e in entries if 'kaggle' in e.lower()]
        if matches:
            print(f"Found in {p}: {matches}")
print("sys.path checked")
PYEOF
echo "--- Trying direct import with traceback ---"
python3 << 'PYEOF'
import traceback
try:
    import kaggle
    print("kaggle imported OK")
except Exception as e:
    traceback.print_exc()
PYEOF
