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
bin/typophic-deploy --remote git@github.com:username/rubylearning.git
```

With a custom domain:

```bash
bin/typophic-deploy --remote URL --custom-domain example.com
```

## Deployment Options

The deployment system supports various options:

```
--local               Deploy for local development
--remote URL          GitHub repository URL
--force               Force push to GitHub Pages
--fix-only            Only fix paths without building or deploying
--build-only          Only build site without deploying
--custom-domain DOMAIN  Set a custom domain
--port PORT           Port for local server (default: 3000)
```

For detailed deployment instructions, see `DEPLOYMENT_INSTRUCTIONS.md`.

## Project Configuration

The site configuration is stored in `config.yml` in the root directory. This file controls site-wide settings like:

- Site name and description
- URL and permalink style
- Date format
- Markdown extensions

## Troubleshooting

If you encounter issues with your site, use the fix tool:

```bash
bin/typophic-fix --all
```

This will fix common issues like:
- Unprocessed template variables
- Path problems
- Link inconsistencies
- Tutorial page formatting

## Site Features

- Syntax highlighting for Ruby code
- Responsive design for all devices
- Modern typography and layout
- Clean, distraction-free reading experience
