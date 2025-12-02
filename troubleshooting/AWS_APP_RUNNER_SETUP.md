# AWS App Runner Setup - Quick Reference

## Quick Checklist

- [ ] ECR image pushed successfully
- [ ] IAM user has `AWSAppRunnerFullAccess` policy
- [ ] Environment variables ready (GROQ_API_KEY, HF_TOKEN)
- [ ] ECR repository URI noted
- [ ] **App Runner service is available in your AWS account** (if you see subscription error, see troubleshooting below)

## ⚠️ Troubleshooting: Subscription Error

If you see: `SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service`

**Quick Solutions:**
1. **Check region**: Ensure you're in a supported region (us-east-1, us-west-2, etc.)
2. **Activate service**: Try accessing App Runner directly and look for "Activate" button
3. **Use alternative**: Consider AWS Elastic Beanstalk or ECS Fargate (see `TROUBLESHOOT_APP_RUNNER.md`)

**Supported Regions:**
- us-east-1, us-east-2, us-west-1, us-west-2
- eu-west-1, eu-west-2, eu-central-1
- ap-southeast-1, ap-southeast-2, ap-northeast-1

## Step-by-Step Setup

### 1. Navigate to App Runner
- AWS Console → Search "App Runner" → Click "Create service"

### 2. Configure Source
- **Source type**: Container registry
- **Provider**: Amazon ECR
- **Image URI**: `<account-id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>`
- **Deployment trigger**: Automatic (recommended)

### 3. Service Settings
- **Service name**: `rag-medical-chatbot`
- **CPU**: 1 vCPU (recommended)
- **Memory**: 2 GB (recommended)
- **Min instances**: 1
- **Max instances**: 5-10

### 4. Advanced Configuration
- **Port**: `5000`
- **Start command**: (leave empty, uses Dockerfile CMD)
- **Environment variables**:
  - `GROQ_API_KEY` = (your key) ✅ Encrypt
  - `HF_TOKEN` = (your token) ✅ Encrypt
  - `PYTHONUNBUFFERED` = `1`

### 5. Security
- **VPC**: No VPC (unless needed)
- **Encryption**: Enabled (default)

### 6. Review & Deploy
- Review all settings
- Click "Create & deploy"
- Wait 3-5 minutes for deployment

### 7. Access Application
- Service URL: `https://<id>.<region>.awsapprunner.com`
- Test the chatbot interface

## Important Settings Summary

| Setting | Value | Notes |
|---------|-------|-------|
| Port | 5000 | Flask default port |
| CPU | 1 vCPU | Good for production |
| Memory | 2 GB | Sufficient for RAG chatbot |
| Min Instances | 1 | Always running |
| Max Instances | 5-10 | Based on traffic |
| Health Check | `/` | Root path |
| Auto Deploy | Yes | Deploys on ECR push |

## Environment Variables

```bash
GROQ_API_KEY=your_groq_api_key_here
HF_TOKEN=your_huggingface_token_here
PYTHONUNBUFFERED=1
```

**⚠️ Always encrypt sensitive variables (GROQ_API_KEY, HF_TOKEN)**

## Service URL Format

```
https://<random-id>.<region>.awsapprunner.com
```

Example:
```
https://abc123xyz.eu-north-1.awsapprunner.com
```

## Cost Estimate

**1 vCPU, 2 GB Memory:**
- ~$25-30/month (varies by region)
- Additional costs for data transfer

## Troubleshooting

### Service Won't Start
1. Check **Logs** tab for errors
2. Verify environment variables
3. Check port configuration (5000)
4. Test Docker image locally first

### Health Check Failing
1. Ensure Flask responds on `/`
2. Check application logs
3. Verify port matches Dockerfile

### Can't Access Application
1. Wait for "Running" status
2. Check service URL
3. Verify security groups (if using VPC)

## Enable Auto-Deployment

1. Go to **Source** tab
2. Click **Edit**
3. Set **Deployment trigger** to **Automatic**
4. Save changes

Now Jenkins can automatically deploy to App Runner!

## Next Steps

1. ✅ Test application at service URL
2. ✅ Uncomment App Runner stage in Jenkinsfile
3. ✅ Configure Jenkins with service ARN
4. ✅ Set up CloudWatch monitoring

## Service ARN Format

```
arn:aws:apprunner:<region>:<account-id>:service/<service-name>/<service-id>
```

You'll need this for Jenkins deployment automation.

