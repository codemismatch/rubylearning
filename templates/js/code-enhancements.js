/**
 * Code Block Enhancements
 * Adds copy buttons and other improvements to code blocks
 */
document.addEventListener('DOMContentLoaded', function() {
  // Initialize Prism if available
  if (typeof Prism !== 'undefined') {
    Prism.highlightAll();
  }

  // Add copy buttons to code blocks
  addCopyButtonsToCodeBlocks();

  // Add language labels to pre tags that don't have them
  addLanguageLabels();
});

/**
 * Adds copy buttons to all code blocks
 */
function addCopyButtonsToCodeBlocks() {
  const codeBlocks = document.querySelectorAll('pre > code');
  
  codeBlocks.forEach(function(codeBlock) {
    const pre = codeBlock.parentNode;
    
    // Create code header if it doesn't exist
    let codeHeader = pre.previousElementSibling;
    if (!codeHeader || !codeHeader.classList.contains('code-header')) {
      codeHeader = document.createElement('div');
      codeHeader.className = 'code-header';
      
      // Add window buttons for styling
      const redBtn = document.createElement('span');
      redBtn.className = 'window-btn red';
      const yellowBtn = document.createElement('span');
      yellowBtn.className = 'window-btn yellow';
      const greenBtn = document.createElement('span');
      greenBtn.className = 'window-btn green';
      
      // Get language from class
      const langClass = Array.from(codeBlock.classList)
        .find(c => c.startsWith('language-'));
      
      const langName = langClass ? 
        langClass.replace('language-', '') : 
        'code';
      
      const titleSpan = document.createElement('span');
      titleSpan.className = 'window-title';
      titleSpan.textContent = langName + (langName === 'ruby' ? '.rb' : '');
      
      codeHeader.appendChild(redBtn);
      codeHeader.appendChild(yellowBtn);
      codeHeader.appendChild(greenBtn);
      codeHeader.appendChild(titleSpan);
      
      // Insert header before pre
      pre.parentNode.insertBefore(codeHeader, pre);
    }
    
    // Only add copy button if it doesn't exist
    if (!codeHeader.querySelector('.copy-button')) {
      const copyButton = document.createElement('button');
      copyButton.className = 'copy-button';
      copyButton.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
          <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
        </svg>
        <span>Copy</span>
      `;
      
      // Add click handler
      copyButton.addEventListener('click', function() {
        const codeToCopy = codeBlock.textContent;
        
        // Copy to clipboard
        navigator.clipboard.writeText(codeToCopy).then(
          function() {
            // Success
            copyButton.innerHTML = `
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="20 6 9 17 4 12"></polyline>
              </svg>
              <span>Copied!</span>
            `;
            
            // Reset after 2 seconds
            setTimeout(function() {
              copyButton.innerHTML = `
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                  <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                </svg>
                <span>Copy</span>
              `;
            }, 2000);
          },
          function() {
            // Error
            copyButton.innerHTML = `
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"></circle>
                <line x1="12" y1="8" x2="12" y2="12"></line>
                <line x1="12" y1="16" x2="12.01" y2="16"></line>
              </svg>
              <span>Error!</span>
            `;
            
            // Reset after 2 seconds
            setTimeout(function() {
              copyButton.innerHTML = `
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                  <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
                </svg>
                <span>Copy</span>
              `;
            }, 2000);
          }
        );
      });
      
      codeHeader.appendChild(copyButton);
    }
    
    // Add code-window class to pre if not present
    if (!pre.classList.contains('code-window')) {
      pre.classList.add('code-window');
    }
    
    // Add code-content class to pre if not present
    if (!pre.classList.contains('code-content')) {
      pre.classList.add('code-content');
    }
  });
}

/**
 * Adds language labels to pre tags without them
 */
function addLanguageLabels() {
  const preElements = document.querySelectorAll('pre:not([class*="language-"])');
  
  preElements.forEach(function(pre) {
    // Check if it has a child code element with a language class
    const codeEl = pre.querySelector('code[class*="language-"]');
    
    if (codeEl) {
      // Get the language class
      const langClass = Array.from(codeEl.classList)
        .find(c => c.startsWith('language-'));
      
      if (langClass) {
        pre.classList.add(langClass);
      }
    }
  });
}
