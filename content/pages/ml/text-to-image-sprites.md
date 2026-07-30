---
layout: tutorial
title: "Chapter 8 &ndash; Text-to-Image: Teaching Diffusion to Listen"
permalink: /courses/image-generation/text-to-image-sprites/
difficulty: advanced
author: Pankaj Doharey
summary: Condition the DDPM on a word - alien, bars, box, cross - and generate the sprite you ask for. This is the exact mechanism behind Stable Diffusion's prompts, at toy scale.
theme: pylearning
previous_tutorial:
  title: "Chapter 7: Diffusion Models from Scratch: Sprite Training"
  url: /courses/image-generation/diffusion-models-from-scratch/
next_tutorial:
  title: "Chapter 9: Latent Diffusion & Super-Resolution"
  url: /courses/image-generation/latent-diffusion/
date: 2026-07-29
---

In [Chapter 7](/courses/image-generation/diffusion-models-from-scratch/) we trained a DDPM that dreams sprites out of pure noise. It is a genuine generative model, and it has a glaring limitation: we cannot tell it *what* to dream. Ask it for an alien and it hands you whatever falls out of the reverse walk - maybe a box, maybe bars. The jump from "generates images" to "generates the image you asked for" is called **conditioning**, and it is one small change: hand the denoiser the word alongside the noisy image, and train exactly as before.

That one change is the whole idea behind text-to-image. Stable Diffusion, DALL-E, Imagen - all of them are denoisers that receive a description of the target and predict noise *in the direction of that description*. We will do it with a four-word vocabulary and the sprite families we already own.

### The mechanism: a word rides in beside the time

Our denoiser already takes two inputs: the noisy sprite and the time `t` (as a sinusoidal embedding). Conditioning adds a third: the word. The word arrives as a one-hot vector over our vocabulary, a lookup into a small **learned embedding table** turns it into 16 numbers, and those numbers get *added* to the time embedding. The combined vector enters the network in the same slot as before:

```text
input = noisy_x_t ++ (time_embed(t) + word_embed(word))
loss  = mean((eps_true - eps_pred(input))^2)
```

The embedding table starts as noise and is trained by the same backpropagation as everything else - the gradient flows through the network back into the input, and the word's row of the table gets its share. After a few thousand steps, the row for "alien" points somewhere different from the row for "box", and the denoiser has learned to use that difference. Nothing else changes. Forward noising, the noise-prediction loss, and the ancestral sampler are byte-for-byte from [Chapter 6](/courses/image-generation/ddpm-from-first-principles/) and Chapter 7.

#> mermaid: caption="Figure 1: the conditional denoiser - the word enters through the same door as time"
graph LR
  X["noisy sprite x_t"] --> D["TinyDenoiser MLP"]
  T["t"] --> TE["time embedding"] --> SUM((+))
  W["word: alien"] --> OH["one-hot"] --> ET["learned embedding table"] --> SUM
  SUM --> D
  D --> P["predicted noise"]
#!

Our vocabulary is `["alien", "bars", "box", "cross"]`, one word per procedural sprite family from Chapter 7. That is the quiet luxury of procedural data: every family name is a free label. Real text-to-image models need billions of captioned images scraped from the web; we get infinite, perfectly labeled pairs from a few lines of code:

```python-exec
import math, random

def make_alien():
    left = [[random.random() < 0.5 for _ in range(4)] for _ in range(8)]
    return [[1.0 if (row[c] if c < 4 else row[7 - c]) else -1.0
             for c in range(8)] for row in left]

def make_bars():
    cols = random.sample(range(8), random.randint(1, 3))
    return [[1.0 if c in cols else -1.0 for c in range(8)]
            for _ in range(8)]

def make_box():
    r0, r1 = sorted(random.sample(range(8), 2))
    c0, c1 = sorted(random.sample(range(8), 2))
    return [[1.0 if (r in (r0, r1) and c0 <= c <= c1) or
             (c in (c0, c1) and r0 <= r <= r1) else -1.0
            for c in range(8)] for r in range(8)]

def make_cross():
    r0 = random.randint(1, 6); c0 = random.randint(1, 6)
    arm = random.randint(1, 2)
    return [[1.0 if (abs(r - r0) <= arm and c == c0) or
             (abs(c - c0) <= arm and r == r0) else -1.0
            for c in range(8)] for r in range(8)]

VOCAB = ["alien", "bars", "box", "cross"]
MAKERS = [make_alien, make_bars, make_box, make_cross]

random.seed(7)
data = []                                   # (flat sprite, word index) pairs
for wi, make in enumerate(MAKERS):
    for _ in range(100):
        data.append(([v for row in make() for v in row], wi))

def show01(x, lo=-1.0, hi=1.0):
    """Flattened sprite -> 8x8 grid of 0..1 values for plt.imshow."""
    return [[max(0.0, min(1.0, (x[r * 8 + c] - lo) / (hi - lo)))
             for c in range(8)] for r in range(8)]

print(f"{len(data)} labeled sprites; vocabulary: {VOCAB}")
for wi in range(4):
    plt.imshow(show01(data[wi * 100][0]), label=VOCAB[wi])
plt.title("One sprite per word - labels come for free")
plt.show()
```

The schedule is Chapter 7's, untouched: T = 200 steps, beta growing linearly from 0.0001 to 0.05, closed-form jump to any `t`:

```python-exec
T = 200
betas = [1e-4 + (0.05 - 1e-4) * t / (T - 1) for t in range(T)]
alphas = [1 - b for b in betas]
alpha_bar = []
p = 1.0
for a in alphas:
    p *= a
    alpha_bar.append(p)

def q_sample(x0, t, noise):
    s = math.sqrt(alpha_bar[t])
    return [s * x + math.sqrt(1 - alpha_bar[t]) * e
            for x, e in zip(x0, noise)]

print(f"signal left at t=199: {alpha_bar[199]:.4f}  (nearly pure noise)")
```

### The conditional denoiser

Same architecture as Chapter 7 - one hidden layer of 64 with ReLU, zero-initialized output head - plus one new object: `EMB`, a 4x16 word embedding table (the miniature of the embedding layer in [the text embeddings chapter](/courses/machine-learning/text-embeddings/)). The conditioning vector is the time embedding plus the word's row, so the network's input shape does not change at all:

```python-exec
def dot(a, b): return sum(x * y for x, y in zip(a, b))
def matvec(W, x): return [dot(row, x) for row in W]
def vecmat(x, W):
    return [sum(x[i] * W[i][j] for i in range(len(x)))
            for j in range(len(W[0]))]
def rand_matrix(r, c, s):
    return [[random.gauss(0, s) for _ in range(c)] for _ in range(r)]

TE = 16                      # time-embedding width
def time_embed(t):
    out = []
    for i in range(TE // 2):
        f = math.exp(-math.log(10000) * i / (TE // 2 - 1))
        out.append(math.sin(t * f))
        out.append(math.cos(t * f))
    return out

TE_CACHE = [time_embed(t / T) for t in range(T)]

DIN, H, DOUT = 64 + TE, 96, 64
random.seed(42)
W1 = rand_matrix(H, DIN, math.sqrt(2 / DIN)); b1 = [0.0] * H
W2 = rand_matrix(DOUT, H, 0.0)                # zero-init output head
b2 = [0.0] * DOUT
NULL = len(VOCAB)                             # extra row: the "no word given" case
EMB = rand_matrix(len(VOCAB) + 1, TE, 0.1)    # the word embedding table

def cond(wi, t):
    """Conditioning vector: time embedding + the word's learned embedding."""
    return [TE_CACHE[t][i] + EMB[wi][i] for i in range(TE)]

def forward(x):
    """noisy 80-vector -> predicted noise (64). Returns cache too."""
    z1 = [a + b for a, b in zip(matvec(W1, x), b1)]
    h1 = [v if v > 0 else 0.0 for v in z1]
    out = [a + b for a, b in zip(matvec(W2, h1), b2)]
    return out, h1

print(f"conditional denoiser: {DIN} -> {H} -> {DOUT}, plus a {len(VOCAB) + 1}x{TE} word table")
```

