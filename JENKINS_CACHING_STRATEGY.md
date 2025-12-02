# Jenkins Caching Strategy for Python Wheel Files

## Overview

This document explains how Jenkins caches Python wheel files (like PyTorch) to dramatically speed up subsequent builds.

## Caching Strategies Implemented

### 1. Docker BuildKit Cache Mounts (Primary Strategy)

**How it works:**
- Uses Docker BuildKit's `--mount=type=cache` feature
- Persists pip cache directory (`/root/.cache/pip`) between builds
- Wheel files are stored in Jenkins workspace and reused

**Benefits:**
- ✅ Wheel files downloaded once, reused forever (until cache expires)
- ✅ Works across different pipeline runs
- ✅ No manual cache management needed

**Implementation:**
```dockerfile
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install torch torchvision torchaudio
```

### 2. Jenkins Pipeline Cache Plugin

**How it works:**
- Uses Jenkins' built-in cache mechanism
- Stores pip cache directory in Jenkins workspace
- Persists between builds automatically

**Benefits:**
- ✅ Integrated with Jenkins
- ✅ Automatic cache management
- ✅ Configurable cache size limits

**Implementation:**
```groovy
cache(maxCacheSize: 500, caches: [
    [$class: 'ArbitraryFileCache', path: '.pip-cache']
]) {
    // Build steps
}
```

### 3. Docker Layer Caching with ECR

**How it works:**
- Pushes a cache image to ECR
- Next build pulls cache image and reuses layers
- Dependency installation layers are cached

**Benefits:**
- ✅ Works even if Jenkins workspace is cleaned
- ✅ Shared across multiple Jenkins agents
- ✅ Persistent across Jenkins restarts

**Implementation:**
```groovy
docker pull ${cacheImage} || true
docker build --cache-from ${cacheImage} ...
docker push ${cacheImage}
```

### 4. Docker BuildKit Inline Cache

**How it works:**
- BuildKit embeds cache metadata in image
- Enables better layer reuse
- Works with `--cache-from`

**Benefits:**
- ✅ More efficient layer caching
- ✅ Better cache hit rates
- ✅ Works with ECR cache images

## Build Time Comparison

### First Build (No Cache)
- PyTorch download: ~5-10 minutes (900 MB)
- Other dependencies: ~2-3 minutes
- **Total: ~10-15 minutes**

### Second Build (With All Caches)
- PyTorch: **0 seconds** (from cache)
- Other dependencies: **0 seconds** (from cache)
- Docker layer reuse: ~30 seconds
- **Total: ~1-2 minutes** ⚡

### Subsequent Builds
- **Total: ~1-2 minutes** (consistent)

## Cache Locations

### 1. Jenkins Workspace Cache
```
/var/jenkins_home/workspace/medical-rag-pipeline/.pip-cache/
```

### 2. Docker BuildKit Cache
```
/var/lib/docker/buildkit/cache/
```

### 3. ECR Cache Image
```
844810703328.dkr.ecr.eu-north-1.amazonaws.com/rag-medical-repo:cache
```

## Cache Management

### View Cache Size
```bash
# In Jenkins container
du -sh /var/jenkins_home/workspace/medical-rag-pipeline/.pip-cache
```

### Clear Cache (if needed)
```bash
# Clear Jenkins workspace cache
rm -rf /var/jenkins_home/workspace/medical-rag-pipeline/.pip-cache/*

# Clear Docker BuildKit cache
docker builder prune

# Remove ECR cache image
aws ecr batch-delete-image --repository-name rag-medical-repo --image-ids imageTag=cache
```

### Cache Expiration

**Jenkins Cache:**
- Default: Never expires (until manually cleared)
- Configurable via `maxCacheSize` parameter

**Docker BuildKit Cache:**
- Default: 7 days of inactivity
- Configurable via `docker builder prune`

**ECR Cache Image:**
- Never expires (until manually deleted)
- Consider setting lifecycle policy in ECR

## Troubleshooting

### Cache Not Working?

1. **Check BuildKit is enabled:**
   ```bash
   DOCKER_BUILDKIT=1 docker build ...
   ```

2. **Verify cache directory exists:**
   ```bash
   ls -la ${WORKSPACE}/.pip-cache
   ```

3. **Check Docker BuildKit is available:**
   ```bash
   docker buildx version
   ```

4. **Verify cache image is being pulled:**
   ```groovy
   sh "docker pull ${cacheImage} || echo 'Cache image not found, will create new'"
   ```

### Cache Too Large?

Set cache size limit in Jenkinsfile:
```groovy
cache(maxCacheSize: 1000, caches: [  // 1GB limit
    [$class: 'ArbitraryFileCache', path: '.pip-cache']
])
```

### Force Cache Refresh

To force re-download of packages:
```bash
# Clear Jenkins cache
rm -rf .pip-cache/*

# Or rebuild without cache
docker build --no-cache ...
```

## Advanced: Pre-built Base Image Strategy

For even faster builds, create a base image with all dependencies:

### Step 1: Create Base Image Dockerfile
```dockerfile
# Dockerfile.base
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --index-url https://download.pytorch.org/whl/cpu \
    torch torchvision torchaudio && \
    pip install -r requirements.txt
```

### Step 2: Build and Push Base Image
```bash
docker build -f Dockerfile.base -t rag-medical-base:latest .
docker tag rag-medical-base:latest ${ECR_URL}/rag-medical-base:latest
docker push ${ECR_URL}/rag-medical-base:latest
```

### Step 3: Use in Main Dockerfile
```dockerfile
FROM ${ECR_URL}/rag-medical-base:latest
COPY . .
RUN pip install -e .
CMD ["python", "app/application.py"]
```

**Benefits:**
- Dependencies only built once
- Application code changes don't trigger dependency rebuild
- Fastest build times (~30 seconds)

## Monitoring Cache Effectiveness

Add to Jenkinsfile:
```groovy
stage('Build Stats') {
    steps {
        script {
            def cacheSize = sh(
                script: "du -sh .pip-cache 2>/dev/null | cut -f1 || echo '0'",
                returnStdout: true
            ).trim()
            echo "Pip cache size: ${cacheSize}"
            
            def buildTime = currentBuild.duration
            echo "Build time: ${buildTime}ms"
        }
    }
}
```

## Best Practices

1. ✅ **Always use BuildKit** for cache mounts
2. ✅ **Push cache images** to ECR for persistence
3. ✅ **Set cache size limits** to prevent disk issues
4. ✅ **Monitor cache hit rates** to verify effectiveness
5. ✅ **Use CPU-only PyTorch** to reduce cache size
6. ✅ **Separate dependency and code layers** in Dockerfile

## Summary

With all caching strategies enabled:
- **First build:** ~10-15 minutes (downloads everything)
- **Subsequent builds:** ~1-2 minutes (uses cache)
- **Cache hit rate:** ~95%+ for dependencies
- **Disk space:** ~1-2 GB for pip cache
- **Speed improvement:** **10x faster** builds! 🚀

