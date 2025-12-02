# Jenkins and AWS Elastic Beanstalk Integration Guide

## Overview

Jenkins automates the CI/CD pipeline for your RAG Medical Chatbot, handling everything from code checkout to deployment to Elastic Beanstalk. This document explains how Jenkins fits into the entire process.

## The Complete CI/CD Workflow

```
Developer pushes code to GitHub
         ↓
Jenkins detects changes (webhook or manual trigger)
         ↓
Jenkins checks out code from GitHub
         ↓
Jenkins builds Docker image
         ↓
Jenkins scans image with Trivy (security)
         ↓
Jenkins pushes image to AWS ECR
         ↓
Jenkins updates Elastic Beanstalk with new image
         ↓
Elastic Beanstalk deploys new version
         ↓
Application is live with new changes
```

## Jenkins Pipeline Stages

### Stage 1: Clone GitHub Repo
**What Jenkins does:**
- Connects to GitHub using credentials
- Pulls the latest code from the repository
- Makes code available for building

**Why it's needed:**
- Ensures you're building from the latest code
- Supports version control and collaboration

### Stage 2: Build, Scan, and Push Docker Image to ECR
**What Jenkins does:**
1. **Builds Docker image:**
   - Uses the Dockerfile in your repository
   - Creates a containerized version of your application
   - Uses BuildKit for faster builds with caching

2. **Scans for vulnerabilities:**
   - Uses Trivy to scan the Docker image
   - Checks for HIGH and CRITICAL security issues
   - Generates a security report

3. **Pushes to ECR:**
   - Logs into AWS ECR
   - Tags the image with version information
   - Pushes image to your ECR repository
   - Also pushes a cache image for faster future builds

**Why it's needed:**
- Ensures your application is containerized and ready for deployment
- Security scanning catches vulnerabilities before deployment
- ECR stores your images securely in AWS

### Stage 3: Deploy to AWS Elastic Beanstalk
**What Jenkins does:**
- Updates Elastic Beanstalk environment configuration
- Points Elastic Beanstalk to the new ECR image
- Triggers Elastic Beanstalk to pull and deploy the new image
- Monitors deployment status

**Why it's needed:**
- Automates deployment (no manual steps)
- Ensures consistent deployments
- Enables zero-downtime deployments (with proper configuration)

## How Jenkins Connects to Elastic Beanstalk

### 1. Initial Setup (One-Time)

**In AWS:**
1. Create Elastic Beanstalk application and environment (manual, one-time)
2. Configure environment with initial Docker image from ECR
3. Set up environment variables (GROQ_API_KEY, HF_TOKEN, etc.)

**In Jenkins:**
1. Configure AWS credentials in Jenkins
2. Set up Jenkinsfile with Elastic Beanstalk deployment stage
3. Configure application and environment names

### 2. Automated Deployment Process

**Every time you push code or trigger a build:**

1. **Jenkins builds new Docker image:**
   ```groovy
   docker build -t rag-medical-repo:latest .
   ```

2. **Jenkins pushes to ECR:**
   ```groovy
   docker push <account-id>.dkr.ecr.<region>.amazonaws.com/rag-medical-repo:latest
   ```

3. **Jenkins updates Elastic Beanstalk:**
   ```groovy
   aws elasticbeanstalk update-environment \
       --application-name rag-medical-chatbot \
       --environment-name rag-medical-chatbot-env \
       --option-settings \
           Namespace=aws:elasticbeanstalk:application:environment,OptionName=DOCKER_IMAGE,Value=<new-image-uri>
   ```

4. **Elastic Beanstalk automatically:**
   - Pulls the new image from ECR
   - Deploys it to your environment
   - Updates your application

## Jenkinsfile Configuration

### Current Jenkinsfile Structure