### Training: same loss, one extra gradient

The training loop is Chapter 7's with three differences. Each batch item now carries its word index, so the input is built with `cond(wi, tt)`. We compute the gradient with respect to the *input* (one extra `vecmat`), because the last 16 entries of that gradient are exactly the gradient for the word's row in `EMB`. And one batch item in ten gets its label replaced by `NULL`, the "no word given" row - so the model also learns to denoise *unconditionally*. That dropout looks like a detail now and becomes the steering wheel at sampling time. The word learns what to mean by being wrong about noise, over and over, alongside every other parameter:

```python-exec
_ms, _vs, _t_adam = {}, {}, 0
def adam(name, p, g, lr=0.005, be1=0.9, be2=0.999, eps=1e-8):
    if name not in _ms:
        zero = ([[0.0] * len(r) for r in p] if isinstance(p[0], list)
                else [0.0] * len(p))
        _ms[name] = [row[:] for row in zero] if isinstance(p[0], list) else zero
        _vs[name] = [row[:] for row in zero] if isinstance(p[0], list) else zero[:]
    m, v = _ms[name], _vs[name]
    c1 = 1 - be1 ** _t_adam; c2 = 1 - be2 ** _t_adam
    if isinstance(p[0], list):
        for i in range(len(p)):
            for j in range(len(p[0])):
                m[i][j] = be1 * m[i][j] + (1 - be1) * g[i][j]
                v[i][j] = be2 * v[i][j] + (1 - be2) * g[i][j] ** 2
                p[i][j] -= lr * (m[i][j] / c1) / (math.sqrt(v[i][j] / c2) + eps)
    else:
        for i in range(len(p)):
            m[i] = be1 * m[i] + (1 - be1) * g[i]
            v[i] = be2 * v[i] + (1 - be2) * g[i] ** 2
            p[i] -= lr * (m[i] / c1) / (math.sqrt(v[i] / c2) + eps)

print("adam ready")
```

Now the loop - 3000 steps, batches of 16. **This is the heavy cell: about two minutes on a laptop, and several minutes in the browser.** An untrained model scores loss ~1.0; watch it fall well below that:

```python-exec
B = 16
steps = 3000
_t_adam = 0           # fresh Adam clock: bias correction assumes t starts at 1
history = []
for step in range(steps + 1):
    _t_adam += 1
    gW1 = [[0.0] * DIN for _ in range(H)]; gb1 = [0.0] * H
    gW2 = [[0.0] * H for _ in range(DOUT)]; gb2 = [0.0] * DOUT
    gE = [[0.0] * TE for _ in range(len(VOCAB) + 1)]
    loss_b = 0.0
    for _ in range(B):                      # one batch
        x0, wi = random.choice(data)
        if random.random() < 0.1:           # label dropout: 10% of items
            wi = NULL                       # train the unconditional guess too
        tt = random.randrange(T)
        noise = [random.gauss(0, 1) for _ in range(64)]
        xin = q_sample(x0, tt, noise) + cond(wi, tt)
        pred, h1 = forward(xin)
        loss_b += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 64
        d2 = [2 * (p_ - n) / (64 * B) for p_, n in zip(pred, noise)]
        for i in range(DOUT):               # d loss / d W2, d b2
            for j in range(H):
                gW2[i][j] += d2[i] * h1[j]
            gb2[i] += d2[i]
        dh1 = vecmat(d2, W2)                # back through ReLU
        dh1 = [d * (1.0 if h > 0 else 0.0) for d, h in zip(dh1, h1)]
        for i in range(H):                  # d loss / d W1, d b1
            for j in range(DIN):
                gW1[i][j] += dh1[i] * xin[j]
            gb1[i] += dh1[i]
        dxin = vecmat(dh1, W1)              # gradient reaches the input...
        for i in range(TE):                 # ...and flows into the word's row
            gE[wi][i] += dxin[64 + i]
    adam('W1', W1, gW1); adam('b1', b1, gb1)
    adam('W2', W2, gW2); adam('b2', b2, gb2)
    adam('EMB', EMB, gE)
    if step % 100 == 0:
        history.append((step, loss_b / B))
        progress(step, steps, suffix=f"loss {loss_b / B:.4f}")
    if step % 500 == 0:
        print(f"step {step:4d}  loss {loss_b / B:.4f}")

# honest eval: average loss over 200 fixed (sprite, word, t, noise) tuples
random.seed(999)
evals = [(random.choice(data), random.randrange(T),
          [random.gauss(0, 1) for _ in range(64)]) for _ in range(200)]
total = 0.0
for (x0, wi), tt, noise in evals:
    pred, _ = forward(q_sample(x0, tt, noise) + cond(wi, tt))
    total += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 64
print(f"eval loss: {total / 200:.4f}")
```

```python-exec
plt.plot([s for s, _ in history], [l for _, l in history],
         label="noise-prediction MSE")
plt.title("Conditional DDPM training loss")
plt.xlabel("step")
plt.ylabel("loss")
plt.show()
```

### Sampling: say the word, get the sprite

The reverse walk is Chapter 7's ancestral sampler with the word injected at all 200 steps, steering from the first, vaguest denoising decision down to the last pixel. And here the label dropout pays off: at every step we ask the model *twice* - once with our word, once with the `NULL` word - and push the prediction away from the unconditional guess: `eps = eps_uncond + w * (eps_cond - eps_uncond)`. That is **classifier-free guidance**, and the scale `w` is the obedience knob. `w = 1` recovers plain conditional sampling; we use `w = 2`:

```python-exec
def sample(word, start=None, guidance=2.0):
    wi = VOCAB.index(word)
    x = list(start) if start is not None else [random.gauss(0, 1) for _ in range(64)]
    for tt in range(T - 1, -1, -1):
        pc, _ = forward(x + cond(wi, tt))       # with the word
        pu, _ = forward(x + cond(NULL, tt))     # without any word
        pred = [u + guidance * (c - u) for c, u in zip(pc, pu)]
        ab = alpha_bar[tt]
        ab_prev = alpha_bar[tt - 1] if tt > 0 else 1.0
        x0 = [(xi - math.sqrt(1 - ab) * e) / math.sqrt(ab)
              for xi, e in zip(x, pred)]
        x0 = [max(-1.0, min(1.0, v)) for v in x0]   # clip to data range
        k1 = math.sqrt(ab_prev) * betas[tt] / (1 - ab)
        k2 = math.sqrt(alphas[tt]) * (1 - ab_prev) / (1 - ab)
        mean = [k1 * a + k2 * xi for a, xi in zip(x0, x)]
        if tt > 0:
            s = math.sqrt(betas[tt])
            x = [m + s * random.gauss(0, 1) for m in mean]
        else:
            x = mean
    return x
```

And the payoff. Below we ask for each word in turn, three samples per word, one row per prompt. There is a controlled experiment hidden in the layout: the **first column of every row starts from the same noise** - identical static, only the word differs. Whatever difference you see in that column is the conditioning doing its job (twelve guided samples at 200 steps takes a couple of minutes):

