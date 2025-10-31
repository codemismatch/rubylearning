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