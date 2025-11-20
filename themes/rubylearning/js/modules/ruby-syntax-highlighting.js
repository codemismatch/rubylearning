/**
 * Ruby Syntax Highlighting Utilities
 * Provides syntax highlighting for Ruby code using Prism.js
 */

function escapeHtml(text) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function highlightRubyInline(code) {
  if (window.Prism && Prism.languages && Prism.languages.ruby) {
    try {
      let highlighted = Prism.highlight(code, Prism.languages.ruby, 'ruby');
      
      // Post-process to fix built-in methods and symbols
      const builtins = ['puts', 'print', 'p', 'gets', 'require', 'raise', 'attr_reader', 'attr_writer', 'attr_accessor', 'alias_method', 'include', 'extend', 'loop', 'sleep'];
      const builtinRegex = new RegExp(`\\b(${builtins.join('|')})\\b`, 'g');
      
      // Wrap built-ins in cyan span if not already in a token
      highlighted = highlighted.replace(builtinRegex, (match) => {
        return `<span class="token builtin">${match}</span>`;
      });
      
      // Ensure symbols are properly highlighted in gold
      highlighted = highlighted.replace(/(:)([a-zA-Z_]\w*)/g, (match, colon, name) => {
        return `<span class="token symbol">${colon}${name}</span>`;
      });
      
      return highlighted;
    } catch (_) {
      return escapeHtml(code);
    }
  }
  return escapeHtml(code);
}

// Export for use in other modules
window.RubySyntaxHighlighting = {
  escapeHtml,
  highlightRubyInline
};
