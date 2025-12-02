# Quick Fix: Docker API Version Mismatch

## Error Message
```
Error response from daemon: client version 1.52 is too new. Maximum supported API version is 1.43
```

## Problem
The Docker client inside Jenkins container is newer than the Docker daemon on your host machine.

## Solution 1: Rebuild Jenkins Image with Compatible Docker Version (Recommended)

1. **Update the Dockerfile** (already done - it now pins Docker to version 24.0)

2. **Rebuild the Jenkins image:**
```bash
cd custom_jenkins
docker build -t jenkins-dind .
```

3. **Stop and remove old container:**
```bash
# For separate instance
docker stop jenkins-dind-rag-medical
docker rm jenkins-dind-rag-medical

# For replaced instance
docker stop jenkins-dind
docker rm jenkins-dind
```

4. **Start new container:**
```bash
# For separate instance
docker run -d \
  --name jenkins-dind-rag-medical \
  --privileged \
  -p 8081:8080 \
  -p 50001:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home_rag_medical:/var/jenkins_home \
  jenkins-dind

# For replaced instance
docker run -d \
  --name jenkins-dind \
  --privileged \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  jenkins-dind
```

5. **Reinstall Python, Trivy, and AWS CLI** (if needed):
   - Follow the documentation steps again

## Solution 2: Quick Workaround (Temporary)

If you can't rebuild right now, set the Docker API version in your Jenkinsfile:

Add this to the environment section:
```groovy
environment {
    AWS_REGION = 'eu-north-1'
    ECR_REPO = 'rag-medical-repo'
    IMAGE_TAG = 'latest'
    DOCKER_API_VERSION = '1.43'  // Add this line
}
```

Or set it in the shell script:
```groovy
sh """
export DOCKER_API_VERSION=1.43
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ecrUrl}
docker build -t ${env.ECR_REPO}:${IMAGE_TAG} .
...
"""
```

## Solution 3: Update Host Docker (If You Have Access)

Update Docker Desktop or Docker Engine on your host machine to a newer version that supports API 1.52+.

**macOS (Docker Desktop):**
- Update Docker Desktop from the menu: Docker Desktop → Check for Updates

**Linux:**
```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

## Verify Fix

After applying the fix, test with:
```bash
docker exec jenkins-dind-rag-medical docker version
```

The client and server API versions should be compatible.

## Recommended Approach

**Solution 1 (Rebuild)** is recommended because:
- It ensures long-term compatibility
- Sets the API version at the container level
- Works for all pipelines without modification

