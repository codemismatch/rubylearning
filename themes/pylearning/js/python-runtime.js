/* Python runtime facade: executes code in a Web Worker (python-worker.js)
 * so heavy cells never block the page's main thread. Falls back to running
 * Pyodide on the main thread when Workers are unavailable or fail to start.
 *
 * Hardened 2026-07-29:
 *   - Runs are TRULY serialized: code is only posted to the worker once the
 *     previous run has resolved (previously the post went out immediately,
 *     so a second Run corrupted the in-flight one's state).
 *   - Watchdog: a run that never resolves (worker OOM/crash) rejects, the
 *     worker is restarted, and the queue keeps moving instead of hanging
 *     every later Run forever.
 *   - PythonRuntime.restart(): manual escape hatch; corpus variables set via
 *     globals.set are replayed after the restart.
 *
 * Public API:
 *   PythonRuntime.run(code)           -> Promise<string> (stdout+tracebacks)
 *   PythonRuntime.setPlotHandler(fn)  -> receives plt.show() figure specs
 *   PythonRuntime.getPyodide()        -> facade with globals.set(name, value)
 *   PythonRuntime.ready()             -> Promise resolving when usable
 *   PythonRuntime.isWorker()          -> true when running in a Web Worker
 *   PythonRuntime.restart()           -> kill and re-init (namespace resets)
 */
