# Use the Jenkins image as the base image
FROM jenkins/jenkins:lts

# Switch to root user to install dependencies
USER root

# Install prerequisites and Docker
# Pin Docker version to ensure compatibility with host Docker daemon
RUN apt-get update -y && \
    apt-get install -y ca-certificates curl gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update -y && \
    apt-get install -y docker-ce=5:24.0.* docker-ce-cli=5:24.0.* containerd.io docker-buildx-plugin docker-compose-plugin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Docker API version for compatibility
ENV DOCKER_API_VERSION=1.43

# Add Jenkins user to the Docker group (create if it doesn't exist)
RUN groupadd -f docker && \
    usermod -aG docker jenkins

# Create the Docker directory and volume for DinD
RUN mkdir -p /var/lib/docker
VOLUME /var/lib/docker

# Switch back to the Jenkins user
USER jenkins