/**
 * Code Overlay Editor Module
 * Creates an editable overlay for code blocks with syntax highlighting
 */

function insertTextAtCursor(textarea, text) {
  const start = textarea.selectionStart ?? 0;
  const end = textarea.selectionEnd ?? 0;
  const value = textarea.value;
  textarea.value = value.slice(0, start) + text + value.slice(end);
  const newPos = start + text.length;
  textarea.selectionStart = textarea.selectionEnd = newPos;
}

function initOverlayEditor(pre, codeBlock, initialValue, onChange) {
  let wrapper = pre.closest('.code-editor');
  if (!wrapper) {
    wrapper = document.createElement('div');
    wrapper.className = 'code-editor';
    pre.parentNode.insertBefore(wrapper, pre);
    wrapper.appendChild(pre);
  }

  pre.classList.add('code-editor__highlight');

  const textarea = document.createElement('textarea');
  textarea.className = 'code-editor__input';
  textarea.value = initialValue;
  textarea.spellcheck = false;
  textarea.setAttribute('aria-label', 'Editable Ruby code');
  wrapper.appendChild(textarea);

  const renderHighlight = (value) => {
    let text = value;
    if (text.endsWith('\n')) {
      text += ' ';
    }
    // Use the syntax highlighting utility if available
    if (window.RubySyntaxHighlighting) {
      codeBlock.innerHTML = window.RubySyntaxHighlighting.highlightRubyInline(text);
    } else {
      codeBlock.textContent = text;
    }
  };

  // Keep layout stable: let CSS control overall height and scrolling,
  // and keep the textarea matched to the wrapper height.
  const syncSize = () => {
    textarea.style.height = '100%';
  };

  const emitChange = () => {
    onChange(textarea.value);
    renderHighlight(textarea.value);
    syncSize();
  };

  textarea.addEventListener('input', emitChange);
  textarea.addEventListener('scroll', () => {
    pre.scrollTop = textarea.scrollTop;
    pre.scrollLeft = textarea.scrollLeft;
  });
  textarea.addEventListener('keydown', (event) => {
    if (event.key === 'Tab') {
      event.preventDefault();
      insertTextAtCursor(textarea, '  ');
      emitChange();
    }
  });

  emitChange();

  return {
    textarea,
    setValue(newValue) {
      textarea.value = newValue;
      emitChange();
    },
    refresh: emitChange
  };
}

// Export for use in other modules
window.CodeOverlayEditor = {
  initOverlayEditor
};
