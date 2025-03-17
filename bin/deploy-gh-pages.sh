#!/bin/bash

# Script to deploy Ruby Learning site to GitHub Pages
# This script:
# 1. Builds the site
# 2. Commits and pushes changes to gh-pages branch
# 3. Preserves source code on main branch

echo "=== Deploying Ruby Learning to GitHub Pages ==="

# Parse command line options
REMOTE_URL=""
FORCE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --remote)
      REMOTE_URL="$2"
      shift 2
      ;;
    --force)
      FORCE=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: deploy-gh-pages.sh [--remote URL] [--force]"
      exit 1
      ;;
  esac
done

# 1. Make sure all changes are committed on main branch
if [ -n "$(git status --porcelain)" ]; then
  echo "There are uncommitted changes in your working directory."
  echo "Please commit or stash these changes before deploying."
  echo "Uncommitted files:"
  git status --porcelain
  exit 1
fi

# 2. Build the site
echo "Building site..."
bin/typophic-build

# 3. Fix paths for GitHub Pages
echo "Fixing paths for GitHub Pages..."
bin/fix-paths.rb --github

# 4. Add all files in public directory to gh-pages branch
echo "Adding built site to gh-pages branch..."
cd public

# Initialize git repository if needed
if [ ! -d ".git" ]; then
  echo "Initializing git in public directory..."
  git init
  git checkout -b gh-pages
  
  # Add remote if provided
  if [ -n "$REMOTE_URL" ]; then
    git remote add origin "$REMOTE_URL"
  else
    # Try to get URL from parent directory
    REMOTE_URL=$(git -C .. remote get-url origin 2>/dev/null)
    if [ -n "$REMOTE_URL" ]; then
      git remote add origin "$REMOTE_URL"
      echo "Using remote URL from parent repository: $REMOTE_URL"
    else
      echo "Warning: No remote URL provided or found in parent repository."
      echo "The site will not be pushed to GitHub. Use --remote to specify a URL."
    fi
  fi
else
  git checkout gh-pages
  
  # Update remote if provided
  if [ -n "$REMOTE_URL" ]; then
    git remote set-url origin "$REMOTE_URL" 2>/dev/null || git remote add origin "$REMOTE_URL"
  fi
fi

# 5. Create .nojekyll file
touch .nojekyll

# 6. Add all files
git add -A

# 7. Commit changes
echo "Committing changes to gh-pages branch..."
git commit -m "Deploy site on $(date)" || echo "No changes to commit"

# 8. Push to remote if we have a URL
if git remote get-url origin >/dev/null 2>&1; then
  echo "Pushing to GitHub Pages..."
  if [ "$FORCE" = true ]; then
    git push -f origin gh-pages
  else
    git push origin gh-pages
  fi
  
  # Get the URL to show to the user
  REPO_URL=$(git remote get-url origin)
  if [[ "$REPO_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
    USERNAME="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    if [[ "$REPO" == *".git" ]]; then
      REPO="${REPO%.git}"
    fi
    echo "Your site should now be live at: https://$USERNAME.github.io/$REPO/"
  else
    echo "Your site should now be live at GitHub Pages."
  fi
else
  echo "Skipping push: No remote repository configured."
  echo "To push to GitHub, run this script with --remote URL parameter."
fi

cd ..

echo "=== Deployment complete! ==="
