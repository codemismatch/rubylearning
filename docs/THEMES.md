# Themes and Nested Themes

Typophic now supports multiple themes in a single site. You can apply one theme to your main pages and a different theme to your blog (posts) or any other section.

## Directory Layout

- `themes/<name>/layouts/*.html` — ERB layouts (`default.html`, `page.html`, `post.html`, etc.)
- `themes/<name>/includes/*.html` — partials available via `render_partial` in layouts
- `themes/<name>/css`, `themes/<name>/js`, `themes/<name>/images` — static assets
- `themes/<name>/helpers/*.rb` — optional Ruby helpers (modules under `Typophic::Helpers`)

## Configure Themes

In `config.yml` you can set a default theme and per-section overrides:

```yaml
theme:
  default: rubylearning
  sections:
    posts: bonsaiblog   # Apply the blog theme to all content under content/posts/
```

You can also override the theme per page/post using frontmatter:

```yaml
---
title: Custom Themed Page
theme: bonsaiblog
layout: page
---
```

## Asset Resolution

- During build, Typophic copies every referenced theme’s assets to `public/themes/<name>/{css,js,images}`.
- For backward compatibility, the default theme’s assets are also copied to root-level folders: `public/css`, `public/js`, `public/images`.
- In layouts you can reference:
  - Site assets: `<%= asset_path('css/style.css') %>`
  - Current theme assets: `<%= theme_asset_path('css/style.css') %>`

## Layout Resolution

When rendering a page, Typophic looks for the chosen `layout:` in this order:

1. `layouts/<layout>.html` (site-level override)
2. `themes/<current-theme>/layouts/<layout>.html`
3. Fallback to the default theme’s layout of the same name

Partials resolve similarly via `includes/` directories.

## Creating a New Theme

You can scaffold a theme skeleton with the CLI:

```bash
typophic theme new bonsaiblog
```

Then customize the generated files under `themes/bonsaiblog/`. For inspiration, this repo includes a Bonso-inspired blog theme wired to `/blog` and all `/posts/*` entries.

## Switching the Blog to a Different Theme

1. Create or select your blog theme (e.g., `themes/bonsaiblog`).
2. Ensure it provides `layouts/default.html` and `layouts/post.html`.
3. Add a section override in `config.yml`:
   ```yaml
   theme:
     default: rubylearning
     sections:
       posts: bonsaiblog
   ```
4. Point the blog index page at the theme (frontmatter) and a blog index layout:
   ```yaml
   ---
   layout: blog_index
   theme: bonsaiblog
   permalink: /blog
   ---
   ```

That’s it — `typophic serve --build` will render the main site using the default theme and `/blog` + `/posts/*` with the blog theme.

