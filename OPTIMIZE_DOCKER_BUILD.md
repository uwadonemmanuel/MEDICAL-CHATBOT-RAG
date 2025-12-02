# Optimizing Docker Build Speed for PyTorch Downloads

## Problem
PyTorch wheel files (899.8 MB) take too long to download during Jenkins pipeline builds.

## Solutions Implemented

### 1. Use PyTorch CPU-Only Version (Recommended)
- **Size reduction**: CPU-only PyTorch is ~150-200 MB vs 900 MB for full version
- **Speed**: Much faster download and installation
- **Sufficient**: For sentence-transformers embeddings, CPU-only is enough

### 2. Optimized Docker Layer Caching
- Copy `requirements.txt` and `setup.py` first
- Install dependencies before copying application code
- This allows Docker to cache the dependency layer even when code changes

### 3. Enable Pip Cache
- Set `PIP_CACHE_DIR` environment variable
- Use `--cache-dir` flag in pip install
- Subsequent builds will reuse cached packages

### 4. Use PyTorch Official Index
- Install PyTorch from official PyTorch wheel repository
- Faster and more reliable than PyPI for PyTorch

## Dockerfile Optimizations

The updated Dockerfile now:
1. Installs PyTorch CPU-only first (smaller, faster)
2. Uses pip cache directory
3. Copies requirements first for better layer caching
4. Uses official PyTorch wheel repository

## Build Time Comparison

**Before:**
- PyTorch download: ~5-10 minutes (900 MB)
- Total build: ~10-15 minutes

**After:**
- PyTorch CPU download: ~1-2 minutes (150-200 MB)
- Total build: ~3-5 minutes (first time)
- Subsequent builds: ~1-2 minutes (with cache)

## Additional Optimizations

### Option 1: Use Pre-built Base Image with PyTorch

Create a custom base image with PyTorch pre-installed:

```dockerfile
FROM python:3.10-slim as base
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
# ... rest of setup

FROM base as app
# ... your application
```

### Option 2: Use Multi-Stage Build

```dockerfile
FROM python:3.10-slim as dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --cache-dir /root/.cache/pip \
    --index-url https://download.pytorch.org/whl/cpu \
    torch torchvision torchaudio && \
    pip install --cache-dir /root/.cache/pip -r requirements.txt

FROM python:3.10-slim
WORKDIR /app
COPY --from=dependencies /root/.cache/pip /root/.cache/pip
COPY --from=dependencies /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY . .
CMD ["python", "app/application.py"]
```

### Option 3: Use BuildKit Cache Mounts (Docker 20.10+)

```dockerfile
# syntax=docker/dockerfile:1.4
FROM python:3.10-slim
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install torch --index-url https://download.pytorch.org/whl/cpu
```

## Jenkins Pipeline Optimization

Add build arguments to use BuildKit:

```groovy
sh """
    DOCKER_BUILDKIT=1 docker build \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        -t ${env.ECR_REPO}:${IMAGE_TAG} .
"""
```

## Verify CPU-Only PyTorch is Sufficient

Test that your application works with CPU-only PyTorch:

```python
import torch
print(torch.__version__)
print(torch.cuda.is_available())  # Should be False, which is fine for embeddings
```

## If You Need GPU Support

If you later need GPU support, change the PyTorch installation to:

```dockerfile
RUN pip install --no-cache-dir \
    --index-url https://download.pytorch.org/whl/cu118 \
    torch torchvision torchaudio
```

But for RAG embeddings with sentence-transformers, CPU-only is sufficient and much faster.

## Monitoring Build Time

Add timing to your Jenkinsfile:

```groovy
stage('Build Docker Image') {
    steps {
        script {
            def startTime = System.currentTimeMillis()
            sh "docker build -t ${env.ECR_REPO}:${IMAGE_TAG} ."
            def endTime = System.currentTimeMillis()
            def duration = (endTime - startTime) / 1000
            echo "Build took ${duration} seconds"
        }
    }
}
```

## Summary

The optimized Dockerfile should reduce build time from ~10-15 minutes to ~3-5 minutes (first build) and ~1-2 minutes (cached builds).

Key improvements:
- ✅ PyTorch CPU-only (150 MB vs 900 MB)
- ✅ Better layer caching
- ✅ Pip cache enabled
- ✅ Official PyTorch repository
- ✅ .dockerignore to exclude unnecessary files

