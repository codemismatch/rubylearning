# Ruby Learning

Ruby Learning is a Typophic-powered static site that curates modern Ruby programming guides, tutorials, and reference material. The repository now revolves around a single `typophic` executable that drives builds, previews, deployments, and scaffolding—no auxiliary binaries required.

## Project Structure

- `bin/` – home of the primary `typophic` executable
- `content/` – Markdown sources organised by section (`posts/`, `pages/`, etc.)
- `themes/rubylearning/` – ERB layouts, partials, and static assets (`css/`, `js/`, `images/`)
- `layouts/`, `includes/`, `assets/` – optional site-level overrides that shadow theme files
- `helpers/` – Ruby helper modules (namespaced under `Typophic::Helpers`) made available to templates
- `lib/` – Typophic runtime (builder, CLI commands, helpers)
- `data/` – optional structured data files used during rendering
- `public/` – generated output (safe to delete; always recreated by `typophic build`)
- `config.yml` – site-wide metadata, deployment settings, and URL information

## Architecture Overview

Typophic is built as a RubyGem-backed static site generator. The same codebase powers the dogfooded `rubylearning` site and can be installed as a reusable tool.

If you want to dive deeper into the internals, see [`docs/INTERNALS.md`](docs/INTERNALS.md).

### Runtime Layers

- **CLI (`bin/typophic`)** – entry point exposing subcommands (`build`, `serve`, `deploy`, `new`, `theme`).
- **Core library (`lib/typophic/`)** – builder, command modules, theme scaffolder, and helper plumbing packaged by the gemspec.
- **Helpers (`helpers/` & `themes/<name>/helpers/`)** – optional Ruby modules under `Typophic::Helpers::*`. They are auto-included in template bindings so themes can add Ruby utilities without custom wiring.

### Content Pipeline

1. **Discovery** – Markdown files in `content/` are parsed, frontmatter extracted, and canonical metadata derived (slug, permalink, date, tags, layout).
2. **Indexing** – Before rendering, Typophic walks the entire content tree to build collections for each section, chronological archives (`site.archives`), and tag taxonomies (`site.tags`). Themes can iterate these data structures to render listings.
3. **Rendering** – Markdown is transformed to HTML with a lightweight renderer, then wrapped in ERB layouts. Layout inheritance is supported via frontmatter (`layout: parent`).
   - Pages can also be expressed as `.html`, `.html.erb`, or `.erb`. Typophic detects the extension, runs ERB when needed (honouring the frontmatter), and drops the generated file at the permalink derived from the frontmatter or file name.
4. **Output** – HTML is written to `public/`, assets are copied, and JSON summaries land in `public/typophic/` for client-side use.

### Theme Resolution

When Typophic looks for a layout, partial, or asset it checks in order:

1. Site-level overrides (`layouts/`, `includes/`, `assets/`).
2. Active theme (`themes/<theme-name>/…`).

This mirrors Hugo/Jekyll behaviour—site-specific tweaks can shadow theme files without forking the theme.

### Theme Packaging

- Themes live under `themes/<name>/` and ship with `layouts/`, `includes/`, `css/`, `js/`, and optional `helpers/` or `images/` directories.
- `config.yml` declares the active theme (`theme: rubylearning`). Switch the value or run `typophic theme new <name>` to scaffold a fresh theme.
- The gemspec includes both runtime code and the default theme so external users can install from RubyGems and get a working starting point.

### Dogfooding Workflow

- The `rubylearning` site depends on the local gem via the same source tree, so improvements to Typophic immediately benefit the site.
- During development run `bundle exec typophic build` or `typophic serve --build` to exercise the generator with real content.
- When Typophic is ready for wider use, `gem build typophic.gemspec` (and optionally `gem push`) publishes the runtime and default theme for other projects.

## Typophic CLI

Every workflow funnels through the `typophic` command.

| Command | Purpose |
|---------|---------|
| `typophic build` | Render Markdown + ERB into the `public/` directory |
| `typophic serve` | Run the built-in WEBrick preview server (optional `--build`, `--watch`, `--livereload`) |
| `typophic deploy` | Either push `public/` to GitHub Pages or run a local preview loop |
| `typophic new` | Scaffold a brand new Typophic site skeleton |
| `typophic theme` | Manage themes (e.g. `typophic theme new minimal`) |

### Developing as a Gem

Typophic is structured as a Ruby gem. To work on the generator and the site simultaneously:

```bash
bundle install
bundle exec typophic build
```

External projects can point at the gemspec during development:

```ruby
# Gemfile
gem "typophic", path: "../typophic"
```

