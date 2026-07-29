// tutorial-enhancements.js - Enhances the tutorial page with interactive features

function runTutorialEnhancementsOnReady(fn) {
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', fn);
  } else {
    fn();
  }
}

runTutorialEnhancementsOnReady(function() {
  // Only run on tutorials page
  if (!document.querySelector('.topic-tags') && !document.querySelector('.tutorial-tag')) return;
  
  // Add smooth scrolling for topic links
  addSmoothScrolling();
  
  // Add progress indicator
  addProgressIndicator();
  
  // Add tutorial filter
  addTutorialFilter();
  
  // Initialize tutorial tags for filtering
  initializeTutorialTags();
});

// Secondary enhancements that should run on both the tutorials index and
// individual tutorial chapters (practice checklists and progress markers).
runTutorialEnhancementsOnReady(function() {
  initPracticeChecklists();
  initChapterListProgress();
  trackLessonReading();
  initCourseTrackHeader();
});

// Add smooth scrolling to topic links
function addSmoothScrolling() {
  const topicLinks = document.querySelectorAll('.topic-tag');
  topicLinks.forEach(link => {
    link.addEventListener('click', function(e) {
      const targetId = this.getAttribute('href');
      if (!targetId || !targetId.startsWith('#')) return;
      
      const targetElement = document.querySelector(targetId);
      if (targetElement) {
        e.preventDefault();
        window.scrollTo({
          top: targetElement.offsetTop - 100,
          behavior: 'smooth'
        });
      }
    });
  });
}

// Add progress indicator to show scroll position
function addProgressIndicator() {
  // Create progress bar element
  const progressBar = document.createElement('div');
  progressBar.className = 'topic-progress';
  document.body.insertBefore(progressBar, document.body.firstChild);
  
  // Update progress on scroll
  window.addEventListener('scroll', () => {
    const scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
    const scrollHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
    const scrollPercentage = (scrollTop / scrollHeight) * 100;
    
    progressBar.style.width = scrollPercentage + '%';
  });
}

// Add tutorial filter functionality
function addTutorialFilter() {
  // Only add filter on the tutorials page
  if (!document.querySelector('.topic-section')) return;
  
  // Create filter container
  const filterContainer = document.createElement('div');
  filterContainer.className = 'topic-filter';
  
  // Create filter input
  const filterInput = document.createElement('input');
  filterInput.type = 'text';
  filterInput.className = 'topic-filter-input';
  filterInput.placeholder = 'Search tutorials by title or tag...';
  
  filterContainer.appendChild(filterInput);
  
  // Insert at the top of the content
  const contentContainer = document.querySelector('.page');
  if (contentContainer && contentContainer.firstChild) {
    contentContainer.insertBefore(filterContainer, contentContainer.firstChild);
    
    // Add filter functionality
    filterInput.addEventListener('input', function() {
      const searchTerm = this.value.toLowerCase();
      const topicSections = document.querySelectorAll('.topic-section');
      
      topicSections.forEach(section => {
        const sectionTitle = section.querySelector('h3').textContent.toLowerCase();
        const sectionTags = Array.from(section.querySelectorAll('.tutorial-tag'))
          .map(tag => tag.textContent.toLowerCase());
        const sectionContent = section.textContent.toLowerCase();
        
        const matchesSearch = 
          sectionTitle.includes(searchTerm) || 
          sectionTags.some(tag => tag.includes(searchTerm)) ||
          sectionContent.includes(searchTerm);
        
        section.style.display = matchesSearch ? 'block' : 'none';
      });
    });
  }
}

// Initialize tutorial tags for filtering
function initializeTutorialTags() {
  const tutorialTags = document.querySelectorAll('.tutorial-tag');
  
  tutorialTags.forEach(tag => {
    tag.addEventListener('click', function(e) {
      e.preventDefault();
      
      // Get the input element if it exists
      const filterInput = document.querySelector('.topic-filter-input');
      if (filterInput) {
        // Set the filter to the tag text and trigger input event
        filterInput.value = this.textContent;
        filterInput.dispatchEvent(new Event('input'));
        
        // Scroll to the top of the tutorials section
        window.scrollTo({
          top: filterInput.offsetTop - 120,
          behavior: 'smooth'
        });
      }
    });
  });
}

