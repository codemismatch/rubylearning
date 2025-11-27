# Content Metadata – Phase 4 (Courses & CLI Scaffolding)

This phase focuses on **course tracks** and their CLI support: SQL, Python, Machine Learning, Deep Learning, etc. It builds on earlier phases so new course content starts with correct metadata, draft handling, and navigation.

## Goals

- Model **courses** (tracks) explicitly:
  - Ruby (existing).
  - SQL (Rubylearning SQL v0.1+).
  - Python.
  - ML / Deep Learning.
- Provide a CLI that can:
  - Create a new course.
  - Scaffold new lessons/chapters within a course.
  - Optionally handle drafts/publishing of lessons.
- Integrate courses into:
  - Navigation (tutorial index, course landing pages).
  - Progress tracking (reuse/extend `rl:chapter:{path}` scheme).

## Course Data Model

### 1. Course definition (data)

Store course metadata under `data/courses.yml`:

```yaml
ruby:
  id: ruby
  title: "Ruby Fundamentals"
  slug: "ruby"
  description: "Main Ruby programming track."
  base_path: "/tutorials/"           # existing Ruby tutorials
  order: 1

sql:
  id: sql
  title: "SQL Essentials"
  slug: "sql"
  description: "Learn SQL from SELECT basics to joins and subqueries."
  base_path: "/sql/"                 # or "/tutorials/sql/"
  order: 2

python:
  id: python
  title: "Python Basics"
  slug: "python"
  description: "Intro to Python programming."
  base_path: "/python/"
  order: 3
```

This gives templates and the CLI a single source of truth for course titles, slugs, and base paths.

### 2. Lesson/Chapter metadata

Lessons for each course should carry:

```yaml
---
layout: tutorial
title: "SQL: SELECT basics"
permalink: /sql/select-basics/
date: 2025-12-01
author: pankaj
course: sql
lesson: 3
difficulty: beginner
draft: true|false
---
```

Fields:

- `course`: course ID from `courses.yml` (e.g., `sql`, `python`).
- `lesson`: numeric ordering within the course.
- Existing fields: `title`, `layout`, `permalink`, `date`, `author`, `difficulty`, `summary`, `draft`.

These fields allow:

- Building per‑course “table of contents”.
- Progress tracking keyed by course and lesson.

## Directory Structure

Two main options:

### Option A – Embed courses under `content/pages/tutorials`

Example:

```text
content/pages/tutorials/
  quick-intro-to-ruby.md        # Ruby
  meet-ruby.md                  # Ruby
  ...
  sql/
    sql-select-basics.md
    sql-where-filtering.md
  python/
    python-intro.md
```

Pros:
- Minimal change to existing tutorial URLs.
Cons:
- Mixed structure under `tutorials/` may get messy as more courses are added.

### Option B – Dedicated `content/courses/<course>/lessons`

Example:

```text
content/courses/
  ruby/
    01-meet-ruby.md
    02-flow-control.md
  sql/
    01-getting-started-sql.md
    02-select-basics.md
  python/
    01-python-intro.md
```

Pros:
- Clean isolation per course.
Cons:
- Requires slightly more wiring in builder and layouts.

In both cases, `permalink` controls final URLs, so we can choose whichever directory layout feels maintainable.

## CLI Commands

Extend Typophic CLI with a `course` command group:

```text
typophic course new TRACK_ID [options]
typophic course lesson new TRACK_ID "Lesson title" [options]
typophic course list
```

### 1. `typophic course new`

Creates a new course definition and optionally a landing page:

- Writes to `data/courses.yml`:
  - Adds new entry with `id`, `title`, `slug`, `base_path`.
- Optionally creates:
  - `content/pages/<track>/index.md` (course landing page).

Options:

```text
--title "SQL Essentials"
--slug sql
--base-path /sql/
--author AUTHOR_ID
```

### 2. `typophic course lesson new`

Scaffolds a new lesson/chapter for a course:

```bash
typophic course lesson new sql "SELECT basics" \
  --lesson 3 \
  --draft \
  --permalink /sql/select-basics/
```

Behavior:

- Creates a `.md` file under the appropriate directory:
  - Draft: `content/drafts/tutorials/sql/select-basics.md` (or `content/drafts/courses/sql/...`).
  - Published: `content/pages/tutorials/sql/select-basics.md` (or `content/courses/sql/01-select-basics.md`).
- Frontmatter includes:
  - `layout: tutorial`
  - `course: sql`
  - `lesson: 3`
  - `author`: from CLI or `Typophic::Util.resolved_author`
  - `date`: today
  - `draft: true` if `--draft` given.

### 3. `typophic course list`

Reads `data/courses.yml` and prints all course tracks, optionally with lesson counts.

## Navigation & Progress Integration

- Tutorials index (`content/pages/tutorials/tutorials.md` and its layout) should:
  - Group chapters by `course`.
  - Show per‑course sections: Ruby, SQL, Python, etc.
- Progress tracking:
  - Reuse `rl:chapter:{path}` keys, but we may later introduce course‑aware keys (e.g., `rl:course:sql:lesson:3`) if needed.

## Tasks

1. Decide directory layout:
   - `content/pages/tutorials/<course>/...` vs. `content/courses/<course>/...`.
2. Add `data/courses.yml` with initial entries (`ruby`, `sql`, `python`, `ml`, `dl`).
3. Implement `typophic course` CLI commands:
   - `course new`
   - `course lesson new`
   - `course list`
4. Extend layouts:
   - Tutorials index to group lessons by `course`.
   - Course landing pages (optional but useful).
5. Ensure new lessons created via CLI use Phase 1 metadata defaults:
   - `author`, `date`, `draft`, `course`, `lesson`.

## Open Questions

- **Per‑course navigation style**
  - Do we mirror the Ruby learning path layout, or design separate styles per course?
- **Versioning courses**
  - For now we treat each course as a single “track”; versioning (SQL v1 vs v2) is out of scope for v0.1.

Phase 4 gives your future SQL/Python/ML/Deep Learning tracks a solid, consistent structure—so the moment you start adding lessons, they behave like first‑class citizens alongside the existing Ruby tutorials.

