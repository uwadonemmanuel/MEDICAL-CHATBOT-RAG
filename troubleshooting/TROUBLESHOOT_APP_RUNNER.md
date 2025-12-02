# Troubleshooting AWS App Runner Subscription Error

## Error Message
```
SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service
```

## What This Means

This error indicates that AWS App Runner requires activation or is not available in your AWS account/region.

## Solutions

### Solution 1: Check App Runner Availability in Your Region

AWS App Runner is available in specific regions. Check if your region supports App Runner:

**Supported Regions:**
- ✅ us-east-1 (N. Virginia)
- ✅ us-east-2 (Ohio)
- ✅ us-west-1 (N. California)
- ✅ us-west-2 (Oregon) - **You're using this**
- ✅ eu-west-1 (Ireland)
- ✅ eu-west-2 (London)
- ✅ eu-central-1 (Frankfurt)
- ✅ ap-southeast-1 (Singapore)
- ✅ ap-southeast-2 (Sydney)
- ✅ ap-northeast-1 (Tokyo)

**Note:** You're using `us-west-2` which should be supported. The issue might be account-specific.

### Solution 2: Activate App Runner Service

1. **Try accessing App Runner directly:**
   - Go to: https://console.aws.amazon.com/apprunner/
   - If you see a "Get started" or "Activate" button, click it

2. **Check Service Quotas:**
   - Go to AWS Console → **Service Quotas**
   - Search for "App Runner"
   - Check if the service is enabled for your account

3. **Contact AWS Support:**
   - If App Runner doesn't appear, you may need to:
     - Enable it through AWS Support
     - Or use an account that has App Runner enabled

### Solution 3: Use Alternative Deployment Method

If App Runner isn't available, use one of these alternatives:

#### Option A: AWS Elastic Beanstalk (Easiest Alternative)

**Steps:**
1. Go to **Elastic Beanstalk** in AWS Console
2. Click **Create application**
3. Select **Docker** platform
4. Upload your Docker image or connect to ECR
5. Configure environment variables
6. Deploy

**Advantages:**
- ✅ Similar ease of use to App Runner
- ✅ Available in all regions
- ✅ No subscription required
- ✅ Free tier available

#### Option B: AWS ECS Fargate (Recommended for Production)

**Steps:**
1. Go to **ECS** → **Clusters**
2. Create a new cluster (Fargate)
3. Create a task definition pointing to your ECR image
4. Create a service
5. Configure load balancer and auto-scaling

**Advantages:**
- ✅ More control and flexibility
- ✅ Better for production workloads
- ✅ Available in all regions
- ✅ No subscription required

#### Option C: AWS EC2 (Traditional)

**Steps:**
1. Launch an EC2 instance
2. Install Docker
3. Pull and run your image from ECR
4. Configure security groups

**Advantages:**
- ✅ Full control
- ✅ Cheapest option
- ✅ Available everywhere
- ❌ Requires more manual setup

#### Option D: AWS Lambda (If Applicable)

**Note:** Lambda has limitations (15-minute timeout, smaller memory), but might work for your chatbot if you refactor slightly.

### Solution 4: Check IAM Permissions

Ensure your IAM user has the correct permissions:

**Required Policy:**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "apprunner:*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage"
            ],
            "Resource": "*"
        }
    ]
}
```

### Solution 5: Try Different Region

1. **Switch to a different region:**
   - Try `us-east-1` (N. Virginia) - most commonly available
   - Or `eu-west-1` (Ireland)

2. **Update your ECR region:**
   - Make sure your ECR repository is in the same region
   - Or use cross-region image replication

## Recommended Next Steps

### If App Runner is Not Available:

1. **Use AWS Elastic Beanstalk** (easiest alternative):
   - Similar to App Runner in ease of use
   - No subscription required
   - Works with Docker images from ECR

2. **Or use AWS ECS Fargate** (best for production):
   - More control and features
   - Better for scaling
   - Industry standard for containerized apps

### Quick Setup: Elastic Beanstalk Alternative

1. **Prerequisites:**
   - ECR image already pushed ✅
   - IAM permissions for Elastic Beanstalk

2. **Steps:**
   ```
   1. AWS Console → Elastic Beanstalk
   2. Create new application
   3. Platform: Docker
   4. Source: ECR image
   5. Configure environment variables
   6. Deploy
   ```

3. **Environment Variables:**
   - Add GROQ_API_KEY
   - Add HF_TOKEN
   - Add PYTHONUNBUFFERED=1

4. **Access:**
   - Elastic Beanstalk provides a URL automatically
   - Format: `http://your-app.region.elasticbeanstalk.com`

## Update Jenkinsfile for Alternative Deployment

If you switch to Elastic Beanstalk or ECS, update your Jenkinsfile deployment stage:

### For Elastic Beanstalk:
```groovy
stage('Deploy to Elastic Beanstalk') {
    steps {
        sh """
        aws elasticbeanstalk update-environment \
            --application-name rag-medical-chatbot \
            --environment-name rag-medical-prod \
            --version-label ${BUILD_NUMBER}
        """
    }
}
```

### For ECS:
```groovy
stage('Deploy to ECS') {
    steps {
        sh """
        aws ecs update-service \
            --cluster rag-medical-cluster \
            --service rag-medical-service \
            --force-new-deployment
        """
    }
}
```

## Summary

**The Issue:**
- App Runner requires subscription/activation in your account
- May not be available in your specific AWS account setup

**Quick Fix:**
- Use **AWS Elastic Beanstalk** instead (similar ease, no subscription)
- Or use **AWS ECS Fargate** (more control, production-ready)

**Both alternatives:**
- ✅ Work with your existing ECR image
- ✅ Support environment variables
- ✅ Auto-scaling available
- ✅ No subscription required
- ✅ Available in all regions

Would you like me to create detailed setup instructions for Elastic Beanstalk or ECS Fargate as an alternative?