// Turn "Practice checklist" bullets into interactive, persistent items.
function initPracticeChecklists() {
  const article = document.querySelector('article.tutorial');
  if (!article) return;

  const heading = Array.from(article.querySelectorAll('h3')).find(h =>
    h.textContent.trim().toLowerCase() === 'practice checklist'
  );
  if (!heading) return;

  const path = window.location.pathname.replace(/\/$/, '');
  const chapterKeyPrefix = `rl:chapter:${path}`;
  const itemKeys = [];

  // Collect consecutive <ul> blocks after the heading
  let el = heading.nextElementSibling;
  const lists = [];
  while (el && el.tagName && el.tagName.toLowerCase() === 'ul') {
    lists.push(el);
    el = el.nextElementSibling;
  }

  let index = 0;
  lists.forEach(ul => {
    ul.querySelectorAll('li').forEach(li => {
      const key = `${chapterKeyPrefix}:item:${index}`;
      itemKeys.push(key);
      const saved = window.localStorage.getItem(key) === '1';

      li.classList.add('practice-checklist-item');

      // Strip leading [ ] / [x] markers from the first text node only
      const firstNode = li.firstChild;
      if (firstNode && firstNode.nodeType === Node.TEXT_NODE) {
        firstNode.textContent = firstNode.textContent.replace(/^\s*\[\s*[xX]?\s*\]\s*/, '');
      }

      const toggle = document.createElement('button');
      toggle.type = 'button';
      toggle.className = 'practice-checklist-toggle';
      toggle.setAttribute('aria-pressed', saved ? 'true' : 'false');
      toggle.setAttribute('data-key', key);
      toggle.textContent = saved ? '✅' : '☐';

      toggle.addEventListener('click', () => {
        const isOn = toggle.getAttribute('aria-pressed') === 'true';
        const nextState = !isOn;
        toggle.setAttribute('aria-pressed', nextState ? 'true' : 'false');
        toggle.textContent = nextState ? '✅' : '☐';
        try {
          window.localStorage.setItem(key, nextState ? '1' : '0');
        } catch (_) {}
        updateChapterCompletion(chapterKeyPrefix, itemKeys);
      });

      li.insertBefore(toggle, li.firstChild);
      index += 1;
    });
  });

  // Persist total item count for index-page progress rings
  try {
    window.localStorage.setItem(`${chapterKeyPrefix}:total`, String(itemKeys.length));
  } catch (_) {}

  // Mark chapter as visited and update completion status once on load
  try {
    window.localStorage.setItem(`${chapterKeyPrefix}:visited`, '1');
  } catch (_) {}
  updateChapterCompletion(chapterKeyPrefix, itemKeys);

  // Expose checklist metadata for practice runners (e.g. Ruby WASM checks)
  window.TypophicPractice = window.TypophicPractice || {};
  window.TypophicPractice[chapterKeyPrefix] = itemKeys.slice();
  window.TypophicPractice.markPracticeItem = function(chapterId, index, passed) {
    const keys = window.TypophicPractice[chapterId];
    if (!keys || index == null || index < 0 || index >= keys.length) return;

    const key = keys[index];

    if (passed) {
      try {
        window.localStorage.setItem(key, '1');
      } catch (_) {}
      const btn = document.querySelector(`.practice-checklist-toggle[data-key="${key}"]`);
      if (btn) {
        btn.setAttribute('aria-pressed', 'true');
        btn.textContent = '✅';
        btn.setAttribute('aria-pressed', 'true');
      }
      updateChapterCompletion(chapterId, keys);
    }
  };
}

function updateChapterCompletion(chapterKeyPrefix, itemKeys) {
  if (!itemKeys.length) return;
  let allDone = true;
  try {
    for (const key of itemKeys) {
      if (window.localStorage.getItem(key) !== '1') {
        allDone = false;
        break;
      }
    }
    window.localStorage.setItem(
      `${chapterKeyPrefix}:complete`,
      allDone ? '1' : '0'
    );
  } catch (_) {
    // If localStorage fails, just skip persistence.
  }
}

