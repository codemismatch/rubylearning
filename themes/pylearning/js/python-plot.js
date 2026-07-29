!function(){function e(e,t,l){const i=document.createElementNS(n,e);return t&&Object.keys(t).forEach(e=>i.setAttribute(e,t[e])),null!=l&&(i.textContent=l),i}function t(e,t,l){if(!isFinite(e)||!isFinite(t)||e===t)return[e||0];const i=(t-e)/l,s=Math.pow(10,Math.floor(Math.log10(i))),o=i/s,n=(o>=5?10:o>=2?5:o>=1?2:1)*s,a=[];for(let l=Math.ceil(e/n)*n;l<=t+1e-9;l+=n)a.push(l);return a}function l(e){const t=Math.abs(e);return 0!==t&&(t>=1e4||t<.01)?e.toExponential(1):Number.isInteger(e)?String(e):e.toFixed(2).replace(/\.?0+$/,"")}function i(i){const s=640,n=360,a={top:34,right:16,bottom:46,left:58},r=s-a.left-a.right,f=n-a.top-a.bottom,p=e("svg",{viewBox:`0 0 ${s} ${n}`,class:"typophic-plot",role:"img","aria-label":i.title||"plot",style:"max-width:100%;height:auto;display:block;background:var(--code-bg,#1e1e1e);border-radius:8px;margin:0.5rem 0;"}),d=[],h=[];if((i.series||[]).forEach(e=>{(e.x||[]).forEach(e=>{null!=e&&d.push(e)}),(e.y||[]).forEach(e=>{null!=e&&h.push(e)})}),!d.length||!h.length)return p;let c=Math.min(...d),x=Math.max(...d),y=Math.min(...h),b=Math.max(...h);c===x&&(c-=1,x+=1),y===b&&(y-=1,b+=1);const _=.06*(b-y);y-=_,b+=_;const u=e=>a.left+(e-c)/(x-c)*r,m=e=>a.top+f-(e-y)/(b-y)*f,g="#9ca3af";if(p.appendChild(e("line",{x1:a.left,y1:a.top,x2:a.left,y2:a.top+f,stroke:g,"stroke-width":1})),p.appendChild(e("line",{x1:a.left,y1:a.top+f,x2:a.left+r,y2:a.top+f,stroke:g,"stroke-width":1})),t(c,x,6).forEach(t=>{p.appendChild(e("line",{x1:u(t),y1:a.top+f,x2:u(t),y2:a.top+f+5,stroke:g}));const i=e("text",{x:u(t),y:a.top+f+18,fill:g,"font-size":11,"text-anchor":"middle"},l(t));p.appendChild(i)}),t(y,b,5).forEach(t=>{p.appendChild(e("line",{x1:a.left-5,y1:m(t),x2:a.left,y2:m(t),stroke:g})),p.appendChild(e("line",{x1:a.left,y1:m(t),x2:a.left+r,y2:m(t),stroke:g,"stroke-opacity":.15})),p.appendChild(e("text",{x:a.left-8,y:m(t)+4,fill:g,"font-size":11,"text-anchor":"end"},l(t)))}),i.title&&p.appendChild(e("text",{x:s/2,y:20,fill:"#e5e7eb","font-size":14,"font-weight":"bold","text-anchor":"middle"},i.title)),i.xlabel&&p.appendChild(e("text",{x:a.left+r/2,y:n-8,fill:g,"font-size":12,"text-anchor":"middle"},i.xlabel)),i.ylabel){const t=e("text",{x:14,y:a.top+f/2,fill:g,"font-size":12,"text-anchor":"middle",transform:`rotate(-90 14 ${a.top+f/2})`},i.ylabel);p.appendChild(t)}(i.series||[]).forEach((t,l)=>{const i=o[l%o.length],s=(t.x||[]).map((e,l)=>[e,(t.y||[])[l]]).filter(e=>null!=e[0]&&null!=e[1]);if(s.length)if("scatter"===t.kind)s.forEach(([t,l])=>{p.appendChild(e("circle",{cx:u(t),cy:m(l),r:3.5,fill:i,"fill-opacity":.85}))});else if("bar"===t.kind){const t=Math.max(2,r/s.length*.7),l=m(Math.max(y,0));s.forEach(([s,o])=>{const n=m(Math.max(o,0)),a=m(Math.min(o,0));p.appendChild(e("rect",{x:u(s)-t/2,y:n,width:t,height:Math.max(1,(a===n?l:a)-n),fill:i,"fill-opacity":.8}))})}else{const t=s.map(([e,t],l)=>`${l?"L":"M"}${u(e).toFixed(1)},${m(t).toFixed(1)}`).join(" ");p.appendChild(e("path",{d:t,fill:"none",stroke:i,"stroke-width":2}))}});const w=(i.series||[]).filter(e=>e.label);if(w.length){const t=e("g",{class:"typophic-plot-legend"});w.forEach((l,s)=>{const n=(i.series||[]).indexOf(l),r=a.top+6+16*s;t.appendChild(e("rect",{x:a.left+8,y:r-8,width:10,height:10,fill:o[n%o.length]})),t.appendChild(e("text",{x:a.left+22,y:r+1,fill:"#e5e7eb","font-size":11},l.label))}),p.appendChild(t)}return p}const s=String.raw`
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
`,o=["#2563eb","#f59e0b","#22c55e","#ef4444","#a855f7","#06b6d4","#f97316","#84cc16"],n="http://www.w3.org/2000/svg";window.TypophicPlot={shimSource:s,render:i}}();