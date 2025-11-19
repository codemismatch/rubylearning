document.addEventListener('DOMContentLoaded', async () => {
  if (typeof Prism !== 'undefined') Prism.highlightAll();
  addCopyButtonsToCodeBlocks();
  initRubyConsoleDrawer();
  await addRubyExecSupport();
});

function initRubyConsoleDrawer() {
  const drawer = document.querySelector('.ruby-console-drawer');
  if (!drawer) return;
  const toggle = drawer.querySelector('.ruby-console-toggle');
  if (!toggle) return;

  const icon = toggle.querySelector('.ruby-console-toggle-icon');
  const input = drawer.querySelector('.ruby-irb-input');

  const setState = (open) => {
    drawer.classList.toggle('ruby-console-drawer--open', open);
    toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    
    // Focus input when drawer opens
    if (open && input) {
      // Small delay to allow CSS transition to start
      setTimeout(() => {
        input.focus();
      }, 100);
    }
  };

  toggle.addEventListener('click', () => {
    const open = !drawer.classList.contains('ruby-console-drawer--open');
    setState(open);
  });
}

async function setupRubyWasm() {
  // Check if Ruby WASM is already loaded
  if (window.rubyWasmLoaded) return;
  
  return new Promise((resolve, reject) => {
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.7.1/dist/browser/+esm';
    script.type = 'module';
    script.onload = () => {
      window.rubyWasmLoaded = true;
      resolve();
    };
    script.onerror = reject;
    document.head.appendChild(script);
  });
}

function launchConfettiAround(element) {
  if (!element) return;
  const rect = element.getBoundingClientRect();
  const originX = rect.left + rect.width / 2;
  const originY = rect.top + rect.height / 2;
  const colors = ['#f97316', '#38bdf8', '#22c55e', '#e11d48', '#6366f1'];

  for (let i = 0; i < 32; i++) {
    const piece = document.createElement('span');
    piece.className = 'confetti-piece';
    const angle = (Math.random() - 0.5) * 2 * Math.PI;
    const distance = 80 + Math.random() * 80;

    piece.style.left = `${originX}px`;
    piece.style.top = `${originY}px`;
    piece.style.backgroundColor = colors[i % colors.length];
    piece.style.setProperty('--confetti-x', `${Math.cos(angle) * distance}px`);
    piece.style.setProperty('--confetti-y', `${Math.sin(angle) * distance + 120}px`);

    document.body.appendChild(piece);

    setTimeout(() => {
      piece.remove();
    }, 1200);
  }
}

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

