# AWS Elastic Beanstalk Setup - Complete Guide

## Quick Checklist

- [ ] ECR image pushed successfully
- [ ] IAM user has `AWSElasticBeanstalkFullAccess` policy
- [ ] IAM user has `AmazonEC2FullAccess` policy
- [ ] Environment variables ready (GROQ_API_KEY, HF_TOKEN)
- [ ] ECR repository URI noted
- [ ] Jenkins configured with AWS credentials (for automated deployment)

> 📖 **For Jenkins integration details, see `JENKINS_BEANSTALK_INTEGRATION.md`**

## Step-by-Step Setup

### Step 1: Navigate to Elastic Beanstalk

1. Log in to your **AWS Console** at [https://console.aws.amazon.com](https://console.aws.amazon.com)
2. In the search bar at the top, type **"Elastic Beanstalk"** and click on **Elastic Beanstalk**
3. You'll see the Elastic Beanstalk dashboard
4. Click the **"Create application"** button (usually a blue button)

### Step 2: Configure Application Information

1. **Application name:**
   - Enter: `rag-medical-chatbot`
   - Maximum length: 100 characters
   - Must be unique within your AWS account
   - Use lowercase letters, numbers, and hyphens only

2. **Application tags** (optional):
   - Click **"Add new tag"** to add tags
   - You can add up to 50 tags
   - Example tags:
     - Key: `Project`, Value: `RAG-Medical-Chatbot`
     - Key: `Environment`, Value: `Production`
   - Tags help you group and filter resources

3. Click **"Create application"**

### Step 3: Create Environment

1. After application is created, you'll see the application dashboard
2. Click **"Create environment"** button
3. You'll see the environment configuration page

### Step 4: Configure Environment Tier

1. **Environment tier:**
   - Select **"Web server environment"** ✅
     - This is for websites, web applications, or web APIs that serve HTTP requests
     - This is the correct choice for your Flask chatbot
   - **Worker environment** is for background tasks (not needed here)

### Step 5: Configure Environment Information

1. **Environment name:**
   - Enter: `rag-medical-chatbot-env` (or your preferred name)
   - Must be 4 to 40 characters in length
   - Can contain only letters, numbers, and hyphens
   - Cannot start or end with a hyphen
   - Must be unique within a region in your account
   - ⚠️ **Note:** This name cannot be changed later

2. **Domain:**
   - Elastic Beanstalk will show: `.us-east-1.elasticbeanstalk.com` (or your selected region)
   - Your full domain will be: `<env-name>.<region>.elasticbeanstalk.com`
   - Example: `rag-medical-chatbot-env.us-east-1.elasticbeanstalk.com`
   - Click **"Check availability"** to verify the domain is available

3. **Environment description** (optional):
   - Add a description for your environment
   - Example: "RAG Medical Chatbot production environment"

### Step 6: Configure Platform

1. **Platform:**
   - Click **"Choose a platform"** dropdown
   - Select **"Docker"**

2. **Platform branch:**
   - After selecting Docker, click **"Choose a platform branch"**
   - Select **"Docker running on 64bit Amazon Linux 2"** (latest/recommended)

3. **Platform version:**
   - Click **"Choose a platform version"**
   - Select **"Latest"** (recommended) or a specific version

### Step 7: Configure Application Code

1. **Application code options:**
   - **Sample application** - Use this for initial setup (we'll configure ECR later)
   - **Existing version** - Select from previously uploaded versions
   - **Upload your code** - Upload a source bundle or `Dockerrun.aws.json` file

2. **For initial setup:**
   - Select **"Sample application"** for now
   - We'll configure ECR image deployment after the environment is created

3. **For ECR deployment** (after setup):
   - We'll use the **"Upload your code"** option with `Dockerrun.aws.json`
   - Or configure via environment settings (see Step 11)

### Step 8: Choose Configuration Preset

1. **Configuration presets:**
   - **Single instance (free tier eligible)** ✅ Recommended for testing
     - Cheapest option
     - Good for development/testing
     - Free tier eligible (t3.micro for 12 months)
   
   - **Single instance (using spot instance)**
     - Uses EC2 Spot instances (cheaper but can be interrupted)
   
   - **High availability** ✅ Recommended for production
     - Load balanced setup
     - Multiple instances for redundancy
     - Better for production workloads
   
   - **High availability (using spot and on-demand instances)**
     - Mix of spot and on-demand instances
     - Cost optimization for production
   
   - **Custom configuration**
     - Full control over all settings
     - Advanced configuration options

2. **Recommendation:**
   - For **testing/development**: Choose **"Single instance (free tier eligible)"**
   - For **production**: Choose **"High availability"**

3. Click **"Next"** or **"Review and launch"** to continue

### Step 9: Additional Configuration (If Using Custom Configuration)

If you selected **"Custom configuration"**, you'll see additional sections:

#### Service Access

1. **Service role:**
   - Select **"Create and use new service role"** (recommended)
   - AWS will create the role automatically with necessary permissions

2. **EC2 key pair** (optional):
   - Select an existing key pair if you want SSH access
   - Or leave as **"None"** (you can add later)

3. **EC2 instance profile:**
   - Select **"Create and use new instance profile"** (recommended)
   - This allows EC2 instances to access ECR

#### Networking, Database, and Tags (Optional)

1. **VPC** (optional):
   - Leave as default unless you need VPC configuration
   - For most applications, default is fine

2. **Database** (optional):
   - Skip for now (not needed for this chatbot)

3. **Tags** (optional):
   - Add tags for organization

#### Instance Traffic and Scaling

1. **Capacity:**
   - **Instance type:**
     - **t3.micro** - Free tier eligible, good for testing
     - **t3.small** - Recommended for production
     - **t3.medium** - For higher traffic

2. **Scaling:**
   - **Min instances:** 1
   - **Max instances:** 5-10 (based on expected traffic)
   - **Scaling trigger:** CPU utilization > 70% (default)

#### Updates, Monitoring, and Logs

1. **Rolling updates and deployments:**
   - **Deployment policy:** **"All at once"** (faster) or **"Rolling"** (safer)
   - **Rolling update type:** **"Time-based"** or **"Immutable"**

2. **Health reporting:**
   - **Health check URL:** `/` (root path)
   - **Health check grace period:** 300 seconds (5 minutes)

3. **Monitoring:**
   - **Health check:** **"Enhanced"** (recommended)
   - **Logs:** Enable **"Instance log streaming to CloudWatch Logs"**

### Step 10: Review and Launch

1. **Review all settings:**
   - Application name: `rag-medical-chatbot`
   - Environment name: `rag-medical-chatbot-env`
   - Domain: `.us-east-1.elasticbeanstalk.com` (or your region)
   - Platform: Docker
   - Configuration preset: Your selected preset
   - Application code: Sample application

2. **Verify:**
   - Environment name is correct (cannot be changed later)
   - Platform is Docker
   - Preset matches your needs

3. Click **"Create environment"**

4. **Wait for environment creation:**
   - This takes 5-10 minutes
   - Watch the events log for progress
   - Status will change from "Launching" to "Up"
   - You'll see progress indicators for:
     - Creating security group
     - Launching EC2 instance
     - Creating application version
     - Deploying application

### Step 10: Configure Environment Variables

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

### Step 11: Configure ECR Image Deployment

#### Option A: Using Dockerrun.aws.json (Recommended)

1. Create `Dockerrun.aws.json` file in your project root:

```json
{
  "AWSEBDockerrunVersion": "1",
  "Image": {
    "Name": "<account-id>.dkr.ecr.<region>.amazonaws.com/rag-medical-repo:latest",
    "Update": "true"
  },
  "Ports": [
    {
      "ContainerPort": 5000
    }
  ],
  "Environment": [
    {
      "Name": "GROQ_API_KEY",
      "Value": "your-groq-api-key"
    },
    {
      "Name": "HF_TOKEN",
      "Value": "your-hf-token"
    }
  ]
}
```

2. Replace placeholders with your actual values
3. Commit and push to GitHub
4. In Elastic Beanstalk, go to **"Upload and deploy"**
5. Upload the `Dockerrun.aws.json` file or deploy from GitHub

#### Option B: Using Environment Configuration

1. Go to **"Configuration"** → **"Docker"**
2. Click **"Edit"**
3. **Docker image:** Enter your ECR image URI:
   - Format: `<account-id>.dkr.ecr.<region>.amazonaws.com/rag-medical-repo:latest`
4. **Port:** `5000`
5. Click **"Apply"**

### Step 12: Access Your Application

1. Once deployment is complete, find your application URL:
   - Go to environment dashboard
   - Look for **"Domain"** or **"CNAME"**
   - Format: `http://rag-medical-chatbot-prod.<region>.elasticbeanstalk.com`

2. **Note:** Elastic Beanstalk uses HTTP by default
   - For HTTPS, configure SSL certificate (optional)

3. **Test your application:**
   - Open the URL in your browser
   - You should see your RAG Medical Chatbot interface
   - Try asking a medical question to verify it's working

### Step 13: Enable HTTPS (Optional but Recommended)

1. Go to **"Configuration"** → **"Load balancer"**
2. Click **"Edit"**
3. Under **"Listeners"**, add HTTPS listener:
   - **Port:** 443
   - **Protocol:** HTTPS
   - **SSL certificate:** Request or upload a certificate
4. Click **"Apply"**

## Important Settings Summary

| Setting | Value | Notes |
|---------|-------|-------|
| Application Name | rag-medical-chatbot | Max 100 characters |
| Environment Name | rag-medical-chatbot-env | 4-40 chars, cannot change later |
| Environment Tier | Web server environment | For HTTP-serving apps |
| Platform | Docker | Required for containerized apps |
| Platform Branch | Docker on 64bit Amazon Linux 2 | Latest recommended |
| Configuration Preset | Single instance (free tier) or High availability | Based on needs |
| Instance Type | t3.micro (free tier) or t3.small (prod) | Based on preset |
| Port | 5000 | Flask default port |
| Health Check | `/` | Root path |
| Min Instances | 1 | Always running (if load balanced) |
| Max Instances | 5-10 | Based on traffic (if load balanced) |
| Deployment | Rolling | Safer for production |

## Environment Variables

```bash
GROQ_API_KEY=your_groq_api_key_here
HF_TOKEN=your_huggingface_token_here
PYTHONUNBUFFERED=1
```

## Application URL Format

```
http://<env-name>.<region>.elasticbeanstalk.com
```

Example:
```
http://rag-medical-chatbot-env.us-east-1.elasticbeanstalk.com
```

**Note:** The domain is automatically generated based on:
- Environment name: `rag-medical-chatbot-env`
- Region: `us-east-1` (or your selected region)
- Full domain: `rag-medical-chatbot-env.us-east-1.elasticbeanstalk.com`

## Cost Estimate

**t3.small instance (Single):**
- ~$15-20/month
- Additional costs for load balancer (if using)

**t3.micro (Free Tier):**
- Free for first 12 months (if eligible)
- Then ~$8-10/month

## Troubleshooting

### Environment Won't Start
1. Check **"Events"** tab for error messages
2. Check **"Logs"** → **"Last 100 Lines"**
3. Verify Docker image URI is correct
4. Check environment variables are set

### Health Check Failing
1. Ensure Flask responds on `/` path
2. Check application logs
3. Verify port 5000 is configured
4. Check security groups allow traffic

### Can't Access Application
1. Wait for environment status: "Up"
2. Check application URL
3. Verify security groups (port 80/443)
4. Check load balancer health (if using)

### Docker Image Pull Errors
1. Verify ECR image URI is correct
2. Check IAM role has ECR permissions
3. Ensure image tag exists in ECR
4. Check region matches

## Next Steps

1. ✅ Test application at Elastic Beanstalk URL
2. ✅ Configure Jenkinsfile for Elastic Beanstalk deployment (see `JENKINS_BEANSTALK_INTEGRATION.md`)
3. ✅ Set up CloudWatch monitoring
4. ✅ Configure auto-scaling based on traffic
5. ✅ Set up automated deployments via Jenkins

## Jenkins Integration

After setting up Elastic Beanstalk, Jenkins can automatically deploy updates:

1. **Jenkins builds Docker image** from your code
2. **Jenkins pushes image to ECR**
3. **Jenkins updates Elastic Beanstalk** with new image
4. **Elastic Beanstalk automatically deploys** the new version

**For detailed Jenkins integration guide, see:** `JENKINS_BEANSTALK_INTEGRATION.md`

Your RAG Medical Chatbot is now live on AWS Elastic Beanstalk! 🚀

