# Ruby Learning

A beautiful static website for learning Ruby programming language using the Typophic static site generator.

## Project Structure

- `bin/` - Core utility scripts for building and managing the site
- `content/` - Source Markdown files for the site content
- `data/` - Data files for the site (for dynamic content)
- `public/` - Generated static site output
- `templates/` - HTML templates and assets (CSS, JS, images)
- `tools/` - Additional helper utilities

## Core Commands

The following commands are available for site management:

| Command | Description |
|---------|-------------|
| `bin/typophic` | Main static site generator |
| `bin/typophic-build` | Build the site with all optimizations |
| `bin/typophic-deploy` | Unified deployment system (local or GitHub Pages) |
| `bin/typophic-fix` | Fix common site issues |
| `bin/typophic-new` | Create new content |
| `bin/typophic-serve` | Local development server |

## Quick Start

### First-time Setup

```bash
# Make all scripts executable
chmod +x bin/*
```

### Building the Site

Build the site with all optimizations:

```bash
bin/typophic-build
```

### Preview the Site

Start a local development server:

```bash
bin/typophic-serve
```

Visit http://localhost:3000 in your browser.

### Creating New Content

Create a new post:

```bash
bin/typophic-new post "My New Ruby Tutorial"
```

Create a new page:

```bash
bin/typophic-new page "About Ruby"
```

### Deploying the Site

For local development:

```bash
bin/typophic-deploy --local
```

For GitHub Pages:

```bash
bin/typophic-deploy
```

The GitHub Pages repository URL is configured in `config.yml`:

```yaml
repository:
  url: git@github.com:username/rubylearning.git
  branch: main
  deploy_branch: gh-pages
```

## Detailed Command Documentation

### typophic-build

Builds the site with all necessary optimizations.

```bash
bin/typophic-build [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--deploy` | Build with deployment optimizations |
| `--no-minify` | Skip minification of CSS and JavaScript |
| `--no-optimize` | Skip image optimization |
| `--watch` | Watch for changes and rebuild automatically |
| `--verbose` | Display detailed output during build |
| `--quiet` | Suppress all output except errors |
| `--clean` | Clean build directory before building |

**Examples:**

```bash
# Build for production with all optimizations
bin/typophic-build --deploy

# Build for development with file watching
bin/typophic-build --watch

# Clean and rebuild the site
bin/typophic-build --clean
```

### typophic-serve

Starts a local development server for previewing the site.

```bash
bin/typophic-serve [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--port PORT` | Specify the port number (default: 3000) |
| `--bind ADDRESS` | Specify the bind address (default: 127.0.0.1) |
| `--live-reload` | Enable live reload on file changes |
| `--no-cache` | Disable caching of assets |
| `--open` | Open browser automatically |

**Examples:**

```bash
# Start server on default port 3000
bin/typophic-serve

# Start server on port 8080 with live reload
bin/typophic-serve --port 8080 --live-reload

# Start server and open browser automatically
bin/typophic-serve --open
```

### typophic-new

Creates new content with proper frontmatter and templates.

```bash
bin/typophic-new [type] [title] [options]
```

**Content Types:**

| Type | Description |
|------|-------------|
| `post` | Blog post or tutorial entry |
| `page` | Static page |
| `category` | Category index page |
| `tutorial` | Multi-part tutorial |

**Options:**

| Option | Description |
|--------|-------------|
| `--author NAME` | Specify content author |
| `--date DATE` | Specify publication date (default: current date) |
| `--draft` | Mark as draft (not published) |
| `--series NAME` | Add to a tutorial series |
| `--template NAME` | Use specific template |
| `--no-frontmatter` | Skip frontmatter generation |

**Examples:**

```bash
# Create a new blog post
bin/typophic-new post "Getting Started with Ruby Classes"

# Create a draft page
bin/typophic-new page "Contributing Guidelines" --draft

# Create a tutorial with specific author and series
bin/typophic-new tutorial "Building a CLI App" --author "Jane Doe" --series "Ruby CLI"
```

### typophic-fix

Fix common issues in the site content and structure.

