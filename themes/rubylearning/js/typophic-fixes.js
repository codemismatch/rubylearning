/**
 * Typophic site fixes for syntax highlighting and template variable rendering
 */
document.addEventListener('DOMContentLoaded', function() {
  // Fix template variables that weren't rendered
  fixTemplateVariables();
  
  // Apply syntax highlighting to code blocks
  applySyntaxHighlighting();
  
  // Add copy buttons to code blocks
  addCopyButtons();
});

/**
 * Replaces unrendered template variables with proper content
 */
function fixTemplateVariables() {
  // Get the page title from the meta title tag
  const pageTitle = document.title.split('|')[0].trim();
  const siteName = document.title.split('|')[1]?.trim() || 'Ruby Learning';
  
  // Replace unrendered site name variables
  document.querySelectorAll('*:not(script):not(style)').forEach(el => {
    if (el.innerHTML.includes('<%= site.name %>')) {
      el.innerHTML = el.innerHTML.replace(/<%= site\.name %>/g, siteName);
    }
    if (el.innerHTML.includes('<%= page.title %>')) {
      el.innerHTML = el.innerHTML.replace(/<%= page\.title %>/g, pageTitle);
    }
  });
}

/**
 * Applies syntax highlighting to code blocks
 */
function applySyntaxHighlighting() {
  // Check if highlight.js is already loaded
  if (typeof hljs === 'undefined') {
    console.warn('Highlight.js is not loaded. Syntax highlighting will not be applied.');
    return;
  }
  
  // Get all pre > code elements
  const codeBlocks = document.querySelectorAll('pre > code');
  
  codeBlocks.forEach(block => {
    // Try to detect language from class
    let language = '';
    const classes = block.className.split(' ');
    
    for (const cls of classes) {
      if (cls.startsWith('language-')) {
        language = cls.replace('language-', '');
        break;
      }
    }
    
    // If no language class found, try to detect language
    if (!language) {
      // Detect Ruby code
      if (block.textContent.includes('def ') || 
          block.textContent.includes('class ') || 
          block.textContent.includes('module ') ||
          block.textContent.includes('require ')) {
        language = 'ruby';
      }
      // Detect Markdown
      else if (block.textContent.includes('# ') || 
               block.textContent.includes('## ') ||
               block.textContent.match(/\[.+\]\(.+\)/)) {
        language = 'markdown';
      }
      
      // Add language class if detected
      if (language) {
        block.classList.add(`language-${language}`);
      }
    }
    
    // Apply highlighting
    hljs.highlightElement(block);
  });
}

/**
 * Adds copy buttons to code blocks
 */
function addCopyButtons() {
  document.querySelectorAll('pre > code').forEach(block => {
    // Create the copy button wrapper and button
    const wrapper = document.createElement('div');
    wrapper.className = 'code-block-wrapper';
    
    const copyButton = document.createElement('button');
    copyButton.className = 'copy-button';
    copyButton.textContent = 'Copy';
    
    // Insert the wrapper and button
    const pre = block.parentNode;
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);
    wrapper.appendChild(copyButton);
    
    // Add click event to copy code
    copyButton.addEventListener('click', () => {
      const code = block.textContent;
      navigator.clipboard.writeText(code).then(() => {
        copyButton.textContent = 'Copied!';
        setTimeout(() => {
          copyButton.textContent = 'Copy';
        }, 2000);
      }).catch(err => {
        console.error('Failed to copy code:', err);
        copyButton.textContent = 'Error!';
        setTimeout(() => {
          copyButton.textContent = 'Copy';
        }, 2000);
      });
    });
  });
}
