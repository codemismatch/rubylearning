!function(){function e(e,l){const i=14,s=14,n=18,o=e.title?24:0,a=l.map(e=>e.grid[0].length*i+2*s),r=a.reduce((e,t)=>e+t,0),f=t("svg",{viewBox:`0 0 ${r} ${l[0].grid.length*i+2*s+n+o}`,class:"typophic-plot",role:"img","aria-label":e.title||"image",style:"max-width:100%;height:auto;display:block;background:var(--code-bg,#1e1e1e);border-radius:8px;margin:0.5rem 0;"});e.title&&f.appendChild(t("text",{x:r/2,y:16,fill:"#e5e7eb","font-size":13,"font-weight":"bold","text-anchor":"middle"},e.title));let d=0;return l.forEach((e,l)=>{const n=e.grid.length,r=e.grid[0].length,p="image_rgb"===e.kind;for(let l=0;l<n;l++)for(let n=0;n<r;n++){let a;if(p){const t=e.grid[l][n];a=`rgb(${Math.round(255*Math.max(0,Math.min(1,t[0])))},${Math.round(255*Math.max(0,Math.min(1,t[1])))},${Math.round(255*Math.max(0,Math.min(1,t[2])))})`}else{const t=Math.max(0,Math.min(1,e.grid[l][n])),i=Math.round(255*t);a=`rgb(${i},${i},${i})`}f.appendChild(t("rect",{x:d+s+n*i,y:o+s+l*i,width:i,height:i,fill:a}))}e.label&&f.appendChild(t("text",{x:d+a[l]/2,y:o+s+n*i+14,fill:"#9ca3af","font-size":11,"text-anchor":"middle"},e.label)),d+=a[l]}),f}function t(e,t,l){const i=document.createElementNS(a,e);return t&&Object.keys(t).forEach(e=>i.setAttribute(e,t[e])),null!=l&&(i.textContent=l),i}function l(e,t,l){if(!isFinite(e)||!isFinite(t)||e===t)return[e||0];const i=(t-e)/l,s=Math.pow(10,Math.floor(Math.log10(i))),n=i/s,o=(n>=5?10:n>=2?5:n>=1?2:1)*s,a=[];for(let l=Math.ceil(e/o)*o;l<=t+1e-9;l+=o)a.push(l);return a}function i(e){const t=Math.abs(e);return 0!==t&&(t>=1e4||t<.01)?e.toExponential(1):Number.isInteger(e)?String(e):e.toFixed(2).replace(/\.?0+$/,"")}function s(s){const n=(s.series||[]).filter(e=>"image"===e.kind||"image_rgb"===e.kind);if(n.length)return e(s,n);const a=640,r=360,f={top:34,right:16,bottom:46,left:58},d=a-f.left-f.right,p=r-f.top-f.bottom,h=t("svg",{viewBox:`0 0 ${a} ${r}`,class:"typophic-plot",role:"img","aria-label":s.title||"plot",style:"max-width:100%;height:auto;display:block;background:var(--code-bg,#1e1e1e);border-radius:8px;margin:0.5rem 0;"}),c=[],x=[];if((s.series||[]).forEach(e=>{(e.x||[]).forEach(e=>{null!=e&&c.push(e)}),(e.y||[]).forEach(e=>{null!=e&&x.push(e)})}),!c.length||!x.length)return h;let g=Math.min(...c),b=Math.max(...c),y=Math.min(...x),m=Math.max(...x);g===b&&(g-=1,b+=1),y===m&&(y-=1,m+=1);const u=.06*(m-y);y-=u,m+=u;const _=e=>f.left+(e-g)/(b-g)*d,w=e=>f.top+p-(e-y)/(m-y)*p,k="#9ca3af";if(h.appendChild(t("line",{x1:f.left,y1:f.top,x2:f.left,y2:f.top+p,stroke:k,"stroke-width":1})),h.appendChild(t("line",{x1:f.left,y1:f.top+p,x2:f.left+d,y2:f.top+p,stroke:k,"stroke-width":1})),l(g,b,6).forEach(e=>{h.appendChild(t("line",{x1:_(e),y1:f.top+p,x2:_(e),y2:f.top+p+5,stroke:k}));const l=t("text",{x:_(e),y:f.top+p+18,fill:k,"font-size":11,"text-anchor":"middle"},i(e));h.appendChild(l)}),l(y,m,5).forEach(e=>{h.appendChild(t("line",{x1:f.left-5,y1:w(e),x2:f.left,y2:w(e),stroke:k})),h.appendChild(t("line",{x1:f.left,y1:w(e),x2:f.left+d,y2:w(e),stroke:k,"stroke-opacity":.15})),h.appendChild(t("text",{x:f.left-8,y:w(e)+4,fill:k,"font-size":11,"text-anchor":"end"},i(e)))}),s.title&&h.appendChild(t("text",{x:a/2,y:20,fill:"#e5e7eb","font-size":14,"font-weight":"bold","text-anchor":"middle"},s.title)),s.xlabel&&h.appendChild(t("text",{x:f.left+d/2,y:r-8,fill:k,"font-size":12,"text-anchor":"middle"},s.xlabel)),s.ylabel){const e=t("text",{x:14,y:f.top+p/2,fill:k,"font-size":12,"text-anchor":"middle",transform:`rotate(-90 14 ${f.top+p/2})`},s.ylabel);h.appendChild(e)}(s.series||[]).forEach((e,l)=>{const i=o[l%o.length],s=(e.x||[]).map((t,l)=>[t,(e.y||[])[l]]).filter(e=>null!=e[0]&&null!=e[1]);if(s.length)if("scatter"===e.kind)s.forEach(([e,l])=>{h.appendChild(t("circle",{cx:_(e),cy:w(l),r:3.5,fill:i,"fill-opacity":.85}))});else if("bar"===e.kind){const e=Math.max(2,d/s.length*.7),l=w(Math.max(y,0));s.forEach(([s,n])=>{const o=w(Math.max(n,0)),a=w(Math.min(n,0));h.appendChild(t("rect",{x:_(s)-e/2,y:o,width:e,height:Math.max(1,(a===o?l:a)-o),fill:i,"fill-opacity":.8}))})}else{const e=s.map(([e,t],l)=>`${l?"L":"M"}${_(e).toFixed(1)},${w(t).toFixed(1)}`).join(" ");h.appendChild(t("path",{d:e,fill:"none",stroke:i,"stroke-width":2}))}});const M=(s.series||[]).filter(e=>e.label);if(M.length){const e=t("g",{class:"typophic-plot-legend"});M.forEach((l,i)=>{const n=(s.series||[]).indexOf(l),a=f.top+6+16*i;e.appendChild(t("rect",{x:f.left+8,y:a-8,width:10,height:10,fill:o[n%o.length]})),e.appendChild(t("text",{x:f.left+22,y:a+1,fill:"#e5e7eb","font-size":11},l.label))}),h.appendChild(e)}return h}const n=String.raw`
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
        """Show a 2D grid of numbers (0..1) as grayscale, or an HxWx3 grid as RGB."""
        try:
            first = grid[0][0]
        except Exception:
            first = 0
        if isinstance(first, (list, tuple)) and len(first) >= 3:
            self._series.append({
                "kind": "image_rgb",
                "grid": [[[float(c) for c in list(px)[:3]] for px in row] for row in grid],
                "label": str(label) if label is not None else None,
            })
        else:
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
`,o=["#2563eb","#f59e0b","#22c55e","#ef4444","#a855f7","#06b6d4","#f97316","#84cc16"],a="http://www.w3.org/2000/svg";window.TypophicPlot={shimSource:n,render:s}}();