document.addEventListener('DOMContentLoaded', async () => {
  if (typeof Prism !== 'undefined') Prism.highlightAll();
  addCopyButtonsToCodeBlocks();
  await addRubyExecSupport();
});

async function setupRubyWasm() {
  const script = document.createElement('script');
  script.src = 'https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.7.1/dist/browser/+esm';
  script.type = 'module';
  document.head.appendChild(script);

  return new Promise((resolve, reject) => {
    script.onload = resolve;
    script.onerror = reject;
  });
}

async function addRubyExecSupport() {
  await setupRubyWasm();

  // Load the Ruby WASM module
  const response = await fetch('https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.7.1/dist/ruby+stdlib.wasm');
  const module = await WebAssembly.compileStreaming(response);
  const { DefaultRubyVM } = await import('https://cdn.jsdelivr.net/npm/@ruby/wasm-wasi@2.7.1/dist/browser/+esm');
  const { vm } = await DefaultRubyVM(module);

  document.querySelectorAll('.code-window pre.language-ruby').forEach((pre, index) => {
    const codeBlock = pre.querySelector('code.language-ruby');
    if (!codeBlock) return;

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

    // Add run button to the header
    const header = pre.closest('.code-window').querySelector('.code-header');
    const runButton = document.createElement('button');
    runButton.className = 'run-button';
    runButton.textContent = '▶ Run Ruby';
    header.appendChild(runButton);

    // Insert output area after the <pre>
    pre.parentNode.insertBefore(outputArea, pre.nextSibling);

    // Add event listener for the run button
    runButton.addEventListener('click', async () => {
      const rubyCode = pre.textContent.trim();
      outputContent.textContent = 'Executing Ruby code...\n';

      try {
        // Execute Ruby code with output redirection
        const result = vm.eval(`
          require 'stringio'
          output = StringIO.new
          $stdout = output
          $stderr = output
          begin
            ${rubyCode}
          rescue StandardError => e
            "Error: \#{e.message}\n\#{e.backtrace.join('\\n')}"
          ensure
            $stdout = STDOUT
            $stderr = STDERR
          end
          output.string
        `);

        // Display the captured output
        outputContent.textContent = result || 'Execution completed successfully.';
      } catch (err) {
        outputContent.textContent = `Error: ${err.message}\n${err.stack}`;
      }
    });
  });
}

function addCopyButtonsToCodeBlocks() {
  document.querySelectorAll('pre > code').forEach(codeBlock => {
    const pre = codeBlock.parentNode;

    // Transfer language class from code to pre
    const langClass = codeBlock.className
      .split(' ')
      .find(c => c.startsWith('language-'));
    if (langClass) pre.className = langClass;

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
          <span class="window-title">${langClass
            ? langClass.replace('language-', '') +
              (langClass.includes('ruby') ? '.rb' : '')
            : 'code'}</span>`
      });
      codeWindow.insertBefore(header, pre);
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
