# Content Metadata – Phase 1 (Author & Date Baseline)

This phase turns “author + date” from an optional nicety into a **mandatory, consistent contract** for posts, tutorials, and key pages.

## Goals

- Every **blog post**, **tutorial chapter**, and **main page** has:
  - A clear **primary author**.
  - A **published date** (and optional updated date).
- The frontmatter schema is **standardized**, so templates and tools can rely on it without ad‑hoc checks.
- New content created via Typophic CLI **always includes this metadata** by default.

## Requirements

### 1. Frontmatter schema

For posts (`layout: post`), tutorials (`layout: tutorial`), and key pages (`layout: page`):

- Required fields:
  - `title: "..."`  
  - `layout: post|tutorial|page`  
  - `date: YYYY-MM-DD` (or full ISO datetime if needed) – **auto-populated from Git** if missing  
  - `author: <author_id>` – where `<author_id>` is a key into `data/authors.yml` – **auto-populated from Git** if missing
- Optional fields:
  - `updated_at: YYYY-MM-DD` – used for "Updated on …" – **auto-populated from Git** last commit
  - `contributors: [alice, bob]` – **auto-populated from Git** (all authors except primary)
  - `draft: true|false` – drafts skip Git analysis
  - `tags`, `summary`, `difficulty`, `permalink`, etc.

Example (post):

```yaml
---
title: "Welcome to Ruby Learning"
layout: post
date: 2023-01-01
author: pankaj
tags: [introduction, beginners]
description: "Start here for the guided Ruby learning path."
---
```

Example (tutorial chapter):

```yaml
---
layout: tutorial
title: "Super Fast Ruby Intro (40 minutes)"
permalink: /tutorials/quick-intro/
date: 2025-11-27
author: pankaj
difficulty: beginner
summary: "A 40-minute tour from Ruby as a calculator to a tiny DSL."
---
```

### 2. Author directory (`data/authors.yml`)

Define a canonical **registry** of all authors. This serves three purposes:

1. **Email → Author ID mapping** (for Git analysis)
2. **GitHub username mapping** (for API lookups)
3. **Cached author data** (name, avatar, bio from GitHub API)

**Hybrid Architecture**: `authors.yml` is NOT the source of truth for "who wrote what" (that's Git history), but rather:
- A **local cache** to avoid hitting GitHub API on every build
- An **email directory** to map Git commit emails to author IDs
- A **manual override** system for edge cases

Suggested schema:

```yaml
pankajdoharey:
  github: codemismatch          # GitHub username (required)
  emails:                       # All Git commit emails for this person
    - pankaj@example.com
    - pankajdoharey@users.noreply.github.com
    - pankaj@work.com
  # Cached from GitHub API (refreshed via `typophic authors refresh`)
  name: "Pankaj Doharey"        # From GitHub API or manual override
  avatar: "https://avatars.githubusercontent.com/u/12345"  # From GitHub
  bio: "Maintainer of Rubylearning and Typophic."
  cached_at: 2025-11-27         # Last GitHub API fetch

satish:
  github: satish
  emails:
    - satish@example.com
  name: "Satish Talim"
  avatar: "https://avatars.githubusercontent.com/u/67890"
  bio: "Author of the original RubyLearning lessons."
  cached_at: 2025-11-27
```

The layout logic added in Phase 0 already uses:

- `author_id = page.author_id | default: page.author`
- `author_data = site.data.authors[author_id]`

Phase 1 formally defines what lives in `authors.yml` and establishes it as the central author registry.

### 3. CLI defaults

Update CLI generators so new content never “forgets” author and date.

Already partially present:

- `Typophic::Commands::New.run_post` (`lib/typophic/commands/new.rb`):
  - Initializes `date: Date.today`.
  - If `--author` is omitted, uses `Typophic::Util.resolved_author` (which inspects git config / origin remote).
- `Typophic::Commands::Blog.create_post` (`lib/typophic/commands/blog.rb`):
  - Writes `author` into post frontmatter.

Phase 1 tasks:

- Ensure **all** generators include `author` + `date`:
  - `new post`
  - `blog new`
  - `new page`
  - any future `new tutorial` or `new course lesson` commands.
- For tutorials currently authored directly as `.md` under `content/pages/tutorials/`:
  - Add `date` and `author` frontmatter where missing.

### 4. Layout behavior (post + tutorial)

We already wired:

- `post.html`:
  - Show author avatar or initials, name, and date in `.post-meta`.
- `tutorial.html`:
  - Show author + date in `.tutorial-meta`, above the summary.

Phase 1 ensures:

- All posts and tutorials **actually have** author + date, so the UI appears consistently.
- Pages where author/date are truly irrelevant (e.g., a static resources page) can omit `author`, but we should decide whether `date` is still required or simply recommended.

## Tasks

1. **Create authors.yml registry**:
   - Create `data/authors.yml` with schema (github, emails, cached data)
   - Seed with initial authors and their Git commit emails
   - Add documentation for maintaining the registry

2. **Build Git analysis infrastructure**:
   - Create `lib/typophic/git_authorship.rb` module
   - Implement Git log parsing per content file
   - Implement email → author_id mapping logic
   - Compute primary author (first commit strategy)
   - Compute contributors (all other committers)
   - Extract published_at and updated_at from Git history

3. **Integrate Git analysis with builder**:
   - Update `lib/typophic/builder.rb` to call Git analysis in `build_page_context`
   - Auto-populate `author`, `contributors`, `date`, `updated_at` from Git
   - Skip Git analysis for drafts
   - Allow manual frontmatter to override Git-detected values

4. **Update layouts for multi-author support**:
   - Update `themes/rubylearning/layouts/post.html` to show contributors
   - Update `themes/rubylearning/layouts/tutorial.html` to show contributors
   - Add CSS for contributor avatar display ("Edited by" section)

5. **CLI enhancements**:
   - Ensure all generators (`new post`, `blog new`, `new page`) set author from Git config
   - Add `typophic authors refresh` command to sync GitHub API data
   - Add `typophic authors list` command to show registry

6. **Optional manual normalization**:
   - For existing content without commits, manually add `author:` and `date:` to frontmatter
   - Git analysis will handle the rest going forward

## Open Questions

- **Single vs multiple authors in v1**
  - Phase 1 treats `author` as a single ID. We’ll add `contributors` in Phase 2 once Git‑aware tooling exists.

- **Author images**
  - Do we want to serve avatars from **local assets** (`/images/authors/*.jpg`) for stability, or link to `https://github.com/<user>.png`?
  - Local assets are safer for offline use and avoid depending on third‑party CDNs; but they require adding images to the repo.

- **Minimum metadata for pages**
  - Do all top‑level pages (About, Resources, Tutorials index) need an author, or just the blog/tutorial content?

These decisions can be refined as we start populating `authors.yml` and updating existing content.

