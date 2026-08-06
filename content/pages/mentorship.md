---
title: Mentorship Programme
layout: page
---

# The Ruby Learning Mentorship Programme

A free, self-study programme with light-touch mentorship for early-career programmers, run by **Pankaj Doharey** (CTO and co-founder of VoxLogic.ai, 17 years in software engineering). This exists for one reason: good engineers kept doors open for us, and this is how we keep them open for you.

## Who it is for

- You are working through (or have finished) one of our tracks: Ruby Basics, Advanced Ruby, Python Basics, or Machine Learning: From Zero to LLMs.
- You want a working engineer, not a tutorial, to point you in the right direction when you get stuck.

## How it works

This is a self-study programme. There are no classes, no scheduled doubt-clearing sessions, and no multi-week commitment:

1. **An introductory call.** We start with one relaxed call to understand where you are, what you are learning, and what you want to build.
2. **You study on your own.** Work through the tracks and your own projects at your own pace.
3. **Email when you have a doubt.** Whenever something will not click - a concept, a design decision, a piece of code - drop me an email and I will reply with pointers, explanations, or a review.

## Get in touch

Fill in the form below and it lands directly in my inbox - no mail client needed. Tell me which track you are on and what you are working on, and we will set up the introductory call.

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
    <option>Other / self-taught</option>
  </select>

  <label for="cf-message">Your message</label>
  <textarea id="cf-message" name="message" rows="8" required placeholder="Tell me where you are in your studies, what you are working on, and what you would like help with."></textarea>

  <button type="submit" id="cf-submit">Send message</button>
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
      status.textContent = "Message sent! I will get back to you soon.";
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
