#!/bin/bash

# Quick Fix Script: Remove Secrets from Git History
# Run this script to remove Dockerrun.aws.json with secrets from git

echo "⚠️  WARNING: This will rewrite git history!"
echo "Make sure you've backed up your work."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

echo "Step 1: Removing Dockerrun.aws.json from last commit..."
git reset --soft HEAD~1

echo "Step 2: Unstaging the file..."
git reset HEAD Dockerrun.aws.json 2>/dev/null || true

echo "Step 3: Removing local file (if exists)..."
rm -f Dockerrun.aws.json

echo "Step 4: Staging all other changes..."
git add .

echo "Step 5: Creating new commit without secrets..."
git commit -m "Remove secrets from Dockerrun.aws.json - use environment variables instead"

echo ""
echo "✅ Done! Now you need to:"
echo "1. Force push: git push origin main --force"
echo "2. ROTATE YOUR API KEYS immediately (they were exposed in git history)"
echo "   - Groq: https://console.groq.com/"
echo "   - Hugging Face: https://huggingface.co/settings/tokens"
echo "3. Update Elastic Beanstalk environment variables with new keys"
echo ""
echo "⚠️  IMPORTANT: The old API keys are compromised. You MUST rotate them!"

