(function () {
  function onReady(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  }

  async function initPythonConsoles() {
    const consoles = document.querySelectorAll(".python-repl[data-python-console='true']");
    if (!consoles.length || !window.PythonRuntime) return;

    const py = await PythonRuntime.getPyodide();
    consoles.forEach(container => {
      if (container.dataset.pythonConsoleInitialized === "true") return;
      container.dataset.pythonConsoleInitialized = "true";
      const outputEl = container.querySelector(".python-repl-output");
      const form = container.querySelector(".python-repl-form");
      const input = container.querySelector(".python-repl-input");
      const promptEl = container.querySelector(".python-repl-prompt");
      if (!outputEl || !form || !input || !promptEl) return;

      let history = [];
      let historyIndex = -1;

      function appendLine(text, cssClass) {
        const line = document.createElement("div");
        line.className = "python-repl-line" + (cssClass ? " " + cssClass : "");
        line.textContent = text;
        outputEl.appendChild(line);
        outputEl.scrollTop = outputEl.scrollHeight;
      }

      appendLine("Python console powered by Pyodide. Type Python code and press Enter.", "python-repl-line--intro");
      appendLine('Try: 1 + 2, or print("hello")', "python-repl-line--intro");

      function setPrompt(continuation) {
        promptEl.textContent = continuation ? "... " : ">>> ";
      }

      setPrompt(false);

      form.addEventListener("submit", async (evt) => {
        evt.preventDefault();
        const code = input.value.trimEnd();
        if (!code) return;

        appendLine(promptEl.textContent + code, "python-repl-line--input");

        history.push(code);
        historyIndex = history.length;
        input.value = "";

        try {
          if (window.PythonRuntime.setPlotHandler && window.TypophicPlot) {
            PythonRuntime.setPlotHandler(spec => {
              outputEl.appendChild(window.TypophicPlot.render(spec));
            });
          }
          const result = await PythonRuntime.run(code);
          if (result && result.trim()) {
            result.split("\n").forEach(line => {
              if (line.length) appendLine(line, "python-repl-line--output");
            });
          }
        } catch (err) {
          appendLine(String(err), "python-repl-line--error");
        }

        setPrompt(false);
      });

      input.addEventListener("keydown", (evt) => {
        // History navigation
        if (evt.key === "ArrowUp") {
          if (history.length && historyIndex > 0) {
            historyIndex -= 1;
            input.value = history[historyIndex] || "";
            evt.preventDefault();
          }
        } else if (evt.key === "ArrowDown") {
          if (history.length && historyIndex < history.length) {
            historyIndex += 1;
            input.value = history[historyIndex] || "";
            evt.preventDefault();
          }
        } else if (evt.key === "Enter" && !evt.shiftKey) {
          form.dispatchEvent(new Event("submit", { cancelable: true, bubbles: false }));
          evt.preventDefault();
        }
      });
    });
  }

  async function initPythonConsoleDrawer() {
    const drawer = document.querySelector(".python-console-drawer");
    if (!drawer) return;
    const toggle = drawer.querySelector(".python-console-toggle");
    if (!toggle) return;

    const icon = toggle.querySelector(".python-console-toggle-icon");
    const input = drawer.querySelector(".python-repl-input");

    const setState = (open) => {
      drawer.classList.toggle("python-console-drawer--open", open);
      toggle.setAttribute("aria-expanded", open ? "true" : "false");
      if (icon) {
        icon.style.transform = open ? "rotate(180deg)" : "rotate(0deg)";
      }
      if (open && input) {
        setTimeout(() => input.focus(), 100);
      }
    };

    toggle.addEventListener("click", () => {
      const open = !drawer.classList.contains("python-console-drawer--open");
      setState(open);
    });

    // Console starts open inside tutorials so learners see it immediately.
    setState(true);
  }

  onReady(() => {
    initPythonConsoleDrawer();
    initPythonConsoles();
  });

  // If the runtime loads after this script, initialise consoles when it
  // reports ready.
  document.addEventListener("PythonRuntimeLoaded", () => {
    initPythonConsoles();
  });
})();
