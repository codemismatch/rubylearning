# Blog Setup

The repository ships with a dedicated blog theme (`themes/bonsaiblog`) inspired by Bonso.

## What’s Included

- `themes/bonsaiblog/layouts/default.html` — Blog chrome (header/footer)
- `themes/bonsaiblog/layouts/blog_index.html` — Archive wrapper for `/blog`
- `themes/bonsaiblog/layouts/post.html` — Single-post layout
- `themes/bonsaiblog/css/style.css` — Color system and components

## Routing & Content

- Blog posts live under `content/posts/` and follow the usual markdown frontmatter (`title`, `date`, `tags`, etc.).
- The blog index is `content/pages/blog.html.erb` and lists all posts.

## Theme Wiring

`config.yml` assigns the `bonsaiblog` theme to the `posts` section:

```yaml
theme:
  default: rubylearning
  sections:
    posts: bonsaiblog
```

The blog index page opts into the same theme and uses the `blog_index` layout:

```yaml
---
layout: blog_index
theme: bonsaiblog
permalink: /blog
---
```

## Development

Run a live preview with watch + livereload:

```bash
bin/typophic serve --build
```

Edit files under `themes/bonsaiblog/` or `content/posts/`; the site rebuilds and the browser refreshes automatically.

