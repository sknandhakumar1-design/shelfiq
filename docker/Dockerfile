# ─── ShelfIQ Demand Forecasting API ─────────────────────────────────────────
# Docker image for the ShelfIQ FastAPI inference server
# ─────────────────────────────────────────────────────────────────────────────

FROM python:3.11-slim

# Metadata
LABEL maintainer="ShelfIQ Team"
LABEL description="ShelfIQ Autonomous Retail Demand Forecasting - Inference API"
LABEL version="1.0.0"

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MODEL_PATH=/app/models/champion_model.pkl

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
        pandas \
        numpy \
        lightgbm \
        mlflow \
        scikit-learn \
        "fastapi>=0.104.0" \
        "uvicorn>=0.24.0" \
        pyarrow \
        python-dotenv \
        prometheus-fastapi-instrumentator==6.1.0 \
        prometheus-client

# Copy application code
COPY api/ ./api/
COPY models/ ./models/

# Create directories for runtime
RUN mkdir -p /app/data/raw /app/data/processed /app/mlruns

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Run the server
CMD ["uvicorn", "api.main:app", "--host", "0.0.0.0", "--port", "8000"]
