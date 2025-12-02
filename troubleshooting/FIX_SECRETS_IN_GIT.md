# Fix: Remove Secrets from Git History

## Problem

GitHub detected secrets (API keys) in your `Dockerrun.aws.json` file and blocked the push. The secrets are in commit `5381ee9`.

## Solution: Remove Secrets from Git History

### Option 1: Remove File from Last Commit (Recommended)

If the file with secrets is only in the last commit:

```bash
# Remove the file from the last commit (but keep it locally)
git reset --soft HEAD~1

# Remove the file from staging
git reset HEAD Dockerrun.aws.json

# Delete the file (it contains secrets)
rm Dockerrun.aws.json

# Commit again without the file
git add .
git commit -m "Update Docker configuration (removed secrets)"

# Force push (since we rewrote history)
git push origin main --force
```

### Option 2: Remove File from Specific Commit

If you need to remove it from a specific commit:

```bash
# Remove the file from git history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch Dockerrun.aws.json" \
  --prune-empty --tag-name-filter cat -- --all

# Force push
git push origin main --force
```

### Option 3: Use BFG Repo-Cleaner (Faster for Large Repos)

```bash
# Install BFG (if not installed)
# brew install bfg  # macOS
# or download from https://rtyley.github.io/bfg-repo-cleaner/

# Remove the file
bfg --delete-files Dockerrun.aws.json

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push
git push origin main --force
```

## After Fixing

### 1. Create Template File

Use `Dockerrun.aws.json.template` (already created) as a template. Never commit actual secrets.

### 2. Update .gitignore

The `.gitignore` already includes `Dockerrun.aws.json`, but verify:

```bash
cat .gitignore | grep Dockerrun
```

Should show: `Dockerrun.aws.json`

### 3. Rotate Your Secrets

**IMPORTANT:** Since the secrets were exposed in git history, you should:

1. **Rotate Groq API Key:**
   - Go to [Groq Console](https://console.groq.com/)
   - Generate a new API key
   - Revoke the old one

2. **Rotate Hugging Face Token:**
   - Go to [Hugging Face Settings](https://huggingface.co/settings/tokens)
   - Generate a new token
   - Revoke the old one

3. **Update in Elastic Beanstalk:**
   - Go to Elastic Beanstalk → Configuration → Software
   - Update environment variables with new keys

### 4. Use Environment Variables Instead

**Best Practice:** Don't put secrets in `Dockerrun.aws.json`. Instead:

1. Configure secrets in Elastic Beanstalk environment variables (via AWS Console)
2. Or use AWS Secrets Manager
3. Keep `Dockerrun.aws.json` for image configuration only

## Prevention

### 1. Always Use Templates

- Use `Dockerrun.aws.json.template` as a template
- Replace placeholders when deploying
- Never commit files with real secrets

### 2. Use .gitignore

Ensure these are in `.gitignore`:
```
.env
Dockerrun.aws.json
*.key
*.pem
secrets/
```

### 3. Use Environment Variables

Configure secrets via:
- Elastic Beanstalk Console (Environment Properties)
- AWS Secrets Manager
- CI/CD pipeline secrets (Jenkins credentials)

### 4. Pre-commit Hooks

Consider using pre-commit hooks to scan for secrets:

```bash
# Install detect-secrets
pip install detect-secrets

# Scan before commit
detect-secrets scan --baseline .secrets.baseline
```

## Quick Fix Commands

**If you just want to remove the file and push:**

```bash
# 1. Remove from last commit
git reset --soft HEAD~1
git reset HEAD Dockerrun.aws.json
rm Dockerrun.aws.json

# 2. Commit without secrets
git add .
git commit -m "Remove secrets from Dockerrun.aws.json"

# 3. Force push
git push origin main --force
```

**Then rotate your API keys immediately!**