// Track continuous reading progress for a lesson (scroll percentage)
function trackLessonReading() {
  const article = document.querySelector('article.tutorial');
  if (!article) return;

  const path = window.location.pathname.replace(/\/$/, '');
  const chapterKeyPrefix = `rl:chapter:${path}`;

  // Mark chapter as visited as soon as it loads
  try {
    window.localStorage.setItem(`${chapterKeyPrefix}:visited`, '1');
  } catch (_) {}

  const articleTop = article.offsetTop;
  const articleHeight = article.offsetHeight || 0;
  if (articleHeight <= 0) return;

  let lastSavedAt = 0;
  let lastPercent = 0;
  // Legacy support: keep lesson-read in sync for older code that may still read it.
  let legacyMarkedRead = false;
  try {
    legacyMarkedRead = window.localStorage.getItem(`${chapterKeyPrefix}:lesson-read`) === '1';
  } catch (_) {}

  const updateScrollPercent = () => {
    const scrollTop = window.scrollY || document.documentElement.scrollTop || 0;
    const viewportHeight = window.innerHeight || document.documentElement.clientHeight || 0;

    // How far the bottom of the viewport has moved past the top of the article
    const scrolledPastTop = scrollTop + viewportHeight - articleTop;
    const rawPercent = (scrolledPastTop / articleHeight) * 100;
    const percent = Math.max(0, Math.min(100, isFinite(rawPercent) ? rawPercent : 0));

    const now = Date.now();
    if (percent !== lastPercent && now - lastSavedAt >= 100) {
      try {
        window.localStorage.setItem(
          `${chapterKeyPrefix}:scroll-percent`,
          String(Math.round(percent))
        );
      } catch (_) {}
      lastSavedAt = now;
      lastPercent = percent;
    }

    // Maintain the old lesson-read flag for compatibility when the user
    // has scrolled at least 70% through the article.
    if (!legacyMarkedRead && percent >= 70) {
      try {
        window.localStorage.setItem(`${chapterKeyPrefix}:lesson-read`, '1');
      } catch (_) {}
      legacyMarkedRead = true;
      // Mark streak activity for the day
      updateLearningStreak();
    }
  };

  window.addEventListener('scroll', updateScrollPercent);
  window.addEventListener('resize', updateScrollPercent);
  // Prime the value on load
  updateScrollPercent();
}

// Lightweight streak tracking: increments when a lesson is read to ~70%
function updateLearningStreak() {
  try {
    const today = new Date();
    const todayKey = today.toISOString().slice(0, 10); // YYYY-MM-DD

    const lastDate = window.localStorage.getItem('rl:streak:last-date');
    let current = parseInt(window.localStorage.getItem('rl:streak:current') || '0', 10);
    if (!Number.isFinite(current) || current < 0) current = 0;

    if (!lastDate) {
      current = 1;
    } else if (lastDate === todayKey) {
      // already counted today; keep streak as-is
    } else {
      const last = new Date(lastDate + 'T00:00:00Z');
      const diffMs = today.setHours(0,0,0,0) - last.getTime();
      const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24));
      if (diffDays === 1) {
        current += 1;
      } else {
        current = 1;
      }
    }

    window.localStorage.setItem('rl:streak:last-date', todayKey);
    window.localStorage.setItem('rl:streak:current', String(current));
  } catch (_) {
    // Ignore storage errors; streak is a best-effort UX enhancement.
  }
}

