// Basic JavaScript for the Hugo Serif Typophic theme

document.addEventListener('DOMContentLoaded', function() {
  console.log('Hugo Serif Typophic theme loaded');
  
  // Mobile menu toggle
  const mobileMenuButton = document.querySelector('.mobile-menu-toggle');
  if (mobileMenuButton) {
    mobileMenuButton.addEventListener('click', function() {
      document.body.classList.toggle('mobile-menu-open');
    });
  }
});