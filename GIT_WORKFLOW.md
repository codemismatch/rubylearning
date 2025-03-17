# Git Workflow for Ruby Learning

This document explains the Git workflow for the Ruby Learning project, which separates source code and the built site into different branches.

## Branch Structure

- **main** branch: Contains all source code, templates, and build scripts
- **gh-pages** branch: Contains only the built site (public directory)

## Setting Up the Workflow

If you haven't set up the workflow yet, run:

```bash
chmod +x setup-git-workflow.sh
./setup-git-workflow.sh
```

This script will:
1. Initialize a Git repository in the project root
2. Create a `.gitignore` file that excludes the `public` directory from the main branch
3. Commit all source code to the main branch
4. Set up a gh-pages branch for the built site
5. Create a deploy script for GitHub Pages

## Development Workflow

### 1. Making Changes to the Site

Work directly on the main branch:

```bash
# Edit content, templates, or scripts
git add .
git commit -m "Your commit message"
```

### 2. Building the Site Locally

To preview your changes:

```bash
bin/typophic-build
bin/typophic-serve
```

### 3. Deploying to GitHub Pages

When you're ready to deploy:

```bash
# Deploy built site to gh-pages branch
bin/deploy-gh-pages.sh
```

This script:
1. Builds the site with `typophic-build`
2. Fixes paths for GitHub Pages deployment
3. Commits the built site to the gh-pages branch
4. Pushes the gh-pages branch to GitHub

### 4. Publishing Source Code

Don't forget to also push your source code:

```bash
git push origin main
```

## Advanced Options

### Specifying a Remote Repository

```bash
bin/deploy-gh-pages.sh --remote https://github.com/username/repo.git
```

### Force Pushing (Use with Caution)

```bash
bin/deploy-gh-pages.sh --force
```

## Benefits of This Workflow

1. **Source Preservation**: All your content, templates, and scripts are version-controlled
2. **Clear Separation**: Source code and built site are in separate branches
3. **Easier Collaboration**: Others can contribute to the source code
4. **Build Process Control**: You control when and how the site is built and deployed

## Common Issues

### "Failed to push to GitHub"

Make sure you have the correct permissions and the remote URL is properly set up:

```bash
git remote -v
# Should show your GitHub repository URL
```

### "There are uncommitted changes"

Commit or stash changes on the main branch before deploying:

```bash
git add .
git commit -m "Commit message"
# Or stash changes
git stash
```
