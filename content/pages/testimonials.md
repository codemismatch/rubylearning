---
title: Testimonials
layout: page
description: What learners from around the world say about studying Ruby, Python, and machine learning with RubyLearning's tracks and mentorship.
permalink: /pages/testimonials/
---

# Testimonials

Learners from around the world study with our tracks. Here is what a few of them say:

<blockquote class="testimonial-quote">
  <p>"I came in knowing only Excel formulas and finished Ruby Basics in about six weeks, studying on my commute. The chapters on blocks and hashes finally made the code at my job readable. The runnable examples in the browser meant I never had to set anything up before I was ready."</p>
  <footer><strong>Ananya Sharma</strong> &mdash; Pune, India</footer>
</blockquote>

<blockquote class="testimonial-quote">
  <p>"What got me was the mentorship. I emailed a doubt about <code>method_missing</code> expecting a two-line reply, and got back a full explanation plus a suggestion to read the open classes chapter first. That one habit - asking when stuck - saved me weeks of silent confusion."</p>
  <footer><strong>Rohan Mehta</strong> &mdash; Bengaluru, India</footer>
</blockquote>

<blockquote class="testimonial-quote">
  <p>"Even though Ruby was born in Japan, most good material is in English, and this site is the clearest I found. The Advanced Ruby track is honest about the hard parts - eigenclasses, refinements, constant lookup - instead of pretending they do not exist."</p>
  <footer><strong>Haruki Sato</strong> &mdash; Osaka, Japan</footer>
</blockquote>

<blockquote class="testimonial-quote">
  <p>"I bounced off three video courses before this. The difference here is that every chapter makes you type and run code immediately, and the Machine Learning track builds everything from scratch - no framework magic. I finally understand what a gradient actually is."</p>
  <footer><strong>Jake Sullivan</strong> &mdash; Austin, USA</footer>
</blockquote>

<blockquote class="testimonial-quote">
  <p>"The vibe coding approach sold me: I described a small tool in plain English, got working Ruby, and then used the course chapters to understand what the AI had written. Three months later I maintain two internal tools at my company and review generated code with confidence."</p>
  <footer><strong>Emily Carter</strong> &mdash; Portland, USA</footer>
</blockquote>

## Share your experience

Studying with one of our tracks? We would love to hear how it is going - what worked, what confused you, and what you built. Fill in the form below and it lands directly in our inbox - no mail client needed. Your story might encourage the next learner to start.

<form id="mentorship-form" class="contact-form">
  <label for="cf-name">Your name</label>
  <input type="text" id="cf-name" name="name" placeholder="Ada Lovelace" required>

  <label for="cf-email">Your email</label>
  <input type="email" id="cf-email" name="email" placeholder="ada@example.com" required>

  <label for="cf-track">Track you are studying (or have finished)</label>
  <select id="cf-track" name="track">
    <option value="">Choose a track</option>
    <option>Ruby Basics</option>
    <option>Advanced Ruby</option>
    <option>Python Basics</option>
    <option>Machine Learning: From Zero to LLMs</option>
    <option>Image Generation: From Pixels to Diffusion</option>
    <option>Vibe Coding with Ruby</option>
    <option>AI-Powered Learning</option>
    <option>Other / self-taught</option>
  </select>

  <label for="cf-message">Your experience</label>
  <textarea id="cf-message" name="message" rows="8" required placeholder="Tell us how your learning is going - what worked, what confused you, and what you built."></textarea>

  <button type="submit" id="cf-submit">Send testimonial</button>
  <p id="cf-status" class="contact-form-status" role="status"></p>
</form>

<script>
var FORM_ENDPOINT = "https://contact-form-mailer.pankajdoharey.workers.dev";

document.getElementById("mentorship-form").addEventListener("submit", async function (e) {
  e.preventDefault();
  var btn = document.getElementById("cf-submit");
  var status = document.getElementById("cf-status");
  btn.disabled = true;
  status.className = "contact-form-status";
  status.textContent = "Sending...";
  try {
    var res = await fetch(FORM_ENDPOINT, { method: "POST", body: new FormData(e.target) });
    if (res.ok) {
      status.classList.add("contact-form-status--ok");
      status.textContent = "Message sent! Thank you for sharing your experience.";
      e.target.reset();
    } else {
      throw new Error("HTTP " + res.status);
    }
  } catch (err) {
    status.classList.add("contact-form-status--error");
    status.textContent = "Could not send right now - please try again in a moment.";
  } finally {
    btn.disabled = false;
  }
});
</script>
