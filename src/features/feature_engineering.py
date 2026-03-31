"""
Feature Engineering for ShelfIQ — Autonomous Retail Demand Forecasting Platform

Strategy: Process one store at a time (54 stores × ~575K rows each = ~30MB peak RAM).
Reads the full CSV once, groups by store, writes per-store results to parquet,
then combines at the end.
"""

import pandas as pd
import numpy as np
import os
import sys
import gc
import pyarrow as pa
import pyarrow.parquet as pq


RAW_PATH   = "data/raw/train.csv"
OUT_PATH   = "data/processed/features.parquet"
TMP_DIR    = "data/processed/tmp_stores"

# Use 2016-11 onwards for context + 2017 as target
CONTEXT_START = "2016-11-01"
TARGET_START  = "2017-01-01"


def add_date_features(df: pd.DataFrame) -> pd.DataFrame:
    df["day_of_week"]    = df["date"].dt.dayofweek.astype("int8")
    df["month"]          = df["date"].dt.month.astype("int8")
    df["day"]            = df["date"].dt.day.astype("int8")
    df["is_weekend"]     = (df["day_of_week"] >= 5).astype("int8")
    df["is_month_start"] = df["date"].dt.is_month_start.astype("int8")
    df["is_month_end"]   = df["date"].dt.is_month_end.astype("int8")
    return df


def process_store(df_store: pd.DataFrame) -> pd.DataFrame:
    """Compute all features for a single store's data."""
    df_store = df_store.sort_values(["item_nbr", "date"]).reset_index(drop=True)
    df_store["unit_sales"] = df_store["unit_sales"].clip(lower=0)
    df_store = add_date_features(df_store)

    g = df_store.groupby("item_nbr")["unit_sales"]
    df_store["lag_1"]           = g.shift(1).astype("float32")
    df_store["lag_7"]           = g.shift(7).astype("float32")
    df_store["lag_14"]          = g.shift(14).astype("float32")
    df_store["rolling_mean_7"]  = g.shift(1).groupby(df_store["item_nbr"]) \
                                    .transform(lambda x: x.rolling(7,  min_periods=1).mean()) \
                                    .astype("float32")
    df_store["rolling_mean_14"] = g.shift(1).groupby(df_store["item_nbr"]) \
                                    .transform(lambda x: x.rolling(14, min_periods=1).mean()) \
                                    .astype("float32")
    df_store["rolling_mean_30"] = g.shift(1).groupby(df_store["item_nbr"]) \
                                    .transform(lambda x: x.rolling(30, min_periods=1).mean()) \
                                    .astype("float32")

    # Drop NaN rows
    lag_cols = ["lag_1","lag_7","lag_14","rolling_mean_7","rolling_mean_14","rolling_mean_30"]
    df_store = df_store.dropna(subset=lag_cols)

    # Keep only target year
    df_store = df_store[df_store["date"] >= TARGET_START]
    return df_store


def main():
    print("=" * 60)
    print("ShelfIQ — Feature Engineering (Per-Store, Memory Safe)")
    print("=" * 60)

    os.makedirs(TMP_DIR, exist_ok=True)
    os.makedirs("data/processed", exist_ok=True)

    if not os.path.exists(RAW_PATH):
        print(f"ERROR: {RAW_PATH} not found!")
        sys.exit(1)

    file_gb = os.path.getsize(RAW_PATH) / 1024**3
    print(f"\nInput : {RAW_PATH} ({file_gb:.2f} GB)")
    print(f"Output: {OUT_PATH}")

    dtype_map = {
        "id": "int32",
        "store_nbr": "int8",
        "item_nbr": "int32",
        "unit_sales": "float32",
        "onpromotion": "object",
    }

    # ─── Phase 1: Scan CSV chunks, bucket by store ────────────────────────────
    print(f"\n[1/3] Filtering date range and bucketing by store (chunked scan)...")
    print(f"  Date range: {CONTEXT_START} → 2017-08-15")

    store_data = {}   # store_nbr -> list of DataFrames
    total_rows = 0
    chunk_n    = 0
    past_2017  = False

    for chunk in pd.read_csv(
        RAW_PATH,
        parse_dates=["date"],
        dtype=dtype_map,
        low_memory=False,
        chunksize=3_000_000,
        usecols=["date", "store_nbr", "item_nbr", "unit_sales"],
    ):
        chunk_n += 1
        sub = chunk.loc[chunk["date"] >= CONTEXT_START].copy()
        if len(sub):
            total_rows += len(sub)
            for store, grp in sub.groupby("store_nbr", sort=False):
                if store not in store_data:
                    store_data[store] = []
                store_data[store].append(grp)
            # Check if we've reached past 2017
            if chunk["date"].max() > pd.Timestamp("2017-08-15"):
                past_2017 = True

        if chunk_n % 10 == 0 or past_2017:
            print(f"  chunk {chunk_n:>2}: kept so far {total_rows:>10,} rows")

        if past_2017:
            print("  Reached end of 2017, done scanning.")
            break
        del chunk, sub
        gc.collect()

    print(f"  Total rows bucketed: {total_rows:,}  across {len(store_data)} stores")

    # ─── Phase 2: Process each store ──────────────────────────────────────────
    print(f"\n[2/3] Processing {len(store_data)} stores individually...")

    out_cols = [
        "store_nbr", "item_nbr", "date", "unit_sales",
        "lag_1", "lag_7", "lag_14",
        "rolling_mean_7", "rolling_mean_14", "rolling_mean_30",
        "day_of_week", "month", "day",
        "is_weekend", "is_month_start", "is_month_end",
    ]

    writer = None
    schema = None
    total_out = 0

    for i, store_nbr in enumerate(sorted(store_data.keys()), 1):
        df_store = pd.concat(store_data[store_nbr], ignore_index=True)
        del store_data[store_nbr]
        gc.collect()

        rows_in = len(df_store)
        df_store = process_store(df_store)
        df_out   = df_store[[c for c in out_cols if c in df_store.columns]]
        rows_out = len(df_out)
        total_out += rows_out

        # Write to parquet incrementally
        table = pa.Table.from_pandas(df_out, preserve_index=False)
        if writer is None:
            schema = table.schema
            writer = pq.ParquetWriter(OUT_PATH, schema)
        writer.write_table(table)

        print(f"  Store {store_nbr:>2} ({i}/{len(store_data)+i-1}): "
              f"{rows_in:>10,} in → {rows_out:>9,} out  |  total={total_out:>10,}")
        del df_store, df_out, table
        gc.collect()

    if writer:
        writer.close()

    # ─── Phase 3: Done ────────────────────────────────────────────────────────
    size_mb = os.path.getsize(OUT_PATH) / 1024**2
    print(f"\n[3/3] Saved {total_out:,} rows → {OUT_PATH} ({size_mb:.1f} MB)")

    print("\n" + "=" * 60)
    print("✓ STEP 10 COMPLETE — Feature Engineering Done!")
    print(f"  Output : {OUT_PATH}")
    print(f"  Rows   : {total_out:,}")
    print(f"  Columns: {out_cols}")
    print("=" * 60)


if __name__ == "__main__":
    main()
