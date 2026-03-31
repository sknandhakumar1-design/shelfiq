#!/bin/bash
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
cd "$PROJ"
source venv/bin/activate
echo "Python: $(which python3)"
echo "Testing pandas install..."
python3 -m pip install pandas==2.1.0 2>&1 | tail -5
echo "Testing import pandas..."
python3 -c "import pandas; print('pandas:', pandas.__version__)" 2>&1
echo "Done"