When ready to distribute, run `gem build typophic.gemspec` (and `gem push` if publishing to RubyGems).

### Scaffolding Themes

Create a fresh theme skeleton alongside the default `rubylearning` theme:

```bash
typophic theme new minimal
```

The command drops starter layouts, includes, and asset folders under `themes/minimal/` ready for customization.

### Building

```bash
typophic build [--no-clean] [--quiet] [--deploy]
```

- `--no-clean` keeps existing files in `public/` for faster rebuilds.
- `--quiet` suppresses progress output.
- `--deploy` adds `.nojekyll` and a polished `404.html`, ready for GitHub Pages.
- Tutorial Markdown under `content/pages/tutorials/` is automatically normalised (Ruby fences reflowed, code windows wrapped) on every build.

### Serving

```bash
typophic serve [--build] [--watch] [--livereload]
              [--port PORT] [--host HOST]
```

- `--build` triggers a fresh build before the server starts (recommended on first run).
- `--watch` monitors `content/`, `themes/`, `layouts/`, `includes/`, `helpers/`, `assets/`, `data/`, and `config.yml`, rebuilding automatically.
- `--livereload` injects a lightweight polling script so browsers refresh as soon as a rebuild completes.
- Specify `--port` (default `3000`) and `--host` (default `localhost`) to suit your environment.

For an end-to-end live preview, run:

```bash
bin/typophic serve --build --watch --livereload
```

If you only need to serve an already-built site, `bin/typophic serve` without flags will reuse the existing `public/` output.

### Deploying

```bash
typophic deploy [--local] [--watch] [--port PORT]
                    [--remote REMOTE] [--branch BRANCH] [--force]
                    [--custom-domain DOMAIN]
```

- `--local` builds the site and starts a preview server instead of pushing.
- `--watch` (local mode only) rebuilds whenever `content/`, `themes/`, `helpers/`, `assets/`, `data/`, or `config.yml` changes.
- `--remote` / `--branch` control the git target (defaults come from `config.yml`).
- `--force` forces the subtree push if the remote branch diverged.
- `--custom-domain` writes `public/CNAME` before publishing.

### Bootstrapping a New Site

```bash
typophic new [--name NAME] [--dir DIR]
              [--type blog|docs|ruby]
              [--author AUTHOR] [--description TEXT]
```

The generator mirrors the current repository layout, sets up sensible defaults in `config.yml`, and copies the `typophic` executable into the new project.

## Configuration

Key settings live in `config.yml`:

```yaml
site_name: Ruby Learning
author: Typophic User
description: A beautiful static website for learning Ruby
url: https://rubylearning.in        # Used for canonical/absolute links
date_format: "%B %-d, %Y"
repository:
  url: git@github.com:metacritical/rubylearning.git
  branch: main
  deploy_branch: gh-pages
```

The builder derives `site.base_path` from `url`, so links and asset paths are correct the first time—no post-processing fixups required.

## Development Workflow

1. Edit Markdown in `content/` or tweak ERB layouts in `themes/<active-theme>/`.
2. Run `bin/typophic serve --build --watch --livereload` for an auto-rebuilding preview (or `bin/typophic build` for a one-off render).
3. Inspect the generated site under `public/`.
4. Publish with `typophic deploy` once you are ready.

Because link rewrites now happen during rendering, there is no need for the legacy `typophic-fix` step. Any previous wrapper will emit a reminder and exit harmlessly.

### Blogging workflow

Typophic includes a `blog` command for scaffolding and publishing articles:

```bash
# Draft a new article (saved under content/drafts/slug.md)
bin/typophic blog new --title "Understanding Enumerable" --tags "ruby,enumerable" --draft

# Promote a draft into content/posts/YYYY-MM-DD-slug.md with a fresh date
bin/typophic blog publish --slug understanding-enumerable
```

- Published posts are timestamped Markdown files stored in `content/posts/`. They adopt the `post` layout by default and automatically appear on `/blog/`.
- The blog index itself lives at `content/pages/blog.html.erb`. That ERB template iterates `site.collections.posts`, so you can tweak the archive design without touching Ruby.
- Drafts remain in `content/drafts/` until you run `blog publish`, which updates the frontmatter date and moves the file into `content/posts/`.

## Deployment Notes

Deploys remain git-based: `typophic deploy` invokes `git subtree push --prefix public` against the configured remote/branch. Verify that `public/` stays ignored locally, and keep `config.yml` updated with the correct repository URL, branch names, and production URL so the builder can generate canonical links accurately.
