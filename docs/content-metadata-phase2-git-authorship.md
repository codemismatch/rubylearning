# Content Metadata – Phase 2 (Git‑Aware Authorship & Contributors)

Phase 1 makes `author` and `date` explicit and consistent in frontmatter.  
Phase 2 makes that metadata **Git‑aware**: we derive authors and contributors from commit history and keep frontmatter in sync.

## Goals

- Use **Git history** to:
  - Identify the **primary author** (first or dominant committer) for each content file.
  - Capture additional **contributors/editors**.
- Keep frontmatter fields up to date:
  - `author: <id>` — primary author.
  - `contributors: [id1, id2, ...]` — sorted list of additional editors.
- Provide tooling that can run:
  - On demand (e.g., `bundle exec ruby tools/update_authors.rb content/posts`).
  - As a **pre‑commit hook** to ensure new or modified content always carries authorship metadata.

## Requirements

### 1. Git → author mapping

We need a mapping from Git commit identity (name/email) to `author_id` in `data/authors.yml`.

Approach:

- Extend `data/authors.yml` to optionally include emails:

```yaml
pankaj:
  name: "Pankaj Doharey"
  github: "codemismatch"
  emails:
    - "pankaj@example.com"
    - "pankaj@users.noreply.github.com"
  avatar: "/images/authors/pankaj.jpg"
```

- A small Ruby helper (e.g. `Typophic::Util.author_id_for_email(email)`) will:
  - Load `data/authors.yml`.
  - Match the email against any `emails` arrays.
  - Fall back to a simple mapping (e.g., normalized name or Git config) when unknown.

### 2. Tools: update authors/contributors from Git

Add a script under `tools/` (or `bin/`):

- `tools/update_authors_from_git.rb` (name TBD)

Behavior:

1. Accept a list of paths or glob patterns (e.g., `content/posts`, `content/pages/tutorials`).
2. For each file:
   - Call `git log --follow --format='%an|%ae' -- <path>` to get ordered commits.
   - Map each `(name, email)` pair to an `author_id` using the helper above.
   - Decide:
     - **Primary author** — first committer, or committer with most changes (configurable).
     - **Contributors** — unique remaining author_ids, excluding the primary.
3. Parse the file’s frontmatter:
   - If `author` is missing, set it to the primary `author_id`.
   - If `contributors` is missing, set it to the contributors list.
   - If they already exist, optionally:
     - Update `contributors` to reflect new editors.
     - Leave `author` alone unless it conflicts with the strongest signal from Git (configurable to avoid thrash).
4. Write the updated file back, preserving body content and relative formatting as much as possible.

This script is **idempotent**: running it multiple times should not produce noise if nothing changed.

### 3. Pre‑commit hook (optional but recommended)

Provide a sample `.git/hooks/pre-commit` script (or a `tools/install_hooks.rb` helper) that:

- Detects staged content files (`git diff --cached --name-only`).
- Filters for `content/posts/**`, `content/pages/**`, `content/tutorials/**` (configurable).
- Runs the authorship updater on those files.
- Re‑adds the modified files to the index (`git add`), then exits.

Important constraints:

- The hook should **fail fast** if tooling is missing (e.g., if Ruby or Bundler isn’t present) and not block commits in contributor environments unexpectedly.
- It should be opt‑in (documented in README) rather than silently installed for everyone.

### 4. Layout changes (using contributors)

Extend `post.html` and `tutorial.html` to optionally show contributors:

- Frontmatter fields:
  - `author: pankaj`
  - `contributors: [satish, alice]`

Layout handling:

```liquid
{% if page.contributors and page.contributors.size > 0 %}
  <div class="post-contributors">
    Edited by
    {% for cid in page.contributors %}
      {% assign c = site.data.authors[cid] %}
      <span class="post-contributor-name">
        {{ c.name | default: cid }}{% if forloop.last == false %},{% endif %}
      </span>
    {% endfor %}
  </div>
{% endif %}
```

CSS would mirror the author styles, but smaller and less prominent.

### 5. Handling edge cases

- Files moved or renamed:
  - Use `git log --follow` to track history across renames.
- Multiple emails for the same person:
  - The `emails` array in `authors.yml` handles this.
- Unknown contributors:
  - For unmapped emails, we can:
    - Add a `TODO:` entry to `authors.yml`, or
    - Use a generic `unknown-<hash>` id until manually resolved.

## Tasks

1. Implement `Typophic::Util.author_id_for_email(email)` helper using `data/authors.yml`.
2. Write `tools/update_authors_from_git.rb` to:
   - Walk files and update `author`/`contributors` frontmatter.
   - Be safe and idempotent.
3. Add documentation:
   - New section in `README.md` describing how to run the tool.
   - Example author mapping in `data/authors.yml`.
4. Add optional pre‑commit hook sample under `tools/` or `docs/`:
   - Explain how to enable/disable it.
5. Extend layouts to render contributors where present.

## Open Questions

- **Primary author definition**:
  - First committer vs. “most lines changed” vs. “author field if set”.
  - Recommendation: default to **first committer**, but never overwrite an existing explicit `author` unless a flag is passed.

- **Performance on large histories**:
  - For a small learning site this is unlikely to matter, but the script should be mindful of repeated `git log` calls and support scoping to specific directories.

Phase 2 makes the metadata **self‑healing**: even if someone forgets to set the author, running the update tool (or a hook) keeps content aligned with actual Git authorship and moves us closer to the “real people behind each chapter” experience you described.

