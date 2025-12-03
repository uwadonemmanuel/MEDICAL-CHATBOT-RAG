# MEDICAL RAG CHATBOT - Full Documentation

## 📋 Table of Contents

1. [Project Setup](#project-setup)
2. [Jenkins Setup for Deployment](#1--jenkins-setup-for-deployment)
3. [Jenkins Integration with GitHub](#2--jenkins-integration-with-github)
4. [Build Docker Image, Scan with Trivy, and Push to AWS ECR](#3--build-docker-image-scan-with-trivy-and-push-to-aws-ecr)
5. [Deployment to AWS Fargate](#4--deployment-to-aws-fargate)

---

## Project Setup

### Clone the Project

```bash
git clone https://github.com/data-guru0/LLMOPS-2-TESTING-MEDICAL.git
cd LLMOPS-2-TESTING-MEDICAL
```

### Create a Virtual Environment

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**macOS/Linux:**
```bash
python -m venv venv
source venv/bin/activate
```

### Install Dependencies

```bash
pip install -r requirements.txt
```

### Set Up Environment Variables

Create a `.env` file in the root directory:

```bash
GROQ_API_KEY=your_groq_api_key_here
HF_TOKEN=your_huggingface_token_here  # Optional
```

### Build Vector Store

Before running the application, process your medical PDF documents:

```bash
python -m app.components.data_loader
```

This will create the FAISS vector store from PDFs in the `data/` directory.

### Run the Application

```bash
python app/application.py
```

Access the chatbot at: http://localhost:5000

## ✅ Prerequisites Checklist (Complete These Before Moving Forward)

- [ ] **Docker Desktop** is installed and running in the background
- [ ] **Code versioning** is properly set up using GitHub (repository pushed and updated)
- [ ] **Dockerfile** is created and configured for the project
- [ ] **Dockerfile** is also created and configured for **Jenkins**

## ==> 1. 🚀 Jenkins Setup for Deployment

### Overview

This project includes a custom Jenkins setup with Docker-in-Docker (DinD) support. The setup uses **ports 8081 and 50001** to avoid conflicts with existing Jenkins instances.

### Prerequisites

- Docker Desktop installed and running
- Git repository set up and pushed to GitHub

### Option 1: Quick Start with Helper Script (Recommended)

Navigate to the Jenkins directory:

```bash
cd custom_jenkins
```

Run the helper script:

```bash
./run-jenkins.sh
```

The script will:
- Build the Docker image if needed
- Check for port conflicts
- Start Jenkins on ports 8081 (web) and 50001 (agent)
- Create a separate volume `jenkins_home_rag_medical`

**Access Jenkins at:** http://localhost:8081

### Option 2: Using Docker Compose

```bash
cd custom_jenkins
docker-compose up -d
```

**Access Jenkins at:** http://localhost:8081

### Option 3: Manual Docker Run

**macOS/Linux:**
```bash
cd custom_jenkins
docker build -t jenkins-dind .
docker run -d \
  --name jenkins-dind-rag-medical \
  --privileged \
  -p 8081:8080 \
  -p 50001:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home_rag_medical:/var/jenkins_home \
  jenkins-dind
```

**Windows (PowerShell):**
```powershell
cd custom_jenkins
docker build -t jenkins-dind .
docker run -d `
  --name jenkins-dind-rag-medical `
  --privileged `
  -p 8081:8080 `
  -p 50001:50000 `
  -v /var/run/docker.sock:/var/run/docker.sock `
  -v jenkins_home_rag_medical:/var/jenkins_home `
  jenkins-dind
```

> ✅ If successful, you'll get a long alphanumeric container ID

### 4. Check Jenkins Logs and Get Initial Password

```bash
docker ps
docker logs jenkins-dind-rag-medical
```

If the password isn't visible, run:

```bash
docker exec jenkins-dind-rag-medical cat /var/jenkins_home/secrets/initialAdminPassword
```

### 5. Access Jenkins Dashboard

Open your browser and go to: [http://localhost:8081](http://localhost:8081)

### 6. Install Python Inside Jenkins Container

Back in the terminal:

```bash
docker exec -u root -it jenkins-dind-rag-medical bash
apt update -y
apt install -y python3
python3 --version
ln -s /usr/bin/python3 /usr/bin/python
python --version
apt install -y python3-pip
exit
```

### 7. Restart Jenkins Container

```bash
docker restart jenkins-dind-rag-medical
```

### 8. Go to Jenkins Dashboard and Sign In Again

Open: http://localhost:8081

## ==> 2. 🔗 Jenkins Integration with GitHub

### 1. Generate a GitHub Personal Access Token

- Go to **GitHub** → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
- Click **Generate new token (classic)**
- Provide:
  - A **name** (e.g., `Jenkins Integration`)
  - Select scopes:
    - `repo` (for full control of private repositories)
    - `admin:repo_hook` (for webhook integration)

- Generate the token and **save it securely** (you won’t see it again!).

> ℹ️ **What is this token?**
> A GitHub token is a secure way to authenticate Jenkins (or any CI/CD tool) to access your GitHub repositories without needing your GitHub password. It's safer and recommended over using plain credentials.

---

### 2. Add GitHub Token to Jenkins Credentials

- Go to **Jenkins Dashboard** → **Manage Jenkins** → **Credentials** → **(Global)** → **Add Credentials**
- Fill in the following:
  - **Username:** Your GitHub username
  - **Password:** Paste the GitHub token you just generated
  - **ID:** `github-token`
  - **Description:** `GitHub Token for Jenkins`

Click **Save**.

---

### 3. Create a New Pipeline Job in Jenkins

- Go back to **Jenkins Dashboard**
- Click **New Item** → Select **Pipeline**
- Enter a name (e.g., `medical-rag-pipeline`)
- Click **OK** → Scroll down, configure minimal settings → Click **Save**

> ⚠️ You will have to configure pipeline details **again** in the next step

---

### 4. Generate Checkout Script from Jenkins UI

- In the left sidebar of your pipeline project, click **Pipeline Syntax**
- From the dropdown, select **`checkout: General SCM`**
- Fill in:
  - SCM: Git
  - Repository URL: Your GitHub repo URL
  - Credentials: Select the `github-token` you just created
- Click **Generate Pipeline Script**
- Copy the generated Groovy script (e.g., `checkout([$class: 'GitSCM', ...])`)

---

### 5. Create a `Jenkinsfile` in Your Repo ( Already done )

- Open your project in **VS Code**
- Create a file named `Jenkinsfile` in the root directory


### 6. Push the Jenkinsfile to GitHub

```bash
git add Jenkinsfile
git commit -m "Add Jenkinsfile for CI pipeline"
git push origin main
```

---

### 7. Trigger the Pipeline

- Go to **Jenkins Dashboard** → Select your pipeline → Click **Build Now**

🎉 **You’ll see a SUCCESS message if everything works!**

✅ **Your GitHub repository has been cloned inside Jenkins’ workspace!**

---

> 🔁 If you already cloned the repo with a `Jenkinsfile` in it, you can skip creating a new one manually.

## ==> 3. 🐳 Build Docker Image, Scan with Trivy, and Push to AWS ECR

### 1. Install Trivy in Jenkins Container

```bash
docker exec -u root -it jenkins-dind-rag-medical bash
apt update -y
curl -LO https://github.com/aquasecurity/trivy/releases/download/v0.62.1/trivy_0.62.1_Linux-64bit.deb
dpkg -i trivy_0.62.1_Linux-64bit.deb
trivy --version
exit
```

Then restart the container:

```bash
docker restart jenkins-dind-rag-medical
```

---

### 2. Install AWS Plugins in Jenkins

- Go to **Jenkins Dashboard** → **Manage Jenkins** → **Plugins**
- Install:
  - **AWS SDK**
  - **AWS Credentials**
- Restart the Jenkins container:

```bash
docker restart jenkins-dind-rag-medical
```

---

### 3. Create IAM User in AWS

Follow these detailed steps to create an IAM user with ECR access:

#### Step 1: Navigate to IAM Console

1. Log in to your **AWS Console** at [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. In the search bar at the top, type **"IAM"** and click on **IAM** (Identity and Access Management)
3. In the left sidebar, click on **Users**

#### Step 2: Create New User

1. Click the **"Add users"** or **"Create user"** button (usually a blue button at the top)
2. In the **User name** field, enter a descriptive name (e.g., `jenkins-ecr-user` or `rag-medical-jenkins`)
3. **DO NOT** check "Provide user access to the AWS Management Console" (we only need programmatic access)
4. Click **"Next"**

#### Step 3: Set Permissions

1. You'll see options for setting permissions. Select **"Attach policies directly"**
2. In the search box, type: **`ECR`** or **`AmazonEC2ContainerRegistry`**
3. Find and **check the box** next to: **`AmazonEC2ContainerRegistryFullAccess`**
   - This policy provides full access to Amazon ECR (push, pull, create repositories, etc.)
4. Click **"Next"**

#### Step 4: Review and Create

1. Review the user details:
   - User name: (your chosen name)
   - Access type: Programmatic access
   - Permissions: AmazonEC2ContainerRegistryFullAccess
2. Click **"Create user"**

#### Step 5: Save Access Credentials (CRITICAL!)

⚠️ **IMPORTANT: This is the ONLY time you'll see these credentials!**

After clicking "Create user", you'll see a success page with:

1. **Access key ID** - A long string starting with `AKIA...`
2. **Secret access key** - A long string of random characters

**You MUST save these credentials now:**

**Option A: Download CSV file (Recommended)**
- Click **"Download .csv file"** button
- Save the file securely (e.g., `aws-credentials.csv`)
- Store it in a secure location (password manager, encrypted drive)

**Option B: Copy manually**
- Click the **"Show"** link next to Secret access key to reveal it
- Copy both the **Access key ID** and **Secret access key**
- Paste them into a secure password manager or encrypted document

**Option C: Copy from the page**
- The Access key ID is visible
- Click "Show" for the Secret access key
- Copy both values

#### Step 6: Verify Credentials

Before closing the page, verify you have:
- ✅ Access key ID (starts with `AKIA`)
- ✅ Secret access key (long random string)

> 🔐 **Security Best Practices:**
> - Never commit these credentials to Git
> - Never share them in screenshots or documentation
> - Store them in a password manager
> - If credentials are compromised, delete and recreate them immediately

#### What You'll Need Next

You'll use these credentials in the next step when adding AWS credentials to Jenkins:
- **Access Key ID**: `AKIA...` (from Step 5)
- **Secret Access Key**: `...` (from Step 5)

> 💡 **Tip:** If you lose these credentials, you'll need to create a new access key (the secret cannot be retrieved again, only regenerated).

---

### 4. Add AWS Credentials to Jenkins

- Go to **Jenkins Dashboard** → **Manage Jenkins** → **Credentials**
- Click on **(Global)** → **Add Credentials**
- Select **AWS Credentials**
- Add:
  - **Access Key ID**
  - **Secret Access Key**
- Give an ID (e.g., `aws-ecr-creds`) and Save

---

### 5. Install AWS CLI Inside Jenkins Container

```bash
docker exec -u root -it jenkins-dind-rag-medical bash
apt update
apt install -y unzip curl
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
aws --version
exit
```

---

### 6. Create an ECR Repository

- Go to AWS Console → ECR → Create Repository
- Note the **repository URI**

---

### 7. Add Build, Scan, and Push Stage in Jenkinsfile (  Already done if cloned )



> 🔐 **Tip**: Change `--exit-code 0` to `--exit-code 1` in Trivy to make the pipeline fail on vulnerabilities.

---

### 8. Fix Docker Daemon Issues (If Any)

If you encounter Docker socket permission issues (error: `permission denied while trying to connect to the Docker daemon socket`), follow these steps:

#### Step 1: Check Current Docker Socket Permissions

```bash
docker exec -u root -it jenkins-dind-rag-medical bash
ls -la /var/run/docker.sock
getent group docker
groups jenkins
exit
```

#### Step 2: Fix Docker Socket Permissions

```bash
docker exec -u root -it jenkins-dind-rag-medical bash
# Ensure docker group exists
groupadd -f docker

# Add Jenkins user to docker group
usermod -aG docker jenkins

# Fix socket permissions (if mounted from host)
chown root:docker /var/run/docker.sock
chmod 660 /var/run/docker.sock

# Verify Jenkins is in docker group
groups jenkins

# Test Docker access as Jenkins user
su - jenkins -c "docker ps"

exit
```

#### Step 3: Restart Jenkins Container

```bash
docker restart jenkins-dind-rag-medical
```

#### Step 4: Verify Docker Access from Jenkins Pipeline

After restarting, test Docker access:

1. Go to **Jenkins Dashboard** → Your Pipeline → **Configure**
2. Scroll to **Pipeline** section
3. Add a test stage or run a build with a simple Docker command
4. Check the console output for Docker permission errors

#### Alternative Solution: Fix Host Docker Socket Permissions

If the issue persists, the problem might be with the host Docker socket permissions:

**macOS/Linux:**
```bash
# Check host Docker socket permissions
ls -la /var/run/docker.sock

# Fix host permissions (if needed)
sudo chmod 666 /var/run/docker.sock
# OR
sudo chown root:docker /var/run/docker.sock
sudo chmod 660 /var/run/docker.sock
```

**Windows (Docker Desktop):**
- Docker Desktop on Windows handles permissions automatically
- Ensure Docker Desktop is running
- Try restarting Docker Desktop

#### Step 5: Test Docker Build in Jenkins

Create a simple test pipeline or add a test stage:

```groovy
stage('Test Docker Access') {
    steps {
        sh 'docker ps'
        sh 'docker --version'
    }
}
```

If this succeeds, Docker permissions are fixed!

#### Common Error Messages and Solutions

**Error:** `permission denied while trying to connect to the Docker daemon socket`
- **Solution:** Follow Steps 1-3 above

**Error:** `dial unix /var/run/docker.sock: connect: permission denied`
- **Solution:** Ensure Jenkins user is in docker group and socket has correct permissions

**Error:** `Cannot connect to the Docker daemon`
- **Solution:** Verify Docker Desktop is running on the host

**Error:** `client version 1.52 is too new. Maximum supported API version is 1.43`
- **Solution:** This happens when the Docker client version is newer than what the host Docker daemon supports. Fix by:
  1. **If using docker-compose:** The `docker-compose.yml` already sets `DOCKER_API_VERSION=1.43` in the environment
  2. **If using docker run:** Add `-e DOCKER_API_VERSION=1.43` to your docker run command (already included in `run-jenkins.sh`)
  3. **If container is already running:** Set it manually:
     ```bash
     docker exec -u root -it jenkins-dind-rag-medical bash
     echo 'export DOCKER_API_VERSION=1.43' >> /etc/profile
     echo 'export DOCKER_API_VERSION=1.43' >> ~/.bashrc
     exit
     docker restart jenkins-dind-rag-medical
     ```
  4. **Verify it's set:**
     ```bash
     docker exec jenkins-dind-rag-medical env | grep DOCKER_API_VERSION
     ```
     Should show: `DOCKER_API_VERSION=1.43`

> **Note:** The Dockerfile already includes Docker installation and adds the Jenkins user to the docker group. However, if you're mounting the Docker socket from the host (`-v /var/run/docker.sock:/var/run/docker.sock`), you may need to fix permissions as shown above. The `DOCKER_API_VERSION=1.43` environment variable is set in the Dockerfile and docker-compose.yml to ensure compatibility with host Docker daemons.

## ==> 4. 🚀 Deployment to AWS Fargate

### ✅ Prerequisites

1. **Jenkinsfile Deployment Stage** (Will be configured in this section)
2. **Docker image pushed to ECR** (completed in previous steps)

### 🔐 IAM User Permissions

- Go to **AWS Console** → **IAM** → Select your Jenkins user
- Attach the following policies:
  - `AmazonEC2ContainerRegistryFullAccess` (already done)
  - `AmazonECS_FullAccess` (for ECS and Fargate)
  - `AmazonEC2FullAccess` (for VPC and networking resources)
  - `IAMFullAccess` (for creating task execution roles, or create custom policy with minimal permissions)

---

### 🌐 Setup AWS Fargate (Manual Step)

Follow these detailed steps to deploy your RAG Medical Chatbot to AWS Fargate:

#### Prerequisites

Before starting, ensure you have:
- ✅ Docker image pushed to ECR (completed in previous steps)
- ✅ ECR repository URI (e.g., `844810703328.dkr.ecr.eu-north-1.amazonaws.com/rag-medical-repo`)
- ✅ IAM user with `AmazonECS_FullAccess` and `AmazonEC2FullAccess` policies attached
- ✅ Environment variables ready (GROQ_API_KEY, HF_TOKEN)

#### Step 1: Navigate to AWS ECS

1. Log in to your **AWS Console** at [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. In the search bar at the top, type **"ECS"** and click on **Elastic Container Service**
3. You'll see the ECS dashboard
4. Click **"Clusters"** in the left sidebar

#### Step 2: Create ECS Cluster

1. Click **"Create Cluster"** button
2. **Cluster name:**
   - Enter: `rag-medical-chatbot-cluster` (or your preferred name)
   - Must be unique within your AWS account
   - Use lowercase letters, numbers, and hyphens only

3. **Infrastructure:**
   - Select **"AWS Fargate (serverless)"**
   - This option provides serverless compute (no EC2 instances to manage)

4. **Tags** (optional):
   - Add tags for organization (e.g., `Project: RAG-Medical-Chatbot`)

5. Click **"Create"**

6. **Wait for cluster creation:**
   - This takes 1-2 minutes
   - Status will change to "Active"

#### Step 3: Create Task Definition

1. In the ECS dashboard, click **"Task definitions"** in the left sidebar
2. Click **"Create new task definition"**
3. **Task definition family:**
   - Enter: `rag-medical-chatbot-task` (or your preferred name)

4. **Launch type:**
   - Select **"Fargate"**

5. **Task size:**
   - **CPU:** `0.5 vCPU` (for testing) or `1 vCPU` (recommended for production)
   - **Memory:** `1 GB` (for testing) or `2 GB` (recommended for production)

6. **Task execution role:**
   - Select **"Create new role"** (AWS will create `ecsTaskExecutionRole`)
   - Or select existing role if you have one with ECR permissions

7. **Task role:**
   - Select **"None"** (unless your app needs AWS service access)

8. **Container definitions:**
   - Click **"Add container"**
   - **Container name:** `rag-medical-chatbot`
   - **Image URI:** Enter your ECR image URI:
     - Format: `<account-id>.dkr.ecr.<region>.amazonaws.com/rag-medical-repo:latest`
     - Example: `844810703328.dkr.ecr.eu-north-1.amazonaws.com/rag-medical-repo:latest`
   - **Port mappings:**
     - **Container port:** `5000`
     - **Protocol:** `TCP`
   - **Environment variables:**
     - Click **"Add environment variable"**
     - Add:
       - **Name:** `GROQ_API_KEY`, **Value:** Your Groq API key
       - **Name:** `HF_TOKEN`, **Value:** Your HuggingFace token (optional)
       - **Name:** `PYTHONUNBUFFERED`, **Value:** `1`
   - **Logging:**
     - **Log driver:** `awslogs`
     - **Log group:** Create new or select existing (e.g., `/ecs/rag-medical-chatbot`)
     - **Log stream prefix:** `ecs`
   - Click **"Add"**

9. Click **"Create"**

#### Step 4: Create Service

1. Go back to your cluster (`rag-medical-chatbot-cluster`)
2. Click on the cluster name
3. Click **"Create"** button (or go to **"Services"** tab → **"Create"**)

4. **Service configuration:**
   - **Launch type:** `Fargate`
   - **Task definition:**
     - **Family:** Select `rag-medical-chatbot-task`
     - **Revision:** Select `1` (latest)
   - **Service name:** `rag-medical-chatbot-service`
   - **Number of tasks:** `1` (for testing) or `2` (for high availability)

5. **Networking:**
   - **VPC:** Select your default VPC or create a new one
   - **Subnets:** Select at least 2 subnets (for high availability)
   - **Security groups:** 
     - Select existing or create new
     - Must allow inbound traffic on port `5000` (or port you configure in load balancer)
   - **Auto-assign public IP:** `ENABLED` (required for Fargate tasks to pull images from ECR)

6. **Load balancing (optional but recommended):**
   - **Load balancer type:** `Application Load Balancer` (recommended)
   - **Load balancer name:** Create new or select existing
   - **Container to load balance:**
     - **Container name:** `rag-medical-chatbot`
     - **Container port:** `5000`
   - **Listener:**
     - **Protocol:** `HTTP`
     - **Port:** `80`
   - **Target group:**
     - **Target group name:** `rag-medical-chatbot-tg`
     - **Health check path:** `/` (root path)
     - **Health check interval:** `30 seconds`
     - **Health check timeout:** `5 seconds`
     - **Healthy threshold:** `2`
     - **Unhealthy threshold:** `3`

7. **Service auto-scaling (optional):**
   - **Auto Scaling:** Enable if desired
   - **Min tasks:** `1`
   - **Max tasks:** `5-10` (based on expected traffic)
   - **Target CPU utilization:** `70%`

8. Click **"Create"**

9. **Wait for service creation:**
   - This takes 3-5 minutes
   - Watch the service events for progress
   - Status will change to "Running" when tasks are healthy

#### Step 5: Access Your Application

1. **If using a Load Balancer (Recommended):**
   - Go to **"Load balancers"** in EC2 console (or from ECS service details)
   - Click on your load balancer
   - Copy the **DNS name** (e.g., `rag-medical-chatbot-1234567890.us-east-1.elb.amazonaws.com`)
   - **Access using HTTP:** `http://<dns-name>`
   - ⚠️ **Important:** Use `http://` (not `https://`) unless you've configured HTTPS (see Step 6)

2. **If no load balancer (Direct Public IP Access):**
   - Get the public IP of your task:
     - Go to **ECS** → **Clusters** → Your cluster → **Tasks** tab
     - Click on the running task
     - Find **"Public IP"** in the network section
     - Example: `12.16.60.189`
   - **Access using HTTP:** `http://<public-ip>:5000`
   - ⚠️ **Important:** 
     - Use `http://` (not `https://`) - HTTPS is not supported without a load balancer
     - Include the port `:5000` in the URL
     - Example: `http://12.16.60.189:5000`

3. **Test your application:**
   - Open the URL in your browser
   - ⚠️ **If your browser shows "This site can't provide a secure connection" or "HTTPS not supported":**
     - Make sure you're using `http://` (not `https://`)
     - Some browsers auto-redirect to HTTPS - type `http://` explicitly
     - If browser blocks HTTP, click "Advanced" → "Proceed to site (unsafe)" or use a different browser
   - You should see your RAG Medical Chatbot interface
   - Try asking a medical question to verify it's working

4. **Security Note:**
   - Direct IP access over HTTP is not secure (data is not encrypted)
   - For production, use a load balancer with HTTPS (see Step 6)
   - HTTP is fine for testing, but HTTPS is recommended for production

#### Step 6: Enable HTTPS (Optional but Recommended)

1. Go to **EC2 Console** → **Load Balancers**
2. Select your load balancer
3. Click **"Listeners"** tab → **"Add listener"**
4. Configure:
   - **Protocol:** `HTTPS`
   - **Port:** `443`
   - **Default action:** Forward to your target group
   - **SSL certificate:** Request or upload a certificate from ACM (AWS Certificate Manager)
5. Click **"Save"**

#### Troubleshooting

**Service won't start:**
- Check **"Events"** tab in service details for error messages
- Check CloudWatch Logs for container logs
- Verify task definition image URI is correct
- Check environment variables are set
- Verify security groups allow traffic

**Tasks keep stopping:**
- Check CloudWatch Logs for application errors
- Verify health check path is correct (`/`)
- Check task definition resource limits (CPU/memory)
- Ensure ECR image is accessible (check IAM permissions)

**Can't access application:**
- Wait for service status: "Running" and tasks: "Healthy"
- Check load balancer DNS name or task public IP
- Verify security groups allow inbound traffic (port 80/443 or 5000)
- Check target group health status

**"This site can't provide a secure connection" or "HTTPS not supported" error:**
- **Cause:** You're trying to access via HTTPS (`https://`) but the application only supports HTTP
- **Solution:** 
  - Use `http://` (not `https://`) in the URL
  - For direct IP access: `http://<public-ip>:5000` (include the port)
  - For load balancer: `http://<dns-name>` (port 80 is default)
  - If browser auto-redirects to HTTPS, type `http://` explicitly in the address bar
  - Some browsers may show a warning - click "Advanced" → "Proceed" to continue
- **Note:** HTTPS requires a load balancer with SSL certificate (see Step 6). Direct IP access only supports HTTP.

**Image pull errors:**
- Verify ECR image URI is correct
- Check task execution role has ECR permissions
- Ensure image tag exists in ECR
- Check region matches
- Verify VPC has internet gateway (for public IP)

**High costs:**
- Use appropriate task size (start with 0.5 vCPU, 1 GB)
- Set up auto-scaling to scale down during low traffic
- Use CloudWatch to monitor costs
- Consider using Spot Fargate (if available in your region)

#### Cost Optimization Tips

1. **Use appropriate task size:**
   - Start with **0.5 vCPU, 1 GB** for testing
   - Scale to **1 vCPU, 2 GB** for production
   - Monitor CloudWatch metrics to optimize

2. **Configure auto-scaling:**
   - Set minimum tasks to `1` during low traffic
   - Scale up based on CPU/memory utilization
   - Use scheduled scaling for predictable traffic patterns

3. **Monitor usage:**
   - Use CloudWatch to track task count and resource utilization
   - Set up billing alerts
   - Review and optimize task definitions regularly

#### Next Steps

After Fargate service is running:
1. ✅ Test your chatbot at the provided URL
2. ✅ Configure Jenkinsfile for Fargate deployment (see below)
3. ✅ Set up CloudWatch monitoring and alarms
4. ✅ Configure auto-scaling based on traffic
5. ✅ Set up HTTPS with ACM certificate

Your RAG Medical Chatbot is now live on AWS Fargate! 🚀

---

### 🧪 Run Jenkins Pipeline

- Go to **Jenkins Dashboard** → Select your pipeline job
- Click **Build Now**

If all stages succeed (Checkout → Build → Trivy Scan → Push to ECR → Deploy to Fargate):

🎉 **CI/CD Deployment to AWS Fargate is complete!**

✅ Your app is now live and running on AWS 🚀

---

## 📝 Additional Notes

### Container Management

**View running containers:**
```bash
docker ps
```

**View all containers (including stopped):**
```bash
docker ps -a
```

**Stop Jenkins container:**
```bash
docker stop jenkins-dind-rag-medical
```

**Start Jenkins container:**
```bash
docker start jenkins-dind-rag-medical
```

**View logs:**
```bash
docker logs -f jenkins-dind-rag-medical
```

**Remove container (keeps volume):**
```bash
docker rm jenkins-dind-rag-medical
```

**Remove container and volume:**
```bash
docker rm jenkins-dind-rag-medical
docker volume rm jenkins_home_rag_medical
```

### Port Configuration Summary

| Web Port | Agent Port | Container Name | Volume Name |
|----------|------------|----------------|-------------|
| 8081 | 50001 | jenkins-dind-rag-medical | jenkins_home_rag_medical |

### Troubleshooting

**Port conflicts:**
- Check what's using the port: `lsof -i :8081` or `docker ps --format "{{.Ports}}"`
- Use different ports or stop the conflicting service

**Docker socket issues:**
- Ensure Docker Desktop is running
- Verify the socket mount: `docker exec jenkins-dind-rag-medical ls -la /var/run/docker.sock`

**Permission denied errors:**
- The container runs with `--privileged` flag for Docker-in-Docker support
- Jenkins user is automatically added to the docker group in the Dockerfile

### Project-Specific Configuration

This Jenkins setup is configured for the RAG Medical Chatbot project with:
- Docker-in-Docker (DinD) support for building Docker images
- Python 3 support (install manually as shown in step 6)
- Trivy for security scanning
- AWS CLI and plugins for ECR and Fargate deployment

For more details, see the `custom_jenkins/README.md` file.
