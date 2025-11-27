# Content Metadata – Phase 0 (Current State Snapshot)

## Rephrased Problem Statement

> On the live Rubylearning site, posts, tutorials, and pages do not clearly show **who wrote them** or **when they were published/updated**. We want every blog article, tutorial chapter, and major page to expose proper author + date metadata.  
>  
> Ultimately, author names (and ideally avatars) should be driven from Git/GitHub data so that:  
> - The **primary author** is the person who originally authored the content.  
> - **Additional editors** are credited if multiple people have committed changes.  
> - Author “cards” at the top of posts/chapters show their real name and image.  
>  
> We also want a proper **drafts** system so unfinished content (posts, pages, chapters) can exist in the repo but stay unpublished. And longer‑term, we want CLI workflows to scaffold new **courses** (SQL, Python, ML, Deep Learning) with the right metadata from day one.

This file describes what’s currently implemented (“baseline”) and how it relates to the bigger goal.

## What’s Implemented Today

### 1. Page/Chapter Context

The builder already computes a rich `page` hash for each content file (`lib/typophic/builder.rb:600+`):

- `page.title`, `page.permalink`, `page.url`, `page.output_path`
- `page.section` (e.g. `posts`, `pages`, `tutorials`)
- `page.date` and `page.date_iso` (derived from frontmatter or filename)
- `page.tags`
- `page.layout` (e.g. `post`, `tutorial`)

Newly added in this phase:

- `page.draft` is normalized to a boolean: `page["draft"] = !!page["draft"]`.

### 2. Rendering authors and dates

Layouts now display author + date when the data is present.

- `themes/rubylearning/layouts/post.html`
  - Uses `page.author_id` or `page.author` to look up `site.data.authors[author_id]` (when present).
  - Renders:
    - Author avatar (from `authors.yml`) or initials fallback.
    - Author name.
    - Post date (`page.date`) formatted via `site.date_format`.
  - Tags remain unchanged.

- `themes/rubylearning/layouts/tutorial.html`
  - Similar logic in `.tutorial-meta`:
    - Author avatar/initials, name.
    - Date if available.

CSS support:

- `themes/rubylearning/css/style.css`: `.post-meta`, `.post-author*`, `.post-date` for blog posts.
- `themes/rubylearning/css/tutorials.css`: `.tutorial-meta`, `.tutorial-author*`, `.tutorial-date` for chapters.

Currently, authors are only shown when the frontmatter provides `author` (or `author_id`); there’s no `data/authors.yml` yet, so everything falls back to the raw frontmatter string.

### 3. Draft handling

The build now treats drafts as unpublished:

- In `Typophic::Builder#process_content_files`:
  - Files under `content/**/drafts/**` are **ignored**.
  - After parsing, entries with `entry[:meta]["draft"]` truthy are **filtered out** in both sequential and parallel flows.

Result:

- Any content file with `draft: true` in frontmatter will *not* be indexed or rendered.
- The existing blog CLI (`typophic blog new --draft`, `blog publish`, etc.) continues to use `content/drafts` for blog drafts; those files are now guaranteed not to leak into the build.

## What Remains / Not Yet Implemented

1. **Author directory**
   - Missing `data/authors.yml` schema (e.g. `id`, `name`, `github`, `avatar`, `bio`).
   - No mapping from Git commit authors to these IDs.

2. **Automatic author + contributor attribution**
   - Today, `author` is manual frontmatter.  
   - No tool exists to:
     - Inspect Git history for a file.
     - Derive a primary author + additional contributors.
     - Update `author` and `contributors` fields in frontmatter.

3. **Multi‑author rendering**
   - Layouts only show a single primary author.  
   - No UI yet for “Edited by Alice, Bob” or contributor lists.

4. **Drafts UX**
   - There is no “Drafts” index page for maintainers.  
   - Tutorials/pages CLI doesn’t yet support `--draft` like blog posts do (only blog drafts are fully wired).

5. **Course scaffolding**
   - No CLI commands yet to scaffold “tracks” (SQL, Python, ML, Deep Learning) with consistent frontmatter (`course`, `lesson`, `author`, `draft`, etc.).

## Tricky/Challenging Aspects

- **Deriving authors from Git/GitHub**
  - Git author/committer names/emails may be inconsistent, aliased, or changed over time.
  - Mapping email → GitHub username → avatar requires either:
    - A maintained mapping table in `data/authors.yml`, or
    - Network calls + auth to the GitHub API (not desirable in a static build).
  - Collaborators may contribute from forks or different email addresses; we need a clear rule for “primary author vs contributor”.

- **Keeping frontmatter as the source of truth**
  - We want Git history to *populate* and update `author`/`contributors`, but once written, frontmatter should remain a simple, inspectable truth source for templates and external tools.
  - Pre‑commit hooks must be careful not to clobber manual edits.

- **Drafts across all content types**
  - The blog system already has CLI + directory conventions (`content/posts`, `content/drafts`).
  - Tutorials and pages live under `content/pages/**` with custom structures; adding drafts there needs consistent rules so authors don’t get confused.

These challenges drive the later phases.

## Direction of Evolution

The baseline changes are intentionally small:

- We’ve **enabled** author and date display where metadata exists.
- We’ve **blocked** drafts from being published.

Next, we evolve toward your described vision via separate phases (each with its own doc):

- `content-metadata-phase1-authors-and-dates.md` — Standardize frontmatter, add `data/authors.yml`, and make every new post/page/tutorial carry author+date.
- `content-metadata-phase2-git-authorship.md` — Add Git‑aware tools/pre‑commit hooks that update `author` and `contributors` from history.
- `content-metadata-phase3-drafts.md` — Unify draft handling and introduce clear authoring UX for drafts across posts/pages/tutorials.
- `content-metadata-phase4-courses-cli.md` — Course/track scaffolding (SQL, Python, ML, Deep Learning), so new content launches with all metadata wired from day one.

Each subsequent phase file details requirements and tasks for that slice of the work.

