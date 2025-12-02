# Quick Fix: Docker Permission Error in Jenkins Pipeline

## Error Message
```
ERROR: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock
```

## Quick Fix (Run These Commands)

### If using separate Jenkins instance (port 8081):
```bash
docker exec -u root -it jenkins-dind-rag-medical bash
groupadd -f docker
usermod -aG docker jenkins
chown root:docker /var/run/docker.sock
chmod 660 /var/run/docker.sock
su - jenkins -c "docker ps"
exit
docker restart jenkins-dind-rag-medical
```

### If using replaced Jenkins instance (port 8080):
```bash
docker exec -u root -it jenkins-dind bash
groupadd -f docker
usermod -aG docker jenkins
chown root:docker /var/run/docker.sock
chmod 660 /var/run/docker.sock
su - jenkins -c "docker ps"
exit
docker restart jenkins-dind
```

## Verify the Fix

1. Wait for Jenkins to restart (about 30 seconds)
2. Go to Jenkins Dashboard → Your Pipeline
3. Click **Build Now**
4. Check the console output - Docker commands should work now

## If Still Not Working

Try fixing the host Docker socket permissions:

**macOS/Linux:**
```bash
sudo chmod 666 /var/run/docker.sock
```

Then restart the Jenkins container again.

## Test Docker Access

After fixing, test with a simple pipeline stage:
```groovy
stage('Test Docker') {
    steps {
        sh 'docker ps'
    }
}
```

If this works, your Docker permissions are fixed! ✅

