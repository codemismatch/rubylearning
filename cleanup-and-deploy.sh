#!/bin/bash

# Make sure this script is executable:
# chmod +x cleanup-and-deploy.sh

# Exit on error and print commands
set -e
set -x

echo "Starting cleanup and deployment process..."

# 0. Make sure all scripts are executable
echo "Making all scripts executable..."
chmod +x bin/*

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

# Check if the typophic scripts exist
if [ ! -f "bin/typophic" ]; then
  echo "Error: bin/typophic script not found. Cannot proceed with build."
  exit 1
fi

if [ ! -f "bin/typophic-build" ]; then
  echo "Error: bin/typophic-build script not found."
  echo "Attempting to create a basic version..."
  
  # Create a simple typophic-build script that just calls typophic
  cat > bin/typophic-build << 'EOF'
#!/usr/bin/env ruby

require 'fileutils'

puts "Building site with basic typophic-build..."

# Run the basic build
typophic_script = File.join(File.dirname(__FILE__), 'typophic')
if File.exist?(typophic_script)
  system(typophic_script)
else
  puts "Error: Could not find typophic script."
  exit 1
end

puts "Build complete! Site is ready in the 'public' directory."
puts "Run 'bin/typophic-serve' to preview your site."
EOF
  
  chmod +x bin/typophic-build
  echo "Created a basic typophic-build script."
fi

# Run the build
if ! bin/typophic-build; then
  echo "Error: Site build failed!"
  echo "Please check the typophic-build script for errors and try again."
  exit 1
fi

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

# Check if the typophic-deploy script exists
if [ ! -f "bin/typophic-deploy" ]; then
  echo "Error: bin/typophic-deploy script not found."
  echo "Creating a simplified deployment solution..."
  
  # Create a public directory if it doesn't exist
  mkdir -p public
  
  # Initialize a git repository in the public directory
  cd public
  git init
  git checkout -b gh-pages
  
  # Add all files
  git add .
  
  # Commit
  git commit -m "Deploy to GitHub Pages"
  
  # Add remote and push
  git remote add origin "$REPO_URL"
  git push -f origin gh-pages
  
  # Return to the parent directory
  cd ..
  
  echo "Deployed using simplified git commands."
else
  # Use the existing deploy script
  if [ -x "bin/typophic-deploy" ]; then
    bin/typophic-deploy --remote "$REPO_URL"
  else
    chmod +x bin/typophic-deploy
    bin/typophic-deploy --remote "$REPO_URL"
  fi
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
