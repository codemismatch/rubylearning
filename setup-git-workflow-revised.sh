#!/bin/bash

# Revised script to set up proper Git workflow for Ruby Learning project
# - Main branch: Source code
# - gh-pages branch: Built site (public directory)
# Uses the existing typophic-deploy script

echo "=== Setting up proper Git workflow ==="

# 1. Check if git is initialized in the project root
if [ ! -d ".git" ]; then
  echo "Initializing git repository in project root..."
  git init
  echo "Created git repository"
else
  echo "Git repository already exists in project root"
fi

# 2. Create .gitignore file to exclude public directory from main branch
echo "Setting up .gitignore..."
cat > .gitignore << EOF
# Ignore built site in main branch
public/

# macOS system files
.DS_Store

# Backup files
*.bak

# Editor-specific files
.vscode/
.idea/

# Ruby environment
.ruby-version
.ruby-gemset

# Temporary files
*.tmp
*.log
EOF
echo "Created .gitignore"

# 3. Add and commit source files to main branch
echo "Adding source files to main branch..."
git add .
git commit -m "Initial commit of Ruby Learning source code"
echo "Source code committed to main branch"

# 4. Verify that typophic-deploy exists
if [ ! -f "bin/typophic-deploy" ]; then
  echo "Error: bin/typophic-deploy not found!"
  exit 1
else
  echo "Found bin/typophic-deploy ✓"
  chmod +x bin/typophic-deploy
fi

# 5. Instructions for setting up remote repository
echo ""
echo "=== Next Steps ==="
echo "1. Create a GitHub repository for your project"
echo "2. Add the remote repository using:"
echo "   git remote add origin https://github.com/USERNAME/REPO_NAME.git"
echo ""
echo "3. Push your source code to the main branch:"
echo "   git push -u origin main"
echo ""
echo "4. Deploy your site to GitHub Pages using your existing typophic-deploy script:"
echo "   bin/typophic-deploy --remote https://github.com/USERNAME/REPO_NAME.git"
echo ""
echo "Your source code will be on the main branch, and the built site on the gh-pages branch."
echo "The public directory is excluded from the main branch via .gitignore"
