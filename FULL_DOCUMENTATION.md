# MEDICAL RAG CHATBOT - Full Documentation

## 📋 Table of Contents

1. [Project Setup](#project-setup)
2. [Jenkins Setup for Deployment](#1--jenkins-setup-for-deployment)
3. [Jenkins Integration with GitHub](#2--jenkins-integration-with-github)
4. [Build Docker Image, Scan with Trivy, and Push to AWS ECR](#3--build-docker-image-scan-with-trivy-and-push-to-aws-ecr)
5. [Deployment to AWS App Runner](#4--deployment-to-aws-app-runner)

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

### Option 3: Manual Docker Run (Separate Instance)

If you want to run alongside an existing Jenkins instance:

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

### Option 4: Replace Existing Jenkins (Use Original Ports)

If you want to replace an existing Jenkins container and use ports 8080/50000:

```bash
# Stop and remove existing container
docker stop jenkins-dind
docker rm jenkins-dind

# Build and run
cd custom_jenkins
docker build -t jenkins-dind .
docker run -d \
  --name jenkins-dind \
  --privileged \
  -p 8080:8080 \
  -p 50000:50000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v jenkins_home:/var/jenkins_home \
  jenkins-dind
```

**Access Jenkins at:** http://localhost:8080

### 4. Check Jenkins Logs and Get Initial Password

```bash
# For separate instance
docker ps
docker logs jenkins-dind-rag-medical

# For replaced instance
docker logs jenkins-dind
```

If the password isn't visible, run:

```bash
# For separate instance
docker exec jenkins-dind-rag-medical cat /var/jenkins_home/secrets/initialAdminPassword

# For replaced instance
docker exec jenkins-dind cat /var/jenkins_home/secrets/initialAdminPassword
```

### 5. Access Jenkins Dashboard

- **Separate instance:** Open your browser and go to: [http://localhost:8081](http://localhost:8081)
- **Replaced instance:** Open your browser and go to: [http://localhost:8080](http://localhost:8080)

### 6. Install Python Inside Jenkins Container

Back in the terminal:

**For separate instance:**
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

**For replaced instance:**
```bash
docker exec -u root -it jenkins-dind bash
apt update -y
apt install -y python3
python3 --version
ln -s /usr/bin/python3 /usr/bin/python
python --version
apt install -y python3-pip
exit
```

### 7. Restart Jenkins Container

**For separate instance:**
```bash
docker restart jenkins-dind-rag-medical
```

**For replaced instance:**
```bash
docker restart jenkins-dind
```

### 8. Go to Jenkins Dashboard and Sign In Again

- **Separate instance:** http://localhost:8081
- **Replaced instance:** http://localhost:8080

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

**For separate instance:**
```bash
docker exec -u root -it jenkins-dind-rag-medical bash
apt update -y
curl -LO https://github.com/aquasecurity/trivy/releases/download/v0.62.1/trivy_0.62.1_Linux-64bit.deb
dpkg -i trivy_0.62.1_Linux-64bit.deb
trivy --version
exit
```

**For replaced instance:**
```bash
docker exec -u root -it jenkins-dind bash
apt update -y
curl -LO https://github.com/aquasecurity/trivy/releases/download/v0.62.1/trivy_0.62.1_Linux-64bit.deb
dpkg -i trivy_0.62.1_Linux-64bit.deb
trivy --version
exit
```

Then restart the container:

**For separate instance:**
```bash
docker restart jenkins-dind-rag-medical
```

**For replaced instance:**
```bash
docker restart jenkins-dind
```

---

### 2. Install AWS Plugins in Jenkins

- Go to **Jenkins Dashboard** → **Manage Jenkins** → **Plugins**
- Install:
  - **AWS SDK**
  - **AWS Credentials**
- Restart the Jenkins container:

**For separate instance:**
```bash
docker restart jenkins-dind-rag-medical
```

**For replaced instance:**
```bash
docker restart jenkins-dind
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

**For separate instance:**
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

**For replaced instance:**
```bash
docker exec -u root -it jenkins-dind bash
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

**For separate instance:**
```bash
docker exec -u root -it jenkins-dind-rag-medical bash
ls -la /var/run/docker.sock
getent group docker
groups jenkins
exit
```

**For replaced instance:**
```bash
docker exec -u root -it jenkins-dind bash
ls -la /var/run/docker.sock
getent group docker
groups jenkins
exit
```

#### Step 2: Fix Docker Socket Permissions

**For separate instance:**
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

**For replaced instance:**
```bash
docker exec -u root -it jenkins-dind bash
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

**For separate instance:**
```bash
docker restart jenkins-dind-rag-medical
```

**For replaced instance:**
```bash
docker restart jenkins-dind
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

> **Note:** The Dockerfile already includes Docker installation and adds the Jenkins user to the docker group. However, if you're mounting the Docker socket from the host (`-v /var/run/docker.sock:/var/run/docker.sock`), you may need to fix permissions as shown above.

## ==> 4. 🚀 Deployment to AWS Elastic Beanstalk

### ✅ Prerequisites

1. **Jenkinsfile Deployment Stage** (Will be configured in this section)
2. **Docker image pushed to ECR** (completed in previous steps)

### 🔐 IAM User Permissions

- Go to **AWS Console** → **IAM** → Select your Jenkins user
- Attach the policy: `AWSElasticBeanstalkFullAccess`
- Also ensure these policies are attached:
  - `AmazonEC2ContainerRegistryFullAccess` (already done)
  - `AmazonEC2FullAccess` (for EC2 instances created by Beanstalk)

---

### 🌐 Setup AWS Elastic Beanstalk (Manual Step)

Follow these detailed steps to deploy your RAG Medical Chatbot to AWS Elastic Beanstalk:

#### Prerequisites

Before starting, ensure you have:
- ✅ Docker image pushed to ECR (completed in previous steps)
- ✅ ECR repository URI (e.g., `844810703328.dkr.ecr.eu-north-1.amazonaws.com/rag-medical-repo`)
- ✅ IAM user with `AWSElasticBeanstalkFullAccess` and `AmazonEC2FullAccess` policies attached
- ✅ Environment variables ready (GROQ_API_KEY, HF_TOKEN)

#### Step 1: Navigate to AWS Elastic Beanstalk

1. Log in to your **AWS Console** at [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. In the search bar at the top, type **"Elastic Beanstalk"** and click on **Elastic Beanstalk**
3. You'll see the Elastic Beanstalk dashboard
4. Click the **"Create application"** button (usually a blue button)

#### Step 2: Create Application

1. **Application name:**
   - Enter: `rag-medical-chatbot` (or your preferred name)
   - Must be unique within your AWS account
   - Use lowercase letters, numbers, and hyphens only

2. **Application tags** (optional):
   - Add tags for organization (e.g., `Project: RAG-Medical-Chatbot`)

3. Click **"Create"**

#### Step 3: Create Environment

1. After application is created, click **"Create environment"** button
2. Select **"Web server environment"** (default)
3. Click **"Select"**

#### Step 4: Configure Environment

1. **Environment name:**
   - Enter: `rag-medical-chatbot-prod` (or your preferred name)
   - Must be unique within the application

2. **Domain:**
   - Elastic Beanstalk will auto-generate a domain
   - Format: `<env-name>.<region>.elasticbeanstalk.com`

3. **Platform:**
   - Select **"Docker"**
   - Platform branch: **"Docker running on 64bit Amazon Linux 2"** (latest)
   - Platform version: Leave as **"Latest"**

4. **Application code:**
   - Select **"Sample application"** for now (we'll configure ECR image later)
   - Or upload `Dockerrun.aws.json` file (see Step 11)

5. **Preset:**
   - **"Single instance (free tier eligible)"** for testing
   - **"High availability"** for production (recommended)

6. Click **"Review and launch"** or continue with advanced settings

#### Step 5: Configure Instance and Scaling

1. **Instance type:**
   - **t3.micro** - Free tier eligible, good for testing
   - **t3.small** - Recommended for production
   - **t3.medium** - For higher traffic

2. **Scaling:**
   - **Min instances:** 1
   - **Max instances:** 5-10 (based on expected traffic)
   - **Scaling trigger:** CPU utilization > 70% (default)

3. **Service role:**
   - Select **"Create and use new service role"** (recommended)
   - AWS will create the role automatically

4. **EC2 instance profile:**
   - Select **"Create and use new instance profile"** (recommended)
   - This allows EC2 instances to access ECR

#### Step 6: Configure Health Check and Monitoring

1. **Health check:**
   - **Health check URL:** `/` (root path)
   - **Health check grace period:** 300 seconds (5 minutes)

2. **Monitoring:**
   - **Health check:** **"Enhanced"** (recommended)
   - **Logs:** Enable **"Instance log streaming to CloudWatch Logs"**

3. Click **"Review and launch"**

#### Step 7: Review and Launch

1. **Review all settings:**
   - Application name
   - Environment name
   - Platform: Docker
   - Instance type
   - Scaling configuration

2. Click **"Create environment"**

3. **Wait for environment creation:**
   - This takes 5-10 minutes
   - Watch the events log for progress
   - Status will change from "Launching" to "Up"

#### Step 8: Configure Environment Variables

1. Once environment is **"Up"**, go to **"Configuration"** tab
2. Click **"Edit"** on **"Software"** configuration
3. Scroll to **"Environment properties"**
4. Add environment variables:

   **Variable 1:**
   - **Name:** `GROQ_API_KEY`
   - **Value:** Your Groq API key
   
   **Variable 2:**
   - **Name:** `HF_TOKEN`
   - **Value:** Your HuggingFace token (optional)
   
   **Variable 3:**
   - **Name:** `PYTHONUNBUFFERED`
   - **Value:** `1`

5. Click **"Apply"**

#### Step 9: Configure ECR Image Deployment

**Option A: Using Docker Configuration (Recommended)**

1. Go to **"Configuration"** → **"Docker"**
2. Click **"Edit"**
3. **Docker image:** Enter your ECR image URI:
   - Format: `<account-id>.dkr.ecr.<region>.amazonaws.com/rag-medical-repo:latest`
   - Example: `844810703328.dkr.ecr.eu-north-1.amazonaws.com/rag-medical-repo:latest`
4. **Port:** `5000`
5. Click **"Apply"**

**Option B: Using Dockerrun.aws.json**

1. Create `Dockerrun.aws.json` file in your project root (see detailed guide in `AWS_ELASTIC_BEANSTALK_SETUP.md`)
2. Commit and push to GitHub
3. In Elastic Beanstalk, go to **"Upload and deploy"**
4. Upload the file or deploy from GitHub

#### Step 10: Access Your Application

1. Once deployment is complete, find your application URL:
   - Go to environment dashboard
   - Look for **"Domain"** or **"CNAME"**
   - Format: `http://rag-medical-chatbot-prod.<region>.elasticbeanstalk.com`

2. **Test your application:**
   - Open the URL in your browser
   - You should see your RAG Medical Chatbot interface
   - Try asking a medical question to verify it's working

3. **Note:** Elastic Beanstalk uses HTTP by default
   - For HTTPS, configure SSL certificate (optional, see Step 11)

#### Step 11: Enable HTTPS (Optional but Recommended)

1. Go to **"Configuration"** → **"Load balancer"**
2. Click **"Edit"**
3. Under **"Listeners"**, add HTTPS listener:
   - **Port:** 443
   - **Protocol:** HTTPS
   - **SSL certificate:** Request or upload a certificate
4. Click **"Apply"**

#### Troubleshooting

**Environment won't start:**
- Check **"Events"** tab for error messages
- Check **"Logs"** → **"Last 100 Lines"**
- Verify Docker image URI is correct
- Check environment variables are set

**Health check failing:**
- Ensure Flask responds on `/` path
- Check application logs
- Verify port 5000 is configured
- Check security groups allow traffic

**Can't access application:**
- Wait for environment status: "Up"
- Check application URL
- Verify security groups (port 80/443)
- Check load balancer health (if using)

**Docker image pull errors:**
- Verify ECR image URI is correct
- Check IAM role has ECR permissions
- Ensure image tag exists in ECR
- Check region matches

#### Cost Optimization Tips

1. **Use appropriate instance size:**
   - Start with **t3.micro** (free tier eligible) for testing
   - Scale to **t3.small** for production

2. **Monitor usage:**
   - Use CloudWatch to track metrics
   - Adjust auto-scaling based on actual traffic

3. **Use single instance** for development:
   - Cheaper than load-balanced setup
   - Upgrade to load-balanced for production

#### Next Steps

After Elastic Beanstalk is running:
1. ✅ Test your chatbot at the provided URL
2. ✅ Configure Jenkinsfile for Elastic Beanstalk deployment (see below)
3. ✅ Set up CloudWatch monitoring
4. ✅ Configure auto-scaling based on traffic

Your RAG Medical Chatbot is now live on AWS Elastic Beanstalk! 🚀

> 📖 **For detailed step-by-step instructions, see `AWS_ELASTIC_BEANSTALK_SETUP.md`**

---

### 🧪 Run Jenkins Pipeline

- Go to **Jenkins Dashboard** → Select your pipeline job
- Click **Build Now**

If all stages succeed (Checkout → Build → Trivy Scan → Push to ECR → Deploy to Elastic Beanstalk):

🎉 **CI/CD Deployment to AWS Elastic Beanstalk is complete!**

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
# Separate instance
docker stop jenkins-dind-rag-medical

# Replaced instance
docker stop jenkins-dind
```

**Start Jenkins container:**
```bash
# Separate instance
docker start jenkins-dind-rag-medical

# Replaced instance
docker start jenkins-dind
```

**View logs:**
```bash
# Separate instance
docker logs -f jenkins-dind-rag-medical

# Replaced instance
docker logs -f jenkins-dind
```

**Remove container (keeps volume):**
```bash
# Separate instance
docker rm jenkins-dind-rag-medical

# Replaced instance
docker rm jenkins-dind
```

**Remove container and volume:**
```bash
# Separate instance
docker rm jenkins-dind-rag-medical
docker volume rm jenkins_home_rag_medical

# Replaced instance
docker rm jenkins-dind
docker volume rm jenkins_home
```

### Port Configuration Summary

| Instance Type | Web Port | Agent Port | Container Name | Volume Name |
|--------------|----------|------------|----------------|-------------|
| Separate | 8081 | 50001 | jenkins-dind-rag-medical | jenkins_home_rag_medical |
| Replaced | 8080 | 50000 | jenkins-dind | jenkins_home |

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
- AWS CLI and plugins for ECR and Elastic Beanstalk deployment

For more details, see the `custom_jenkins/README.md` file.
