# syntax=docker/dockerfile:1.4
## Parent image
FROM python:3.10-slim

## Essential environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_CACHE_DIR=/root/.cache/pip \
    PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

## Work directory inside the docker container
WORKDIR /app

## Installing system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

## Copy only requirements files first for better layer caching
COPY requirements.txt setup.py ./

## Install PyTorch CPU-only first (much smaller and faster than full PyTorch)
## Using BuildKit cache mount to persist pip cache between builds
## This is sufficient for sentence-transformers embeddings
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --index-url https://download.pytorch.org/whl/cpu \
    torch torchvision torchaudio

## Install other Python dependencies
## Using BuildKit cache mount to persist pip cache
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install \
    --index-url https://pypi.org/simple \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    -r requirements.txt && \
    pip install -e .

## Copy the rest of the application code
COPY . .

## Expose only flask port
EXPOSE 5000

## Run the Flask app
CMD ["python", "app/application.py"]


