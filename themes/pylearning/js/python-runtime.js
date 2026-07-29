/* Python runtime facade: executes code in a Web Worker (python-worker.js)
 * so heavy cells never block the page's main thread. Falls back to running
 * Pyodide on the main thread when Workers are unavailable or fail to start.
 *
 * Public API (unchanged):
 *   PythonRuntime.run(code)           -> Promise<string> (stdout+tracebacks)
 *   PythonRuntime.setPlotHandler(fn)  -> receives plt.show() figure specs
 *   PythonRuntime.getPyodide()        -> facade with globals.set(name, value)
 *   PythonRuntime.ready()             -> Promise resolving when usable
 *   PythonRuntime.isWorker()          -> true when running in a Web Worker
 */
(function () {
  const CDN_PYODIDE_URL = "https://cdn.jsdelivr.net/pyodide/v0.25.1/full/pyodide.js";
  const CDN_PYODIDE_INDEX = "https://cdn.jsdelivr.net/pyodide/v0.25.1/full/";

  function normalizeDir(path) {
    if (!path) return "";
    return path.endsWith("/") ? path : path + "/";
  }

  // Allow overriding the Pyodide location so we can host it locally.
  // Priority:
  //   1) window.TypophicPythonRuntimeConfig.{scriptURL, indexURL, baseURL}
  //   2) <meta name="pyodide-base" content="...">
  //   3) CDN defaults.
  function resolveOverrideConfig() {
    try {
      if (typeof window !== "undefined" && window.TypophicPythonRuntimeConfig) {
        const cfg = window.TypophicPythonRuntimeConfig || {};
        if (cfg.scriptURL || cfg.indexURL || cfg.baseURL) {
          const base = cfg.baseURL || "";
          const indexURL = cfg.indexURL || (base ? normalizeDir(base) : CDN_PYODIDE_INDEX);
          const scriptURL = cfg.scriptURL || (indexURL + "pyodide.js");
          return { url: scriptURL, index: normalizeDir(indexURL) };
        }
      }

      if (typeof document !== "undefined") {
        const meta = document.querySelector('meta[name="pyodide-base"]');
        if (meta && meta.content) {
          let base = meta.content.trim();
          if (base) {
            if (base.endsWith("pyodide.js")) {
              const index = base.replace(/pyodide\.js$/, "");
              return { url: base, index: normalizeDir(index) };
            }
            const index = normalizeDir(base);
            return { url: index + "pyodide.js", index };
          }
        }
      }
    } catch (_e) {
      // Fall through to CDN defaults.
    }
    return null;
  }

  function pyodideCandidates() {
    const candidates = [];
    const override = resolveOverrideConfig();
    if (override) candidates.push(override);
    candidates.push({ url: CDN_PYODIDE_URL, index: CDN_PYODIDE_INDEX });
    return candidates;
  }

  function workerScriptURL() {
    try {
      const current =
        document.currentScript ||
        document.querySelector('script[src*="python-runtime.js"]');
      if (current && current.src) {
        return new URL("python-worker.js", current.src).href;
      }
    } catch (_e) { /* fall through */ }
    return "/themes/pylearning/js/python-worker.js";
  }

  let plotHandler = null;
  let streamHandler = null;

  function setPlotHandler(fn) {
    plotHandler = fn;
  }

  function setStreamHandler(fn) {
    streamHandler = fn;
  }

  function emitPlots(specs) {
    if (!plotHandler || !Array.isArray(specs)) return;
    specs.forEach((spec) => {
      try {
        plotHandler(spec);
      } catch (_e) { /* ignore render errors */ }
    });
  }

  // ---------------------------------------------------------------- worker
  let workerState = null; // { worker, pending: Map, queue: Promise, mode }

  function initWorker() {
    if (typeof Worker === "undefined") {
      return Promise.reject(new Error("Web Workers unavailable"));
    }

    return new Promise((resolve, reject) => {
      let worker;
      try {
        worker = new Worker(workerScriptURL());
      } catch (err) {
        reject(err);
        return;
      }

      const pending = new Map();
      let nextId = 0;
      let settled = false;

      const state = {
        mode: "worker",
        worker,
        pending,
        queue: Promise.resolve(),
        run(code) {
          const id = ++nextId;
          const task = new Promise((resolveRun) => {
            pending.set(id, resolveRun);
            worker.postMessage({ type: "run", id, code });
          });
          // Serialize runs so the shared namespace behaves like notebook cells.
          const chained = state.queue.then(() => task);
          state.queue = chained.catch(() => {});
          return chained;
        },
        set(name, value) {
          worker.postMessage({ type: "set", name, value });
        }
      };

      const initTimeout = setTimeout(() => {
        if (!settled) {
          settled = true;
          worker.terminate();
          reject(new Error("Pyodide worker init timed out"));
        }
      }, 180000);

      worker.onmessage = (e) => {
        const msg = e.data || {};
        if (msg.type === "ready") {
          if (!settled) {
            settled = true;
            clearTimeout(initTimeout);
            workerState = state;
            resolve(state);
          }
          return;
        }
        if (msg.type === "error") {
          if (!settled) {
            settled = true;
            clearTimeout(initTimeout);
            worker.terminate();
            reject(new Error(msg.error || "Pyodide worker failed"));
          }
          return;
        }
        if (msg.type === "stream") {
          if (streamHandler) {
            try {
              streamHandler(String(msg.text || ""));
            } catch (_e) { /* ignore */ }
          }
          return;
        }
        if (msg.type === "result") {
          const resolveRun = pending.get(msg.id);
          if (resolveRun) {
            pending.delete(msg.id);
            emitPlots(msg.plots);
            resolveRun(String(msg.result || ""));
          }
        }
      };

      worker.onerror = (e) => {
        if (!settled) {
          settled = true;
          clearTimeout(initTimeout);
          reject(new Error(e.message || "Pyodide worker error"));
        }
      };

      const shim =
        window.TypophicPlot && window.TypophicPlot.shimSource
          ? window.TypophicPlot.shimSource
          : "";

      // One init attempt in the worker (override config if present, else the
      // default CDN). On failure the caller falls back to the main thread,
      // which retries all candidates itself.
      const cfg = pyodideCandidates()[0];
      worker.postMessage({ type: "init", url: cfg.url, index: cfg.index, shim });
    });
  }

  // ---------------------------------------------------- main-thread backup
  async function loadScriptOnce(src) {
    return new Promise((resolve, reject) => {
      const existing = document.querySelector(`script[src="${src}"]`);
      if (existing) {
        if (existing.dataset.loaded === "true") return resolve();
        existing.addEventListener("load", () => resolve(), { once: true });
        existing.addEventListener("error", () => reject(new Error(`Failed to load ${src}`)), { once: true });
        return;
      }

      const script = document.createElement("script");
      script.src = src;
      script.async = true;
      script.onload = () => {
        script.dataset.loaded = "true";
        resolve();
      };
      script.onerror = () => reject(new Error(`Failed to load ${src}`));
      document.head.appendChild(script);
    });
  }

  async function initMainThread() {
    let lastError = null;
    for (const cfg of pyodideCandidates()) {
      try {
        await loadScriptOnce(cfg.url);
        if (typeof loadPyodide !== "function") {
          throw new Error("loadPyodide is not available after loading pyodide.js");
        }
        const instance = await loadPyodide({ indexURL: cfg.index });
        instance.globals.set("_typophic_emit_plot", (payload) => {
          if (!plotHandler) return;
          try {
            plotHandler(JSON.parse(payload));
          } catch (_e) { /* ignore malformed plot specs */ }
        });
        if (window.TypophicPlot && window.TypophicPlot.shimSource) {
          await instance.runPythonAsync(window.TypophicPlot.shimSource);
        }

        const state = {
          mode: "main",
          queue: Promise.resolve(),
          run(code) {
            const task = async () => {
              if (typeof instance.loadPackagesFromImports === "function") {
                try {
                  await instance.loadPackagesFromImports(code);
                } catch (_e) { /* import error surfaces in output */ }
              }
              instance.globals.set("__typophic_code", code);
              const result = await instance.runPythonAsync(`
import sys, io, traceback
_stdout = sys.stdout
_stderr = sys.stderr
buf = io.StringIO()
sys.stdout = buf
sys.stderr = buf
ns = globals()
try:
    try:
        compiled = compile(__typophic_code, "<console>", "eval")
    except SyntaxError:
        compiled = None

    if compiled is not None:
        result = eval(compiled, ns)
        if result is not None:
            print(repr(result))
    else:
        exec(__typophic_code, ns)
except Exception:
    traceback.print_exc()
finally:
    sys.stdout = _stdout
    sys.stderr = _stderr
buf.getvalue()
`);
              return String(result || "");
            };
            const chained = state.queue.then(task);
            state.queue = chained.catch(() => {});
            return chained;
          },
          set(name, value) {
            instance.globals.set(name, value);
          }
        };
        workerState = state;
        return state;
      } catch (err) {
        lastError = err;
      }
    }
    throw lastError || new Error("Failed to initialise Pyodide");
  }

  // ------------------------------------------------------------ public API
  let readyPromise = null;

  function ready() {
    if (!readyPromise) {
      readyPromise = initWorker().catch(() => initMainThread());
    }
    return readyPromise;
  }

  async function runPython(code) {
    const state = await ready();
    return state.run(code);
  }

  // Compatibility facade for callers that used to touch pyodide directly
  // (e.g. the corpus upload widget setting globals).
  async function getPyodideFacade() {
    const state = await ready();
    return {
      globals: {
        set(name, value) {
          state.set(name, value);
        }
      }
    };
  }

  window.PythonRuntime = {
    getPyodide: getPyodideFacade,
    run: runPython,
    setPlotHandler: setPlotHandler,
    setStreamHandler: setStreamHandler,
    ready: ready,
    isWorker: () => !!(workerState && workerState.mode === "worker")
  };

  // Mark readiness for pages/tests that wait on the runtime.
  ready().then(() => {
    window.pyodide = { viaWorker: workerState && workerState.mode === "worker" };
  }).catch(() => {});

  // Let other scripts know that the PythonRuntime shim is available. This
  // fires before the actual Pyodide runtime has finished loading; callers
  // should still await getPyodide() as needed.
  if (typeof document !== "undefined" && document.dispatchEvent) {
    try {
      document.dispatchEvent(new Event("PythonRuntimeLoaded"));
    } catch (_e) {
      // IE11-style fallback, just in case
      try {
        var evt = document.createEvent("Event");
        evt.initEvent("PythonRuntimeLoaded", false, false);
        document.dispatchEvent(evt);
      } catch (_ignored) {}
    }
  }
})();
