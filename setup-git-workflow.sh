#!/bin/bash

# Script to set up proper Git workflow for Ruby Learning project
# - Main branch: Source code
# - gh-pages branch: Built site (public directory)

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

# 4. Set up worktree for gh-pages branch
echo "Setting up gh-pages branch..."
if [ -d "public" ]; then
  # Check if gh-pages branch exists
  if git rev-parse --verify gh-pages >/dev/null 2>&1; then
    echo "gh-pages branch already exists"
  else
    echo "Creating gh-pages branch..."
    git branch gh-pages
    echo "Created gh-pages branch"
  fi
  
  # Modify typophic-deploy script to use the correct workflow
  echo "Updating typophic-deploy script to handle proper git workflow..."
  
  # Create a more robust deployment script
  cat > bin/deploy-gh-pages.sh << EOF
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
  git remote add origin \$(git -C .. remote get-url origin)
else
  git checkout gh-pages
fi

# Add all files
git add .

# Commit changes
echo "Committing changes to gh-pages branch..."
git commit -m "Deploy site on \$(date)"

# Push to remote
echo "Pushing to GitHub Pages..."
git push -f origin gh-pages

cd ..

echo "=== Deployment complete! ==="
echo "Your site should now be live at GitHub Pages."
EOF

  chmod +x bin/deploy-gh-pages.sh
  echo "Created deploy-gh-pages.sh script"
else
  echo "Error: public directory not found. Run bin/typophic-build first."
  exit 1
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
echo "4. Deploy your site to GitHub Pages:"
echo "   bin/deploy-gh-pages.sh"
echo ""
echo "Your source code will be on the main branch, and the built site on the gh-pages branch."
