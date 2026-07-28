/* Pyodide Web Worker: runs Python off the main thread so heavy cells
 * (e.g. the mini-GPT training loop) don't freeze the page.
 *
 * Protocol (main -> worker):
 *   {type:'init', url, index, shim}  -> loads Pyodide + installs plt shim
 *   {type:'run', id, code}           -> executes in the shared namespace
 *   {type:'set', name, value}        -> sets a global (e.g. uploaded corpus)
 * Protocol (worker -> main):
 *   {type:'ready'} | {type:'error', error}
 *   {type:'result', id, result, plots}
 */
const WRAPPER = `
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
`;

let pyodide = null;
let plots = [];

self.onmessage = async (e) => {
  const msg = e.data || {};

  if (msg.type === "init") {
    try {
      importScripts(msg.url);
      // eslint-disable-next-line no-undef
      pyodide = await loadPyodide({ indexURL: msg.index });
      pyodide.globals.set("_typophic_emit_plot", (payload) => {
        try {
          plots.push(JSON.parse(payload));
        } catch (_) { /* ignore malformed specs */ }
      });
      if (msg.shim) {
        await pyodide.runPythonAsync(msg.shim);
      }
      self.postMessage({ type: "ready" });
    } catch (err) {
      self.postMessage({ type: "error", error: String((err && err.message) || err) });
    }
    return;
  }

  if (!pyodide) return;

  if (msg.type === "set") {
    try {
      pyodide.globals.set(msg.name, msg.value);
    } catch (_) { /* ignore */ }
    return;
  }

  if (msg.type === "run") {
    try {
      if (typeof pyodide.loadPackagesFromImports === "function") {
        try {
          await pyodide.loadPackagesFromImports(msg.code);
        } catch (_) { /* import error surfaces in output */ }
      }
      pyodide.globals.set("__typophic_code", msg.code);
      plots = [];
      const result = await pyodide.runPythonAsync(WRAPPER);
      self.postMessage({ type: "result", id: msg.id, result: String(result || ""), plots: plots });
    } catch (err) {
      self.postMessage({ type: "result", id: msg.id, result: String((err && err.message) || err), plots: [] });
    }
  }
};
