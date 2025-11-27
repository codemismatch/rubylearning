// tutorial-enhancements.js - Enhances the tutorial page with interactive features

document.addEventListener('DOMContentLoaded', function() {
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
document.addEventListener('DOMContentLoaded', function() {
  initPracticeChecklists();
  initChapterListProgress();
  trackLessonReading();
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
    }
  };

  window.addEventListener('scroll', updateScrollPercent);
  window.addEventListener('resize', updateScrollPercent);
  // Prime the value on load
  updateScrollPercent();
}

// On the Ruby learning path page, annotate chapters with visited/completed ticks.
function initChapterListProgress() {
  const chapterNav = document.querySelector('.chapter-nav');
  if (!chapterNav) return;

  const links = chapterNav.querySelectorAll('ol li > a[href^="/tutorials/"]');
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
