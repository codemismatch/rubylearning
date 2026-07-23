(function () {
  function onReady(fn) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
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
          const code = codeEl.textContent.trimEnd();
          outputContent.textContent = "Running Python code...\n";
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

  onReady(() => {
    initPythonExecBlocks();
  });

  document.addEventListener("PythonRuntimeLoaded", () => {
    initPythonExecBlocks();
  });
})();
