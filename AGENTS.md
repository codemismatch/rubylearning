# Repository Guidelines

## Project Structure & Module Organization
The `typophic` executable lives in `bin/`, while all reusable code ships under `lib/typophic/` (CLI, builder, command modules). Authoring happens in `content/` (Markdown lessons by topic) and `themes/<name>/` (ERB layouts, partials, and static assets). Optional overrides live in root-level `layouts/`, `includes/`, `assets/`, and `helpers/`. Shared YAML data belongs in `data/`, and generated output always lands in `public/`—treat it as disposable. Automation utilities stay in `tools/`, and environment-wide settings remain in `config.yml`.

## Build, Test, and Development Commands
Use `typophic build` for one-off builds; add `--deploy` before publishing to drop `.nojekyll` and the 404 page. Run `typophic serve --build --port 3000` during authoring for a live preview. For deploy rehearsals run `typophic deploy --local --watch`; to publish, call `typophic deploy --remote origin --branch gh-pages`. Scaffold new themes with `typophic theme new <name>`—every workflow now flows through the single `typophic` CLI.

## Coding Style & Naming Conventions
Ruby code sticks to two-space indentation, snake_case identifiers, and descriptive class/module names (e.g., `Typophic::Builder`). Keep `bin/typophic` executable (`chmod +x`). New CLI or helper files must start with `#!/usr/bin/env ruby` and `# frozen_string_literal: true`. In ERB templates, prefer semantic HTML and BEM-ish class names. Add concise comments only when intent is unclear. Content Markdown should include frontmatter with `title`, `layout`, and optional `permalink`. Theme/site helper methods should live under `helpers/` and define modules within `Typophic::Helpers` so templates can include them automatically.

## Testing Guidelines
There is no automated suite yet; manually run `typophic build --deploy` and `typophic serve --port 3000` to verify pages, navigation, theme overrides, and assets. Spot-check generated URLs and asset paths—link fixing happens during the build now. When touching Ruby helpers, add quick smoke scripts under `tools/` or invoke via `typophic` in dry runs to ensure missing frontmatter is handled gracefully.

## Commit & Pull Request Guidelines
Keep commit subjects imperative and ≤60 characters (e.g., `Add deploy watcher`). PRs should summarize user-visible changes, list manual verification commands, and attach screenshots for UI tweaks. Request a second review for deployment flow or `config.yml` updates. Avoid committing the `public/` directory; CI/CD should regenerate it.

## Configuration, Deployment & Future Plans
Always update `config.yml` when introducing new routes, repo URLs, or base paths. Secrets stay out of version control—`typophic deploy` expects environment variables for auth. Mid-term roadmap: package Typophic as a gem for reuse, add Hugo-style theme directories (while keeping ERB flexibility), and experiment with LLM-assisted theme scaffolding. Track these efforts in dedicated issues and update this guide as capabilities land.
