#!/bin/bash
source $HOME/shelfiq_venv/venv/bin/activate

python3 << 'EOF'
import sys
print("Python:", sys.version)
packages = [
    ('pandas', 'pandas'),
    ('numpy', 'numpy'),
    ('lightgbm', 'lightgbm'),
    ('mlflow', 'mlflow'),
    ('fastapi', 'fastapi'),
    ('uvicorn', 'uvicorn'),
    ('pyarrow', 'pyarrow'),
    ('dotenv', 'python-dotenv'),
    ('sklearn', 'scikit-learn'),
    ('kaggle', 'kaggle'),
]
all_ok = True
for mod, pkg in packages:
    try:
        m = __import__(mod)
        ver = getattr(m, '__version__', 'unknown')
        print(f"  OK  {pkg} ({ver})")
    except ImportError as e:
        print(f"  FAIL {pkg}: {e}")
        all_ok = False
if all_ok:
    print("\nALL PACKAGES OK")
else:
    print("\nSOME PACKAGES MISSING")
    sys.exit(1)
EOF
