---
layout: tutorial
title: Chapter R3 &ndash; Rails Hotwire feedback
permalink: /tutorials/rails-hotwire-feedback/
difficulty: intermediate
summary: Layer Hotwire updates and feedback loops onto your Rails UI to keep users in flow.
previous_tutorial:
  title: "Chapter R2: Routes & controllers"
  url: /tutorials/rails-routes-controllers/
related_tutorials:
  - title: "Rails learning hub"
    url: /rails/
  - title: "Project-driven roadmap for learning Rails"
    url: /blog/rails-learning-roadmap/
---

```erb
<!-- app/views/entries/index.html.erb -->
<%= turbo_stream_from :entries %>

<%= form_with model: Entry.new, class: "stack" do |form| %>
  <div class="field">
    <%= form.label :title %>
    <%= form.text_field :title, required: true %>
  </div>
  <div class="field">
    <%= form.label :body %>
    <%= form.text_area :body, rows: 4 %>
  </div>
  <%= form.submit "Add entry", class: "btn btn-primary" %>
<% end %>

<div id="entries">
  <%= render @entries %>
</div>
```

<pre class="language-ruby"><code class="language-ruby">
# app/models/entry.rb
class Entry &lt; ApplicationRecord
  after_create_commit -&gt; { broadcast_prepend_to :entries }
  validates :title, presence: true
end
</code></pre>

### Practice checklist

- Add Turbo Stream templates to broadcast updates when entries change.
- Use Stimulus to show success/error toasts after submissions.
- Wire up background jobs (ActiveJob + Sidekiq/GoodJob) to send summary emails.

Next, iterate on the project by adding authentication, dashboards, or background processing. Keep exploring ideas in the [Rails learning hub](/rails/).

#### Practice 1 - Thinking through Turbo Stream updates

<p><strong>Goal:</strong> Describe how Turbo Stream templates can broadcast updates when entries change.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-hotwire-feedback"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('turbo_stream') }"><code class="language-ruby">
# TODO: Print a short explanation of how a Turbo Stream template
# might be used to prepend a new entry to a list when it is created.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-hotwire-feedback"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-hotwire-feedback:0">
puts "Turbo Stream templates can use turbo_stream.prepend to insert"
puts "a rendered entry partial into the #entries element after create."
</script>

#### Practice 2 - Stimulus feedback ideas

<p><strong>Goal:</strong> Outline how Stimulus could show success/error toasts after submissions.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-hotwire-feedback"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('stimulus') }"><code class="language-ruby">
# TODO: Print a couple of sentences on how a Stimulus controller
# might listen for form submission events and display toast messages.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-hotwire-feedback"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-hotwire-feedback:1">
puts "A Stimulus controller can watch for turbo:submit-end events"
puts "and show a toast on success or error based on the response."
</script>

#### Practice 3 - Background jobs for summaries

<p><strong>Goal:</strong> Plan how background jobs could send summary emails.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/rails-hotwire-feedback"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('activejob') } || lines.any? { |l| l.downcase.include?('sidekiq') }"><code class="language-ruby">
# TODO: Print a brief description of how you could use ActiveJob with
# a background worker (like Sidekiq or GoodJob) to send periodic entry
# summary emails.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/rails-hotwire-feedback"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/rails-hotwire-feedback:2">
puts "ActiveJob can enqueue a SummaryEmailJob that runs via Sidekiq or GoodJob"
puts "on a schedule, gathering recent entries and emailing a digest."
</script>
