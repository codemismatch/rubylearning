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

Pick a preferred slot for a first 30-minute conversation, then send your application by email:

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
