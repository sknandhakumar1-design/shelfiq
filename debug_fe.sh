#!/bin/bash
VENV="/home/nandhu/shelfiq_venv"
PROJ="/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq"
source "$VENV/bin/activate"
cd "$PROJ"

echo "=== Debug: Running feature engineering with error capture ==="
python3 << 'PYEOF'
import traceback, sys
try:
    import pandas as pd
    import numpy as np
    import os
    
    print("pandas:", pd.__version__)
    print("numpy:", np.__version__)
    
    raw_path = "data/raw/train.csv"
    print(f"\nLoading {raw_path}...")
    
    # Check file size
    size_gb = os.path.getsize(raw_path) / 1024**3
    print(f"File size: {size_gb:.2f} GB")
    
    # Try loading with minimal dtypes to save memory
    df = pd.read_csv(
        raw_path,
        parse_dates=["date"],
        low_memory=False,
        dtype={"id": "int32", "store_nbr": "int8", "item_nbr": "int32",
               "onpromotion": "object"}
    )
    print(f"Loaded: {len(df):,} rows, {df.shape[1]} columns")
    print(f"Columns: {list(df.columns)}")
    print(f"Memory: {df.memory_usage(deep=True).sum() / 1024**3:.2f} GB")
    print(f"unit_sales dtype: {df['unit_sales'].dtype}")
    print(f"Sample:\n{df.head(3)}")
    
except MemoryError as e:
    print(f"MEMORY ERROR: {e}")
    traceback.print_exc()
except Exception as e:
    print(f"ERROR: {type(e).__name__}: {e}")
    traceback.print_exc()
PYEOF