function initRubyConsoles(vm) {
  const consoles = document.querySelectorAll('.ruby-irb[data-ruby-console="true"]');
  if (!consoles.length) return;

  // Prepare a helper in the shared VM that evaluates a single line,
  // capturing everything printed to $stdout and returning a combined string.
  try {
    if (!window.TypophicRubyConsoleInitialized) {
      vm.eval(`
        require 'stringio'

        $typ_irb_output = StringIO.new
        $typ_irb_buffer = +""

        def _typophic_eval(line)
          $typ_irb_output.truncate(0)
          $typ_irb_output.rewind
          result = nil

          begin
            old_stdout = $stdout
            $stdout = $typ_irb_output
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
                $typ_irb_output.puts("\#{e.class}: \#{e.message}")
              end
            end
          rescue Exception => e
            $typ_irb_output.puts("\#{e.class}: \#{e.message}")
          ensure
            $stdout = old_stdout
          end

          out = $typ_irb_output.string
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
      requestAnimationFrame(updateCaret); // Use requestAnimationFrame for smooth updates
    });
    
    // Update caret on selection change (for mouse drag selections)
    input.addEventListener('select', () => {
      requestAnimationFrame(updateCaret);
    });
    
    // Update caret position after any key that moves the cursor
    // This handles arrow keys, Home, End, and any other navigation keys
    input.addEventListener('keyup', (e) => {
      // Update caret for any cursor movement key
      const cursorKeys = ['ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown', 'Home', 'End', 'PageUp', 'PageDown'];
      if (cursorKeys.includes(e.key) || (e.ctrlKey && ['a', 'e', 'b', 'f'].includes(e.key.toLowerCase()))) {
        requestAnimationFrame(updateCaret);
      }
    });
    
    // Also update caret on any selection change (handles mouse clicks, drags, etc.)
    document.addEventListener('selectionchange', () => {
      if (document.activeElement === input) {
        requestAnimationFrame(updateCaret);
      }
    });

    // Readline shortcuts and command history
    input.addEventListener('keydown', (event) => {
      // Handle Enter for submission (check first to avoid conflicts)
      if (event.key === 'Enter' && !event.shiftKey && !event.ctrlKey && !event.metaKey) {
        event.preventDefault();
        form.dispatchEvent(new Event('submit', { cancelable: true, bubbles: true }));
        return;
      }
      
      // Readline-style shortcuts (check BEFORE arrow keys to handle Ctrl+Arrow combinations)
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
            
          case 'b': // Move backward one character (Ctrl+B)
            event.preventDefault();
            if (input.selectionStart > 0) {
              input.selectionStart = input.selectionEnd = input.selectionStart - 1;
              updateCaret();
            }
            return;
            
          case 'f': // Move forward one character (Ctrl+F)
            event.preventDefault();
            if (input.selectionStart < input.value.length) {
              input.selectionStart = input.selectionEnd = input.selectionStart + 1;
              updateCaret();
            }
            return;
        }
      }
      
      // Command history navigation with Up/Down arrows (only if not modified)
      if (event.key === 'ArrowUp' && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
        event.preventDefault();
        if (commandHistory.length === 0) return;
        
        // Save current draft when first entering history
        if (historyIndex === -1) {
          currentDraft = input.value;
        }
        
        // Move backwards in history
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
        
        // Move forward in history
        historyIndex--;
        if (historyIndex === -1) {
          // Restore draft
          input.value = currentDraft;
        } else {
          input.value = commandHistory[commandHistory.length - 1 - historyIndex];
        }
        input.selectionStart = input.selectionEnd = input.value.length;
        ghostEl.innerHTML = highlightRubyInline(input.value || '');
        updateCaret();
        return;
      }
      
      // For unmodified arrow keys (left/right only), allow default behavior
      // The keyup handler will update the caret position
      if ((event.key === 'ArrowLeft' || event.key === 'ArrowRight') && !event.ctrlKey && !event.metaKey && !event.shiftKey) {
        // Let browser handle cursor movement, keyup will update our custom caret
        return;
      }
      
      // For Home/End keys, allow default behavior
      if ((event.key === 'Home' || event.key === 'End') && !event.ctrlKey && !event.metaKey) {
        // Let browser handle cursor movement, keyup will update our custom caret
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

      // Add to command history (avoid duplicates)
      if (commandHistory.length === 0 || commandHistory[commandHistory.length - 1] !== code) {
        commandHistory.push(code);
      }
      // Reset history navigation
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

          // Simple auto-indent: carry leading spaces and add two for common block starters
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

  async function addRubyExecSupport() {
  // Add Ruby execution support when there are runnable code blocks
  // OR when the inline Ruby console drawer is present.
  const rubyBlocks = document.querySelectorAll('.code-window pre.language-ruby, pre[data-executable="true"]');
  const hasInlineConsole = !!document.querySelector('.ruby-irb[data-ruby-console="true"]');
  if (rubyBlocks.length === 0 && !hasInlineConsole) return;
  
  try {
    await setupRubyWasm();
    
    // Load the Ruby WASM module
    const { DefaultRubyVM } = await import('https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.7.1/dist/browser/+esm');
    
    let vm;
    try {
      const response = await fetch('https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.7.1/dist/ruby+stdlib.wasm');
      const module = await WebAssembly.compileStreaming(response);
      const instance = await DefaultRubyVM(module);
      vm = instance.vm;
      console.log('Ruby VM initialized successfully');
    } catch (error) {
      console.error('Failed to load Ruby WASM:', error);
      return;
    }

    // Expose the VM globally so other helpers (like the mini console) can reuse it
    window.TypophicRubyVM = vm;

    // Wire interactive stdin via Ruby's JS bridge
    // This overrides Kernel#gets to call window.prompt() when not in test mode
    try {
      const setupResult = vm.eval(`
        require 'js'
        
        # Override Kernel#gets to use JS prompt
        module Kernel
          alias_method :__original_wasm_gets, :gets
          
          def gets(*args)
            # If $stdin is a StringIO (from tests), use it
            if defined?(StringIO) && $stdin.is_a?(StringIO)
              return $stdin.gets(*args)
            end
            
            # Otherwise prompt via JS - use JS.global.call syntax
            result = JS.global.call(:prompt, "Ruby input >")
            if result.nil?
              return nil
            end
            result_str = result.to_s
            return nil if result_str == "null"
            result_str + "\\n"
          end
        end
        
        # Test that gets override works
        $gets_test = defined?(gets) ? "method_defined" : "method_undefined"
        "gets_override_ready"
      `);
      console.log('stdin override installed:', setupResult.toString());
      
      // Verify gets method is accessible
      const getsTest = vm.eval('$gets_test');
      console.log('gets method status:', getsTest.toString());
    } catch (err) {
      console.error('Failed to install stdin override:', err);
    }

    // Initialize any inline Ruby consoles (virtual irb) before wiring code blocks
    if (hasInlineConsole) {
      initRubyConsoles(vm);
    }

    // Progress tracking across both practice items and runnable examples
    const chapterKeyPrefix = `rl:chapter:${window.location.pathname.replace(/\/$/, '')}`;
    let exampleCounter = 0;

    rubyBlocks.forEach((pre, index) => {
      // Accept either explicit ruby code blocks or ruby-exec markers
      const codeBlock = pre.querySelector('code.language-ruby, code.ruby-exec');
      if (!codeBlock) return;

      const practiceChapter = pre.dataset.practiceChapter || codeBlock.dataset.practiceChapter;
      const practiceIndex = pre.dataset.practiceIndex ? parseInt(pre.dataset.practiceIndex, 10) : null;
      const practiceTest = pre.dataset.test || codeBlock.dataset.test || "";
      const isPracticeCheck = !!practiceChapter && !Number.isNaN(practiceIndex) && practiceTest.trim().length > 0;
      // Index for non-practice example blocks
      const exampleIndex = isPracticeCheck ? null : exampleCounter++;

      // Ensure the code block has contenteditable enabled
      pre.setAttribute('contenteditable', true);
      pre.style.whiteSpace = 'pre-wrap';
      pre.style.outline = 'none';

      // Create output area
      const outputArea = document.createElement('div');
      outputArea.className = 'output-area';
      const outputContent = document.createElement('pre');
      outputContent.className = 'output-content';
      outputArea.appendChild(outputContent);

      // Add run/check button to the header
      const header = pre.closest('.code-window')?.querySelector('.code-header') || pre.parentElement?.querySelector('.code-header');
      if (header && !header.querySelector('.run-button')) {
        // For practice blocks, only show Check button (which runs tests)
        // For non-practice blocks, show Run button
        const mainButton = document.createElement('button');
        mainButton.className = 'run-button';
        
        if (isPracticeCheck) {
          mainButton.classList.add('check-button');
          mainButton.textContent = '✔ Check';
        } else {
          mainButton.textContent = '▶ Run';
        }
        
        header.appendChild(mainButton);

        // Insert output area after the <pre>
        pre.parentNode.insertBefore(outputArea, pre.nextSibling);

        // Shared execution logic
        const executeCode = async (runTests) => {
          const userCode = codeBlock.textContent.trim();
          outputContent.textContent = 'Executing Ruby code...\n';

          try {
            const heredocTag = 'RUBYEXEC';
            const coreConstants = new Set([
              'String', 'Integer', 'Numeric', 'Float', 'Fixnum', 'Bignum',
              'Array', 'Hash', 'Range', 'Symbol', 'Object', 'Kernel',
              'Enumerable', 'Comparable', 'File', 'Dir', 'IO', 'Process'
            ]);

            const normalized = userCode.replace(/^(\s*)(class|module)\s+([A-Z]\w*)/gm, (match, indent, keyword, name) => {
              const qualified = coreConstants.has(name) ? `::${name}` : name;
              return `${indent}${keyword} ${qualified}`;
            });
            const programLines = [
              "require 'stringio'",
              "require 'js'",
              "$__exec_output__ = StringIO.new",
              "$__last_prompt_line__ = nil",
              "",
              "# Override Kernel methods to capture output and provide gets",
              "module Kernel",
              "  # Capture output",
              "  def puts(*args)",
              "    if args.empty?",
              "      $__exec_output__.puts",
              "      $__last_prompt_line__ = nil",
              "    else",
              "      args.each do |arg|",
              "        $__exec_output__.puts(arg)",
              "        $__last_prompt_line__ = arg.to_s",
              "      end",
              "    end",
              "    nil",
              "  end",
              "",
              "  def print(*args)",
              "    text = args.join",
              "    $__exec_output__.print(text)",
              "    $__last_prompt_line__ = text unless text.empty?",
              "    nil",
              "  end",
              "",
              "  def p(*args)",
              "    args.each { |arg| $__exec_output__.puts(arg.inspect) }",
              "    args.length <= 1 ? args.first : args",
              "  end",
              "",
              "  # Override gets to prompt via JS when available, using the",
              "  # last printed line as the prompt text when possible.",
              "  alias __typophic_original_gets gets unless method_defined?(:__typophic_original_gets)",
              "  def gets(*args)",
              "    if defined?(JS) && JS.respond_to?(:global)",
              "      prompt_text = $__last_prompt_line__.to_s.strip",
              "      prompt_text = 'Ruby input >' if prompt_text.empty?",
              "      result = JS.global.call(:prompt, prompt_text)",
              "      return nil if result.nil?",
              "      result.to_s + \"\\n\"",
              "    else",
              "      __typophic_original_gets(*args)",
              "    end",
              "  end",
              "end",
              "",
              "begin",
              `  eval <<-'${heredocTag}'`,
              normalized,
              heredocTag,
              "rescue Exception => e",
              "  $__exec_output__.puts(\"Error: \#{e.class}: \#{e.message}\")",
              "end"
            ];

            // For practice blocks, always run tests (Check button)
            // For non-practice blocks, just run the code (Run button)
            if (isPracticeCheck && practiceTest.trim().length > 0) {
              const testTag = 'RUBYTEST';
              programLines.push(
                "# Make output variable available to tests",
                "output = $__exec_output__",
                "",
                "test_result = begin",
                "  begin",
                "    # Prefer Test::Unit-style assertions when available, but",
                "    # fall back to treating the last expression as a boolean.",
                "    begin",
                "      require 'test/unit/assertions'",
                "      extend Test::Unit::Assertions",
                "    rescue LoadError",
                "      # In minimal environments, assertions may not be available.",
                "    end",
                `    __test_value__ = (eval <<-'${testTag}')`,
                practiceTest,
                testTag,
                "    __test_value__ = true if __test_value__.nil?",
                "    !!__test_value__",
                "  rescue Exception => e",
                "    # Swallow test framework details; surface only a concise error.",
                "    $__exec_output__.puts(\"Test error: \#{e.message}\")",
                "    false",
                "  end",
                "rescue Exception => e",
                "  $__exec_output__.puts(\"Test error: \#{e.message}\")",
                "  false",
                "end",
                "output_text = $__exec_output__.string",
                "output_text + \"\\n__TEST__=\#{test_result ? 'PASS' : 'FAIL'}\""
              );
            } else {
              programLines.push("$__exec_output__.string");
            }

            const result = vm.eval(programLines.join("\n"));
            let outputText = result?.toString?.() ?? '';

            let testPassed = null;
            if (isPracticeCheck) {
              const markerMatch = outputText.match(/__TEST__=(PASS|FAIL)\s*$/);
              if (markerMatch) {
                testPassed = markerMatch[1] === 'PASS';
                outputText = outputText.replace(/\s*__TEST__=(PASS|FAIL)\s*$/, '');
              }
            }

            outputContent.textContent = outputText ? `>> ${outputText}` : '>>';

            if (isPracticeCheck && practiceChapter && testPassed !== null) {
              const feedback = document.querySelector(
                `.practice-feedback[data-practice-chapter="${practiceChapter}"][data-practice-index="${practiceIndex}"]`
              );
              if (feedback) {
                feedback.textContent = testPassed
                  ? '✅ Challenge passed! Practice item marked complete.'
                  : '❌ Not yet. Adjust your code and try again.';
              }

              if (testPassed) {
                if (window.TypophicPractice && typeof window.TypophicPractice.markPracticeItem === 'function') {
                  window.TypophicPractice.markPracticeItem(practiceChapter, practiceIndex, true);
                }
                launchConfettiAround(header || pre);
              } else {
                // Reveal "Show code" button after first failed attempt
                const existing = header.querySelector('.show-solution-button');
                if (!existing) {
                  const showButton = document.createElement('button');
                  showButton.className = 'show-solution-button';
                  showButton.textContent = 'Show code';
                  header.appendChild(showButton);

                  // Event listener that always fetches fresh solution from script tag
                  showButton.addEventListener('click', () => {
                    try {
                      const solutionKey = `${practiceChapter}:${practiceIndex}`;
                      const solutionNode = document.querySelector(
                        `script[data-practice-solution="${solutionKey}"]`
                      );
                      if (!solutionNode) {
                        console.warn('Solution not found for:', solutionKey);
                        return;
                      }

                      // Always restore from the stored solution
                      const solution = solutionNode.textContent.replace(/^\s+|\s+$/g, '');
                      codeBlock.textContent = solution;
                      if (typeof Prism !== 'undefined') {
                        Prism.highlightElement(codeBlock);
                      }
                    } catch (err) {
                      console.warn('Failed to show solution:', err);
                    }
                  });
                }
              }
            }
          } catch (err) {
            outputContent.textContent = `Error: ${err.message}`;
          }
        };

        // Wire up button event listener
        mainButton.addEventListener('click', async () => {
          await executeCode(isPracticeCheck); // Practice = run tests, non-practice = just run code
          // Mark example as executed for progress tracking
          if (!isPracticeCheck && exampleIndex != null) {
            try { window.localStorage.setItem(`${chapterKeyPrefix}:example:${exampleIndex}`, '1'); } catch (_) {}
          }
        });
      }
    });
    // Persist examples total count for progress rings on index page
    try { window.localStorage.setItem(`${chapterKeyPrefix}:examples_total`, String(exampleCounter)); } catch (_) {}
  } catch (error) {
    console.warn('Ruby execution support failed to initialize:', error);
  }
}

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
    if (typeof Prism !== 'undefined') {
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
          await navigator.clipboard.writeText(codeBlock.textContent);
          updateBtn('<polyline points="20 6 9 17 4 12"/>', 'Copied!');
        } catch {
          updateBtn('<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>', 'Error!', 2000);
        }
      });

      codeWindow.querySelector('.code-header').appendChild(copyBtn);
    }
  });
}
