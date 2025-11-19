---
layout: tutorial
title: Chapter R2 &ndash; Rails routes & controllers
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

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
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

When you&rsquo;re comfortable with the request cycle, carry on to [Chapter R3: Hotwire views & feedback](/tutorials/rails-hotwire-feedback/).

#### Practice 1 - Thinking through scaffolding and migrations

<p><strong>Goal:</strong> Outline what scaffolding the `Entry` model and running migrations involves.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-routes-controllers"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('rails generate scaffold') }"><code class="language-ruby">
# TODO: Print the commands and steps you would use to scaffold the
# Entry model and run migrations in your Rails app.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-routes-controllers"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-routes-controllers:0">
puts "rails generate scaffold Entry title:string body:text"
puts "rails db:migrate"
</script>

#### Practice 2 - Validations and failure handling

<p><strong>Goal:</strong> Describe how validations affect controller behaviour on failure.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-routes-controllers"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('validates') } && lines.any? { |l| l.downcase.include?('unprocessable_entity') }"><code class="language-ruby">
# TODO: Print a short example of a validation and note how the
# controller might respond when validations fail (rendering with
# status :unprocessable_entity).
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-routes-controllers"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-routes-controllers:1">
puts "Example: validates :title, presence: true"
puts "On failure, the controller can render :new with status :unprocessable_entity"
</script>

#### Practice 3 - Request specs or system tests

<p><strong>Goal:</strong> Capture the idea of writing request or system tests for the happy path.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-routes-controllers"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('request spec') } || lines.any? { |l| l.downcase.include?('system test') }"><code class="language-ruby">
# TODO: Print one or two sentences about what a happy-path request
# spec or system test would assert in this journal app.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-routes-controllers"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-routes-controllers:2">
puts "A request spec would POST a valid entry and expect a redirect."
puts "A system test would fill in the form, submit it, and expect to see the new entry."
</script>