// On the Ruby learning path page, annotate chapters with visited/completed ticks.
function initChapterListProgress() {
  const chapterNav = document.querySelector('.chapter-nav');
  if (!chapterNav) return;

  const links = chapterNav.querySelectorAll('ol li > a[href^="/tutorials/"], ol li > a[href^="/courses/"]');
  links.forEach(link => {
    try {
      const url = new URL(link.getAttribute('href'), window.location.origin);
      const path = url.pathname.replace(/\/$/, '');
      const chapterKeyPrefix = `rl:chapter:${path}`;
      const visited = window.localStorage.getItem(`${chapterKeyPrefix}:visited`) === '1';

      const marker = document.createElement('span');
      marker.className = 'chapter-progress-marker';

      // Scroll progress: continuous 0-100%
      const scrollStr = window.localStorage.getItem(`${chapterKeyPrefix}:scroll-percent`);
      const scrollPercent = scrollStr ? Math.max(0, Math.min(100, parseFloat(scrollStr))) : 0;

      // Practice checklist progress
      const totalStr = window.localStorage.getItem(`${chapterKeyPrefix}:total`);
      const total = totalStr ? parseInt(totalStr, 10) : 0;
      let practiceCompleted = 0;
      if (total > 0) {
        for (let i = 0; i < total; i++) {
          if (window.localStorage.getItem(`${chapterKeyPrefix}:item:${i}`) === '1') practiceCompleted += 1;
        }
      }

      const examplesTotalStr = window.localStorage.getItem(`${chapterKeyPrefix}:examples_total`);
      const examplesTotal = examplesTotalStr ? parseInt(examplesTotalStr, 10) : 0;
      let examplesCompleted = 0;
      if (examplesTotal > 0) {
        for (let i = 0; i < examplesTotal; i++) {
          if (window.localStorage.getItem(`${chapterKeyPrefix}:example:${i}`) === '1') {
            examplesCompleted += 1;
          }
        }
      }

      // Compute percentage combining scroll, practice checklist, and runnable examples.
      let percent = 0;
      const hasPractice = total > 0;
      const hasExamples = examplesTotal > 0;

      const scroll0to1 = scrollPercent / 100;
      const practice0to1 = hasPractice ? (practiceCompleted / total) : 0;
      const examples0to1 = hasExamples ? (examplesCompleted / examplesTotal) : 0;

      const anyPracticeDone = hasPractice && practiceCompleted > 0;
      const anyExamplesDone = hasExamples && examplesCompleted > 0;

      if (hasPractice || hasExamples) {
        // If the chapter has interactive work, don't award progress at all
        // until at least one practice item has been completed or one example
        // has been executed. Scrolling alone is not enough.
        if (!anyPracticeDone && !anyExamplesDone) {
          percent = 0;
        } else if (hasPractice && hasExamples) {
          // 40% scroll, 30% practice, 30% examples
          percent =
            scroll0to1 * 40 +
            practice0to1 * 30 +
            examples0to1 * 30;
        } else if (hasPractice && !hasExamples) {
          // 50% scroll, 50% practice
          percent =
            scroll0to1 * 50 +
            practice0to1 * 50;
        } else if (!hasPractice && hasExamples) {
          // 50% scroll, 50% examples
          percent =
            scroll0to1 * 50 +
            examples0to1 * 50;
        }
      } else {
        // Neither practice nor examples: scroll-only
        percent = scrollPercent;
      }

      percent = Math.max(0, Math.min(100, Math.round(percent)));

      const stateClass = percent >= 100 ? 'is-complete' : percent > 0 ? 'is-partial' : 'is-pending';
      marker.classList.add(stateClass);
      marker.style.setProperty('--percent', percent + '%');

      const ariaLabel = percent > 0 ? `Chapter progress: ${percent}%` : 'Chapter not started';
      marker.setAttribute('aria-label', ariaLabel);

      // Insert marker before the link text so it appears to the left
      link.insertBefore(marker, link.firstChild);
    } catch (_) {
      // Ignore malformed URLs
    }
  });
}

