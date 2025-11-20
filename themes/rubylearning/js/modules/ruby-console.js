/**
 * Ruby Console (IRB) Module
 * Provides an interactive Ruby console (IRB) interface
 */

function initRubyConsoles(vm) {
  const consoles = document.querySelectorAll('.ruby-irb[data-ruby-console="true"]');
  if (!consoles.length) return;

  // Prepare a helper in the shared VM that evaluates a single line,
  // capturing everything printed to $stdout and returning a combined string.
  try {
    if (!window.TypophicRubyConsoleInitialized) {
      vm.eval(`
        $typ_irb_output = +""
        $typ_irb_buffer = +""

        def _typophic_eval(line)
          $typ_irb_output.clear
          result = nil

          begin
            old_stdout = $stdout
            # Create a simple IO-like object that captures output to string
            $stdout = Object.new
            def $stdout.puts(*args)
              if args.empty?
                $typ_irb_output << "\\n"
              else
                args.each { |arg| $typ_irb_output << arg.to_s << "\\n" }
              end
            end
            def $stdout.print(*args)
              $typ_irb_output << args.join
            end
            def $stdout.write(str)
              $typ_irb_output << str.to_s
            end
            
            $typ_irb_buffer << line << "\\n"
            begin
              result = eval($typ_irb_buffer, TOPLEVEL_BINDING)
              $typ_irb_buffer.clear
            rescue SyntaxError => e
              message = e.message.to_s
              if message.include?("unexpected end-of-input") || message.include?("unterminated")
                return "__INCOMPLETE__"
              else
                $typ_irb_buffer.clear
                $typ_irb_output << "\#{e.class}: \#{e.message}\\n"
              end
            end
          rescue Exception => e
            $typ_irb_output << "\#{e.class}: \#{e.message}\\n"
          ensure
            $stdout = old_stdout
          end

          out = $typ_irb_output
          if result.nil?
            out.empty? ? "=> nil" : "\#{out}=> nil"
          else
            out.empty? ? "=> \#{result.inspect}" : "\#{out}=> \#{result.inspect}"
          end
        end
      `);
      window.TypophicRubyConsoleInitialized = true;
    }
  } catch (err) {
    console.warn('Failed to initialize Ruby console helper:', err);
  }

  const highlightRubyInline = window.RubySyntaxHighlighting?.highlightRubyInline || ((code) => {
    if (window.Prism && Prism.languages && Prism.languages.ruby) {
      try {
        return Prism.highlight(code, Prism.languages.ruby, 'ruby');
      } catch (_) {
        return window.RubySyntaxHighlighting?.escapeHtml(code) || code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      }
    }
    return window.RubySyntaxHighlighting?.escapeHtml(code) || code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  });

  const escapeHtml = window.RubySyntaxHighlighting?.escapeHtml || ((text) => {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  });

  consoles.forEach(container => {
    const outputEl = container.querySelector('.ruby-irb-output');
    const form = container.querySelector('.ruby-irb-form');
    const input = container.querySelector('.ruby-irb-input');
    const promptEl = container.querySelector('.ruby-irb-prompt');
    const ghostEl = container.querySelector('.ruby-irb-ghost');
    const caretEl = container.querySelector('.ruby-irb-caret');
    if (!outputEl || !form || !input || !ghostEl || !caretEl) return;

    const appendLine = (text, cssClass, asHtml = false) => {
      const line = document.createElement('div');
      line.className = 'ruby-irb-line' + (cssClass ? ` ${cssClass}` : '');
      if (asHtml || /<[^>]+>/.test(text)) {
        line.innerHTML = text;
      } else {
        line.textContent = text;
      }
      outputEl.appendChild(line);
      outputEl.scrollTop = outputEl.scrollHeight;
    };

    let lineNumber = 1;
    let pendingBlock = false;
    
    // Command history
    let commandHistory = [];
    let historyIndex = -1;
    let currentDraft = '';
    
    // Readline kill ring (for yank)
    let killRing = '';

    // Caret positioning - measure text width up to cursor position
    const updateCaret = () => {
      const cursorPos = input.selectionStart || 0;
      const textBeforeCursor = input.value.substring(0, cursorPos);
      
      // Create a temporary element with the same styling as the ghost to measure width
      const tempSpan = document.createElement('span');
      const ghostStyles = window.getComputedStyle(ghostEl);
      tempSpan.style.position = 'absolute';
      tempSpan.style.visibility = 'hidden';
      tempSpan.style.whiteSpace = 'pre';  // Use 'pre' to preserve spaces
      tempSpan.style.fontFamily = ghostStyles.fontFamily;
      tempSpan.style.fontSize = ghostStyles.fontSize;
      tempSpan.style.fontWeight = ghostStyles.fontWeight;
      tempSpan.style.letterSpacing = ghostStyles.letterSpacing;
      tempSpan.style.wordSpacing = ghostStyles.wordSpacing;
      tempSpan.textContent = textBeforeCursor || '\u200B'; // Zero-width space for empty text
      document.body.appendChild(tempSpan);
      
      const width = tempSpan.getBoundingClientRect().width;
      tempSpan.remove();
      
      // Position caret - visibility and display are managed, but not opacity (for blinking)
      caretEl.style.display = 'block';
      caretEl.style.visibility = 'visible';
      caretEl.style.left = `${width}px`;
      caretEl.style.top = '0.4rem';
      
      // Debug mode
      if (window.location.search.includes('debug=caret')) {
        console.log('Caret update:', {
          cursorPos,
          textBeforeCursor: JSON.stringify(textBeforeCursor),
          width,
          left: caretEl.style.left,
          inputLength: input.value.length
        });
      }
    };

    const updatePrompt = () => {
      if (!promptEl) return;
      const label = String(lineNumber).padStart(3, '0');
      const sign = pendingBlock ? '*' : '>';
      promptEl.textContent = `mrc(main):${label}${sign}`;
      ghostEl.innerHTML = highlightRubyInline(input.value || '');
      updateCaret();
    };

    // Initial hint
    if (!outputEl.dataset.initialized) {
      appendLine('<span class="tinted-diamond" aria-hidden="true">💎</span> Mini Ruby console. Type Ruby code and press Enter.', 'ruby-irb-line--intro ruby-irb-line--intro-green', true);
      appendLine('Try: 1 + 2, "Hello".upcase', 'ruby-irb-line--intro ruby-irb-line--intro-white');
      outputEl.dataset.initialized = 'true';
    }

    // Initialize caret visibility and position
    updatePrompt();
    updateCaret();

    input.addEventListener('input', (e) => {
      const currentValue = input.value;
      const trimmed = currentValue.trim();
      
      // Auto-dedent keywords that should be at the same level as their opening
      const dedentKeywords = /^(end|else|elsif|when|rescue|ensure)$/;
      if (dedentKeywords.test(trimmed)) {
        // Remove one level of indentation (2 spaces)
        const leadingSpaces = currentValue.match(/^(\s*)/)[1];
        if (leadingSpaces.length >= 2) {
          input.value = leadingSpaces.slice(2) + trimmed;
        }
      }
      
      ghostEl.innerHTML = highlightRubyInline(input.value || '');
      requestAnimationFrame(updateCaret);
    });

    input.addEventListener('focus', updateCaret);
    input.addEventListener('blur', () => {
      caretEl.style.visibility = 'hidden';
    });
    
    // Update caret on mouse click
    input.addEventListener('click', () => {
      requestAnimationFrame(updateCaret);
    });
    
    // Update caret on selection change (for mouse drag selections)
    input.addEventListener('select', () => {
      requestAnimationFrame(updateCaret);
    });
    
    // Update caret position after any key that moves the cursor
    input.addEventListener('keyup', (e) => {
      const cursorKeys = ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Home', 'End', 'PageUp', 'PageDown'];
      if (cursorKeys.includes(e.key) || (e.ctrlKey && ['a', 'e', 'b', 'f'].includes(e.key.toLowerCase()))) {
        requestAnimationFrame(updateCaret);
      }
    });
    
    // Also update caret on any selection change
    document.addEventListener('selectionchange', () => {
      if (document.activeElement === input) {
        requestAnimationFrame(updateCaret);
      }
    });

    // Readline shortcuts and command history
    input.addEventListener('keydown', (event) => {
      // Handle Enter for submission
      if (event.key === 'Enter' && !event.shiftKey && !event.ctrlKey && !event.metaKey) {
        event.preventDefault();
        form.dispatchEvent(new Event('submit', { cancelable: true, bubbles: true }));
        return;
      }
      
      // Readline-style shortcuts
      if (event.ctrlKey || event.metaKey) {
        switch (event.key.toLowerCase()) {
          case 'a': // Move to beginning of line
            event.preventDefault();
            input.selectionStart = input.selectionEnd = 0;
            updateCaret();
            ghostEl.innerHTML = highlightRubyInline(input.value || '');
            return;
            
          case 'e': // Move to end of line
            event.preventDefault();
            input.selectionStart = input.selectionEnd = input.value.length;
            updateCaret();
            ghostEl.innerHTML = highlightRubyInline(input.value || '');
            return;
            
          case 'k': // Kill (cut) from cursor to end of line
            event.preventDefault();
            killRing = input.value.substring(input.selectionStart);
            input.value = input.value.substring(0, input.selectionStart);
            ghostEl.innerHTML = highlightRubyInline(input.value || '');
            updateCaret();
            return;
            
          case 'u': // Kill (cut) from beginning to cursor
            event.preventDefault();
            killRing = input.value.substring(0, input.selectionStart);
            input.value = input.value.substring(input.selectionStart);
            input.selectionStart = input.selectionEnd = 0;
            ghostEl.innerHTML = highlightRubyInline(input.value || '');
            updateCaret();
            return;
            
          case 'y': // Yank (paste) from kill ring
            event.preventDefault();
            if (killRing) {
              const pos = input.selectionStart;
              input.value = input.value.substring(0, pos) + killRing + input.value.substring(pos);
              input.selectionStart = input.selectionEnd = pos + killRing.length;
              ghostEl.innerHTML = highlightRubyInline(input.value || '');
              updateCaret();
            }
            return;
            
          case 'w': // Kill word backwards
            event.preventDefault();
            const beforeCursor = input.value.substring(0, input.selectionStart);
            const afterCursor = input.value.substring(input.selectionStart);
            const wordMatch = beforeCursor.match(/\s*\S+\s*$/);
            if (wordMatch) {
              killRing = wordMatch[0];
              input.value = beforeCursor.substring(0, beforeCursor.length - wordMatch[0].length) + afterCursor;
              input.selectionStart = input.selectionEnd = beforeCursor.length - wordMatch[0].length;
              ghostEl.innerHTML = highlightRubyInline(input.value || '');
              updateCaret();
            }
            return;
            
          case 'b': // Move backward one character
            event.preventDefault();
            if (input.selectionStart > 0) {
              input.selectionStart = input.selectionEnd = input.selectionStart - 1;
              updateCaret();
            }
            return;
            
          case 'f': // Move forward one character
            event.preventDefault();
            if (input.selectionStart < input.value.length) {
              input.selectionStart = input.selectionEnd = input.selectionStart + 1;
              updateCaret();
            }
            return;
        }
      }
      
      // Command history navigation
      if (event.key === 'ArrowUp' && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
        event.preventDefault();
        if (commandHistory.length === 0) return;
        
        if (historyIndex === -1) {
          currentDraft = input.value;
        }
        
        if (historyIndex < commandHistory.length - 1) {
          historyIndex++;
          input.value = commandHistory[commandHistory.length - 1 - historyIndex];
          input.selectionStart = input.selectionEnd = input.value.length;
          ghostEl.innerHTML = highlightRubyInline(input.value || '');
          updateCaret();
        }
        return;
      }
      
      if (event.key === 'ArrowDown' && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
        event.preventDefault();
        if (historyIndex === -1) return;
        
        historyIndex--;
        if (historyIndex === -1) {
          input.value = currentDraft;
        } else {
          input.value = commandHistory[commandHistory.length - 1 - historyIndex];
        }
        input.selectionStart = input.selectionEnd = input.value.length;
        ghostEl.innerHTML = highlightRubyInline(input.value || '');
        updateCaret();
        return;
      }
      
      // Allow default behavior for arrow keys
      if ((event.key === 'ArrowLeft' || event.key === 'ArrowRight') && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
        return;
      }
      
      if ((event.key === 'Home' || event.key === 'End') && !event.ctrlKey && !event.metaKey) {
        return;
      }
    });

    form.addEventListener('submit', event => {
      event.preventDefault();
      const code = input.value;
      if (!code.trim()) {
        input.value = '';
        return;
      }

      // Add to command history
      if (commandHistory.length === 0 || commandHistory[commandHistory.length - 1] !== code) {
        commandHistory.push(code);
      }
      historyIndex = -1;
      currentDraft = '';

      try {
        input.value = '';
        const rubyString = JSON.stringify(code);
        const result = vm.eval(`_typophic_eval(${rubyString})`);
        const text = (result && typeof result.toString === 'function')
          ? result.toString()
          : '=> nil';
        const label = String(lineNumber).padStart(3, '0');

        if (text === '__INCOMPLETE__') {
          const line = document.createElement('div');
          line.className = 'ruby-irb-line ruby-irb-line--input';
          line.innerHTML = `<span class="ruby-irb-label">mrc(main):${label}*</span> <span class="ruby-irb-code">${highlightRubyInline(code)}</span>`;
          outputEl.appendChild(line);
          outputEl.scrollTop = outputEl.scrollHeight;
          lineNumber += 1;
          pendingBlock = true;

          // Auto-indent
          const leading = (code.match(/^\s*/) || [''])[0];
          const trimmed = code.trim();
          let indent = leading;
          if (/\b(def|class|module|if|case|while|until|for|begin|do)\b/.test(trimmed)) {
            indent += '  ';
          }
          input.value = indent;
          ghostEl.innerHTML = highlightRubyInline(input.value || '');
          updatePrompt();
          return;
        }

        const inputLine = document.createElement('div');
        inputLine.className = 'ruby-irb-line ruby-irb-line--input';
        inputLine.innerHTML = `<span class="ruby-irb-label">mrc(main):${label}&gt;</span> <span class="ruby-irb-code">${highlightRubyInline(code)}</span>`;
        outputEl.appendChild(inputLine);
        outputEl.scrollTop = outputEl.scrollHeight;
        lineNumber += 1;
        pendingBlock = false;
        input.value = '';
        ghostEl.innerHTML = '';
        updatePrompt();

        const lines = text.split(/\r?\n/);
        lines.forEach((raw, idx) => {
          const lineText = raw.trimEnd();
          if (!lineText) return;
          const lineEl = document.createElement('div');
          lineEl.className = 'ruby-irb-line ruby-irb-line--result';

          if (idx === lines.length - 1 && lineText.startsWith('=>')) {
            const value = lineText.slice(2).trim();
            lineEl.innerHTML = `<span class="ruby-irb-result-marker">=&gt;</span> <span class="ruby-irb-result-value">${escapeHtml(value)}</span>`;
          } else {
            lineEl.textContent = lineText;
          }

          outputEl.appendChild(lineEl);
          outputEl.scrollTop = outputEl.scrollHeight;
        });
      } catch (err) {
        appendLine(`ERROR: ${err.message}`, 'ruby-irb-line--error');
      }
    });
  });
}

// Export for use in other modules
window.RubyConsole = {
  initRubyConsoles
};
