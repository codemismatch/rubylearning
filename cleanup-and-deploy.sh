#!/bin/bash

# Make sure this script is executable:
# chmod +x cleanup-and-deploy.sh

# Exit on error and print commands
set -e
set -x

echo "Starting cleanup and deployment process..."

# 1. Remove unnecessary Markdown files
echo "Removing unnecessary Markdown files..."
rm -f DEPLOYMENT_INSTRUCTIONS.md GIT_WORKFLOW_REVISED.md USAGE.md

# 2. Add and commit changes to main branch
echo "Committing changes to main branch..."
git add README.md
git add -u  # Add all deleted files to staging
git commit -m "Consolidate documentation into a single README.md"

# 3. Build the site
echo "Building the site..."
bin/typophic-build

# 4. Get the repository URL from config.yml or use a default
REPO_URL=$(grep -A 3 "repository:" config.yml | grep "url:" | sed 's/.*url: //' | sed 's/[[:space:]]//g' || echo "")
if [ -z "$REPO_URL" ]; then
  # Try to get the URL from git remote
  REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
  
  # If still empty, ask user
  if [ -z "$REPO_URL" ]; then
    echo "Repository URL not found. Please provide the repository URL:"
    read REPO_URL
  fi
fi

echo "Using repository URL: $REPO_URL"

# 5. Deploy to gh-pages branch
echo "Deploying to gh-pages branch..."
if [ -x "bin/typophic-deploy" ]; then
  bin/typophic-deploy --remote "$REPO_URL"
else
  echo "Error: typophic-deploy not found or not executable"
  echo "Make sure to make all scripts executable with: chmod +x bin/*"
  exit 1
fi

# 6. Push main branch to remote
echo "Pushing main branch to remote..."
git push origin main

echo "Deployment complete!"
echo "This script will self-destruct in 3 seconds..."
sleep 3

# 7. Self-destruct: Remove this script
echo "Cleaning up..."
rm -- "$0"
echo "Script successfully deleted itself. All operations completed."
