# ShelfIQ Build Progress — ALL STEPS COMPLETE ✅
> Last updated: Model save/load migrated from pickle → joblib. API confirmed working end-to-end.

## Summary
All 10 steps of the ShelfIQ Phase 1 build are complete and verified.

---

## ✅ STEP 1 — Folder Structure Created
All directories and `__init__.py` files created:
```
shelfiq/data/raw/, data/processed/, src/ingest/, src/features/,
src/models/, api/, models/, notebooks/, docker/
```

## ✅ STEP 2 — requirements.txt Created
All 10 specified packages written to `requirements.txt`.

## ✅ STEP 3 — Python Virtual Environment + Packages Installed
- Python 3.12.3 (WSL2 Ubuntu)
- **Persistent venv**: `/home/nandhu/shelfiq_venv`
- Packages: pandas 2.3.3, numpy 2.4.4, lightgbm 4.6.0, mlflow 3.10.1, fastapi 0.135.2, uvicorn 0.42.0, pyarrow 23.0.1, python-dotenv, scikit-learn 1.8.0, kaggle
- Note: Newer compatible versions used (Python 3.12 has no wheels for pinned versions)

## ✅ STEP 4 — Favorita Dataset Downloaded and Extracted
- Downloaded via Kaggle Python API (`kaggle.KaggleApi`)
- 458 MB zip → inner .7z files extracted via py7zr
- Files: `train.csv` (4.65 GB), `test.csv`, `stores.csv`, `items.csv`, `transactions.csv`, etc.

## ✅ STEP 5 — src/features/feature_engineering.py Created
- Memory-safe per-store chunked approach (handles 4.65GB CSV in WSL2)
- Features: lag_1, lag_7, lag_14, rolling_mean_7/14/30, day_of_week, month, day, is_weekend, is_month_start, is_month_end
- Groups by store_nbr and item_nbr before rolling/lag
- Saves to `data/processed/features.parquet`

## ✅ STEP 6 — src/models/train.py Created and Executed
- LightGBM: n_estimators=500, learning_rate=0.05, num_leaves=63
- MLflow tracking: experiment `shelfiq_demand_forecasting`
- **Final metrics (2017 test set):**
  - RMSE:  17.01
  - MAE:   3.59
  - MAPE:  83.02%
- Model saved to `models/champion_model.pkl` (2.7 MB)
- MLflow run_id: `db6cd04fb6414c0a99296f70c2ac07b7`

## ✅ STEP 7 — api/main.py Created
- GET /health → `{status, model_loaded, timestamp, model_version}`
- POST /predict → `{predicted_sales, model_version}`
- CORS middleware, error handling, Pydantic validation
- **Live test result**: `/predict` returned `predicted_sales: 4.27` ✅

## ✅ STEP 8 — docker/Dockerfile Created
- Base: `python:3.11-slim`
- Copies api/ and models/, exposes port 8000
- Health check, uvicorn entrypoint

## ✅ STEP 9 — README.md Created
- Project title, one-line description, tech stack table
- How to run locally (venv + uvicorn), Docker instructions
- API endpoint docs, project structure tree, MLflow tracking info

## ✅ STEP 10 — Feature Engineering Script Executed Successfully
- Ran in **2m 11s** (per-store incremental parquet writing)
- Output: `data/processed/features.parquet` (276 MB, ~440K rows of 2017 data)
- Verified: correct columns, no NaN in lag/rolling features

---

## Key Files
| File | Status |
|------|--------|
| `src/features/feature_engineering.py` | ✅ Working |
| `src/models/train.py` | ✅ Working |
| `api/main.py` | ✅ Working (tested live) |
| `docker/Dockerfile` | ✅ Created |
| `models/champion_model.pkl` | ✅ Trained (2.7 MB) |
| `data/processed/features.parquet` | ✅ Generated (276 MB) |
| `mlruns/` | ✅ MLflow tracking active |

## How to Resume / Re-Run

### Recreate venv (if needed):
```bash
wsl bash -c "bash '/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq/install_compat.sh'"
```

### Run feature engineering:
```bash
wsl bash -c "bash '/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq/step10_run.sh'"
```

### Run training:
```bash
wsl bash -c "bash '/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq/run_training.sh'"
```

### Start API server:
```bash
wsl bash -c "source /home/nandhu/shelfiq_venv/bin/activate && cd '/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq' && uvicorn api.main:app --host 0.0.0.0 --port 8000"
```

### Verify everything:
```bash
wsl bash -c "bash '/mnt/c/Users/Nandha Kumar S K/Desktop/shelfiq/verify_api.sh'"
```
