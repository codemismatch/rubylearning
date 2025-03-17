#!/bin/bash

# simple-deploy.sh - Simple deployment script that fixes the header link

set -e  # Exit on error

REPO_URL=$1

# Check for repository URL
if [ -z "$REPO_URL" ]; then
  REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
  
  # If still empty, prompt the user
  if [ -z "$REPO_URL" ]; then
    echo "Repository URL not found. Please provide it:"
    read -r REPO_URL
    
    if [ -z "$REPO_URL" ]; then
      echo "Error: No repository URL provided. Cannot deploy."
      exit 1
    fi
  fi
fi

echo "===== RUBY LEARNING DEPLOYMENT ====="
echo "Using repository URL: $REPO_URL"

# Make scripts executable
chmod +x bin/* 2>/dev/null || echo "Warning: Could not make bin scripts executable"
chmod +x fix-header-link.rb

# Build the site
echo "1. Building the site..."
if [ -f "bin/typophic-build" ]; then
  bin/typophic-build
elif [ -f "bin/typophic" ]; then
  bin/typophic
else
  echo "Error: No build script found."
  exit 1
fi

# Fix the header link
echo "2. Fixing header link to point to /posts/ instead of /pages/..."
ruby fix-header-link.rb

# Make sure .nojekyll exists
echo "3. Adding .nojekyll file..."
touch public/.nojekyll

# Deploy to GitHub Pages
echo "4. Deploying to GitHub Pages..."
TMP_DIR=$(mktemp -d)
echo "  - Created temporary directory: $TMP_DIR"

# Copy the public directory contents
cp -r public/* "$TMP_DIR/"
cp public/.nojekyll "$TMP_DIR/"
echo "  - Copied site files"

# Navigate to the temporary directory
cd "$TMP_DIR" || exit

# Initialize git
git init
git checkout -b gh-pages
echo "  - Initialized git repository"

# Add all files
git add .

# Commit
git commit -m "Deploy to GitHub Pages - $(date)"
echo "  - Committed changes"

# Add remote
git remote add origin "$REPO_URL"

# Push (with force)
git push -f origin gh-pages
echo "  - Pushed to gh-pages branch"

# Clean up
cd - || exit
rm -rf "$TMP_DIR"
echo "  - Cleaned up temporary directory"

# Push source changes to main branch
echo "5. Pushing source changes to main branch..."
git push origin main

echo "===== DEPLOYMENT COMPLETE ====="
echo "Your site has been deployed to GitHub Pages!"
echo "It may take a few minutes for the changes to appear."
