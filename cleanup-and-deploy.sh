#!/bin/bash

# Exit on error
set -e

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
REPO_URL=$(grep -A 3 "repository:" config.yml | grep "url:" | sed 's/.*url: //' || echo "")
if [ -z "$REPO_URL" ]; then
  echo "Repository URL not found in config.yml. Please provide the repository URL:"
  read REPO_URL
fi

# 5. Deploy to gh-pages branch
echo "Deploying to gh-pages branch..."
bin/typophic-deploy --remote "$REPO_URL"

# 6. Push main branch to remote
echo "Pushing main branch to remote..."
git push origin main

echo "Deployment complete!"
echo "This script will self-destruct in 3 seconds..."
sleep 3

# 7. Self-destruct: Remove this script
rm -- "$0"