```python-exec
random.seed(123)
shared_noise = [random.gauss(0, 1) for _ in range(64)]
NAMES = {"alien": "an alien", "bars": "bars",
         "box": "a box", "cross": "a cross"}
for word in VOCAB:
    for i in range(3):
        s = sample(word, start=shared_noise if i == 0 else None)
        plt.imshow(show01(s), label=f"{word} #{i + 1}")
    plt.title(f"You say '{word}', the model draws {NAMES[word]}")
    plt.show()
```

Judge the rows honestly. The alien row should be dense mirrored blobs; bars should show full-height columns; boxes and crosses should be visibly sparser, with the cross row the sparsest of all. They will be blobby and imperfect - that is the correct result at this scale, as Chapter 7 taught us - but the rows are unmistakably different from each other, and each row leans toward *the thing you asked for*. The model now takes requests.

### Real photographs, real captions

The sprite labels were free because we wrote both sides of every pair. Real text-to-image starts from the opposite situation: a folder of photographs, each carrying one caption, and nothing else. That folder - one image, one caption - is exactly the format Stable Diffusion fine-tunes and LoRA trainings consume, and it is what this page now hands to the same code: 167 real COCO photographs with real BLIP captions, as `coco16.csv`. (Images: COCO 2017 subset with BLIP captions, via Pin-ky/coco-blip-captions on Hugging Face, CC-BY-4.0, reduced to 16x16 grayscale.)

<div data-corpus-url="/assets/data/coco16.csv" data-corpus-var="coco_text"></div>

```python-exec
rows = [ln for ln in coco_text.strip().split("\n")[1:] if ln.count(",") >= 257   # skip the header, drop non-data lines
CLASSES = []
cdata = []          # (flat 256-vector rescaled to +-1, class index)
caps = {}
for ln in rows:
    parts = ln.split(",")                     # captions contain no commas
    word = parts[0]
    if word not in CLASSES:
        CLASSES.append(word)
    if word not in caps:
        caps[word] = parts[1].strip('"')
    px = [float(v) * 2 - 1 for v in parts[2:]]     # 0..1 -> -1..1
    cdata.append((px, CLASSES.index(word)))

def show16(x, lo=-1.0, hi=1.0):
    """Flattened 16x16 photo -> 0..1 grid for plt.imshow."""
    return [[max(0.0, min(1.0, (x[r * 16 + c] - lo) / (hi - lo)))
             for c in range(16)] for r in range(16)]

print(f"{len(cdata)} photographs, {len(CLASSES)} classes: {CLASSES}")
for w in CLASSES:
    print(f'  {w:11s} e.g. "{caps[w]}"')
```

Six classes - motorcycle, car, cat, giraffe, bus, dog - with captions like *"A Honda motorcycle parked in a grass driveway"* and *"A giraffe looks down at a zebra on the field"*. Now the honesty paragraph, because you deserve one: at 16x16 grayscale a photograph is not a recognizable object, it is a texture. Look at the preview - three real photos per class - and try to sort them yourself. You cannot, and neither can we:

```python-exec
for wi, word in enumerate(CLASSES):
    imgs = [x for x, i in cdata if i == wi][:3]
    for j, x in enumerate(imgs):
        plt.imshow(show16(x), label=f"{word} #{j + 1}")
    plt.title(f"real photographs: {word}")
    plt.show()
```

The point of this section is the pipeline - load pairs, condition, train, sample - and the pipeline is identical at every resolution. The denoiser is the sprite model's twin stretched to 256 pixels: input 256 + 16, output 256, and a *smaller* hidden layer (64 instead of 96) so the bigger matrices still train in a browser. New weights, same machinery - `q_sample`, `TE_CACHE`, `adam`, the hand-written backprop, the 10% label dropout, all unchanged:

```python-exec
CDIN, CH, CDOUT = 256 + TE, 64, 256
random.seed(1234)
CW1 = rand_matrix(CH, CDIN, math.sqrt(2 / CDIN)); Cb1 = [0.0] * CH
CW2 = rand_matrix(CDOUT, CH, 0.0)                 # zero-init output head
Cb2 = [0.0] * CDOUT
CNULL = len(CLASSES)
CEMB = rand_matrix(len(CLASSES) + 1, TE, 0.1)     # word table + NULL row

def ccond(wi, t):
    return [TE_CACHE[t][i] + CEMB[wi][i] for i in range(TE)]

def cforward(x):
    z1 = [a + b for a, b in zip(matvec(CW1, x), Cb1)]
    h1 = [v if v > 0 else 0.0 for v in z1]
    out = [a + b for a, b in zip(matvec(CW2, h1), Cb2)]
    return out, h1

print(f"photo denoiser: {CDIN} -> {CH} -> {CDOUT}, plus a {len(CLASSES) + 1}x{TE} word table")
```

Train it - 1200 steps, batches of 16, the largest cell in the course: **about two minutes on a laptop, and several minutes in the browser** (Pyodide runs pure Python a few times slower). One small mercy: we train only on noise levels `t >= 25`, because Chapter 7 already taught us the near-clean steps are the hardest and matter least for generation - the whole budget goes where the learning is. An untrained model scores loss ~1.0:

```python-exec
import time
B = 16
steps = 1200
_t_adam = 0           # fresh Adam clock: bias correction assumes t starts at 1
t0 = time.time()
for step in range(steps + 1):
    _t_adam += 1
    gW1 = [[0.0] * CDIN for _ in range(CH)]; gb1 = [0.0] * CH
    gW2 = [[0.0] * CH for _ in range(CDOUT)]; gb2 = [0.0] * CDOUT
    gE = [[0.0] * TE for _ in range(len(CLASSES) + 1)]
    loss_b = 0.0
    for _ in range(B):                      # one batch
        x0, wi = random.choice(cdata)
        if random.random() < 0.1:           # label dropout, as before
            wi = CNULL
        tt = 25 + random.randrange(T - 25)  # skip the whisper-quiet low t's
        noise = [random.gauss(0, 1) for _ in range(256)]
        xin = q_sample(x0, tt, noise) + ccond(wi, tt)
        pred, h1 = cforward(xin)
        loss_b += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 256
        d2 = [2 * (p_ - n) / (256 * B) for p_, n in zip(pred, noise)]
        for i in range(CDOUT):
            for j in range(CH):
                gW2[i][j] += d2[i] * h1[j]
            gb2[i] += d2[i]
        dh1 = vecmat(d2, CW2)
        dh1 = [d * (1.0 if h > 0 else 0.0) for d, h in zip(dh1, h1)]
        for i in range(CH):
            for j in range(CDIN):
                gW1[i][j] += dh1[i] * xin[j]
            gb1[i] += dh1[i]
        dxin = vecmat(dh1, CW1)
        for i in range(TE):
            gE[wi][i] += dxin[256 + i]
    adam('CW1', CW1, gW1); adam('Cb1', Cb1, gb1)
    adam('CW2', CW2, gW2); adam('Cb2', Cb2, gb2)
    adam('CEMB', CEMB, gE)
    if step % 100 == 0:
        progress(step, steps, suffix=f"loss {loss_b / B:.4f}")
    if step % 500 == 0:
        print(f"step {step:4d}  loss {loss_b / B:.4f}")
print(f"trained in {time.time() - t0:.0f}s")```