(function () {
  const CDN_PYODIDE_URL = "https://cdn.jsdelivr.net/pyodide/v0.25.1/full/pyodide.js";
  const CDN_PYODIDE_INDEX = "https://cdn.jsdelivr.net/pyodide/v0.25.1/full/";
  const RUN_SILENCE_MS = 6 * 60 * 1000; // no output for 6 min = dead; active cells stream progress bars

  function normalizeDir(path) {
    if (!path) return "";
    return path.endsWith("/") ? path : path + "/";
  }

  // Allow overriding the Pyodide location so we can host it locally.
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

  function emitPlots(specs, onPlot) {
    const handler = onPlot || plotHandler;
    if (!handler || !Array.isArray(specs)) return;
    specs.forEach((spec) => {
      try {
        handler(spec);
      } catch (_e) { /* ignore render errors */ }
    });
  }

  // Globals set through the facade are remembered so they can be replayed
  // after a worker restart (corpus datasets like sprites_text survive).
  const savedGlobals = new Map();

  // ---------------------------------------------------------------- worker
  let workerState = null; // { worker, pending: Map, queue: Promise, mode }
  let readyPromise = null;
  let restarting = false;

  function notifyRestart(reason) {
    try {
      document.dispatchEvent(new CustomEvent("PythonRuntimeRestarted", { detail: { reason } }));
    } catch (_e) { /* non-browser env */ }
  }

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

      const rejectAllPending = (message) => {
        pending.forEach((entry) => {
          try { entry.reject(new Error(message)); } catch (_e) { /* noop */ }
        });
        pending.clear();
      };

      const state = {
        mode: "worker",
        worker,
        pending,
        queue: Promise.resolve(),
        inFlight: 0,
        run(code, onStream, onPlot) {
          // Serialize EXECUTION, not just resolution: the code is only posted
          // once the previous run fully resolved. Queue is kept resolved at
          // all times so one failure never stalls later runs.
          const exec = () => new Promise((resolveRun, rejectRun) => {
            const id = ++nextId;
            // Silence watchdog: a live training cell streams progress output,
            // a dead/OOM'd worker goes quiet. Kill only on 6 min of silence,
            // never on total runtime - hour-long runs are fine.
            const arm = () => setTimeout(() => {
              pending.delete(id);
              crashAndRestart("run went silent");
              rejectRun(new Error(
                "This run produced no output for 6 minutes and the runtime was restarted. " +
                "Re-run the earlier cells to rebuild its memory."
              ));
            }, RUN_SILENCE_MS);
            let watchdog = arm();
            pending.set(id, {
              resolve: (v) => { clearTimeout(watchdog); resolveRun(v); },
              reject: (e) => { clearTimeout(watchdog); rejectRun(e); },
              onStream: (text) => {
                clearTimeout(watchdog);
                watchdog = arm();
                if (onStream) onStream(text);
              },
              onPlot
            });
            worker.postMessage({ type: "run", id, code });
          });
          state.inFlight += 1;
          const chained = state.queue.then(exec);
          state.queue = chained.catch(() => {});
          return chained.finally(() => { state.inFlight -= 1; });
        },
        set(name, value) {
          savedGlobals.set(name, value);
          worker.postMessage({ type: "set", name, value });
        },
        crash(message) {
          rejectAllPending(message);
        }
      };

      function crashAndRestart(reason) {
        if (restarting) return;
        restarting = true;
        rejectAllPending(
          "The Python runtime crashed (" + reason + ") and was restarted. " +
          "Re-run the earlier cells to rebuild its memory."
        );
        try { worker.terminate(); } catch (_e) { /* noop */ }
        workerState = null;
        readyPromise = null;
        notifyRestart(reason);
        ready().finally(() => { restarting = false; });
      }
      state._crashAndRestart = crashAndRestart;

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
            // Replay remembered globals (corpus datasets) before any run;
            // postMessages are FIFO, so runs posted after this arrive last.
            savedGlobals.forEach((value, name) => {
              worker.postMessage({ type: "set", name, value });
            });
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
          const entry = pending.get(msg.id);
          const handler = (entry && entry.onStream) || streamHandler;
          if (handler) {
            try {
              handler(String(msg.text || ""));
            } catch (_e) { /* ignore */ }
          }
          return;
        }
        if (msg.type === "result") {
          const entry = pending.get(msg.id);
          if (entry) {
            pending.delete(msg.id);
            emitPlots(msg.plots, entry.onPlot);
            entry.resolve(String(msg.result || ""));
          }
        }
      };

      worker.onerror = (e) => {
        if (!settled) {
          settled = true;
          clearTimeout(initTimeout);
          reject(new Error(e.message || "Pyodide worker error"));
          return;
        }
        // Crash during a run (e.g. WASM OOM): nothing will ever resolve again.
        crashAndRestart(e.message || "worker error");
      };

      const shim =
        window.TypophicPlot && window.TypophicPlot.shimSource
          ? window.TypophicPlot.shimSource
          : "";

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
        // Replay remembered globals (corpus datasets).
        savedGlobals.forEach((value, name) => {
          try { instance.globals.set(name, value); } catch (_e) { /* noop */ }
        });

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
            const chained = state.queue.then(task, task);
            state.queue = chained.catch(() => {});
            return chained;
          },
          set(name, value) {
            savedGlobals.set(name, value);
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
  function ready() {
    if (!readyPromise) {
      readyPromise = initWorker().catch(() => initMainThread());
    }
    return readyPromise;
  }

  async function runPython(code, onStream, onPlot) {
    const state = await ready();
    return state.run(code, onStream, onPlot);
  }

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

  async function restart(reason) {
    if (workerState && workerState._crashAndRestart) {
      workerState._crashAndRestart(reason || "manual stop");
      return;
    }
    // Main-thread mode cannot be killed; clear queue state and re-init facade.
    workerState = null;
    readyPromise = null;
    notifyRestart(reason || "manual stop");
    await ready();
  }

  window.PythonRuntime = {
    getPyodide: getPyodideFacade,
    run: runPython,
    restart: restart,
    setPlotHandler: setPlotHandler,
    setStreamHandler: setStreamHandler,
    ready: ready,
    isWorker: () => !!(workerState && workerState.mode === "worker"),
    isBusy: () => !!(workerState && workerState.inFlight > 0)
  };

  // Mark readiness for pages/tests that wait on the runtime.
  ready().then(() => {
    window.pyodide = { viaWorker: workerState && workerState.mode === "worker" };
  }).catch(() => {});

  // Let other scripts know that the PythonRuntime shim is available.
  if (typeof document !== "undefined" && document.dispatchEvent) {
    try {
      document.dispatchEvent(new Event("PythonRuntimeLoaded"));
    } catch (_e) {
      try {
        var evt = document.createEvent("Event");
        evt.initEvent("PythonRuntimeLoaded", false, false);
        document.dispatchEvent(evt);
      } catch (_ignored) {}
    }
  }
})();
