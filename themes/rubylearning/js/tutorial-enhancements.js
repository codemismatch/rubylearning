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

  // Mark chapter as visited and update completion status once on load
  try {
    window.localStorage.setItem(`${chapterKeyPrefix}:visited`, '1');
  } catch (_) {}
  updateChapterCompletion(chapterKeyPrefix, itemKeys);
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
      const complete = window.localStorage.getItem(`${chapterKeyPrefix}:complete`) === '1';

      if (!visited && !complete) return;

      const marker = document.createElement('span');
      marker.className = 'chapter-progress-marker';
      marker.textContent = complete ? '✅' : '☑️';
      marker.setAttribute(
        'aria-label',
        complete ? 'Chapter completed' : 'Chapter visited'
      );

      link.appendChild(marker);
    } catch (_) {
      // Ignore malformed URLs
    }
  });
}