Before we ask the model for images, measure three things most tutorials skip. Does the word help the loss at all - evaluate with the correct word, with no word, and with the *wrong* word on identical tuples? How far apart are the classes in pixel space to begin with? And would even the *real* photos sort into their own classes?

```python-exec
def eval_with(mode):
    random.seed(999)
    ev = [(random.choice(cdata), 25 + random.randrange(T - 25),
           [random.gauss(0, 1) for _ in range(256)]) for _ in range(100)]
    tot = 0.0
    for (x0, wi), tt, noise in ev:
        if mode == "null":
            wi = CNULL
        elif mode == "wrong":
            wi = (wi + 3) % len(CLASSES)
        pred, _ = cforward(q_sample(x0, tt, noise) + ccond(wi, tt))
        tot += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 256
    return tot / 100

print(f"eval: correct word {eval_with('right'):.4f}  "
      f"no word {eval_with('null'):.4f}  wrong word {eval_with('wrong'):.4f}")

gmean = [sum(x[k] for x, _ in cdata) / len(cdata) for k in range(256)]
protos = []
for wi in range(len(CLASSES)):
    imgs = [x for x, i in cdata if i == wi]
    protos.append([sum(im[k] for im in imgs) / len(imgs) for k in range(256)])
v_in = sum((x[k] - protos[wi][k]) ** 2 for x, wi in cdata
           for k in range(256)) / (len(cdata) * 256)
v_gl = sum((x[k] - gmean[k]) ** 2 for x, _ in cdata
           for k in range(256)) / (len(cdata) * 256)
print(f"spread within a class: {v_in:.3f}   spread overall: {v_gl:.3f}")

def nearest_proto(x):
    d = [sum((a - b) ** 2 for a, b in zip(x, p)) for p in protos]
    return d.index(min(d))

hits = sum(1 for x, wi in cdata if nearest_proto(x) == wi)
print(f"real photos closest to their own class average: "
      f"{hits}/{len(cdata)} (chance is 1/{len(CLASSES)})")
```

Three numbers, one story. The word barely moves the loss. The reason is in the second line: the spread *within* a class is nearly the entire spread, so the class averages are almost identical - at 16x16 grayscale, cat and bus are twins. The third line confirms it from the other side: even real photographs sit closest to their own class average well under half the time. The conditioning mechanism is not broken; the data simply cannot answer six fine-grained questions at this resolution, this sample size, this network size.

