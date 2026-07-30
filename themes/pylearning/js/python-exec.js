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

        // Plots live outside the height-capped scroll window so figures
        // never get chopped.
        const plotArea = document.createElement("div");
        plotArea.className = "plot-area";
        codeWindow.appendChild(plotArea);

        const runButton = document.createElement("button");
        runButton.className = "run-button";
        runButton.innerHTML = "▶&nbsp;Run";
        header.appendChild(runButton);

        // One button, two states: Run while idle, Stop while this cell runs.
        const setRunState = (running) => {
          if (running) {
            runButton.classList.add("is-stop");
            runButton.innerHTML = "&#9632;&nbsp;Stop";
            runButton.title = "Stop this run and restart the Python runtime (its memory resets; re-run earlier cells)";
          } else {
            runButton.classList.remove("is-stop");
            runButton.innerHTML = "▶&nbsp;Run";
            runButton.title = "";
          }
        };

        // Append streamed text like a terminal: \r rewrites the current
        // line (PyTorch-style ASCII progress bars), \n scrolls up inside
        // the fixed-height window.
        const appendTerminalText = (text) => {
          if (outputContent.dataset.queued === "1") {
            outputContent.textContent = "";
            delete outputContent.dataset.queued;
          }
          let cur = outputContent.textContent;
          for (const ch of text) {
            if (ch === "\r") {
              const i = cur.lastIndexOf("\n");
              cur = cur.slice(0, i + 1);
            } else {
              cur += ch;
            }
          }
          outputContent.textContent = cur;
          outputArea.scrollTop = outputArea.scrollHeight;
        };

        // Notebook semantics: before the first Run ANYWHERE on this page,
        // execute every earlier Python block (exec cells and plain data
        // blocks) so shared names just exist. The flag is PAGE-WIDE: once
        // anything has run, later cells trust the namespace instead of
        // replaying the whole training for every window. On heavy chapters
        // the replay is streamed visibly.
        const collectContextCode = () => {
          const wins = [...document.querySelectorAll(".code-window")];
          const idx = wins.indexOf(codeWindow);
          const ctx = [];
          for (let i = 0; i >= 0 && i < idx; i++) {
            const c = wins[i].querySelector("pre code.python-exec, pre code.language-python");
            if (c && c.textContent.trim()) ctx.push(c.textContent);
          }
          return ctx.join("\n\n");
        };

        const runCell = async () => {
          if (codeWindow.dataset.running === "1") return; // click while running = Stop, handled below
          codeWindow.dataset.running = "1";
          setRunState(true);
          const code = currentCode.trimEnd();
          try {
            if (!window.__typophicContextReady) {
              window.__typophicContextReady = true;
              const ctx = collectContextCode();
              if (ctx.trim()) {
                appendTerminalText("Preparing this page: running the earlier cells first " +
                  "(on training chapters this takes a few minutes - watch the progress below)\n\n");
                try { await PythonRuntime.run(ctx, appendTerminalText); } catch (_) { /* context best-effort */ }
                appendTerminalText("\n--- earlier cells done, running THIS cell ---\n");
              }
            }
            plotArea.querySelectorAll(".typophic-plot").forEach(p => p.remove());
            if (window.PythonRuntime.isBusy && PythonRuntime.isBusy()) {
              outputContent.textContent = "queued - this cell will run as soon as the current one finishes...\n";
              outputContent.dataset.queued = "1";
            }
            // Route this run's figures to THIS window's plot area - a
            // later click elsewhere must not steal them.
            const onPlot = (window.TypophicPlot)
              ? (spec) => { plotArea.appendChild(window.TypophicPlot.render(spec)); }
              : null;
            const result = await PythonRuntime.run(code, appendTerminalText, onPlot);
            // Main-thread fallback has no streaming; use the final buffer.
            if (!outputContent.textContent) {
              appendTerminalText(result || "");
            }
          } catch (err) {
            appendTerminalText("\n" + String(err && err.message ? err.message : err) + "\n");
          } finally {
            outputArea.scrollTop = outputArea.scrollHeight;
            delete codeWindow.dataset.running;
            setRunState(false);
          }
        };

        // Exposed so the corpus-upload widget can re-run cells in order.
        codeWindow.runCell = runCell;
        codeWindow.markContextReady = () => { window.__typophicContextReady = true; };
        // The single button toggles: idle = Run, while this cell runs = Stop.
        runButton.addEventListener("click", () => {
          if (codeWindow.dataset.running === "1") {
            if (window.PythonRuntime && window.PythonRuntime.restart) {
              appendTerminalText("\nStopping and restarting the Python runtime (memory reset; re-run earlier cells)...\n");
              window.PythonRuntime.restart("manual stop");
            }
          } else {
            runCell();
          }
        });

        // Surface runtime restarts (crash/watchdog/manual) in every window.
        if (!window.__typophicRestartListenerAdded) {
          window.__typophicRestartListenerAdded = true;
          document.addEventListener("PythonRuntimeRestarted", (ev) => {
            // The worker's memory was wiped, so the page's "context already
            // ran" flag is now a lie: the next click must replay earlier
            // cells to rebuild the namespace.
            window.__typophicContextReady = false;
            document.querySelectorAll(".code-window .output-content").forEach((oc) => {
              oc.textContent += "\n[Python runtime was restarted" +
                (ev.detail && ev.detail.reason ? ": " + ev.detail.reason : "") +
                ". Its memory was reset - re-run earlier cells before this one.]\n";
            });
          });
        }
      }
    });

    // "Run all cells" bar above the first code window: notebook-style
    // sequential execution of every runnable cell on the page, in order.
    if (!document.querySelector(".run-all-bar")) {
      const execWindows = [...document.querySelectorAll(".code-window")]
        .filter(cw => typeof cw.runCell === "function");
      if (execWindows.length >= 2) {
        const bar = document.createElement("div");
        bar.className = "run-all-bar";
        const btn = document.createElement("button");
        btn.className = "run-all-button";
        btn.innerHTML = "▶&nbsp;Run all cells";
        bar.appendChild(btn);
        const note = document.createElement("span");
        note.className = "run-all-note";
        note.textContent = "runs every cell on this page top to bottom, in the shared namespace";
        bar.appendChild(note);
        // Place it at the top of the chapter, right after the header
        // (title, author, difficulty badge); fall back to the first cell.
        const header = document.querySelector(".tutorial-header");
        if (header && header.parentNode) {
          header.parentNode.insertBefore(bar, header.nextSibling);
        } else {
          execWindows[0].parentNode.insertBefore(bar, execWindows[0]);
        }

        btn.addEventListener("click", async () => {
          if (btn.disabled) return;
          btn.disabled = true;
          // Wait for corpus datasets (sprites_text, coco_text, ...) to land.
          const markers = [...document.querySelectorAll("[data-corpus-url]")];
          if (markers.length) {
            btn.innerHTML = "Loading datasets&#8230;";
            const t0 = Date.now();
            while (markers.some(m => !m.dataset.corpusReady) && Date.now() - t0 < 120000) {
              await new Promise(r => setTimeout(r, 300));
            }
          }
          // Every cell runs once, in order, so defs accumulate naturally and
          // no per-cell context replay is needed.
          execWindows.forEach(cw => { if (cw.markContextReady) cw.markContextReady(); });
          for (let i = 0; i < execWindows.length; i++) {
            btn.innerHTML = `Running ${i + 1}/${execWindows.length}&#8230;`;
            try { await execWindows[i].runCell(); } catch (_) { /* keep going */ }
          }
          btn.innerHTML = "▶&nbsp;Run all cells";
          btn.disabled = false;
        });
      }
    }
  }

  // Turns <div data-corpus-url="/path/file.csv" data-corpus-var="moons_text">
  // markers into an auto-loaded dataset: the file is fetched once from the
  // site itself and stored in the shared Pyodide namespace under the given
  // variable name, so chapter cells can train on committed micro datasets
  // entirely in the browser.
  function initCorpusUrls() {
    document.querySelectorAll("[data-corpus-url]").forEach(async (marker) => {
      if (marker.dataset.corpusUrlInitialized === "true") return;
      marker.dataset.corpusUrlInitialized = "true";
      const url = marker.getAttribute("data-corpus-url");
      const varName = marker.getAttribute("data-corpus-var") || "dataset_text";
      const status = document.createElement("div");
      status.className = "corpus-url-status";
      status.style.cssText = "margin:0.5rem 0;font-size:0.9em;opacity:0.85;";
      status.textContent = "Loading dataset " + url + " ...";
      marker.appendChild(status);
      try {
        const resp = await fetch(url);
        if (!resp.ok) throw new Error("HTTP " + resp.status + " (server may need a rebuild)");
        const text = await resp.text();
        if (/^\s*</.test(text)) throw new Error("got an HTML page instead of data - the site build is stale, rebuild with --no-incremental");
        const py = await PythonRuntime.getPyodide();
        py.globals.set(varName, text);
        marker.dataset.corpusReady = "1";
        status.textContent = "Dataset ready: " + url.split("/").pop() +
          " (" + (text.split("\n").length - 1) + " rows) loaded as `" + varName + "`.";
      } catch (err) {
        marker.dataset.corpusReady = "error";
        status.textContent = "Could not load " + url + ": " + err;
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
              `Loaded "${file.name}" (${text.length.toLocaleString()} characters). `;

            // Offer an explicit retrain instead of starting automatically.
            let btn = wrap.querySelector(".corpus-retrain-btn");
            if (btn) btn.remove();
            btn = document.createElement("button");
            btn.className = "corpus-retrain-btn run-button";
            btn.textContent = "▶ Retrain on this corpus (~1 min)";
            btn.style.marginLeft = "0.5rem";
            wrap.insertBefore(btn, status);

            btn.addEventListener("click", async () => {
              btn.disabled = true;
              status.textContent =
                `Retraining on "${file.name}" - running every cell in order (about a minute)...`;
              const cells = [...document.querySelectorAll(".code-window")]
                .filter(cw => typeof cw.runCell === "function");
              for (const cw of cells) {
                await cw.runCell();
              }
              status.textContent =
                `Trained on "${file.name}" (${text.length.toLocaleString()} characters). ` +
                `Plots and generated text below now use your corpus.`;
              btn.disabled = false;
            });
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
  initCorpusUrls();
  });

  document.addEventListener("PythonRuntimeLoaded", () => {
    initPythonExecBlocks();
  });
})();