```bash
bin/typophic-fix [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--all` | Apply all available fixes |
| `--links` | Fix broken links |
| `--images` | Fix image paths and add missing alt text |
| `--code` | Fix code block formatting |
| `--frontmatter` | Validate and fix frontmatter |
| `--templates` | Fix template variables |
| `--dry-run` | Show what would be fixed without making changes |
| `--verbose` | Show detailed information about fixes |

**Examples:**

```bash
# Apply all fixes
bin/typophic-fix --all

# Fix only links and show detailed output
bin/typophic-fix --links --verbose

# Check what would be fixed without making changes
bin/typophic-fix --all --dry-run
```

### typophic-deploy

Unified deployment system for both local development and GitHub Pages.

```bash
bin/typophic-deploy [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--local` | Deploy for local development |
| `--remote URL` | GitHub repository URL (overrides config.yml) |
| `--base-path PATH` | Base path for GitHub Pages (default: site_name from config.yml or repository name) |
| `--force` | Force push to GitHub Pages |
| `--fix-only` | Only fix paths without building or deploying |
| `--build-only` | Only build site without deploying |
| `--custom-domain DOMAIN` | Set a custom domain |
| `--port PORT` | Port for local server (default: 3000) |
| `-h`, `--help` | Show help message |

**Examples:**

```bash
# Deploy to GitHub Pages using site_name from config.yml as base path
bin/typophic-deploy

# Deploy for local development on port 8080
bin/typophic-deploy --local --port 8080

# Override the base path
bin/typophic-deploy --base-path rubylearning

# Only fix paths without deploying
bin/typophic-deploy --fix-only

# Force push to GitHub Pages
bin/typophic-deploy --force

# Deploy with custom domain
bin/typophic-deploy --custom-domain rubylearning.example.com
```

## Feature: Automatic Base Path Detection

The `typophic-deploy` script now automatically determines the base path for GitHub Pages from your `config.yml` file:

1. First, it checks for a `site_name` in your config.yml and uses that as the base path (converted to lowercase with spaces removed)
2. If `site_name` is not available, it falls back to extracting the repository name from the URL
3. The base path can always be manually specified with the `--base-path` option

This feature eliminates the need to manually specify the base path when deploying to GitHub Pages.

## Path Fixing for GitHub Pages

When deploying to GitHub Pages, the `typophic-deploy` script automatically:

1. Updates all links (href, src) to include the correct base path
2. Sets the appropriate base tag in HTML files
3. Fixes CSS url() references
4. Creates a debug file at `/path-debug.html` to help troubleshoot any path issues

## Git Workflow

The project uses a proper Git workflow:

1. The **main** branch contains the source code (content, templates, scripts)
2. The **gh-pages** branch contains the built site (public directory)

The deployment script handles all the Git operations for the gh-pages branch, including:
- Initializing a Git repository in the public directory
- Setting the remote repository URL
- Committing changes with informative commit messages that include the base path
- Pushing to the gh-pages branch

## Troubleshooting

If you encounter issues with your site, use the fix tool:

```bash
bin/typophic-fix --all
```

For path-related issues on GitHub Pages, check the automatically generated debug page:
```
https://username.github.io/rubylearning/path-debug.html
```

## Project Configuration

The site configuration is stored in `config.yml` in the root directory:

```yaml
---
site_name: Ruby Learning         # Used for site title and base path
site_type: ruby                  # Site category/type
author: Your Name                # Default author
description: Site description    # Meta description
url: http://example.com          # Production URL
permalink_style: pretty          # URL format style
date_format: "%B %-d, %Y"        # Date display format
markdown_extensions:             # Markdown processors to enable
  - tables
  - fenced_code_blocks
  - autolink
repository:                      # Git repository settings
  url: git@github.com:username/rubylearning.git
  branch: main
  deploy_branch: gh-pages
```

## Site Features

- Syntax highlighting for Ruby code with Prism.js
- Responsive design for all devices
- Modern typography and layout
- Clean, distraction-free reading experience
- Automated deployment to GitHub Pages