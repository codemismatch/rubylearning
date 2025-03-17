# Ruby Learning Deployment Guide

This guide explains how to deploy your Ruby Learning site either locally for development or to GitHub Pages for production.

## Unified Deployment System

The Ruby Learning project uses a unified deployment system that works seamlessly for both local development and GitHub Pages.

## Quick Reference

### Local Development

```bash
bin/typophic-deploy --local
```

### GitHub Pages

```bash
bin/typophic-deploy --remote git@github.com:username/rubylearning.git
```

### Custom Domain

```bash
bin/typophic-deploy --remote URL --custom-domain example.com
```

## All Available Options

| Option | Description |
|--------|-------------|
| `--local` | Deploy for local development (starts a server) |
| `--remote URL` | Set the GitHub repository URL |
| `--force` | Force push to GitHub Pages |
| `--fix-only` | Only fix paths without building or deploying |
| `--build-only` | Only build site without deploying |
| `--custom-domain DOMAIN` | Set a custom domain |
| `--port PORT` | Port for local server (default: 3000) |
| `-h`, `--help` | Show help message |

## Deployment Process

The deployment process handles several tasks automatically:

### For Local Development

1. Builds the site
2. Fixes paths for local development
3. Starts a local server

### For GitHub Pages

1. Builds the site 
2. Fixes paths for GitHub Pages
3. Creates necessary GitHub Pages files (.nojekyll, etc.)
4. Initializes Git repository if needed
5. Commits and pushes to gh-pages branch

## The Path Fixing Process

The major challenge with multi-environment deployment is handling paths correctly:

### Local Development Paths

- Paths are relative to the server root
- Example: `/css/style.css` → `http://localhost:3000/css/style.css`

### GitHub Pages Paths

- Paths include the repository name
- Example: `/css/style.css` → `https://username.github.io/rubylearning/css/style.css`
- Base tag is added: `<base href="/rubylearning/">`

## Troubleshooting

### CSS/JS Not Loading

If styles or scripts are not loading:

1. Check browser console for 404 errors
2. Run path fixes: `bin/typophic-deploy --fix-only --local` or `--fix-only` for GitHub
3. Ensure template doesn't use hardcoded absolute paths

### Links Not Working

If navigation links don't work:

1. Check that the base path is correctly set
2. Ensure links are properly relative or include base path
3. Run `bin/typophic-fix --links` to fix link issues

### GitHub Pages Issues

If your GitHub Pages deployment isn't working:

1. Verify you're using the correct remote URL
2. Check that site is being pushed to gh-pages branch
3. In GitHub repository settings, ensure Pages is set to gh-pages branch

## GitHub Pages Subdirectory Issue

When hosting on GitHub Pages in a subdirectory (like `/rubylearning/`), you need path fixing to ensure resources load correctly:

- Without fixing: `/css/style.css` tries to load from `https://username.github.io/css/style.css` (404 error)
- With fixing: `/css/style.css` loads from `https://username.github.io/rubylearning/css/style.css`

The deployment system handles this automatically.

## Custom Domain Solution

If you prefer not to deal with subdirectories, you can use a custom domain:

1. Purchase a domain (e.g., rubylearning.com)
2. Deploy with `--custom-domain` option
3. Configure domain DNS settings to point to GitHub Pages

With a custom domain, your site will be served from the root, eliminating path issues.

## Advanced Usage

### Path Fixing Only

```bash
bin/typophic-deploy --fix-only --local
# or
bin/typophic-deploy --fix-only  # for GitHub
```

### Building Only

```bash
bin/typophic-deploy --build-only
```

### Forcing Push

```bash
bin/typophic-deploy --remote URL --force
```

## Best Practices

1. Use relative paths in templates when possible
2. Test locally before deploying to GitHub
3. Use `--fix-only` if you need to fix paths without rebuilding
4. Consider using a custom domain for production sites
