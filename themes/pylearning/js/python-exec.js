(function () {
  function onReady(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  }

  function escapeHtml(text) {
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  // Prism-based Python highlighter for the editable overlay.
  function highlightPythonInline(code) {
    if (window.Prism && Prism.languages && Prism.languages.python) {
      try {
        return Prism.highlight(code, Prism.languages.python, "python");
      } catch (_) { /* fall through */ }
    }
    return escapeHtml(code);
  }

  async function initPythonExecBlocks() {
    if (!window.PythonRuntime) return;
    const blocks = document.querySelectorAll(".code-window pre[data-executable='true']");
    if (!blocks.length) return;

    blocks.forEach((pre) => {
      const codeEl = pre.querySelector("code");
      if (!codeEl) return;

      const isPythonBlock =
        codeEl.classList.contains("python-exec") ||
        codeEl.classList.contains("language-python");
      if (!isPythonBlock) return;

      const codeWindow = pre.closest(".code-window");
      if (!codeWindow) return;

      if (codeWindow.dataset.pythonExecInitialized === "true") return;
      codeWindow.dataset.pythonExecInitialized = "true";

      // Remove any generic loading indicator added at render time so the
      // Python-specific controls don't overlap with it.
      const genericLoading = codeWindow.querySelector(".loading-indicator");
      if (genericLoading) {
        genericLoading.remove();
      }

      let header = codeWindow.querySelector(".code-header");
      if (!header) {
        header = document.createElement("div");
        header.className = "code-header";
        codeWindow.insertBefore(header, codeWindow.firstChild);
      }

      // Make the cell editable (notebook-style) when the overlay editor is
      // available. `currentCode` always holds the latest (possibly edited)
      // source and is what Run executes.
      let currentCode = codeEl.textContent.replace(/\n$/, "");
      if (window.CodeOverlayEditor && !pre.dataset.pythonEditorReady) {
        pre.dataset.pythonEditorReady = "true";
        window.CodeOverlayEditor.initOverlayEditor(pre, codeEl, currentCode, (latest) => {
          currentCode = latest;
        }, highlightPythonInline);
      }

      if (!header.querySelector(".run-button")) {
        const outputArea = document.createElement("div");
        outputArea.className = "output-area";
        const outputContent = document.createElement("pre");
        outputContent.className = "output-content";
        outputArea.appendChild(outputContent);
        codeWindow.appendChild(outputArea);

        const runButton = document.createElement("button");
        runButton.className = "run-button";
        runButton.innerHTML = "▶&nbsp;Run";
        header.appendChild(runButton);

        runButton.addEventListener("click", async () => {
          const code = currentCode.trimEnd();
          outputContent.textContent = "Running Python code...\n";
          // Route plt.show() figures into this block's output area.
          outputArea.querySelectorAll(".typophic-plot").forEach(p => p.remove());
          if (window.PythonRuntime.setPlotHandler && window.TypophicPlot) {
            PythonRuntime.setPlotHandler(spec => {
              outputArea.appendChild(window.TypophicPlot.render(spec));
            });
          }
          try {
            const result = await PythonRuntime.run(code);
            outputContent.textContent = result || "";
          } catch (err) {
            outputContent.textContent = String(err);
          }
        });
      }
    });
  }

  // Turns <div data-corpus-upload="variable_name"> markers into a file-upload
  // widget. The uploaded .txt content is stored in the shared Pyodide
  // namespace under `variable_name`, so chapter cells can train on it.
  function initCorpusUploads() {
    document.querySelectorAll("[data-corpus-upload]").forEach((marker) => {
      if (marker.dataset.corpusInitialized === "true") return;
      marker.dataset.corpusInitialized = "true";

      const varName = marker.getAttribute("data-corpus-upload") || "uploaded_corpus_text";

      const wrap = document.createElement("div");
      wrap.className = "corpus-upload";
      wrap.style.cssText =
        "border:1px dashed var(--primary-color,#2563eb);border-radius:8px;padding:1rem;margin:1rem 0;";

      const label = document.createElement("strong");
      label.textContent = "Train on your own text: ";
      wrap.appendChild(label);

      const input = document.createElement("input");
      input.type = "file";
      input.accept = ".txt,text/plain";
      wrap.appendChild(input);

      const status = document.createElement("div");
      status.className = "corpus-upload-status";
      status.style.cssText = "margin-top:0.5rem;font-size:0.9em;opacity:0.85;";
      status.textContent = "No file chosen - the chapter's built-in corpus is used.";
      wrap.appendChild(status);

      input.addEventListener("change", () => {
        const file = input.files && input.files[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = async () => {
          const text = String(reader.result || "");
          try {
            const py = await PythonRuntime.getPyodide();
            py.globals.set(varName, text);
            status.textContent =
              `Loaded "${file.name}" (${text.length.toLocaleString()} characters) ` +
              `into \`${varName}\`. Re-run the tokenizer cell and everything below it to retrain.`;
          } catch (err) {
            status.textContent = "Could not load corpus: " + String(err);
          }
        };
        reader.readAsText(file);
      });

      marker.parentNode.replaceChild(wrap, marker);
    });
  }

  onReady(() => {
    initPythonExecBlocks();
    initCorpusUploads();
  });

  document.addEventListener("PythonRuntimeLoaded", () => {
    initPythonExecBlocks();
  });
})();
