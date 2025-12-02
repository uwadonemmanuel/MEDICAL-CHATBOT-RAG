#!/bin/bash

# Script to run Jenkins container for RAG Medical Chatbot project
# This script handles conflicts with existing Jenkins containers

set -e

CONTAINER_NAME="jenkins-dind-rag-medical"
IMAGE_NAME="jenkins-dind"
WEB_PORT="8081"
AGENT_PORT="50001"
VOLUME_NAME="jenkins_home_rag_medical"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Jenkins Docker-in-Docker Setup${NC}"
echo "=================================="

# Check if image exists
if ! docker image inspect $IMAGE_NAME > /dev/null 2>&1; then
    echo -e "${YELLOW}Image $IMAGE_NAME not found. Building...${NC}"
    docker build -t $IMAGE_NAME .
fi

# Check if container already exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}Container $CONTAINER_NAME is already running${NC}"
        echo "Access Jenkins at: http://localhost:$WEB_PORT"
        exit 0
    else
        echo -e "${YELLOW}Container $CONTAINER_NAME exists but is stopped. Starting...${NC}"
        docker start $CONTAINER_NAME
        echo -e "${GREEN}Container started!${NC}"
        echo "Access Jenkins at: http://localhost:$WEB_PORT"
        exit 0
    fi
fi

# Check for port conflicts
if lsof -Pi :$WEB_PORT -sTCP:LISTEN -t >/dev/null 2>&1 || \
   docker ps --format '{{.Ports}}' | grep -q ":$WEB_PORT->"; then
    echo -e "${RED}Port $WEB_PORT is already in use!${NC}"
    echo "Please stop the service using port $WEB_PORT or use a different port."
    exit 1
fi

if lsof -Pi :$AGENT_PORT -sTCP:LISTEN -t >/dev/null 2>&1 || \
   docker ps --format '{{.Ports}}' | grep -q ":$AGENT_PORT->"; then
    echo -e "${RED}Port $AGENT_PORT is already in use!${NC}"
    echo "Please stop the service using port $AGENT_PORT or use a different port."
    exit 1
fi

# Run the container
echo -e "${GREEN}Starting Jenkins container...${NC}"
docker run -d \
  --name $CONTAINER_NAME \
  --privileged \
  -p $WEB_PORT:8080 \
  -p $AGENT_PORT:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $VOLUME_NAME:/var/jenkins_home \
  $IMAGE_NAME

echo -e "${GREEN}Jenkins container started successfully!${NC}"
echo ""
echo "Container Name: $CONTAINER_NAME"
echo "Web UI: http://localhost:$WEB_PORT"
echo "Agent Port: $AGENT_PORT"
echo ""
echo "To get the initial admin password, run:"
echo "  docker exec $CONTAINER_NAME cat /var/jenkins_home/secrets/initialAdminPassword"
echo ""
echo "To view logs:"
echo "  docker logs -f $CONTAINER_NAME"
echo ""
echo "To stop:"
echo "  docker stop $CONTAINER_NAME"



