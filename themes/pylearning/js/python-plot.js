/* Notebook-style plotting for python-exec cells.
 *
 * Two parts:
 *  1. A tiny matplotlib-like Python shim (`plt`) installed into the shared
 *     Pyodide namespace. Cells use it exactly like a notebook:
 *       plt.plot(xs, ys, label="loss"); plt.title("Training"); plt.show()
 *     plt.show() serializes the figure to JSON and hands it to JS via the
 *     _typophic_emit_plot global (installed by python-runtime.js).
 *  2. TypophicPlot.render(spec) draws that JSON as a lightweight SVG chart
 *     (line/scatter/bar, axes, ticks, legend) with the theme palette.
 */
(function () {
  const SHIM_SOURCE = String.raw`
import json as _typophic_json

def _typophic_nums(seq):
    out = []
    for v in seq:
        try:
            out.append(float(v))
        except Exception:
            out.append(None)
    return out

class _TypophicPlt:
    """A minimal matplotlib.pyplot-like API backed by Typophic's SVG renderer."""
    def __init__(self):
        self._series = []
        self._title = ""
        self._xlabel = ""
        self._ylabel = ""

    def plot(self, x, y=None, label=None, **_ignored):
        if y is None:
            y = list(x)
            x = list(range(len(y)))
        self._series.append({
            "kind": "line",
            "x": _typophic_nums(list(x)),
            "y": _typophic_nums(list(y)),
            "label": str(label) if label is not None else None,
        })
        return self

    def scatter(self, x, y, label=None, **_ignored):
        self._series.append({
            "kind": "scatter",
            "x": _typophic_nums(list(x)),
            "y": _typophic_nums(list(y)),
            "label": str(label) if label is not None else None,
        })
        return self

    def bar(self, x, y, label=None, **_ignored):
        self._series.append({
            "kind": "bar",
            "x": _typophic_nums(list(x)),
            "y": _typophic_nums(list(y)),
            "label": str(label) if label is not None else None,
        })
        return self

    def title(self, text):
        self._title = str(text)

    def xlabel(self, text):
        self._xlabel = str(text)

    def ylabel(self, text):
        self._ylabel = str(text)

    def legend(self, *_args, **_kwargs):
        pass  # legends are drawn automatically for labelled series

    def imshow(self, grid, label=None, **_ignored):
        """Show a 2D grid of numbers (0..1) as a grayscale image."""
        self._series.append({
            "kind": "image",
            "grid": [[float(v) for v in row] for row in grid],
            "label": str(label) if label is not None else None,
        })
        return self

    def show(self):
        spec = {
            "title": self._title,
            "xlabel": self._xlabel,
            "ylabel": self._ylabel,
            "series": self._series,
        }
        _typophic_emit_plot(_typophic_json.dumps(spec))
        self._series = []

    def close(self, *_args, **_kwargs):
        self._series = []

plt = _TypophicPlt()

def progress(step, total, width=28, suffix=""):
    """PyTorch-style ASCII progress bar that rewrites one line.
    Usage in a training loop: progress(step, total, suffix=f"loss {loss:.4f}")"""
    frac = (step / total) if total else 0
    frac = max(0.0, min(1.0, frac))
    done = int(width * frac)
    if done >= width:
        bar = "=" * width
    else:
        bar = "=" * done + ">" + "." * (width - done - 1)
    pct = int(frac * 100)
    print("\r[" + bar + "] " + str(pct) + "% " + str(step) + "/" + str(total) + (" " + suffix if suffix else ""), end="")
    if step >= total:
        print()
`;

  const PALETTE = ["#2563eb", "#f59e0b", "#22c55e", "#ef4444", "#a855f7", "#06b6d4", "#f97316", "#84cc16"];

  const NS = "http://www.w3.org/2000/svg";

  // Renders {kind:"image", grid, label} series as side-by-side grayscale grids.
  function renderImages(spec, images) {
    const CELL = 14, PAD = 14, LABEL_H = 18, TITLE_H = spec.title ? 24 : 0;
    const perW = images.map(s => s.grid[0].length * CELL + PAD * 2);
    const W = perW.reduce((a, b) => a + b, 0);
    const H = images[0].grid.length * CELL + PAD * 2 + LABEL_H + TITLE_H;
    const svg = el("svg", {
      viewBox: `0 0 ${W} ${H}`,
      class: "typophic-plot",
      role: "img",
      "aria-label": spec.title || "image",
      style: "max-width:100%;height:auto;display:block;background:var(--code-bg,#1e1e1e);border-radius:8px;margin:0.5rem 0;"
    });
    if (spec.title) {
      svg.appendChild(el("text", { x: W / 2, y: 16, fill: "#e5e7eb", "font-size": 13, "font-weight": "bold", "text-anchor": "middle" }, spec.title));
    }
    let ox = 0;
    images.forEach((s, i) => {
      const rows = s.grid.length, cols = s.grid[0].length;
      for (let r = 0; r < rows; r++) {
        for (let c = 0; c < cols; c++) {
          const v = Math.max(0, Math.min(1, s.grid[r][c]));
          const g = Math.round(v * 255);
          svg.appendChild(el("rect", {
            x: ox + PAD + c * CELL, y: TITLE_H + PAD + r * CELL,
            width: CELL, height: CELL,
            fill: `rgb(${g},${g},${g})`
          }));
        }
      }
      if (s.label) {
        svg.appendChild(el("text", { x: ox + perW[i] / 2, y: TITLE_H + PAD + rows * CELL + 14, fill: "#9ca3af", "font-size": 11, "text-anchor": "middle" }, s.label));
      }
      ox += perW[i];
    });
    return svg;
  }

  function el(tag, attrs, text) {
    const node = document.createElementNS(NS, tag);
    if (attrs) Object.keys(attrs).forEach(k => node.setAttribute(k, attrs[k]));
    if (text != null) node.textContent = text;
    return node;
  }

  function niceTicks(min, max, count) {
    if (!isFinite(min) || !isFinite(max) || min === max) {
      return [min || 0];
    }
    const span = max - min;
    const step0 = span / count;
    const mag = Math.pow(10, Math.floor(Math.log10(step0)));
    const norm = step0 / mag;
    const step = (norm >= 5 ? 10 : norm >= 2 ? 5 : norm >= 1 ? 2 : 1) * mag;
    const start = Math.ceil(min / step) * step;
    const ticks = [];
    for (let v = start; v <= max + 1e-9; v += step) ticks.push(v);
    return ticks;
  }

  function fmt(v) {
    const a = Math.abs(v);
    if (a !== 0 && (a >= 10000 || a < 0.01)) return v.toExponential(1);
    return Number.isInteger(v) ? String(v) : v.toFixed(2).replace(/\.?0+$/, "");
  }

  // spec: {title, xlabel, ylabel, series: [{kind, x:[], y:[], label} | {kind:"image", grid, label}]}
  function render(spec) {
    // Image specs render as a row of grayscale pixel grids.
    const images = (spec.series || []).filter(s => s.kind === "image");
    if (images.length) return renderImages(spec, images);

    const W = 640, H = 360;
    const M = { top: 34, right: 16, bottom: 46, left: 58 };
    const iw = W - M.left - M.right;
    const ih = H - M.top - M.bottom;

    const svg = el("svg", {
      viewBox: `0 0 ${W} ${H}`,
      class: "typophic-plot",
      role: "img",
      "aria-label": spec.title || "plot",
      style: "max-width:100%;height:auto;display:block;background:var(--code-bg,#1e1e1e);border-radius:8px;margin:0.5rem 0;"
    });

    const allX = [], allY = [];
    (spec.series || []).forEach(s => {
      (s.x || []).forEach(v => { if (v != null) allX.push(v); });
      (s.y || []).forEach(v => { if (v != null) allY.push(v); });
    });
    if (!allX.length || !allY.length) return svg;

    let xMin = Math.min(...allX), xMax = Math.max(...allX);
    let yMin = Math.min(...allY), yMax = Math.max(...allY);
    if (xMin === xMax) { xMin -= 1; xMax += 1; }
    if (yMin === yMax) { yMin -= 1; yMax += 1; }
    const yPad = (yMax - yMin) * 0.06;
    yMin -= yPad; yMax += yPad;

    const sx = v => M.left + ((v - xMin) / (xMax - xMin)) * iw;
    const sy = v => M.top + ih - ((v - yMin) / (yMax - yMin)) * ih;

    const axisColor = "#9ca3af";
    // axes
    svg.appendChild(el("line", { x1: M.left, y1: M.top, x2: M.left, y2: M.top + ih, stroke: axisColor, "stroke-width": 1 }));
    svg.appendChild(el("line", { x1: M.left, y1: M.top + ih, x2: M.left + iw, y2: M.top + ih, stroke: axisColor, "stroke-width": 1 }));

    niceTicks(xMin, xMax, 6).forEach(t => {
      svg.appendChild(el("line", { x1: sx(t), y1: M.top + ih, x2: sx(t), y2: M.top + ih + 5, stroke: axisColor }));
      const label = el("text", { x: sx(t), y: M.top + ih + 18, fill: axisColor, "font-size": 11, "text-anchor": "middle" }, fmt(t));
      svg.appendChild(label);
    });
    niceTicks(yMin, yMax, 5).forEach(t => {
      svg.appendChild(el("line", { x1: M.left - 5, y1: sy(t), x2: M.left, y2: sy(t), stroke: axisColor }));
      svg.appendChild(el("line", { x1: M.left, y1: sy(t), x2: M.left + iw, y2: sy(t), stroke: axisColor, "stroke-opacity": 0.15 }));
      svg.appendChild(el("text", { x: M.left - 8, y: sy(t) + 4, fill: axisColor, "font-size": 11, "text-anchor": "end" }, fmt(t)));
    });

    if (spec.title) {
      svg.appendChild(el("text", { x: W / 2, y: 20, fill: "#e5e7eb", "font-size": 14, "font-weight": "bold", "text-anchor": "middle" }, spec.title));
    }
    if (spec.xlabel) {
      svg.appendChild(el("text", { x: M.left + iw / 2, y: H - 8, fill: axisColor, "font-size": 12, "text-anchor": "middle" }, spec.xlabel));
    }
    if (spec.ylabel) {
      const t = el("text", { x: 14, y: M.top + ih / 2, fill: axisColor, "font-size": 12, "text-anchor": "middle", transform: `rotate(-90 14 ${M.top + ih / 2})` }, spec.ylabel);
      svg.appendChild(t);
    }

    (spec.series || []).forEach((s, i) => {
      const color = PALETTE[i % PALETTE.length];
      const pts = (s.x || []).map((xv, j) => [xv, (s.y || [])[j]]).filter(p => p[0] != null && p[1] != null);
      if (!pts.length) return;
      if (s.kind === "scatter") {
        pts.forEach(([xv, yv]) => {
          svg.appendChild(el("circle", { cx: sx(xv), cy: sy(yv), r: 3.5, fill: color, "fill-opacity": 0.85 }));
        });
      } else if (s.kind === "bar") {
        const bw = Math.max(2, iw / pts.length * 0.7);
        const base = sy(Math.max(yMin, 0));
        pts.forEach(([xv, yv]) => {
          const y0 = sy(Math.max(yv, 0)), y1 = sy(Math.min(yv, 0));
          svg.appendChild(el("rect", { x: sx(xv) - bw / 2, y: y0, width: bw, height: Math.max(1, (y1 === y0 ? base : y1) - y0), fill: color, "fill-opacity": 0.8 }));
        });
      } else {
        const d = pts.map(([xv, yv], j) => `${j ? "L" : "M"}${sx(xv).toFixed(1)},${sy(yv).toFixed(1)}`).join(" ");
        svg.appendChild(el("path", { d, fill: "none", stroke: color, "stroke-width": 2 }));
      }
    });

    const labelled = (spec.series || []).filter(s => s.label);
    if (labelled.length) {
      const lg = el("g", { class: "typophic-plot-legend" });
      labelled.forEach((s, i) => {
        const idx = (spec.series || []).indexOf(s);
        const y = M.top + 6 + i * 16;
        lg.appendChild(el("rect", { x: M.left + 8, y: y - 8, width: 10, height: 10, fill: PALETTE[idx % PALETTE.length] }));
        lg.appendChild(el("text", { x: M.left + 22, y: y + 1, fill: "#e5e7eb", "font-size": 11 }, s.label));
      });
      svg.appendChild(lg);
    }

    return svg;
  }

  window.TypophicPlot = {
    shimSource: SHIM_SOURCE,
    render: render
  };
})();
