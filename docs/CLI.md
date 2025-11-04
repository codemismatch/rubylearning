Typophic CLI

Usage: `typophic [command] [options]`

Core commands
- `build` — Build the static site (production-ready by default)
- `serve` — Serve `public/` with auto-rebuild and live reload
  - Options: `--build` `--port N` `--host H` `--[no-]watch` `--[no-]livereload`
- `deploy` — Publish the site
  - GitHub Pages (default): `--remote origin` `--branch gh-pages` `--force` `--custom-domain DOMAIN`
  - S3: `--provider s3 --bucket BUCKET [--region REGION]`
  - rsync: `--provider rsync --dest user@host:/path/`
- `new` — Generators for site/blog/post/page
  - `typophic new site NAME [--theme NAME|URL] [--dir DIR] [--type TYPE] [--author NAME] [--description TEXT]`
  - `typophic new blog NAME [--theme NAME|URL] ...` (same options as `site`, with type preset)
  - `typophic new post TITLE [--slug SLUG] [--date YYYY-MM-DD] [--tags a,b] [--description TEXT] [--layout NAME] [--draft] [--author NAME]`
  - `typophic new page TITLE [--permalink /path/] [--layout NAME] [--author NAME]`
  - Author resolution: if `--author` is omitted, the CLI uses `git config user.name` and `user.email`; if a GitHub origin remote is configured, it appends `(@owner)`.
- `blog` — Blog workflow
  - `typophic blog new ...` (same flags as `new post`)
  - `typophic blog publish --slug SLUG [--date YYYY-MM-DD]`
  - `typophic blog list [--drafts]`
  - `typophic blog delete --slug SLUG [--draft] [--date YYYY-MM-DD]`
- `theme` — Theme management
  - `typophic theme new NAME` — scaffold a theme under `themes/NAME`
  - `typophic theme use NAME [--default] [--section SECTION]` — set default or per-section theme in `config.yml`
  - `typophic theme install URL|OWNER/REPO[#ref] [--name NAME]` — install theme from GitHub into `themes/NAME` (supports `#branch` or commit ref)
  - `typophic theme list` — list installed themes
  - `typophic theme remove NAME` — remove theme directory
- `clean` — Remove generated artifacts in `public/`
- `doctor` — Validate project structure and configuration

Examples
- `typophic new site mysite --theme rubylearning`
- `typophic new blog myblog --theme https://github.com/user/cool-theme`
- `typophic new post "Hello World" --tags intro --draft`
- `typophic new page "About" --permalink /about/`
- `typophic theme install user/cool-theme`
- `typophic blog list --drafts`
- `typophic deploy --remote origin --branch gh-pages`
- `typophic deploy --provider s3 --bucket my-bucket`

Notes
- Generated content lives under `content/`; output is written to `public/`.
- Theme files live under `themes/<name>/`. You can also add overrides under root-level `layouts/`, `includes/`, and `assets/`.
- Live reload uses a lightweight polling mechanism.