// Aggregate per-chapter progress into a simple track header on course pages
function initCourseTrackHeader() {
  const chapterNav = document.querySelector('.chapter-nav');
  if (!chapterNav) return;

  // Only show on course-style paths (e.g., /courses/ruby-basics/)
  if (!window.location.pathname.startsWith('/courses/')) return;

  const links = chapterNav.querySelectorAll('ol li > a[href^="/tutorials/"], ol li > a[href^="/courses/"]');
  if (!links.length) return;

  let totalChapters = 0;
  let completedChapters = 0;
  let totalPercent = 0;
  let nextHref = null;

  links.forEach(link => {
    try {
      const url = new URL(link.getAttribute('href'), window.location.origin);
      const path = url.pathname.replace(/\/$/, '');
      const chapterKeyPrefix = `rl:chapter:${path}`;

      const scrollStr = window.localStorage.getItem(`${chapterKeyPrefix}:scroll-percent`);
      const scrollPercent = scrollStr ? Math.max(0, Math.min(100, parseFloat(scrollStr))) : 0;

      const totalStr = window.localStorage.getItem(`${chapterKeyPrefix}:total`);
      const total = totalStr ? parseInt(totalStr, 10) : 0;
      let practiceCompleted = 0;
      if (total > 0) {
        for (let i = 0; i < total; i++) {
          if (window.localStorage.getItem(`${chapterKeyPrefix}:item:${i}`) === '1') practiceCompleted += 1;
        }
      }

      const examplesTotalStr = window.localStorage.getItem(`${chapterKeyPrefix}:examples_total`);
      const examplesTotal = examplesTotalStr ? parseInt(examplesTotalStr, 10) : 0;
      let examplesCompleted = 0;
      if (examplesTotal > 0) {
        for (let i = 0; i < examplesTotal; i++) {
          if (window.localStorage.getItem(`${chapterKeyPrefix}:example:${i}`) === '1') {
            examplesCompleted += 1;
          }
        }
      }

      let percent = 0;
      const hasPractice = total > 0;
      const hasExamples = examplesTotal > 0;
      const scroll0to1 = scrollPercent / 100;
      const practice0to1 = hasPractice ? (practiceCompleted / total) : 0;
      const examples0to1 = hasExamples ? (examplesCompleted / examplesTotal) : 0;
      const anyPracticeDone = hasPractice && practiceCompleted > 0;
      const anyExamplesDone = hasExamples && examplesCompleted > 0;

      if (hasPractice || hasExamples) {
        if (!anyPracticeDone && !anyExamplesDone) {
          percent = 0;
        } else if (hasPractice && hasExamples) {
          percent = scroll0to1 * 40 + practice0to1 * 30 + examples0to1 * 30;
        } else if (hasPractice && !hasExamples) {
          percent = scroll0to1 * 50 + practice0to1 * 50;
        } else if (!hasPractice && hasExamples) {
          percent = scroll0to1 * 50 + examples0to1 * 50;
        }
      } else {
        percent = scrollPercent;
      }

      percent = Math.max(0, Math.min(100, Math.round(percent)));

      totalChapters += 1;
      totalPercent += percent;
      if (percent >= 100) completedChapters += 1;
      if (!nextHref && percent < 100) {
        nextHref = url.pathname + (url.search || '');
      }
    } catch (_) {
      // Ignore malformed URLs
    }
  });

  if (!totalChapters) return;

  const averagePercent = Math.round(totalPercent / totalChapters);

  // Streak: rl:streak:current (days)
  let currentStreak = 0;
  try {
    const streakStr = window.localStorage.getItem('rl:streak:current');
    currentStreak = streakStr ? parseInt(streakStr, 10) : 0;
    if (!Number.isFinite(currentStreak) || currentStreak < 0) currentStreak = 0;
  } catch (_) {}

  // Course title from page header if available
  let courseTitle = 'This course';
  const headerTitle = document.querySelector('.tutorial-header h1, h1');
  if (headerTitle && headerTitle.textContent.trim()) {
    courseTitle = headerTitle.textContent.trim();
  }

  // Update an existing summary template near the Ruby learning path, if present.
  const summary = (chapterNav.parentNode && chapterNav.parentNode.querySelector('[data-course-summary]')) ||
                  document.querySelector('[data-course-summary]');
  if (!summary) return;

  const titleEl = summary.querySelector('[data-course-title]');
  const streakEl = summary.querySelector('[data-course-streak]');
  const barEl = summary.querySelector('[data-course-bar]');
  const statsEl = summary.querySelector('[data-course-stats]');

  if (titleEl) titleEl.textContent = courseTitle;
  if (streakEl) streakEl.textContent = `Current streak: ${currentStreak} day${currentStreak === 1 ? '' : 's'}`;
  if (barEl) barEl.style.width = `${averagePercent}%`;
  if (statsEl) statsEl.textContent = `${completedChapters}/${totalChapters} chapters complete - ${averagePercent}% overall`;
}

