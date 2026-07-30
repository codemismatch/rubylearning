// github-pages-fix.js - Fixes for GitHub Pages deployment

(function() {
  // Only run this script when deployed on GitHub Pages
  if (!isGitHubPages()) return;
  
  document.addEventListener('DOMContentLoaded', function() {
    // Get the repository name
    const repoName = getRepositoryName();
    
    // Fix navigation links
    fixNavigationLinks(repoName);
    
    // Fix asset links (CSS, JS, images)
    fixAssetLinks(repoName);
    
    console.log(`GitHub Pages fix applied for repository: ${repoName}`);
  });
  
  // Determine if we're on GitHub Pages
  function isGitHubPages() {
    return window.location.hostname.endsWith('github.io') || 
           window.location.hostname.includes('.github.io');
  }
  
  // Extract repository name from URL
  function getRepositoryName() {
    const pathSegments = window.location.pathname.split('/');
    // GitHub Pages URLs have format: username.github.io/repo-name/...
    return pathSegments[1] || '';
  }
  
  // Fix navigation links
  function fixNavigationLinks(repoName) {
    const navLinks = document.querySelectorAll('a[href^="/"]');
    
    navLinks.forEach(link => {
      // Skip links that already have the repo name
      if (link.getAttribute('href').startsWith(`/${repoName}/`)) return;
      
      // Skip the root link that needs special handling
      if (link.getAttribute('href') === '/') {
        link.setAttribute('href', `/${repoName}/`);
        return;
      }
      
      // Add repository name to the path
      const currentHref = link.getAttribute('href');
      link.setAttribute('href', `/${repoName}${currentHref}`);
    });
  }
  
  // Fix asset links
  function fixAssetLinks(repoName) {
    // Fix CSS links
    document.querySelectorAll('link[rel="stylesheet"][href^="/"]').forEach(link => {
      if (!link.getAttribute('href').startsWith(`/${repoName}/`)) {
        link.setAttribute('href', `/${repoName}${link.getAttribute('href')}`);
      }
    });
    
    // Fix JavaScript links
    document.querySelectorAll('script[src^="/"]').forEach(script => {
      if (!script.getAttribute('src').startsWith(`/${repoName}/`)) {
        script.setAttribute('src', `/${repoName}${script.getAttribute('src')}`);
      }
    });
    
    // Fix images
    document.querySelectorAll('img[src^="/"]').forEach(img => {
      if (!img.getAttribute('src').startsWith(`/${repoName}/`)) {
        img.setAttribute('src', `/${repoName}${img.getAttribute('src')}`);
      }
    });
  }
})();