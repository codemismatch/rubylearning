/**
 * Code Enhancements - Main Entry Point
 * Loads and coordinates code enhancement modules conditionally based on page content
 */

document.addEventListener('DOMContentLoaded', async () => {
  // Initialize Prism highlighting if available
  if (typeof Prism !== 'undefined') Prism.highlightAll();
  
  // Get the base path for modules (same directory as this script)
  const currentScript = document.currentScript || document.querySelector('script[src*="code-enhancements.js"]');
  const basePath = currentScript ? currentScript.src.replace(/\/[^/]*$/, '/') : '/js/';
  
  // Detect what features are needed on this page
  const hasCodeBlocks = document.querySelectorAll('pre > code').length > 0;
  const hasRunnableCode = document.querySelectorAll('.code-window pre[data-executable="true"], pre[data-practice-chapter]').length > 0;
  const hasInlineConsole = !!document.querySelector('.ruby-irb[data-ruby-console="true"]');
  const hasConsoleDrawer = !!document.querySelector('.ruby-console-drawer');
  
  // Always load syntax highlighting if there are code blocks
  if (hasCodeBlocks) {
    await loadScript(basePath + 'modules/ruby-syntax-highlighting.js');
    await loadScript(basePath + 'modules/code-copy-buttons.js');
    
    // Initialize copy buttons
    if (window.CodeCopyButtons) {
      window.CodeCopyButtons.addCopyButtonsToCodeBlocks();
    }
  }
  
  // Load console drawer only if present
  if (hasConsoleDrawer) {
    await loadScript(basePath + 'modules/ruby-console-drawer.js');
    if (window.RubyConsoleDrawer) {
      window.RubyConsoleDrawer.initRubyConsoleDrawer();
    }
  }
  
  // Load Ruby execution support only if needed
  if (hasRunnableCode || hasInlineConsole) {
    // Load dependencies first
    await loadScript(basePath + 'modules/ui-effects.js');
    await loadScript(basePath + 'modules/code-overlay-editor.js');
    await loadScript(basePath + 'modules/ruby-wasm-loader.js');
    await loadScript(basePath + 'modules/ruby-stdlib-polyfills.js');
    await loadScript(basePath + 'modules/ruby-test-framework.js');
    
    // Load Ruby console module if inline console is present
    // (ruby-exec.js will initialize it, but we need the module loaded first)
    if (hasInlineConsole) {
      await loadScript(basePath + 'modules/ruby-console.js');
    }
    
    // Load Ruby exec support (handles both runnable code and console initialization)
    await loadScript(basePath + 'modules/ruby-exec.js');
    
    // Initialize Ruby execution (handles both console and exec)
    if (window.RubyExec) {
      await window.RubyExec.addRubyExecSupport();
    }
  }
});

/**
 * Helper function to load a script module
 * @param {string} src - Full path to the script file
 */
function loadScript(src) {
  return new Promise((resolve, reject) => {
    // Check if script is already loaded
    const existingScript = document.querySelector(`script[src="${src}"]`);
    if (existingScript) {
      resolve();
      return;
    }
    
    const script = document.createElement('script');
    script.src = src;
    script.async = false; // Load in order
    script.onload = () => resolve();
    script.onerror = () => {
      console.error(`Failed to load script: ${src}`);
      reject(new Error(`Failed to load script: ${src}`));
    };
    document.head.appendChild(script);
  });
}
