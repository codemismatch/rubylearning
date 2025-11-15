document.addEventListener('DOMContentLoaded', async () => {
  if (typeof Prism !== 'undefined') Prism.highlightAll();
  addCopyButtonsToCodeBlocks();
  await addRubyExecSupport();
});

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

async function addRubyExecSupport() {
  // Only add Ruby execution support on pages with executable Ruby code
  const rubyBlocks = document.querySelectorAll('.code-window pre.language-ruby, pre[data-executable="true"]');
  if (rubyBlocks.length === 0) return;
  
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
    } catch (error) {
      console.warn('Failed to load Ruby WASM:', error);
      return;
    }

    rubyBlocks.forEach((pre, index) => {
      // Accept either explicit ruby code blocks or ruby-exec markers
      const codeBlock = pre.querySelector('code.language-ruby, code.ruby-exec');
      if (!codeBlock) return;

      const practiceChapter = pre.dataset.practiceChapter || codeBlock.dataset.practiceChapter;
      const practiceIndex = pre.dataset.practiceIndex ? parseInt(pre.dataset.practiceIndex, 10) : null;
      const practiceTest = pre.dataset.test || codeBlock.dataset.test || "";
      const isPracticeCheck = !!practiceChapter && !Number.isNaN(practiceIndex) && practiceTest.trim().length > 0;

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
        const runButton = document.createElement('button');
        runButton.className = 'run-button';
        runButton.textContent = isPracticeCheck ? '✔ Check' : '▶ Run';
        header.appendChild(runButton);

        // Insert output area after the <pre>
        pre.parentNode.insertBefore(outputArea, pre.nextSibling);

        // Add event listener for the run/check button
        runButton.addEventListener('click', async () => {
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
              "output = StringIO.new",
              "$stdout = output",
              "$stderr = output",
              "begin",
              "  sandbox = Module.new",
              `  sandbox.module_eval <<-'${heredocTag}'`,
              normalized,
              heredocTag,
              "  if sandbox.respond_to?(:main)",
              "    sandbox.main",
              "  end",
              "rescue Exception => e",
              "  output.puts(\"Error: #{e.class}: #{e.message}\")",
              "ensure",
              "  $stdout = STDOUT",
              "  $stderr = STDERR",
              "end"
            ];

            if (isPracticeCheck && practiceTest.trim().length > 0) {
              const testTag = 'RUBYTEST';
              programLines.push(
                "test_result = begin",
                `  !!(eval <<-'${testTag}')`,
                practiceTest,
                testTag,
                "rescue Exception => e",
                "  output.puts(\"Test error: #{e.class}: #{e.message}\")",
                "  false",
                "end",
                "output_text = output.string",
                "output_text + \"\\n__TEST__=#{test_result ? 'PASS' : 'FAIL'}\""
              );
            } else {
              programLines.push("output.string");
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
                // Only reveal "Show code" after at least one failed attempt
                const existing = header.querySelector('.show-solution-button');
                if (!existing) {
                  const showButton = document.createElement('button');
                  showButton.className = 'show-solution-button';
                  showButton.textContent = 'Show code';
                  header.appendChild(showButton);

                  showButton.addEventListener('click', () => {
                    try {
                      const solutionKey = `${practiceChapter}:${practiceIndex}`;
                      const solutionNode = document.querySelector(
                        `script[data-practice-solution="${solutionKey}"]`
                      );
                      if (!solutionNode) return;

                      const solution = solutionNode.textContent.replace(/^\s+|\s+$/g, '');
                      codeBlock.textContent = solution;
                      if (typeof Prism !== 'undefined') {
                        Prism.highlightElement(codeBlock);
                      }
                    } catch (_) {
                      // swallow errors; showing solutions is a convenience only
                    }
                  });
                }
              }
            }
          } catch (err) {
            outputContent.textContent = `Error: ${err.message}`;
          }
        });
      }
    });
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
