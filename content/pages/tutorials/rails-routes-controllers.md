---
layout: tutorial
title: Chapter R2 &ndash; Rails routes & controllers
permalink: /courses/ruby-basics/rails-routes-controllers/
difficulty: intermediate
summary: Shape request flow with RESTful routes, controllers, and model validations.
previous_tutorial:
  title: "Chapter R1: Project setup"
  url: /courses/ruby-basics/rails-project-setup/
next_tutorial:
  title: "Chapter R3: Hotwire views & feedback"
  url: /courses/ruby-basics/rails-hotwire-feedback/
related_tutorials:
  - title: "Hotwire views & feedback"
    url: /courses/ruby-basics/rails-hotwire-feedback/
  - title: "Rails learning hub"
    url: /rails/
---

```ruby-exec
# config/routes.rb
Rails.application.routes.draw do
  root "entries#index"
  resources :entries
end

# app/controllers/entries_controller.rb
class EntriesController < ApplicationController
  def index
    @entries = Entry.order(created_at: :desc)
  end

  def create
    @entry = Entry.new(entry_params)
    if @entry.save
      redirect_to entries_path, notice: "Saved your update!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def entry_params
    params.require(:entry).permit(:title, :body)
  end
end
```

### Practice checklist

- Scaffold the `Entry` model with a migration and run `rails db:migrate`.
- Add model validations and watch the controller handle failures.
- Write request specs (or system tests) to cover the happy path.

When you&rsquo;re comfortable with the request cycle, carry on to [Chapter R3: Hotwire views & feedback](/courses/ruby-basics/rails-hotwire-feedback/).

#### Practice 1 - Thinking through scaffolding and migrations

**Goal:** Outline what scaffolding the `Entry` model and running migrations involves.

#> ruby :practice

# TODO: Print the commands and steps you would use to scaffold the
# Entry model and run migrations in your Rails app.

```solution
puts "rails generate scaffold Entry title:string body:text"
puts "rails db:migrate"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('rails generate scaffold') }
```

#!


#### Practice 2 - Validations and failure handling

**Goal:** Describe how validations affect controller behaviour on failure.

#> ruby :practice

# TODO: Print a short example of a validation and note how the
# controller might respond when validations fail (rendering with
# status :unprocessable_entity).

```solution
puts "Example: validates :title, presence: true"
puts "On failure, the controller can render :new with status :unprocessable_entity"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('validates') } && lines.any? { |l| l.downcase.include?('unprocessable_entity') }
```

#!


#### Practice 3 - Request specs or system tests

**Goal:** Capture the idea of writing request or system tests for the happy path.

#> ruby :practice

# TODO: Print one or two sentences about what a happy-path request
# spec or system test would assert in this journal app.

```solution
puts "A request spec would POST a valid entry and expect a redirect."
puts "A system test would fill in the form, submit it, and expect to see the new entry."
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('request spec') } || lines.any? { |l| l.downcase.include?('system test') }
```

#!

