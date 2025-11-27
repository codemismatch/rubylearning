# Content Metadata – Phase 3 (Unified Draft Workflow)

Phase 0/1 made `draft` a boolean and ensured drafts don’t get rendered.  
Phase 3 designs a **coherent draft workflow** across blog posts, tutorials, and pages.

## Goals

- Authors can create **draft** content for:
  - Blog posts.
  - Tutorial chapters.
  - Major pages (where appropriate).
- Drafts live in the repo but are **never published** in production.
- There is a clear way to:
  - List drafts.
  - Preview them locally.
  - Promote them to “published” (e.g., via CLI).

## Requirements

### 1. Directory conventions

Blog posts already use:

- Published: `content/posts/YYYY-MM-DD-slug.md`
- Drafts: `content/drafts/slug.md`

For tutorials and pages we should adopt a parallel scheme while keeping URLs stable:

- Tutorial drafts:
  - Option A (simplest): `content/drafts/tutorials/<slug>.md`
  - Option B (more structured): `content/drafts/tutorials/<track>/<slug>.md` (future course support)
- Page drafts:
  - `content/drafts/pages/<slug>.md`

Frontmatter for drafts:

```yaml
---
title: "SQL: SELECT basics"
layout: tutorial
permalink: /tutorials/sql/select/
date: 2025-12-01        # planned date / first draft date
author: pankaj
draft: true
---
```

### 2. Builder behavior (already partially implemented)

Current behavior (Phase 0):

- `Typophic::Builder#process_content_files`:
  - Ignores any file under paths that include `"drafts"`.
  - Filters parsed entries with `entry[:meta]["draft"]` truthy.

Phase 3 confirms and documents:

- Draft files under `content/drafts/**` are **never rendered**.
- Draft flags (`draft: true`) in frontmatter for any content file prevent rendering even if the file is outside `drafts/`.

This double guard allows:

- Temporary drafts inside `content/pages/…` (using `draft: true`).
- Long‑term drafts under `content/drafts/**`.

### 3. CLI support for drafts

Blog drafts already have CLI support (`typophic blog new --draft`, `blog publish`).

Phase 3 adds similar ergonomics for tutorials/pages:

- New command or extension:

  - `typophic new tutorial TITLE [--draft] [--course sql] [--permalink /tutorials/sql/select/]`
  - `typophic new page TITLE --draft`

Behavior:

- With `--draft`:
  - Write to `content/drafts/tutorials/...` or `content/drafts/pages/...`.
  - Set `draft: true` in frontmatter.
- Without `--draft`:
  - Write directly to `content/pages/tutorials/...` (or appropriate path) with `draft: false` omitted.

We can mirror `blog publish` for tutorials:

- `typophic tutorial publish --slug select-basics [--course sql]`
  - Move the file from `content/drafts/tutorials/...` into the published tree.
  - Optionally update `date` to today.
  - Set `draft: false` / remove the flag.

### 4. Draft listing & maintenance

Add a small CLI helper:

- `typophic drafts list`
  - Lists all drafts across posts/pages/tutorials.
  - Shows path, title, type, and last modified date.

Example output:

```text
Drafts:
- [post]      content/drafts/sql-intro.md          (SQL Intro)
- [tutorial]  content/drafts/tutorials/sql-select.md  (SQL: SELECT basics)
- [page]      content/drafts/pages/ml-overview.md (ML Overview)
```

This is primarily for maintainers; it doesn’t affect the public site.

### 5. Local preview of drafts

For local authoring, it’s useful to preview drafts without publishing them in production:

- Option A: add a `--include-drafts` flag to `typophic serve` / `typophic build`.
  - When set (or when `ENV["TYPOPHIC_INCLUDE_DRAFTS"]` is truthy), the builder:
    - Does **not** filter out entries where `page["draft"]` is true.
    - Optionally adds a visible “DRAFT” banner in the layout (via `page.draft`).
- For production deploys, we simply don’t pass that flag/environment variable.

This provides a clean separation between local preview and published output.

## Tasks

1. Decide directory conventions for tutorial/page drafts (e.g., `content/drafts/tutorials` and `content/drafts/pages`).
2. Extend the CLI:
   - `new tutorial` and/or `new page` to accept `--draft` and write to draft paths.
   - `tutorial publish` and possibly `page publish` to promote drafts.
3. Add a `typophic drafts list` helper.
4. Add optional draft‑preview flag:
   - `typophic serve --build --include-drafts` or an env var.
   - Layout tweaks to display a “DRAFT” label when `page.draft` is true (for local preview).

## Open Questions

- **Do we allow drafts under published paths?**
  - For minimal confusion, the recommendation is:
    - Long‑lived drafts → `content/drafts/**`.
    - Short‑lived experiment → `draft: true` in place, but this should be rare.

- **Date semantics for drafts**
  - Keep `date` as the *intended publication* date or the *first draft* date?
  - Approach: use `date` as first creation date, add `published_at` if we need a distinct field later.

Phase 3 makes drafts a first‑class concept throughout the authoring workflow, without risking accidental publication.

