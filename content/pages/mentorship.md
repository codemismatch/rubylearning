---
title: Mentorship Programme
layout: page
---

# The Ruby Learning Mentorship Programme

A free, structured, remote mentorship programme for early-career programmers, run by **Pankaj Doharey** (CTO and co-founder of VoxLogic.ai, 17 years in software engineering). The programme exists for one reason: good engineers kept doors open for us, and this is how we keep them open for you.

## Who it is for

- You have finished (or are finishing) one of our tracks: Ruby Basics, Advanced Ruby, Python Basics, or Machine Learning: From Zero to LLMs.
- You can commit **3 to 4 hours a week for 8 weeks**.
- You want a working engineer, not a tutorial, to review your code and your thinking.

## What the 8 weeks look like

1. **Weeks 1 to 2:** fundamentals review, a small project brief, and your first code review.
2. **Weeks 3 to 5:** building a real feature end to end: tests, version control discipline, reading legacy code.
3. **Weeks 6 to 7:** production habits: debugging, logs, deployment, and how senior engineers actually make decisions.
4. **Week 8:** a capstone review, a written evaluation you can show to employers, and a plan for your next six months.

Sessions are held online, one to one or in very small cohorts.

## How we select

Cohorts stay small on purpose. Write to us with: which track you completed, one piece of code you wrote that you are not fully happy with, and what you want to build next. We reply to every serious application within a week.

## Apply

Fill in the form below and it lands directly in our inbox - no mail client needed. Prefer email? The mail-to option further down still works too.

<form id="mentorship-form" class="contact-form">
  <label for="cf-name">Your name</label>
  <input type="text" id="cf-name" name="name" placeholder="Ada Lovelace" required>

  <label for="cf-email">Your email</label>
  <input type="email" id="cf-email" name="email" placeholder="ada@example.com" required>

  <label for="cf-track">Track you completed (or are finishing)</label>
  <select id="cf-track" name="track">
    <option value="">Choose a track</option>
    <option>Ruby Basics</option>
    <option>Advanced Ruby</option>
    <option>Python Basics</option>
    <option>Machine Learning: From Zero to LLMs</option>
    <option>Image Generation: From Pixels to Diffusion</option>
    <option>Other / self-taught</option>
  </select>

  <label for="cf-message">Your application</label>
  <textarea id="cf-message" name="message" rows="8" required placeholder="Tell us: one piece of code you wrote that you are not fully happy with, and what you want to build next."></textarea>

  <button type="submit" id="cf-submit">Send application</button>
  <p id="cf-status" class="contact-form-status" role="status"></p>
</form>

<script>
var FORM_ENDPOINT = "https://contact-form-mailer.YOUR-SUBDOMAIN.workers.dev";
// After `npx wrangler deploy` (see workers/contact-form-mailer/README.md),
// replace YOUR-SUBDOMAIN above - or route rubylearning.in/api/mentorship and
// set FORM_ENDPOINT = "/api/mentorship".

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
      status.textContent = "Application sent! We reply to every serious application within a week.";
      e.target.reset();
    } else {
      throw new Error("HTTP " + res.status);
    }
  } catch (err) {
    status.classList.add("contact-form-status--error");
    status.textContent = "Could not send right now - please use the email option below instead.";
  } finally {
    btn.disabled = false;
  }
});
</script>

Or pick a preferred slot for a first 30-minute conversation, then send your application by email:

<div class="mentorship-apply">
  <label for="slot-date">Preferred date</label>
  <input type="date" id="slot-date" name="slot-date">
  <label for="slot-time">Preferred time (IST)</label>
  <select id="slot-time" name="slot-time">
    <option>10:00</option><option>14:00</option><option>18:00</option><option>20:00</option>
  </select>
  <button type="button" onclick="applyMentorship()">Apply by email</button>
  <p class="apply-note">This opens your mail client with everything pre-filled. You can also write to us directly at <a href="mailto:pankajdoharey@gmail.com?subject=Mentorship%20Programme%20Application">pankajdoharey@gmail.com</a> with the subject "Mentorship Programme Application".</p>
</div>

<script>
function applyMentorship() {
  var d = document.getElementById('slot-date').value;
  var t = document.getElementById('slot-time').value;
  var body = 'Hello,\n\nI would like to apply for the Ruby Learning Mentorship Programme.\n\nTrack completed:\nA piece of code I am not fully happy with:\nWhat I want to build next:\n\nPreferred first conversation slot: ' + (d || '(any date)') + ' at ' + t + ' IST.\n\nThank you.';
  window.location.href = 'mailto:pankajdoharey@gmail.com?subject=' + encodeURIComponent('Mentorship Programme Application') + '&body=' + encodeURIComponent(body);
}
</script>
