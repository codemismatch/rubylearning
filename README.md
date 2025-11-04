# Ruby Learning Website

A static website for learning Ruby programming, built with Typophic.

## Features

### Multi-Theme System
- **rubylearning theme**: Default theme optimized for tutorial content
- **hugo-serif-typophic theme**: Sans-serif theme for blog posts
- **bonsaiblog theme**: Alternative theme for blog sections

### Configuration
The site uses a multi-theme configuration:
```yaml
theme:
  default: rubylearning
  sections:
    posts: hugo-serif-typophic
```

This means:
- Main site (tutorials, about, resources) uses rubylearning theme
- Blog posts use hugo-serif-typophic theme (sans-serif design)

### Blog Post Features
- Sans-serif typography for better readability
- Clean, minimalist design
- Proper date display
- Tag support
- Responsive layout
- Mobile-friendly navigation

### Tutorial Features
- Comprehensive Ruby tutorials
- Step-by-step learning path
- Code examples with syntax highlighting
- Interactive elements

## Theme Structure

### hugo-serif-typophic (Blog Theme)
Location: `themes/hugo-serif-typophic/`

Key files:
- `layouts/post.html` - Blog post layout
- `layouts/default.html` - Default page layout
- `includes/_header.html` - Site header
- `includes/_main-menu.html` - Navigation menu
- `css/style.css` - Theme styling
- `js/scripts.js` - JavaScript enhancements

### rubylearning (Main Theme)
Location: `themes/rubylearning/`

Optimized for tutorial content with:
- Educational-focused layout
- Code snippet styling
- Interactive elements
- Comprehensive navigation

## Recent Enhancements

### 1. Multi-Theme Support
- Implemented section-specific theme assignment
- Blog posts now use sans-serif theme for better readability
- Main content uses tutorial-optimized theme

### 2. Clean Blog Layout
- Simplified HTML structure
- Eliminated header duplication issues
- Consistent navigation across all pages
- Proper metadata handling

### 3. Responsive Design
- Mobile-friendly navigation
- Flexible grid system
- Adaptive typography
- Touch-friendly elements

## Build Process
```bash
# Install dependencies
bundle install

# Build the site
bundle exec typophic build

# Serve locally
bundle exec typophic serve
```

## CLI Commands

Typophic ships a single CLI with Rails-like generators and sensible defaults. Quick reference:

```bash
# Generators
typophic new site mysite --theme rubylearning
typophic new blog myblog --theme https://github.com/user/cool-theme
typophic new post "Hello World" --tags intro --draft
typophic new page "About" --permalink /about/

# Blog workflow
typophic blog new --title "Understanding Enumerable" --tags ruby
typophic blog publish --slug understanding-enumerable
typophic blog list --drafts
typophic blog delete --slug understanding-enumerable --date 2025-01-01

# Theme management
typophic theme new mytheme
typophic theme install user/cool-theme         # or full GitHub URL
typophic theme list
typophic theme use mytheme --default

# Build/serve/deploy
typophic build --deploy
typophic serve --build --port 3000
typophic deploy --remote origin --branch gh-pages
typophic deploy --provider s3 --bucket my-bucket

# Utilities
typophic clean
typophic doctor
```

For the full command reference, see `docs/CLI.md`.

## Content Organization
- `/content/pages/` - Main pages and tutorials
- `/content/posts/` - Blog posts
- `/data/` - Site data files
- `/themes/` - Theme files

## Custom Features
- Syntax highlighting for Ruby code
- Tutorial progression tracking
- Related content suggestions
- Tag-based content organization
