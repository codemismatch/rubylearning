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

  let pyodidePromise = null;

  async function getPyodideInstance() {
    if (window.pyodide) return window.pyodide;
    if (!pyodidePromise) {
      pyodidePromise = (async () => {
        const override = resolveOverrideConfig();
        const candidates = [];
        if (override) candidates.push(override);
        // Always keep CDN as a reliable fallback.
        candidates.push({ url: CDN_PYODIDE_URL, index: CDN_PYODIDE_INDEX });

        let lastError = null;

        for (const cfg of candidates) {
          try {
            await loadScriptOnce(cfg.url);
            if (typeof loadPyodide !== "function") {
              throw new Error("loadPyodide is not available after loading pyodide.js");
            }
            const instance = await loadPyodide({ indexURL: cfg.index });
            return instance;
          } catch (err) {
            lastError = err;
          }
        }

        throw lastError || new Error("Failed to initialise Pyodide");
      })();
    }
    window.pyodide = await pyodidePromise;
    return window.pyodide;
  }

  async function runPython(code) {
    const py = await getPyodideInstance();
    // Expose code as a global so we don't have to interpolate it into the Python string.
    py.globals.set("__typophic_code", code);
    const result = await py.runPythonAsync(`
import sys, io, traceback
_stdout = sys.stdout
buf = io.StringIO()
sys.stdout = buf
ns = globals()
try:
    try:
        # First, try to treat the input as an expression so that
        # entering "1 + 2" shows "3" like a normal REPL.
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
buf.getvalue()
`);
    return String(result || "");
  }

  window.PythonRuntime = {
    getPyodide: getPyodideInstance,
    run: runPython
  };

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
