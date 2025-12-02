# Security Best Practices - Protecting Secrets

## ⚠️ Critical: Never Commit Secrets to Git

GitHub's push protection detected secrets in your repository. Follow these practices to prevent this.

## What Happened

Your `Dockerrun.aws.json` file contained:
- Groq API Key
- Hugging Face Token

These were detected by GitHub's secret scanning and the push was blocked.

## Immediate Actions Required

### 1. Remove Secrets from Git History

See `FIX_SECRETS_IN_GIT.md` for detailed instructions.

**Quick fix:**
```bash
# Remove from last commit
git reset --soft HEAD~1
git reset HEAD Dockerrun.aws.json
rm Dockerrun.aws.json
git add .
git commit -m "Remove secrets from Dockerrun.aws.json"
git push origin main --force
```

### 2. Rotate Your API Keys

**Since secrets were exposed, you MUST rotate them:**

1. **Groq API Key:**
   - Go to https://console.groq.com/
   - Generate new API key
   - Revoke old key

2. **Hugging Face Token:**
   - Go to https://huggingface.co/settings/tokens
   - Generate new token
   - Revoke old token

3. **Update in Elastic Beanstalk:**
   - AWS Console → Elastic Beanstalk → Your Environment
   - Configuration → Software → Environment Properties
   - Update GROQ_API_KEY and HF_TOKEN with new values

## Best Practices

### 1. Use .gitignore

**Always include in `.gitignore`:**
```
.env
.env.local
.env.*.local
Dockerrun.aws.json
*.key
*.pem
secrets/
*.secret
config/secrets.json
```

### 2. Use Template Files

- ✅ Commit: `Dockerrun.aws.json.template`
- ❌ Never commit: `Dockerrun.aws.json` (with real values)

### 3. Environment Variables

**Configure secrets via:**

**Option A: Elastic Beanstalk Console (Recommended)**
- AWS Console → Elastic Beanstalk → Configuration → Software
- Add environment variables
- Secrets are encrypted at rest

**Option B: AWS Secrets Manager**
- Store secrets in AWS Secrets Manager
- Reference in Elastic Beanstalk
- Most secure option

**Option C: Jenkins Credentials**
- Store in Jenkins credentials
- Inject during deployment
- Never in code

### 4. Use .env Files Locally

**For local development:**
```bash
# .env (in .gitignore)
GROQ_API_KEY=your_key_here
HF_TOKEN=your_token_here
```

**Load in code:**
```python
from dotenv import load_dotenv
load_dotenv()
GROQ_API_KEY = os.environ.get("GROQ_API_KEY")
```

### 5. Pre-commit Checks

**Install secret detection:**
```bash
pip install detect-secrets
detect-secrets scan --baseline .secrets.baseline
```

**Add to pre-commit hook:**
```bash
# .git/hooks/pre-commit
#!/bin/sh
detect-secrets scan --baseline .secrets.baseline
```

## Files That Should Never Contain Secrets

❌ **Never commit these with real values:**
- `Dockerrun.aws.json`
- `.env`
- `config.json`
- `secrets.json`
- `credentials.json`
- Any file with `.key`, `.pem`, `.secret` extension

✅ **Safe to commit:**
- `Dockerrun.aws.json.template` (with placeholders)
- `.env.example` (with example values)
- `config.example.json`

## Dockerfile and Environment Variables

**In Dockerfile:**
```dockerfile
# ❌ BAD - Never hardcode secrets
ENV GROQ_API_KEY=sk-1234567890

# ✅ GOOD - Use build args or runtime env vars
ARG GROQ_API_KEY
ENV GROQ_API_KEY=${GROQ_API_KEY}
```

**Or better - don't include in Dockerfile at all:**
- Set at runtime via Elastic Beanstalk environment variables
- Or via Docker run: `docker run -e GROQ_API_KEY=...`

## Jenkins Configuration

**Store secrets in Jenkins:**
1. Jenkins Dashboard → Credentials → Add
2. Kind: Secret text or AWS credentials
3. Use in pipeline:
   ```groovy
   withCredentials([string(credentialsId: 'groq-api-key', variable: 'GROQ_API_KEY')]) {
       sh 'echo $GROQ_API_KEY'
   }
   ```

## Elastic Beanstalk Configuration

**Set environment variables:**
1. AWS Console → Elastic Beanstalk
2. Your Environment → Configuration
3. Software → Edit
4. Environment properties → Add:
   - `GROQ_API_KEY` = (your key)
   - `HF_TOKEN` = (your token)
5. Apply

**These are encrypted at rest and never exposed in code.**

## Checklist Before Committing

- [ ] No API keys in code
- [ ] No tokens in code
- [ ] No passwords in code
- [ ] `.env` is in `.gitignore`
- [ ] `Dockerrun.aws.json` is in `.gitignore`
- [ ] Only template files are committed
- [ ] Secrets are in environment variables or AWS Secrets Manager

## If You Accidentally Commit Secrets

1. **Immediately rotate the secrets** (most important!)
2. Remove from git history (see `FIX_SECRETS_IN_GIT.md`)
3. Update all places where secrets are used
4. Review git history for other exposed secrets
5. Consider using `git-secrets` or `truffleHog` to scan history

## Tools for Secret Detection

1. **GitHub Secret Scanning** (already enabled)
   - Automatically scans pushes
   - Blocks commits with secrets

2. **git-secrets:**
   ```bash
   git secrets --install
   git secrets --register-aws
   ```

3. **truffleHog:**
   ```bash
   pip install truffleHog
   truffleHog --regex --entropy=False .
   ```

4. **detect-secrets:**
   ```bash
   pip install detect-secrets
   detect-secrets scan .
   ```

## Summary

✅ **DO:**
- Use environment variables
- Use template files
- Store secrets in AWS Secrets Manager or Jenkins
- Rotate secrets if exposed
- Use .gitignore properly

❌ **DON'T:**
- Commit API keys
- Commit tokens
- Commit passwords
- Hardcode secrets in code
- Include secrets in Dockerfiles
- Push files with real credentials

**Remember:** Once secrets are in git history, they're exposed. Always rotate them immediately!

