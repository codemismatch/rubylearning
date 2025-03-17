#!/bin/bash

# Script to deploy Ruby Learning site to GitHub Pages
# This script:
# 1. Builds the site
# 2. Commits and pushes changes to gh-pages branch
# 3. Preserves source code on main branch

echo "=== Deploying Ruby Learning to GitHub Pages ==="

# 1. Build the site
echo "Building site..."
bin/typophic-build

# 2. Add all files in public directory to gh-pages branch
echo "Adding built site to gh-pages branch..."
cd public

# Initialize git repository if needed
if [ ! -d ".git" ]; then
  git init
  git checkout -b gh-pages
  git remote add origin $(git -C .. remote get-url origin)
else
  git checkout gh-pages
fi

# Add all files
git add .

# Commit changes
echo "Committing changes to gh-pages branch..."
git commit -m "Deploy site on $(date)"

# Push to remote
echo "Pushing to GitHub Pages..."
git push -f origin gh-pages

cd ..

echo "=== Deployment complete! ==="
echo "Your site should now be live at GitHub Pages."
