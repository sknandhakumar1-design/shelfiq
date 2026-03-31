#!/bin/bash
# Create and verify in single script - persistent for project use
VENV_DIR="/tmp/shelfiq_venv"

if [ ! -f "$VENV_DIR/bin/activate" ]; then
  echo "Creating venv..."
  python3 -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# Check site-packages
SITE="$VENV_DIR/lib/python3.12/site-packages"
echo "=== Packages in site-packages ==="
ls "$SITE" | grep -E "^(pandas|numpy|light|mlflow|fast|uvicorn|pyarrow|dotenv|scikit|kaggle)" 2>&1 | sort

echo ""
echo "=== Python sys paths ==="
python3 -c "
import sys
for p in sys.path:
    print(' ', p)
"

echo ""
echo "=== Import test ==="
python3 -c "
import sys
print('executable:', sys.executable)
site = '$SITE'
if site not in sys.path:
    print('Adding site to sys.path')
    sys.path.insert(0, site)

packages = ['pandas','numpy','lightgbm','mlflow','fastapi','uvicorn','pyarrow','dotenv','sklearn']
ok = 0
fail = 0
for p in packages:
    try:
        m = __import__(p)
        ver = getattr(m, '__version__', 'n/a')
        print(f'  OK {p} ({ver})')
        ok += 1
    except Exception as e:
        print(f'  FAIL {p}: {e}')
        fail += 1
print(f'Result: {ok} OK, {fail} FAIL')
" 2>&1
