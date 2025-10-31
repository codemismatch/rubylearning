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
    url: /posts/rails-learning-roadmap/
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