// Course-card progress pies on the /courses/ index: aggregate the same
// per-chapter localStorage progress used on course pages into one ring per card.
function computeChapterPercentFromStorage(chapterKeyPrefix) {
  try {
    const scrollStr = window.localStorage.getItem(`${chapterKeyPrefix}:scroll-percent`);
    const scrollPercent = scrollStr ? Math.max(0, Math.min(100, parseFloat(scrollStr))) : 0;

    const totalStr = window.localStorage.getItem(`${chapterKeyPrefix}:total`);
    const total = totalStr ? parseInt(totalStr, 10) : 0;
    let practiceCompleted = 0;
    if (total > 0) {
      for (let i = 0; i < total; i++) {
        if (window.localStorage.getItem(`${chapterKeyPrefix}:item:${i}`) === '1') practiceCompleted += 1;
      }
    }

    const examplesTotalStr = window.localStorage.getItem(`${chapterKeyPrefix}:examples_total`);
    const examplesTotal = examplesTotalStr ? parseInt(examplesTotalStr, 10) : 0;
    let examplesCompleted = 0;
    if (examplesTotal > 0) {
      for (let i = 0; i < examplesTotal; i++) {
        if (window.localStorage.getItem(`${chapterKeyPrefix}:example:${i}`) === '1') examplesCompleted += 1;
      }
    }

    const hasPractice = total > 0;
    const hasExamples = examplesTotal > 0;
    const scroll0to1 = scrollPercent / 100;
    const practice0to1 = hasPractice ? (practiceCompleted / total) : 0;
    const examples0to1 = hasExamples ? (examplesCompleted / examplesTotal) : 0;
    const anyPracticeDone = hasPractice && practiceCompleted > 0;
    const anyExamplesDone = hasExamples && examplesCompleted > 0;

    let percent = 0;
    if (hasPractice || hasExamples) {
      if (!anyPracticeDone && !anyExamplesDone) {
        percent = 0;
      } else if (hasPractice && hasExamples) {
        percent = scroll0to1 * 40 + practice0to1 * 30 + examples0to1 * 30;
      } else if (hasPractice && !hasExamples) {
        percent = scroll0to1 * 50 + practice0to1 * 50;
      } else {
        percent = scroll0to1 * 50 + examples0to1 * 50;
      }
    } else {
      percent = scrollPercent;
    }
    return Math.max(0, Math.min(100, Math.round(percent)));
  } catch (_) {
    return 0;
  }
}

function initCourseCardPies() {
  const pies = document.querySelectorAll('[data-course-pie]');
  if (!pies.length) return;

  pies.forEach(pie => {
    const slug = pie.getAttribute('data-course-pie');
    if (!slug) return;
    const label = pie.parentElement
      ? pie.parentElement.querySelector('[data-course-pie-label]')
      : null;

    fetch(`/courses/${slug}/`, { credentials: 'same-origin' })
      .then(res => (res.ok ? res.text() : null))
      .then(html => {
        if (!html) return;
        const doc = new DOMParser().parseFromString(html, 'text/html');
        const links = doc.querySelectorAll('.chapter-nav ol li > a[href^="/courses/"]');
        if (!links.length) return;

        let totalPercent = 0;
        let chapters = 0;
        links.forEach(link => {
          try {
            const url = new URL(link.getAttribute('href'), window.location.origin);
            const path = url.pathname.replace(/\/$/, '');
            totalPercent += computeChapterPercentFromStorage(`rl:chapter:${path}`);
            chapters += 1;
          } catch (_) {
            // skip malformed link
          }
        });
        if (!chapters) return;

        const percent = Math.round(totalPercent / chapters);
        const stateClass = percent >= 100 ? 'is-complete' : percent > 0 ? 'is-partial' : 'is-pending';
        pie.classList.add(stateClass);
        pie.style.setProperty('--percent', percent + '%');
        pie.setAttribute('aria-label', `Course progress: ${percent}%`);
        pie.setAttribute('title', `Course progress: ${percent}%`);
        if (label) {
          label.textContent = percent > 0 ? `${percent}% complete` : 'Not started';
        }
      })
      .catch(() => {
        // offline or fetch failure: leave the pie at 0%
      });
  });
}

runTutorialEnhancementsOnReady(function() {
  initCourseCardPies();
});
