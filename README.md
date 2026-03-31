# ShelfIQ — Autonomous Retail Intelligence Platform

> **AI-powered demand forecasting for retail shelves** — predicting unit sales at store × item × day granularity using LightGBM, MLflow, and FastAPI.

---

## 🧠 Overview

ShelfIQ is a production-grade MLOps platform that ingests the Favorita Grocery Sales dataset, engineers rich temporal features (lags, rolling means, calendar signals), trains a gradient-boosted LightGBM model with full MLflow experiment tracking, and serves real-time predictions via a FastAPI REST API — all containerised with Docker.

---

## 🛠 Tech Stack

| Component          | Technology             | Version     |
|--------------------|------------------------|-------------|
| Data Processing    | pandas, NumPy          | 2.x, 2.x    |
| Machine Learning   | LightGBM               | 4.x         |
| Experiment Tracking| MLflow                 | 3.x         |
| API Framework      | FastAPI                | 0.10x       |
| API Server         | Uvicorn                | 0.2x        |
| Data Storage       | Apache Parquet         | pyarrow 20+ |
| Containerisation   | Docker                 | 20+         |
| Dataset            | Favorita (Kaggle)      | 125M+ rows  |
| Language           | Python                 | 3.11 / 3.12 |

---

## 📂 Project Structure

```
shelfiq/
├── data/
│   ├── raw/                      # Favorita CSV files (train, test, etc.)
│   └── processed/
│       └── features.parquet      # Engineered feature set
├── src/
│   ├── ingest/                   # Data ingestion utilities
│   ├── features/
│   │   └── feature_engineering.py  # Lag/rolling features pipeline
│   └── models/
│       └── train.py              # LightGBM training + MLflow tracking
├── api/
│   └── main.py                   # FastAPI inference server
├── models/
│   └── champion_model.pkl        # Serialised champion model
├── notebooks/                    # EDA & experimentation
├── docker/
│   └── Dockerfile                # Production container spec
├── requirements.txt
├── .env
└── README.md
```

---

## 🚀 Quick Start (Local)

### 1. Clone & set up environment

```bash
# WSL2 / Linux
git clone <repo-url> && cd shelfiq
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Download the Favorita dataset

Ensure `~/.kaggle/kaggle.json` is present, then:

```bash
python3 -c "
import os; os.environ['KAGGLE_CONFIG_DIR'] = os.path.expanduser('~/.kaggle')
from kaggle import KaggleApi
api = KaggleApi(); api.authenticate()
api.competition_download_files('favorita-grocery-sales-forecasting', path='data/raw/')
"
# Extract (uses py7zr for .7z files inside the archive)
pip install py7zr
python3 -c "
import zipfile, py7zr, os, glob
with zipfile.ZipFile('data/raw/favorita-grocery-sales-forecasting.zip', 'r') as z:
    z.extractall('data/raw/')
for f in glob.glob('data/raw/*.7z'):
    with py7zr.SevenZipFile(f, 'r') as z: z.extractall('data/raw/')
"
```

### 3. Run feature engineering

```bash
python3 src/features/feature_engineering.py
```

### 4. Train the model

```bash
python3 src/models/train.py
```

### 5. Start the API server

```bash
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

API docs available at: [http://localhost:8000/docs](http://localhost:8000/docs)

---

## 🐳 Run with Docker

```bash
# Build the image
docker build -f docker/Dockerfile -t shelfiq-api:latest .

# Run the container
docker run -d \
  -p 8000:8000 \
  -v $(pwd)/models:/app/models \
  --name shelfiq-api \
  shelfiq-api:latest

# Check health
curl http://localhost:8000/health
```

---

## 📡 API Endpoints

### `GET /health`

Returns server and model status.

```json
{
  "status": "ok",
  "model_loaded": true,
  "timestamp": "2025-08-15T10:30:00Z",
  "model_version": "champion_v1_1234567890"
}
```

### `POST /predict`

Predict unit sales for a store × item × date.

**Request body:**

```json
{
  "store_nbr": 1,
  "item_nbr": 103665,
  "date": "2017-08-15",
  "lag_1": 5.0,
  "lag_7": 4.5,
  "lag_14": 4.0,
  "rolling_mean_7": 4.8,
  "rolling_mean_14": 4.5,
  "rolling_mean_30": 4.2
}
```

**Response:**

```json
{
  "predicted_sales": 5.123456,
  "model_version": "champion_v1_1234567890"
}
```

### `GET /docs`

Interactive Swagger UI documentation.

---

## 📊 Model Details

| Parameter      | Value           |
|----------------|-----------------|
| Algorithm      | LightGBM Regressor |
| n_estimators   | 500             |
| learning_rate  | 0.05            |
| num_leaves     | 63              |
| Features       | 14 (lag + rolling + calendar + ids) |
| Target         | unit_sales (clipped ≥ 0) |
| Test split     | Last 30 days    |
| Tracking       | MLflow (`mlruns/`) |

### Features Used

| Feature           | Description                          |
|-------------------|--------------------------------------|
| `lag_1`           | Sales 1 day ago                      |
| `lag_7`           | Sales 7 days ago                     |
| `lag_14`          | Sales 14 days ago                    |
| `rolling_mean_7`  | 7-day moving average of sales        |
| `rolling_mean_14` | 14-day moving average of sales       |
| `rolling_mean_30` | 30-day moving average of sales       |
| `day_of_week`     | Day of week (0=Mon, 6=Sun)           |
| `month`           | Month of year (1–12)                 |
| `day`             | Day of month (1–31)                  |
| `is_weekend`      | 1 if Saturday or Sunday              |
| `is_month_start`  | 1 if first day of month              |
| `is_month_end`    | 1 if last day of month               |
| `store_nbr`       | Store identifier                     |
| `item_nbr`        | Item identifier                      |

---

## 🧪 MLflow Tracking

Start the MLflow UI to view experiments:

```bash
mlflow ui --host 0.0.0.0 --port 5000
# Open http://localhost:5000
```

---

## 📜 License

MIT License — see [LICENSE](LICENSE) for details.
