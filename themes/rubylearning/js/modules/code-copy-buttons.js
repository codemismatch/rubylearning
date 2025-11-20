/**
 * Code Copy Buttons Module
 * Adds copy buttons to code blocks
 */

function addCopyButtonsToCodeBlocks() {
  document.querySelectorAll('pre > code').forEach(codeBlock => {
    const pre = codeBlock.parentNode;

    // Determine display language. Prefer a real language (e.g. ruby) over
    // custom markers like 'ruby-exec' so Prism uses the correct grammar.
    const classes = codeBlock.className.split(' ').filter(Boolean);
    const hasRuby = classes.includes('language-ruby');
    const hasRubyExec = classes.includes('ruby-exec');
    const firstRealLang = classes.find(c => c.startsWith('language-')) || '';
    const displayLang = hasRuby ? 'ruby' : (firstRealLang ? firstRealLang.replace('language-','') : 'code');

    // Ensure the <pre> carries 'language-ruby' if present; don't overwrite
    // with the ruby-exec marker which Prism doesn't recognise as a grammar.
    pre.classList.remove(...(pre.className.split(' ').filter(Boolean)));
    if (hasRuby) {
      pre.classList.add('language-ruby');
    } else if (firstRealLang) {
      pre.classList.add(firstRealLang);
    }

    // Create wrapper and header if needed
    let codeWindow = pre.closest('.code-window');
    if (!codeWindow) {
      codeWindow = document.createElement('div');
      codeWindow.className = 'code-window';
      pre.parentNode.insertBefore(codeWindow, pre);
      codeWindow.appendChild(pre);
    }

    if (!codeWindow.querySelector('.code-header')) {
      const header = Object.assign(document.createElement('div'), {
        className: 'code-header',
        innerHTML: `
          ${['red', 'yellow', 'green'].map(color =>
            `<span class="window-btn ${color}"></span>`).join('')}
          <span class="window-title">${displayLang}${displayLang === 'ruby' ? '.rb' : ''}</span>`
      });
      codeWindow.insertBefore(header, pre);
    }

    // Force Prism to (re)highlight after DOM changes to this block
    // Skip contenteditable blocks (ruby-exec) which have their own live highlighting
    if (typeof Prism !== 'undefined' && pre.getAttribute('contenteditable') !== 'true') {
      Prism.highlightElement(codeBlock);
    }

    // Add copy button if missing
    if (!codeWindow.querySelector('.copy-button')) {
      const copyBtn = Object.assign(document.createElement('button'), {
        className: 'copy-button',
        innerHTML: `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg><span>Copy</span>`
      });

      const updateBtn = (iconPath, text, timeout = 2000) => {
        copyBtn.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${iconPath}</svg><span>${text}</span>`;
        if (timeout)
          setTimeout(() => copyBtn.innerHTML =
            `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg><span>Copy</span>`, timeout);
      };

      copyBtn.addEventListener('click', async () => {
        try {
          // Always copy plain text, even if codeBlock has highlighted HTML
          // Check for stored plain text first (from "Show code"), then fall back to textContent
          const plainText = codeBlock.dataset.plainText || codeBlock.textContent;
          await navigator.clipboard.writeText(plainText);
          updateBtn('<polyline points="20 6 9 17 4 12"/>', 'Copied!');
        } catch {
          updateBtn('<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>', 'Error!', 2000);
        }
      });

      codeWindow.querySelector('.code-header').appendChild(copyBtn);
    }
  });
}

// Export for use in other modules
window.CodeCopyButtons = {
  addCopyButtonsToCodeBlocks
};
