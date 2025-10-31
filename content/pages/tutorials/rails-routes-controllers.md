---
layout: tutorial
title: Chapter R2 – Rails routes & controllers
permalink: /tutorials/rails-routes-controllers/
difficulty: intermediate
summary: Shape request flow with RESTful routes, controllers, and model validations.
previous_tutorial:
  title: "Chapter R1: Project setup"
  url: /tutorials/rails-project-setup/
next_tutorial:
  title: "Chapter R3: Hotwire views & feedback"
  url: /tutorials/rails-hotwire-feedback/
related_tutorials:
  - title: "Hotwire views & feedback"
    url: /tutorials/rails-hotwire-feedback/
  - title: "Rails learning hub"
    url: /rails/
---

<pre class="language-ruby"><code class="language-ruby">
# config/routes.rb
Rails.application.routes.draw do
  root &quot;entries#index&quot;
  resources :entries
end

# app/controllers/entries_controller.rb
class EntriesController &lt; ApplicationController
  def index
    @entries = Entry.order(created_at: :desc)
  end

  def create
    @entry = Entry.new(entry_params)
    if @entry.save
      redirect_to entries_path, notice: &quot;Saved your update!&quot;
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def entry_params
    params.require(:entry).permit(:title, :body)
  end
end
</code></pre>

### Practice checklist

- Scaffold the `Entry` model with a migration and run `rails db:migrate`.
- Add model validations and watch the controller handle failures.
- Write request specs (or system tests) to cover the happy path.

When you’re comfortable with the request cycle, carry on to [Chapter R3: Hotwire views & feedback](/tutorials/rails-hotwire-feedback/).