```groovy
pipeline {
    agent any
    environment {
        AWS_REGION = 'eu-north-1'
        ECR_REPO = 'rag-medical-repo'
        IMAGE_TAG = 'latest'
    }
    
    stages {
        // Stage 1: Get code
        stage('Clone GitHub Repo') { ... }
        
        // Stage 2: Build and push
        stage('Build, Scan, and Push Docker Image to ECR') { ... }
        
        // Stage 3: Deploy
        stage('Deploy to AWS Elastic Beanstalk') {
            steps {
                // Updates Elastic Beanstalk with new ECR image
            }
        }
    }
}
```

### Key Configuration Values

**In Jenkinsfile, you need to set:**
- `AWS_REGION`: Your AWS region (e.g., `us-east-1`, `eu-north-1`)
- `ECR_REPO`: Your ECR repository name
- `appName`: Elastic Beanstalk application name (`rag-medical-chatbot`)
- `envName`: Elastic Beanstalk environment name (`rag-medical-chatbot-env`)

## Step-by-Step: How It All Works Together

### Initial Setup Flow

```
1. Developer sets up Elastic Beanstalk manually
   └─> Creates application: rag-medical-chatbot
   └─> Creates environment: rag-medical-chatbot-env
   └─> Configures with initial Docker image
   └─> Sets environment variables

2. Developer sets up Jenkins
   └─> Installs Jenkins with Docker support
   └─> Configures AWS credentials
   └─> Sets up GitHub integration
   └─> Configures Jenkinsfile with correct names

3. First deployment
   └─> Jenkins builds Docker image
   └─> Jenkins pushes to ECR
   └─> Jenkins updates Elastic Beanstalk
   └─> Elastic Beanstalk deploys
   └─> Application is live
```

### Ongoing Deployment Flow (Automated)

```
1. Developer makes code changes
   └─> Commits to GitHub
   └─> Pushes to main branch

2. Jenkins automatically triggers (or manual trigger)
   └─> Webhook notifies Jenkins of new commit
   └─> OR developer clicks "Build Now"

3. Jenkins pipeline runs:
   └─> Stage 1: Clones latest code
   └─> Stage 2: Builds new Docker image
   └─> Stage 2: Scans image (Trivy)
   └─> Stage 2: Pushes to ECR
   └─> Stage 3: Updates Elastic Beanstalk

4. Elastic Beanstalk deploys:
   └─> Pulls new image from ECR
   └─> Deploys to environment
   └─> Health checks pass
   └─> Application updated

5. Result:
   └─> New version is live
   └─> Zero downtime (if configured properly)
   └─> Old version rolled back if health checks fail
```

## Jenkins Configuration Requirements

### 1. AWS Credentials in Jenkins

**Location:** Jenkins Dashboard → Manage Jenkins → Credentials → Global → Add Credentials

**Required:**
- **Kind:** AWS Credentials
- **Access Key ID:** Your AWS access key
- **Secret Access Key:** Your AWS secret key
- **ID:** `aws-credentials` (must match Jenkinsfile)

**IAM Permissions Required:**
- `AWSElasticBeanstalkFullAccess`
- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonEC2FullAccess`

### 2. GitHub Credentials in Jenkins

**Location:** Jenkins Dashboard → Manage Jenkins → Credentials → Global → Add Credentials

**Required:**
- **Kind:** Username with password
- **Username:** Your GitHub username
- **Password:** GitHub Personal Access Token
- **ID:** `github-token` (must match Jenkinsfile)

### 3. Jenkinsfile Configuration

**Update these values in Jenkinsfile:**

```groovy
environment {
    AWS_REGION = 'us-east-1'  // Your AWS region
    ECR_REPO = 'rag-medical-repo'  // Your ECR repo name
    IMAGE_TAG = 'latest'
}

