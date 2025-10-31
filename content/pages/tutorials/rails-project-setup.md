---
layout: tutorial
title: Chapter R1 – Rails project setup
permalink: /tutorials/rails-project-setup/
difficulty: beginner
summary: Assemble your Rails environment, create a clean baseline app, and confirm everything boots.
next_tutorial:
  title: "Chapter R2: Routes & controllers"
  url: /tutorials/rails-routes-controllers/
related_tutorials:
  - title: "Rails learning hub"
    url: /rails/
  - title: "Rails routes & controllers"
    url: /tutorials/rails-routes-controllers/
---

```bash
gem install rails
rails new journal --css=tailwind --database=postgresql
cd journal
bin/rails db:setup
bin/rails server
```

### Practice checklist

- Install PostgreSQL locally (or use Docker) and confirm `rails db:prepare` succeeds.
- Swap Tailwind for another CSS framework and note the differences.
- Initialise a Git repository and commit the pristine app so you can track changes.

Continue to [Chapter R2: Routes & controllers](/tutorials/rails-routes-controllers/) when you can boot the app without errors.