So here is the honest gallery. Each row: two real photos of the class, then two the model drew when asked for that word (guidance `w = 2`, the sprite chapter's knob). The generated pair should look like photographic grain - smoother and blotchier than white static - but it will not look like the class, and now you know precisely why:

```python-exec
def csample(word, guidance=2.0):
    wi = CLASSES.index(word)
    x = [random.gauss(0, 1) for _ in range(256)]
    for tt in range(T - 1, -1, -1):
        pc, _ = cforward(x + ccond(wi, tt))     # with the word
        pu, _ = cforward(x + ccond(CNULL, tt))  # without any word
        pred = [u + guidance * (c - u) for c, u in zip(pc, pu)]
        ab = alpha_bar[tt]
        ab_prev = alpha_bar[tt - 1] if tt > 0 else 1.0
        x0 = [(xi - math.sqrt(1 - ab) * e) / math.sqrt(ab)
              for xi, e in zip(x, pred)]
        x0 = [max(-1.0, min(1.0, v)) for v in x0]
        k1 = math.sqrt(ab_prev) * betas[tt] / (1 - ab)
        k2 = math.sqrt(alphas[tt]) * (1 - ab_prev) / (1 - ab)
        mean = [k1 * a + k2 * xi for a, xi in zip(x0, x)]
        if tt > 0:
            s = math.sqrt(betas[tt])
            x = [m + s * random.gauss(0, 1) for m in mean]
        else:
            x = mean
    return x

random.seed(5)
hits = 0
for wi, word in enumerate(CLASSES):
    imgs = [x for x, i in cdata if i == wi][:2]
    plt.imshow(show16(imgs[0]), label=f"{word} (real)")
    plt.imshow(show16(imgs[1]), label=f"{word} (real)")
    for j in range(2):
        s = csample(word)
        hits += 1 if nearest_proto(s) == wi else 0
        plt.imshow(show16(s), label=f"{word} (gen)")
    plt.title(f"You say '{word}', the model draws its idea of a {word}")
    plt.show()
print(f"generated images closest to the requested class average: "
      f"{hits}/12 (chance is 2/12)")
```

This is the most valuable result in the chapter, and it is a negative result. The sprites proved the mechanism; the photographs proved the bottleneck. Conditioning is not magic that summons class structure - it is a steering wheel that amplifies structure the data already contains. A 167-thumbnail dataset cannot teach six textures to a 30,000-parameter network, no matter how the prompt arrives. Five billion image-caption pairs and a U-Net a thousand times wider can, and that is the *entire* difference between this page and Stable Diffusion: same equations, same guidance formula, louder data.

### More data, better data: pixel art, and the last ingredient

Or so we concluded. But the COCO lesson was narrower: those 167 photographs contain almost no class structure at 16x16. That is a property of *that* data, not of real data in general. So let's go shopping for a dataset that does have structure: 20,000 labeled 24x24 pixel-art images (unstonio/pixelgpt-24x24-20k on Hugging Face, category labels included, reduced to 16x16 grayscale for the browser). Pixel art is the opposite of a blurry thumbnail: dark background, one crisp bright shape, and categories a human can sort at a glance - dragons, bees, flowers, helmets, potions, buildings.

<div data-corpus-url="/assets/data/pixelart16.csv" data-corpus-var="pixel_text"></div>

The parse cell is the COCO cell verbatim. Notice that we reuse the same variable names - `CLASSES`, `cdata`, `caps` - on purpose: nothing in the pipeline cares what the pixels mean. Every function below (`ccond`, `cforward`, `eval_with`, `csample`) reads these globals and just works on the new data:

```python-exec
rows = pixel_text.strip().split("\n")[1:]      # skip the header
CLASSES = []                     # rebuilt for the new dataset
cdata = []
caps = {}
for ln in rows:
    parts = ln.split(",")
    if len(parts) < 258:
        continue        # not data (stale build served a page?)
    word = parts[0]
    if word not in CLASSES:
        CLASSES.append(word)
    if word not in caps:
        caps[word] = parts[1].strip('"')
    px = [float(v) * 2 - 1 for v in parts[2:]]
    cdata.append((px, CLASSES.index(word)))

print(f"{len(cdata)} pixel-art images, {len(CLASSES)} classes: {CLASSES}")
for w in CLASSES:
    print(f'  {w:9s} e.g. "{caps[w]}"')
```

And the preview - three real images per class. This time a dragon is visibly a dragon, a bee is a striped blob with wings, a potion is a mug. No honesty paragraph needed about recognizing them; you can sort these yourself:

```python-exec
for wi, word in enumerate(CLASSES):
    imgs = [x for x, i in cdata if i == wi][:3]
    for j, x in enumerate(imgs):
        plt.imshow(show16(x), label=f"{word} #{j + 1}")
    plt.title(f"pixel art: {word}")
    plt.show()
```

Same denoiser, fresh weights, same training loop - reset the Adam clock first, for the reason we discovered two sections ago (its bias correction assumes `t` starts at 1). Another honest two minutes on a laptop, several in the browser:

```python-exec
random.seed(1234)                                   # fresh weights, same shape
CW1 = rand_matrix(CH, CDIN, math.sqrt(2 / CDIN)); Cb1 = [0.0] * CH
CW2 = rand_matrix(CDOUT, CH, 0.0)
Cb2 = [0.0] * CDOUT
CNULL = len(CLASSES)
CEMB = rand_matrix(len(CLASSES) + 1, TE, 0.1)
print(f"same denoiser, fresh weights: {CDIN} -> {CH} -> {CDOUT}, "
      f"plus a {len(CLASSES) + 1}x{TE} word table")
```

```python-exec
B = 16
steps = 1200
_t_adam = 0           # fresh Adam clock again
t0 = time.time()
for step in range(steps + 1):
    _t_adam += 1
    gW1 = [[0.0] * CDIN for _ in range(CH)]; gb1 = [0.0] * CH
    gW2 = [[0.0] * CH for _ in range(CDOUT)]; gb2 = [0.0] * CDOUT
    gE = [[0.0] * TE for _ in range(len(CLASSES) + 1)]
    loss_b = 0.0
    for _ in range(B):
        x0, wi = random.choice(cdata)
        if random.random() < 0.1:
            wi = CNULL
        tt = 25 + random.randrange(T - 25)
        noise = [random.gauss(0, 1) for _ in range(256)]
        xin = q_sample(x0, tt, noise) + ccond(wi, tt)
        pred, h1 = cforward(xin)
        loss_b += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 256
        d2 = [2 * (p_ - n) / (256 * B) for p_, n in zip(pred, noise)]
        for i in range(CDOUT):
            for j in range(CH):
                gW2[i][j] += d2[i] * h1[j]
            gb2[i] += d2[i]
        dh1 = vecmat(d2, CW2)
        dh1 = [d * (1.0 if h > 0 else 0.0) for d, h in zip(dh1, h1)]
        for i in range(CH):
            for j in range(CDIN):
                gW1[i][j] += dh1[i] * xin[j]
            gb1[i] += dh1[i]
        dxin = vecmat(dh1, CW1)
        for i in range(TE):
            gE[wi][i] += dxin[256 + i]
    adam('CW1', CW1, gW1); adam('Cb1', Cb1, gb1)
    adam('CW2', CW2, gW2); adam('Cb2', Cb2, gb2)
    adam('CEMB', CEMB, gE)
    if step % 100 == 0:
        progress(step, steps, suffix=f"loss {loss_b / B:.4f}")
    if step % 500 == 0:
        print(f"step {step:4d}  loss {loss_b / B:.4f}")
print(f"trained in {time.time() - t0:.0f}s")
```

Same rigor as before - the three measurements, now on data that visibly has structure. `eval_with` and `nearest_proto` need no redefinition; only the prototypes and spreads are recomputed:

```python-exec
print(f"eval: correct word {eval_with('right'):.4f}  "
      f"no word {eval_with('null'):.4f}  wrong word {eval_with('wrong'):.4f}")

gmean = [sum(x[k] for x, _ in cdata) / len(cdata) for k in range(256)]
protos = []
for wi in range(len(CLASSES)):
    imgs = [x for x, i in cdata if i == wi]
    protos.append([sum(im[k] for im in imgs) / len(imgs) for k in range(256)])
v_in = sum((x[k] - protos[wi][k]) ** 2 for x, wi in cdata
           for k in range(256)) / (len(cdata) * 256)
v_gl = sum((x[k] - gmean[k]) ** 2 for x, _ in cdata
           for k in range(256)) / (len(cdata) * 256)
print(f"spread within a class: {v_in:.3f}   spread overall: {v_gl:.3f}")

hits = sum(1 for x, wi in cdata if nearest_proto(x) == wi)
print(f"real images closest to their own class average: "
      f"{hits}/{len(cdata)} (chance is 1/{len(CLASSES)})")
```

Line the three datasets up side by side:

| dataset | within-class share of spread | real images that self-sort | conditional training |
| --- | --- | --- | --- |
| sprites (procedural, 400) | 85% | 75% (chance 25%) | works - rows obey |
| COCO photos (167) | 97% | 36% (chance 17%) | fails - word unused |
| pixel art (270) | 96% | 54% (chance 17%) | keep reading |

The pixel-art data really is different: its class averages have visible shapes, and real images sort themselves correctly half the time. The structure the COCO set lacked is present. And the trained model? The eval line says the word still does not move the loss. Here is the gallery, same layout as before - two real, two generated per class:

```python-exec
random.seed(5)
hits = 0
for wi, word in enumerate(CLASSES):
    imgs = [x for x, i in cdata if i == wi][:2]
    plt.imshow(show16(imgs[0]), label=f"{word} (real)")
    plt.imshow(show16(imgs[1]), label=f"{word} (real)")
    for j in range(2):
        s = csample(word)
        hits += 1 if nearest_proto(s) == wi else 0
        plt.imshow(show16(s), label=f"{word} (gen)")
    plt.title(f"You say '{word}', the model draws its idea of a {word}")
    plt.show()
print(f"generated images closest to the requested class average: "
      f"{hits}/12 (chance is 2/12)")
```

The word does not bite here either, and we can say exactly why, because this failure is *different* from COCO's. The data has structure: 55% of its pixels are near-black background. The generated images come out mid-gray speckle instead - the model has not even learned the global darkness yet, and the loss curve was still falling when the clock ran out. This time the bottleneck is not the data. It is the extractor: 30,000 parameters and two laptop-minutes cannot distill 270 real images into six crisp shapes. (One row will look like it steers: "building" images are the darkest class, and undertrained samples are dark, so they sit closest to the building average. That is an artifact of the collapse, not obedience - check the other five rows before celebrating.)

Three acts so far. Procedural sprites: structure is free and infinite, and a toy model obeys. COCO photographs: no class structure exists at thumbnail scale, and nothing can be learned. Pixel art: structure exists, and a toy model *still* cannot cash it - because extracting structure from real data takes parameters and compute, not just the right equations. Conditioning is the steering wheel; structured data is the road; scale is the engine. But there is one move left, and it is the one every practitioner reaches for first when the machine is too small: shrink the problem.

### Shrinking the problem until it wins

The sprites won at 8x8 with a 64-dimensional input and one hidden layer. The pixel-art model lost at 16x16 with four times the pixels and the same two minutes. The equations are identical in both, so the honest question is not "does conditioning work on real data" but "how small must a real problem get before this machine can steer it?" Two shrinking moves. First, downsample the 270 images from 16x16 to 8x8, averaging each 2x2 block. Second, keep only the three most separable classes: measuring all fifteen pairs of class averages says bee, potion, and building stand furthest apart (the dragon and flower prototypes nearly overlap). The 135 survivors still self-sort to their own class average 67% of the time against a 33% chance - the structure survives the shrink:

<div data-corpus-url="/assets/data/pixelart8.csv" data-corpus-var="pixel8_text"></div>

```python-exec
rows = pixel8_text.strip().split("\n")[1:]      # skip the header
VOCAB = []                     # rebuilt: 3 classes now
data = []
caps = {}
for ln in rows:
    parts = ln.split(",")
    if len(parts) < 66:
        continue        # not data (stale build served a page?)
    word = parts[0]
    if word not in VOCAB:
        VOCAB.append(word)
    if word not in caps:
        caps[word] = parts[1].strip('"')
    px = [float(v) * 2 - 1 for v in parts[2:]]
    data.append((px, VOCAB.index(word)))

print(f"{len(data)} images, {len(VOCAB)} classes: {VOCAB}")
for w in VOCAB:
    print(f'  {w:9s} e.g. "{caps[w]}"')
```

```python-exec
for wi, word in enumerate(VOCAB):
    imgs = [x for x, i in data if i == wi][:3]
    for j, x in enumerate(imgs):
        plt.imshow(show01(x), label=f"{word} #{j + 1}")
    plt.title(f"8x8 pixel art: {word}")
    plt.show()
```

Small, but real: the bee is a center blob, the potion is an upright mug, the building is mostly darkness with a bright edge. Now the point of the whole chapter. We do not write one new line of model code. The network is the sprite model - `forward`, `cond`, `q_sample`, `sample`, the embedding table, the dropout, the guidance knob - with fresh weights and a fresh Adam clock. Only the data changed, and the data is real this time:

```python-exec
random.seed(42)                                   # fresh weights, sprite shape
W1 = rand_matrix(H, DIN, math.sqrt(2 / DIN)); b1 = [0.0] * H
W2 = rand_matrix(DOUT, H, 0.0)
b2 = [0.0] * DOUT
NULL = len(VOCAB)                                 # 3 classes + the NULL row
EMB = rand_matrix(len(VOCAB) + 1, TE, 0.1)
print(f"sprite-sized denoiser: {DIN} -> {H} -> {DOUT}, "
      f"plus a {len(VOCAB) + 1}x{TE} word table")
```

```python-exec
B = 16
steps = 3000
_t_adam = 0           # fresh Adam clock
history = []
for step in range(steps + 1):
    _t_adam += 1
    gW1 = [[0.0] * DIN for _ in range(H)]; gb1 = [0.0] * H
    gW2 = [[0.0] * H for _ in range(DOUT)]; gb2 = [0.0] * DOUT
    gE = [[0.0] * TE for _ in range(len(VOCAB) + 1)]
    loss_b = 0.0
    for _ in range(B):
        x0, wi = random.choice(data)
        if random.random() < 0.1:
            wi = NULL
        tt = random.randrange(T)
        noise = [random.gauss(0, 1) for _ in range(64)]
        xin = q_sample(x0, tt, noise) + cond(wi, tt)
        pred, h1 = forward(xin)
        loss_b += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 64
        d2 = [2 * (p_ - n) / (64 * B) for p_, n in zip(pred, noise)]
        for i in range(DOUT):
            for j in range(H):
                gW2[i][j] += d2[i] * h1[j]
            gb2[i] += d2[i]
        dh1 = vecmat(d2, W2)
        dh1 = [d * (1.0 if h > 0 else 0.0) for d, h in zip(dh1, h1)]
        for i in range(H):
            for j in range(DIN):
                gW1[i][j] += dh1[i] * xin[j]
            gb1[i] += dh1[i]
        dxin = vecmat(dh1, W1)
        for i in range(TE):
            gE[wi][i] += dxin[64 + i]
    adam('W1', W1, gW1); adam('b1', b1, gb1)
    adam('W2', W2, gW2); adam('b2', b2, gb2)
    adam('EMB', EMB, gE)
    if step % 100 == 0:
        history.append((step, loss_b / B))
        progress(step, steps, suffix=f"loss {loss_b / B:.4f}")
    if step % 500 == 0:
        print(f"step {step:4d}  loss {loss_b / B:.4f}")

random.seed(999)
evals = [(random.choice(data), random.randrange(T),
          [random.gauss(0, 1) for _ in range(64)]) for _ in range(200)]
total = 0.0
for (x0, wi), tt, noise in evals:
    pred, _ = forward(q_sample(x0, tt, noise) + cond(wi, tt))
    total += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 64
print(f"eval loss: {total / 200:.4f}")
```

Same two minutes on a laptop - it *is* the sprite model, 64-dimensional input and all. And the measurements, in the same rigorous order as the two failures before it. The eval loss lands near 0.25, sprite territory, far below the 0.83 wall the 16x16 models never broke. The word separates: correct beats no word beats wrong word. And real 8x8 images sort themselves:

```python-exec
def eval8(mode):
    random.seed(999)
    ev = [(random.choice(data), random.randrange(T),
           [random.gauss(0, 1) for _ in range(64)]) for _ in range(200)]
    tot = 0.0
    for (x0, wi), tt, noise in ev:
        if mode == "null":
            wi = NULL
        elif mode == "wrong":
            wi = (wi + 1) % len(VOCAB)
        pred, _ = forward(q_sample(x0, tt, noise) + cond(wi, tt))
        tot += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 64
    return tot / 200

print(f"eval: correct word {eval8('right'):.4f}  "
      f"no word {eval8('null'):.4f}  wrong word {eval8('wrong'):.4f}")

protos8 = []
for wi in range(len(VOCAB)):
    imgs = [x for x, i in data if i == wi]
    protos8.append([sum(im[k] for im in imgs) / len(imgs) for k in range(64)])

def nearest8(x):
    d = [sum((a - b) ** 2 for a, b in zip(x, p)) for p in protos8]
    return d.index(min(d))

hits = sum(1 for x, wi in data if nearest8(x) == wi)
print(f"real images closest to their own class average: "
      f"{hits}/{len(data)} (chance is 1/{len(VOCAB)})")
```

And now the payoff the whole chapter has been pointing at. One real image and three generated ones per class, the same `sample()` function that drew sprite aliens, the same guidance of 2 - but every generated image started as noise and was steered by a real word from a real dataset:

```python-exec
random.seed(123)
hits = 0
for wi, word in enumerate(VOCAB):
    imgs = [x for x, i in data if i == wi][:1]
    plt.imshow(show01(imgs[0]), label=f"{word} (real)")
    for j in range(3):
        s = sample(word)
        hits += 1 if nearest8(s) == wi else 0
        plt.imshow(show01(s), label=f"{word} #{j + 1}")
    plt.title(f"You say '{word}', the model draws a {word}")
    plt.show()
print(f"generated images closest to the requested class average: "
      f"{hits}/9 (chance is 3/9)")
```

In our runs, three quarters or more of the generated images land closest to the class average of the word we asked for, against a chance rate of one in three. Bee prompts produce center-blob insects, potion prompts produce upright mugs, building prompts produce dark frames with a bright edge. They are 8x8 and blobby - and they are *obedient*, on real data, with the same equations that failed twice at larger scale.

Four acts, one lesson. Toy sprites obey: structure came free with the code. Photographs say nothing at thumbnail scale: no structure to amplify. Pixel art at 16x16 has the structure, and our extractor is too small to use it. Shrink the problem to 8x8 and three classes, and the sprite-sized network steers real, human-made data with real category labels. The equations never changed once; only the fit between problem size and model size did.

The honest footnote: the real field took the other exit. Faced with "shrink the problem or grow the machine", it grew everything - billion-image datasets, billion-parameter U-Nets, ten thousand GPUs - which is the only reason you can type "a dragon" into Stable Diffusion at 1024x1024 and get a dragon in full color. This chapter cannot fit that sentence in a browser tab. But it can prove, and just did, every clause that makes it necessary.

### Full color: the same equations, three channels

Everything on this page so far has been one channel of gray. Color is not a new idea - it is the same tensor with three channels, red, green, and blue, and the denoiser never needs to know. Our source set is the same pixel art, kept in color this time: 270 thumbnails at 8x8x3, which is 192 numbers per image (unstonio/pixelgpt-24x24-20k, reduced for the browser).

<div data-corpus-url="/assets/data/pixelart8rgb.csv" data-corpus-var="rgb_text"></div>

192 numbers is fewer than the 256 that failed at 16x16 grayscale, and we tried it exactly that way first: the same conditional MLP, 2000 steps, three minutes. The 16x16 story repeated - eval loss stuck near 0.65, and not one class obeyed its word. You already know the move from the last section: shrink the problem once more. Downsample to 4x4, keeping all three channels, and each image is 48 numbers - *fewer* than the 64 grayscale numbers that already won. The silhouettes die at 4x4, but the hues survive, and hue is most of how you tell a bee from a building anyway. First, which classes should play? We measured prototype distances in full RGB across all six: dragons and helmets still huddle together even in color, so they stay on the bench. The grayscale trio - bee, potion, building - gains a fourth member: flower.

| classes measured at 8x8 RGB | self-sort | chance |
| --- | --- | --- |
| all six | 55% | 17% |
| bee, potion, building (the grayscale trio) | 76% | 33% |
| those three + flower (our four) | 71% | 25% |

```python-exec
KEEP = ["bee", "flower", "potion", "building"]   # widest RGB prototypes
rows = rgb_text.strip().split("\n")[1:]          # skip the header
VOCAB = []
data = []
caps = {}

def down2(x):
    """8x8 RGB flat -> 4x4 RGB flat, 2x2 mean per channel."""
    out = []
    for r in range(0, 8, 2):
        for c in range(0, 8, 2):
            ids = [r * 8 + c, r * 8 + c + 1, (r + 1) * 8 + c, (r + 1) * 8 + c + 1]
            for k in range(3):
                out.append(sum(x[3 * i + k] for i in ids) / 4)
    return out

for ln in rows:
    parts = ln.split(",")
    if len(parts) < 194:
        continue        # not data (stale build served a page?)
    word = parts[0]
    if word not in KEEP:
        continue
    if word not in VOCAB:
        VOCAB.append(word)
    if word not in caps:
        caps[word] = parts[1].strip('"')
    px = [float(v) * 2 - 1 for v in parts[2:]]
    data.append((down2(px), VOCAB.index(word)))

def show_rgb(x):
    """Flat 48-vector (+-1) -> 4x4 grid of [r, g, b] in 0..1."""
    def px(i):
        return [max(0.0, min(1.0, (x[3 * i + k] + 1) / 2)) for k in range(3)]
    return [[px(r * 4 + c) for c in range(4)] for r in range(4)]

print(f"{len(data)} color images, {len(VOCAB)} classes: {VOCAB}")
```

The preview needs no grayscale conversion this time - `plt.imshow` takes the HxWx3 grid directly. Yellow-and-black bees, pink-and-green flowers, brown potion mugs, gray buildings:

```python-exec
for wi, word in enumerate(VOCAB):
    imgs = [x for x, i in data if i == wi][:3]
    for j, x in enumerate(imgs):
        plt.imshow(show_rgb(x), label=f"{word} #{j + 1}")
    plt.title(f"real color thumbnails: {word}")
    plt.show()
```

Same network, fresh weights, 48 numbers in and 48 out. Same embedding table, same 10% dropout, same guidance knob, fresh Adam clock. About two minutes on a laptop, several in the browser:

```python-exec
DIN, H, DOUT = 48 + TE, 96, 48
random.seed(42)
W1 = rand_matrix(H, DIN, math.sqrt(2 / DIN)); b1 = [0.0] * H
W2 = rand_matrix(DOUT, H, 0.0)
b2 = [0.0] * DOUT
NULL = len(VOCAB)                                 # 4 classes + the NULL row
EMB = rand_matrix(len(VOCAB) + 1, TE, 0.1)
print(f"color denoiser: {DIN} -> {H} -> {DOUT}, plus a {len(VOCAB) + 1}x{TE} word table")
```

```python-exec
B = 16
steps = 3000
_t_adam = 0           # fresh Adam clock
history = []
for step in range(steps + 1):
    _t_adam += 1
    gW1 = [[0.0] * DIN for _ in range(H)]; gb1 = [0.0] * H
    gW2 = [[0.0] * H for _ in range(DOUT)]; gb2 = [0.0] * DOUT
    gE = [[0.0] * TE for _ in range(len(VOCAB) + 1)]
    loss_b = 0.0
    for _ in range(B):
        x0, wi = random.choice(data)
        if random.random() < 0.1:
            wi = NULL
        tt = random.randrange(T)
        noise = [random.gauss(0, 1) for _ in range(48)]
        xin = q_sample(x0, tt, noise) + cond(wi, tt)
        pred, h1 = forward(xin)
        loss_b += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 48
        d2 = [2 * (p_ - n) / (48 * B) for p_, n in zip(pred, noise)]
        for i in range(DOUT):
            for j in range(H):
                gW2[i][j] += d2[i] * h1[j]
            gb2[i] += d2[i]
        dh1 = vecmat(d2, W2)
        dh1 = [d * (1.0 if h > 0 else 0.0) for d, h in zip(dh1, h1)]
        for i in range(H):
            for j in range(DIN):
                gW1[i][j] += dh1[i] * xin[j]
            gb1[i] += dh1[i]
        dxin = vecmat(dh1, W1)
        for i in range(TE):
            gE[wi][i] += dxin[48 + i]
    adam('W1', W1, gW1); adam('b1', b1, gb1)
    adam('W2', W2, gW2); adam('b2', b2, gb2)
    adam('EMB', EMB, gE)
    if step % 100 == 0:
        history.append((step, loss_b / B))
        progress(step, steps, suffix=f"loss {loss_b / B:.4f}")
    if step % 500 == 0:
        print(f"step {step:4d}  loss {loss_b / B:.4f}")

random.seed(999)
evals = [(random.choice(data), random.randrange(T),
          [random.gauss(0, 1) for _ in range(48)]) for _ in range(200)]
total = 0.0
for (x0, wi), tt, noise in evals:
    pred, _ = forward(q_sample(x0, tt, noise) + cond(wi, tt))
    total += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 48
print(f"eval loss: {total / 200:.4f}")
```

The measurements, one last time, with one new twist: color likes a firmer hand on the guidance knob. At `w = 2` about two thirds of samples obey; at `w = 3` nearly all of them do, so we sample with 3:

```python-exec
def eval_rgb(mode):
    random.seed(999)
    ev = [(random.choice(data), random.randrange(T),
           [random.gauss(0, 1) for _ in range(48)]) for _ in range(200)]
    tot = 0.0
    for (x0, wi), tt, noise in ev:
        if mode == "null":
            wi = NULL
        elif mode == "wrong":
            wi = (wi + 1) % len(VOCAB)
        pred, _ = forward(q_sample(x0, tt, noise) + cond(wi, tt))
        tot += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 48
    return tot / 200

print(f"eval: correct word {eval_rgb('right'):.4f}  "
      f"no word {eval_rgb('null'):.4f}  wrong word {eval_rgb('wrong'):.4f}")

protos_rgb = []
for wi in range(len(VOCAB)):
    imgs = [x for x, i in data if i == wi]
    protos_rgb.append([sum(im[k] for im in imgs) / len(imgs) for k in range(48)])

def nearest_rgb(x):
    d = [sum((a - b) ** 2 for a, b in zip(x, p)) for p in protos_rgb]
    return d.index(min(d))

hits = sum(1 for x, wi in data if nearest_rgb(x) == wi)
print(f"real images closest to their own class average: "
      f"{hits}/{len(data)} (chance is 1/{len(VOCAB)})")
```

And the finale, in full color. One real thumbnail and three generated ones per class. Judge them by eye, not just by the prototype count: the bee row should buzz yellow and black, the flower row should bloom pink and green, potions should pour brown and copper, buildings should sit gray and dark:

```python-exec
def rgbsample(word, guidance=3.0):
    wi = VOCAB.index(word)
    x = [random.gauss(0, 1) for _ in range(48)]
    for tt in range(T - 1, -1, -1):
        pc, _ = forward(x + cond(wi, tt))      # with the word
        pu, _ = forward(x + cond(NULL, tt))    # without any word
        pred = [u + guidance * (c - u) for c, u in zip(pc, pu)]
        ab = alpha_bar[tt]
        ab_prev = alpha_bar[tt - 1] if tt > 0 else 1.0
        x0 = [(xi - math.sqrt(1 - ab) * e) / math.sqrt(ab)
              for xi, e in zip(x, pred)]
        x0 = [max(-1.0, min(1.0, v)) for v in x0]
        k1 = math.sqrt(ab_prev) * betas[tt] / (1 - ab)
        k2 = math.sqrt(alphas[tt]) * (1 - ab_prev) / (1 - ab)
        mean = [k1 * a + k2 * xi for a, xi in zip(x0, x)]
        if tt > 0:
            s = math.sqrt(betas[tt])
            x = [m + s * random.gauss(0, 1) for m in mean]
        else:
            x = mean
    return x

random.seed(123)
hits = 0
for wi, word in enumerate(VOCAB):
    imgs = [x for x, i in data if i == wi][:1]
    plt.imshow(show_rgb(imgs[0]), label=f"{word} (real)")
    for j in range(3):
        s = rgbsample(word)
        hits += 1 if nearest_rgb(s) == wi else 0
        plt.imshow(show_rgb(s), label=f"{word} #{j + 1}")
    plt.title(f"You say '{word}', the model draws a {word}")
    plt.show()
print(f"generated images closest to the requested class average: "
      f"{hits}/12 (chance is 3/12)")
```

In our runs, about three quarters or more of the generated thumbnails land closest to the requested class, against a one-in-four chance rate - and unlike the grayscale win, you can *see* it without any metric, because the colors themselves obey. Notice what just happened, because it is the quiet miracle of this whole course: the network was never told that red exists, or that pixels have channels, or that bees are yellow. It denoises a vector of 48 numbers. Color fell out of the same equations for free.

That is the chapter. Sprites obeyed because their structure was free. Photographs had nothing to say at thumbnail scale. Pixel art had structure that outgrew our extractor at 16x16, so we shrank the problem until the extractor fit - first in grayscale, now in color. Every step used the same forward process, the same noise-prediction loss, the same guidance formula. The only thing that ever changed was the size of the fight.

### How the real ones do it

Stable Diffusion is this chapter wearing better clothes. Three upgrades, no new ideas:

- **Words become word pieces, embedded by a frozen CLIP transformer.** Our little 5-row table becomes a 77-token sequence of 768-dimensional vectors, produced by a text encoder that was trained separately on image-caption pairs and never touches the diffusion loss.
- **Addition becomes cross-attention.** We add the word to the time embedding, which is crude - the word affects every pixel identically. A U-Net instead runs [cross-attention](/courses/machine-learning/attention-and-transformers/) at every block: the image features are the queries, the token embeddings are the keys and values, so different regions can attend to different words. "A red cube beside a blue sphere" needs that; "alien" does not.
- **Prompts obey because of classifier-free guidance - the knob you just turned.** Our sampler ran two predictions per step and pushed away from the unconditional one with `w = 2`. Production systems use the identical formula with `w` around 7, which is why their prompts are law while ours is a strong suggestion. Crank `guidance` in the gallery cell and watch the rows sharpen, then hollow out - every prompt interface you have ever used hides this same trade-off under a slider.

#> mermaid: caption="Two ways to make a model listen: addition (this chapter) vs cross-attention (Stable Diffusion)"
graph TB
  WE["word embedding (learned)"] --> PLUS((+))
  TE2["time embedding"] --> PLUS
  PLUS --> MLP["MLP denoiser"]
  CLIP["frozen CLIP text transformer"] --> TOK["token embeddings"]
  UNET["U-Net features"] --> XA["cross-attention at every block"]
  TOK --> XA
  XA --> UNET
#!

### Carry forward

- **Conditioning is a passenger, not a new engine.** The DDPM from Chapter 6 survived intact: same forward process, same noise-prediction loss, same ancestral walk. The word just rode along in the input.
- **An embedding table is a dictionary the network rewrites.** It starts as noise, and error signal alone arranges "alien" and "box" into different directions.
- **Same noise, different word, different image.** Conditioning is causation you can see, which is why the first column of the gallery matters.
- **Real data changes the cost, not the math.** One CSV of photographs and captions ran through the same code - and its honest answer was "bring more data and a bigger network". That answer is the whole story of modern text-to-image.
- **Structure is necessary, not sufficient.** The pixel-art set has it (a dragon self-sorts as a dragon), yet the toy model still fails, because extracting structure from real data takes parameters and compute. Steering wheel, road, engine: conditioning, data, scale.
- **Shrink the problem until it wins.** At 8x8 and three classes, the sprite-sized network steers real data - most samples land on the requested class, several times the chance rate. The equations never changed; the fit between problem size and model size did.
- **Color is free.** Three channels are the same vector three times longer. The network never learns what red is; it denoises numbers, and the numbers come out yellow-and-black when you ask for a bee.
- **Guidance is the obedience dial.** Next chapter, [Latent Diffusion & Super-Resolution](/courses/image-generation/latent-diffusion/), shrinks what the model diffuses - everything about conditioning stays exactly as you learned it here.

### Further reading

- Ho & Salimans, *Classifier-Free Diffusion Guidance* (2022) - two pages that explain the knob every prompt interface exposes.
- Radford et al., *Learning Transferable Visual Models From Natural Language Supervision* (CLIP, 2021) - where the text encoder comes from.
- Rombach et al., *High-Resolution Image Synthesis with Latent Diffusion Models* (2022) - the Stable Diffusion paper; the conditioning section will feel like home.

### Practice checklist

- [ ] Sweep the guidance scale: regenerate the gallery with `guidance=1.0`, then `4.0`. Which rows sharpen first, and what artifacts appear at the high end? Explain in terms of the unconditional guess being subtracted away.
- [ ] The dropout rate is 10%. Retrain with 30% and compare guidance `w = 2` samples against the chapter's - what does more dropout buy, and what does it cost?
- [ ] Invent a fifth family (diagonal stripes, say), give it a word, and retrain. How many steps before the new word obeys?
- [ ] After training, print the pairwise dot products of the four word rows of `EMB`. Which two words ended up closest, and does that match the families' visual similarity?
- [ ] Change the conditioning from addition to concatenation (give the network `64 + 16 + 16` inputs). Which learns faster, and why might addition still be preferable?
- [ ] On the photo data, compute each class's top-half minus bottom-half mean brightness from `cdata`. Which two classes are furthest apart? Retrain the photo model on just those two and measure whether the word starts to bite - what does that tell you about prompt granularity at small scale?
- [ ] The pixel-art loss was still falling at step 1200. Run the same cell with `steps = 4800` (go make tea) and re-measure: eval, self-sort of real images, and generated nearest-prototype per class. At what step count does the first word start to bite, and which class obeys first?
- [ ] The 8x8 set was downsampled with 2x2 mean pooling. Regenerate it with max pooling (brightest pixel of each 2x2 block) and retrain: which silhouette style self-sorts better, and does the steering sharpen or smear?
