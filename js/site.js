// Shared site behaviors
document.addEventListener('DOMContentLoaded', function() {
  // Mobile menu toggle for .menu-toggle and .site-nav
  var menuToggle = document.querySelector('.menu-toggle');
  var siteNav = document.querySelector('.site-nav');

  if (menuToggle && siteNav) {
    menuToggle.addEventListener('click', function() {
      siteNav.classList.toggle('active');
      menuToggle.classList.toggle('active');
    });
  }

  // Prism syntax highlighting if present
  if (typeof Prism !== 'undefined' && Prism && typeof Prism.highlightAll === 'function') {
    Prism.highlightAll();
  }
});