// In deployment stage:
def appName = "rag-medical-chatbot"  // Must match Elastic Beanstalk app name
def envName = "rag-medical-chatbot-env"  // Must match Elastic Beanstalk env name
```

## Deployment Methods

### Method 1: Update Docker Configuration (Current)

**How it works:**
- Jenkins updates Elastic Beanstalk's Docker configuration
- Elastic Beanstalk pulls the new image from ECR
- Elastic Beanstalk deploys the new version

**Pros:**
- Simple and direct
- Works with existing setup
- No need for Dockerrun.aws.json

**Cons:**
- Requires Elastic Beanstalk to be configured to accept Docker image updates

### Method 2: Upload Dockerrun.aws.json (Alternative)

**How it works:**
1. Jenkins creates `Dockerrun.aws.json` with new image URI
2. Jenkins creates Elastic Beanstalk application version
3. Jenkins updates environment to use new version

**Pros:**
- More explicit versioning
- Better for rollbacks
- Can include environment variables

**Cons:**
- More complex setup
- Requires S3 bucket for version storage

## Monitoring and Troubleshooting

### Check Jenkins Build Status

1. Go to Jenkins Dashboard
2. Click on your pipeline job
3. View build history
4. Click on a build to see:
   - Console output (detailed logs)
   - Stage status (success/failure)
   - Build duration

### Check Elastic Beanstalk Deployment

1. Go to AWS Console → Elastic Beanstalk
2. Select your application
3. Select your environment
4. View:
   - **Events:** See deployment events
   - **Health:** Check environment health
   - **Logs:** View application logs

### Common Issues

**Issue: Jenkins can't update Elastic Beanstalk**
- **Solution:** Check AWS credentials in Jenkins
- **Solution:** Verify IAM permissions
- **Solution:** Check application/environment names match

**Issue: Elastic Beanstalk doesn't pull new image**
- **Solution:** Verify ECR image URI is correct
- **Solution:** Check Elastic Beanstalk has ECR access
- **Solution:** Verify image tag exists in ECR

**Issue: Deployment fails in Elastic Beanstalk**
- **Solution:** Check Elastic Beanstalk logs
- **Solution:** Verify Docker image runs locally
- **Solution:** Check environment variables are set

## Benefits of Jenkins Integration

### 1. **Automation**
- No manual deployment steps
- Consistent deployment process
- Reduces human error

### 2. **Speed**
- Fast feedback on code changes
- Automated testing and scanning
- Quick deployments

### 3. **Security**
- Automated security scanning (Trivy)
- Credentials managed securely
- Audit trail of all deployments

### 4. **Reliability**
- Repeatable process
- Automatic rollback on failure
- Health checks ensure quality

### 5. **Visibility**
- Clear build history
- Deployment logs
- Status tracking

## Best Practices

### 1. **Use Version Tags**
Instead of always using `latest`, consider:
```groovy
IMAGE_TAG = "${BUILD_NUMBER}"  // or "${GIT_COMMIT_SHORT}"
```

### 2. **Enable Notifications**
Configure Jenkins to notify on:
- Build success/failure
- Deployment status
- Security scan results

### 3. **Set Up Rollback**
Configure Elastic Beanstalk for:
- Automatic rollback on health check failure
- Manual rollback capability
- Version history retention

### 4. **Monitor Deployments**
- Set up CloudWatch alarms
- Monitor Elastic Beanstalk health
- Track deployment frequency

### 5. **Test Before Deploy**
- Add testing stage in Jenkinsfile
- Run unit tests
- Integration tests
- Only deploy if tests pass

## Summary

**Jenkins Role:**
- ✅ Automates the entire CI/CD pipeline
- ✅ Builds and tests your application
- ✅ Scans for security issues
- ✅ Pushes to ECR
- ✅ Deploys to Elastic Beanstalk

**Elastic Beanstalk Role:**
- ✅ Hosts your application
- ✅ Manages infrastructure
- ✅ Handles scaling
- ✅ Provides health monitoring
- ✅ Manages deployments

**Together:**
- Jenkins handles the "how" (automation)
- Elastic Beanstalk handles the "where" (hosting)
- Result: Fully automated, reliable deployments! 🚀

