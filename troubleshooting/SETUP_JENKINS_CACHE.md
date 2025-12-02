# Setting Up Jenkins Caching for Wheel Files

## Quick Setup Guide

### Step 1: Install Pipeline Cache Plugin (Optional but Recommended)

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Plugins**
2. Search for **"Pipeline Cache"** or **"Pipeline Utility Steps"**
3. Install the plugin
4. Restart Jenkins if prompted

**Note:** The caching will still work with BuildKit cache mounts even without this plugin, but the Jenkins cache plugin provides additional persistence.

### Step 2: Verify Docker BuildKit Support

Check if BuildKit is available in your Jenkins container:

```bash
docker exec jenkins-dind-rag-medical docker buildx version
```

If not available, BuildKit is included in Docker 20.10+ and should work automatically.

### Step 3: Test the Build

1. Commit and push the updated Jenkinsfile and Dockerfile
2. Run the pipeline
3. **First build:** Will download all wheels (~10-15 minutes)
4. **Second build:** Should use cache (~1-2 minutes) ⚡

## How It Works

### Docker BuildKit Cache Mounts (Primary)

The Dockerfile uses `--mount=type=cache` which:
- Stores pip cache in Docker's BuildKit cache
- Persists between builds automatically
- Works even without Jenkins cache plugin

**Location:** `/var/lib/docker/buildkit/cache/`

### Jenkins Pipeline Cache (Secondary)

The Jenkinsfile uses the cache step to:
- Store pip cache in Jenkins workspace
- Persist across pipeline runs
- Survive workspace cleanup (if configured)

**Location:** `${WORKSPACE}/.pip-cache/`

### ECR Cache Image (Tertiary)

A cache image is pushed to ECR:
- Stores Docker layer cache
- Works across different Jenkins agents
- Survives Jenkins restarts

**Location:** `ECR_REPO:cache` tag

## Verification

### Check Cache is Working

After the second build, you should see:

```
# In build logs
Step 5/8 : RUN --mount=type=cache,target=/root/.cache/pip pip install...
 ---> Using cache
 ---> abc123def456
```

The `Using cache` message indicates cache is working!

### Check Cache Size

```bash
# In Jenkins container
docker exec jenkins-dind-rag-medical du -sh /var/lib/docker/buildkit/cache/
```

Expected size: ~500 MB - 1 GB (for all Python packages)

### Check ECR Cache Image

```bash
aws ecr list-images --repository-name rag-medical-repo --region eu-north-1
```

You should see a `cache` tag.

## Troubleshooting

### Cache Not Working?

1. **Verify BuildKit is enabled:**
   - Check build logs for `DOCKER_BUILDKIT=1`
   - Should see `Using cache` messages

2. **Check Dockerfile syntax:**
   - First line should be: `# syntax=docker/dockerfile:1.4`
   - Cache mounts use: `RUN --mount=type=cache,target=/root/.cache/pip`

3. **Verify cache directory:**
   ```bash
   docker exec jenkins-dind-rag-medical ls -la /var/lib/docker/buildkit/cache/
   ```

### Cache Plugin Error?

If you see errors about the cache plugin:
- The build will still work (fallback mode)
- BuildKit cache mounts work independently
- Install the plugin for additional persistence

### Clear Cache (if needed)

```bash
# Clear BuildKit cache
docker exec jenkins-dind-rag-medical docker builder prune -f

# Clear Jenkins workspace cache
rm -rf ${WORKSPACE}/.pip-cache/*

# Remove ECR cache image
aws ecr batch-delete-image \
  --repository-name rag-medical-repo \
  --image-ids imageTag=cache \
  --region eu-north-1
```

## Expected Results

### Build Times

| Build | Time | Reason |
|-------|------|--------|
| 1st | 10-15 min | Downloads all wheels |
| 2nd | 1-2 min | Uses cache |
| 3rd+ | 1-2 min | Uses cache |

### Cache Hit Rate

After 2nd build, you should see:
- **PyTorch:** 100% cache hit (0 seconds)
- **Other packages:** 95%+ cache hit
- **Total speedup:** 10x faster! 🚀

## Advanced: Pre-built Base Image

For even faster builds, create a base image with all dependencies:

```bash
# Build base image once
docker build -f Dockerfile.base -t rag-medical-base:latest .

# Tag and push
docker tag rag-medical-base:latest ${ECR_URL}/rag-medical-base:latest
docker push ${ECR_URL}/rag-medical-base:latest
```

Then use in main Dockerfile:
```dockerfile
FROM ${ECR_URL}/rag-medical-base:latest
COPY . .
RUN pip install -e .
```

**Result:** Builds in ~30 seconds! ⚡⚡⚡

## Summary

✅ **Docker BuildKit cache mounts** - Primary caching (works automatically)
✅ **Jenkins Pipeline Cache** - Additional persistence (optional plugin)
✅ **ECR Cache Image** - Layer caching across agents
✅ **Result:** 10x faster builds after first run!

