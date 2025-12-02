# Jenkins Docker-in-Docker Setup for RAG Medical Chatbot

This directory contains the Docker setup for running Jenkins with Docker-in-Docker (DinD) support for CI/CD pipelines.

## Prerequisites

- Docker installed and running
- Docker Compose (optional, for easier management)

## Building the Image

```bash
docker build -t jenkins-dind .
```

## Running Jenkins

### Option 1: Using Docker Compose (Recommended)

```bash
docker-compose up -d
```

This will:
- Use port **8081** (to avoid conflict with existing Jenkins on 8080)
- Use port **50001** for agent communication
- Create a separate volume `jenkins_home_rag_medical`
- Container name: `jenkins-dind-rag-medical`

Access Jenkins at: http://localhost:8081

### Option 2: Using Docker Run (Separate Instance)

If you want to keep both Jenkins instances running simultaneously:

```bash
docker run -d \
  --name jenkins-dind-rag-medical \
  --privileged \
  -p 8081:8080 \
  -p 50001:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home_rag_medical:/var/jenkins_home \
  jenkins-dind
```

### Option 3: Replace Existing Jenkins Container

If you want to replace the existing Jenkins container:

```bash
# Stop and remove the old container
docker stop jenkins-dind
docker rm jenkins-dind

# Run the new container with original ports
docker run -d \
  --name jenkins-dind \
  --privileged \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  jenkins-dind
```

## Port Configuration

| Service | Default Port | This Project Port | Reason |
|---------|-------------|-------------------|---------|
| Jenkins Web UI | 8080 | **8081** | Avoid conflict with existing Jenkins |
| Agent Communication | 50000 | **50001** | Avoid conflict with existing Jenkins |

## Volumes

- **jenkins_home_rag_medical**: Stores Jenkins configuration and data for this project
- **/var/run/docker.sock**: Allows Jenkins to use the host's Docker daemon

## Accessing Jenkins

1. Open your browser and navigate to: `http://localhost:8081` (or 8080 if using Option 3)
2. Get the initial admin password:
   ```bash
   docker exec jenkins-dind-rag-medical cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Follow the setup wizard

## Managing the Container

### View Logs
```bash
docker logs jenkins-dind-rag-medical
# or with docker-compose
docker-compose logs -f
```

### Stop the Container
```bash
docker stop jenkins-dind-rag-medical
# or with docker-compose
docker-compose down
```

### Start the Container
```bash
docker start jenkins-dind-rag-medical
# or with docker-compose
docker-compose up -d
```

### Remove the Container (keeps volume)
```bash
docker rm jenkins-dind-rag-medical
# or with docker-compose
docker-compose down
```

### Remove Everything (including volume)
```bash
docker-compose down -v
# or manually
docker rm jenkins-dind-rag-medical
docker volume rm jenkins_home_rag_medical
```

## Troubleshooting

### Port Already in Use
If you get a port conflict error, check what's using the port:
```bash
lsof -i :8081
# or
docker ps --format "{{.Ports}}" | grep 8081
```

### Permission Issues
The container runs with `--privileged` flag to allow Docker-in-Docker. This is required for Jenkins to build Docker images.

### Docker Socket Issues
If Jenkins can't access Docker, verify the socket mount:
```bash
docker exec jenkins-dind-rag-medical ls -la /var/run/docker.sock
```

## Notes

- The container is configured with Docker-in-Docker (DinD) support
- Jenkins user is added to the docker group
- The image includes Docker CE, Docker CLI, and Docker Compose plugins
- All Jenkins data persists in the named volume



