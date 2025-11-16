---
layout: tutorial
title: Chapter R1 &ndash; Rails project setup
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

#### Practice 1 - Verifying database setup

<p><strong>Goal:</strong> Think through what it means for `rails db:prepare` to succeed on your machine.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-project-setup"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('db:prepare') }"><code class="language-ruby">
# TODO: Print a short checklist of what you need in place for
# `rails db:prepare` to work (database running, config correct, etc.).
# This script doesn't run Rails, but you can document the steps here.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-project-setup"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-project-setup:0">
puts "To run `rails db:prepare` successfully you generally need:"
puts "- PostgreSQL (or your chosen DB) running"
puts "- config/database.yml pointing at the right database"
puts "- The app's gems installed"
</script>

#### Practice 2 - Reflecting on CSS framework choices

<p><strong>Goal:</strong> Note differences you might see when swapping Tailwind for another CSS framework.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-project-setup"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('tailwind') }"><code class="language-ruby">
# TODO: Print a few high-level observations you expect when swapping
# Tailwind for another CSS framework (class names, build pipeline,
# design tokens, etc.).
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-project-setup"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-project-setup:1">
puts "Tailwind uses utility classes; other frameworks may use components."
puts "Swapping frameworks can change class names and build tooling."
</script>

#### Practice 3 - Committing a pristine app

<p><strong>Goal:</strong> Plan the first Git commit for a new Rails app.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-project-setup"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('git init') }"><code class="language-ruby">
# TODO: Describe the Git commands you would use to initialise a
# repository and commit the pristine app.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-project-setup"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-project-setup:2">
puts "git init"
puts "git add ."
puts "git commit -m 'Initial Rails app'"
</script>
