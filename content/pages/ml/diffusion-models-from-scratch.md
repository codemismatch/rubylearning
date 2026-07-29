---
layout: tutorial
title: "Diffusion Models from Scratch: Sprite Training"
permalink: /courses/image-generation/diffusion-models-from-scratch/
difficulty: advanced
author: Pankaj Doharey
summary: Train a real denoising diffusion model (DDPM) in pure Python on procedurally generated 8x8 sprites, then sample brand-new sprites from pure noise - entirely in the browser.
theme: pylearning
previous_tutorial:
  title: "Diffusion Models: DDPM from First Principles"
  url: /courses/image-generation/ddpm-from-first-principles/
next_tutorial:
  title: "Latent Diffusion & Super-Resolution"
  url: /courses/image-generation/latent-diffusion/
date: 2026-04-07
---

In the previous chapter we built a DDPM on 1D data and watched it denoise a distribution back into shape. Now we do it for real images. A **diffusion model** learns to turn pure random noise into data. There are no labels anywhere - not even the self-supervised "next token" kind. The training signal is noise itself: we corrupt a real image with a known amount of Gaussian noise, and teach a network to predict *which noise was added*. Remove the noise a little at a time and a clean image appears.

That idea - DDPM, Denoising Diffusion Probabilistic Models - is the engine behind modern image generators like Stable Diffusion, DALL-E 3, and Midjourney. We will build a real one, small enough to train in this page: forward noising, a noise-predicting network with a time embedding, manual backpropagation, and the ancestral sampling loop. Our data is procedurally generated 8x8 sprites - infinite, free, and needing no labeling, because diffusion is unsupervised.

#> mermaid: caption="Figure 1: Forward noising destroys data step by step; the learned reverse process rebuilds it"
graph LR
  X0[x0: clean sprite] --> X1[x1] --> X2[x2] --> XN[xT: pure noise]
  XN -. learned denoising .-> X2
  X2 -. learned denoising .-> X1
  X1 -. learned denoising .-> X0
#!

The forward process (solid arrows) is fixed math - no learning. Each step adds a small amount of Gaussian noise: `x_t = sqrt(alpha_t) * x_{t-1} + sqrt(beta_t) * noise`. After T = 200 steps nothing of the sprite remains. The reverse process (dashed arrows) is the model: given a noisy `x_t` and the time `t`, predict the noise, subtract a little of it, repeat.

### The dataset: procedural sprites

We need images that are free, infinite, and simple enough for a tiny model. So we draw them in code: 8x8 grids of ±1 pixels from four families - mirrored "space invader" aliens (a random 4-wide left half, reflected), vertical bars, boxes, and crosses. Each sprite flattens to a 64-dimensional vector.

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

random.seed(7)
families = [make_alien, make_alien, make_bars, make_box, make_cross]
sprites = [[v for row in random.choice(families)() for v in row]
           for _ in range(300)]

def show01(x, lo=-1.0, hi=1.0):
    """Flattened sprite -> 8x8 grid of 0..1 values for plt.imshow."""
    return [[max(0.0, min(1.0, (x[r * 8 + c] - lo) / (hi - lo)))
             for c in range(8)] for r in range(8)]

print(f"{len(sprites)} sprites, each {len(sprites[0])} numbers")
for r in range(8):      # an alien sprite as ASCII art
    print("".join("#" if sprites[1][r * 8 + c] > 0 else "."
                  for c in range(8)))
```

And four of them as actual images - the mirrored aliens, bars, boxes, and crosses are all in there:

```python-exec
for i in range(4):
    plt.imshow(show01(sprites[i]), label=f"sprite {i}")
plt.title("Training sprites (8x8)")
plt.show()
```

### Forward diffusion: a schedule of noise

The schedule controls how fast signal dies. We use T = 200 steps with beta growing linearly from 0.0001 to 0.05, and precompute the cumulative product `alpha_bar_t` - the fraction of signal surviving to step t. Because Gaussian noise composes, we can jump straight to any t in one formula: `x_t = sqrt(alpha_bar_t) * x0 + sqrt(1 - alpha_bar_t) * noise`.

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

print(f"signal left at t=50:  {alpha_bar[50]:.3f}")
print(f"signal left at t=150: {alpha_bar[150]:.3f}")
print(f"signal left at t=199: {alpha_bar[199]:.4f}  (nearly pure noise)")

demo_noise = [random.gauss(0, 1) for _ in range(64)]
for t in [0, 50, 100, 150, 199]:
    plt.imshow(show01(q_sample(sprites[1], t, demo_noise), lo=-2, hi=2),
               label=f"t={t}")
plt.title("One sprite, noised to increasing t")
plt.show()
```

By t = 199 the sprite is essentially gone. The model's job is to walk this film backwards.

### The denoiser: an MLP that predicts noise

The network takes a noisy 64-vector plus a **time embedding** - 16 sine/cosine features of t (the same trick as Chapter 17's positional encoding) so the network knows how much noise to expect - and predicts the 64 noise values that were added. This epsilon-prediction parameterization is the standard DDPM choice: predicting noise works much better than predicting the clean image directly. One hidden layer of 64 with ReLU is enough at this scale; the output layer starts at zero, a small trick that makes early training stable.

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

DIN, H, DOUT = 64 + TE, 64, 64
random.seed(42)
W1 = rand_matrix(H, DIN, math.sqrt(2 / DIN)); b1 = [0.0] * H
W2 = rand_matrix(DOUT, H, 0.0)                # zero-init output head
b2 = [0.0] * DOUT

def forward(x):
    """noisy 80-vector -> predicted noise (64). Returns cache too."""
    z1 = [a + b for a, b in zip(matvec(W1, x), b1)]
    h1 = [v if v > 0 else 0.0 for v in z1]
    out = [a + b for a, b in zip(matvec(W2, h1), b2)]
    return out, h1

n_params = H * DIN + H + DOUT * H + DOUT
print(f"denoiser: {DIN} -> {H} -> {DOUT}, {n_params} parameters")
```

### Training: predict the noise that was added

One training step is four random choices: pick a sprite, pick a time t, draw Gaussian noise, corrupt the sprite - then make the network predict that exact noise and descend the MSE. We train in small batches of 16 with the Adam optimizer (Chapter 5's gradient descent, plus a per-parameter adaptive step size: keep running averages of each gradient and its square, and scale the step by their ratio).

```python-exec
_ms, _vs, _t_adam = {}, {}, 0
def adam(name, p, g, lr=0.002, be1=0.9, be2=0.999, eps=1e-8):
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

Now the loop - 3000 steps with backpropagation written out by hand through the two linear layers. **This is the heavy cell: about 80 seconds here, and a few minutes in the browser** (Pyodide runs pure Python several times slower). An untrained model scores loss ~1.0 (predicting "zero noise" everywhere); watch it fall well below that.

```python-exec
B = 16
steps = 3000
history = []
for step in range(steps + 1):
    _t_adam += 1
    gW1 = [[0.0] * DIN for _ in range(H)]; gb1 = [0.0] * H
    gW2 = [[0.0] * H for _ in range(DOUT)]; gb2 = [0.0] * DOUT
    loss_b = 0.0
    for _ in range(B):                      # one batch
        x0 = random.choice(sprites)
        tt = random.randrange(T)
        noise = [random.gauss(0, 1) for _ in range(64)]
        xin = q_sample(x0, tt, noise) + TE_CACHE[tt]
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
    adam('W1', W1, gW1); adam('b1', b1, gb1)
    adam('W2', W2, gW2); adam('b2', b2, gb2)
    if step % 100 == 0:
        history.append((step, loss_b / B))
        progress(step, steps, suffix=f"loss {loss_b / B:.4f}")
    if step % 500 == 0:
        print(f"step {step:4d}  loss {loss_b / B:.4f}")

# honest eval: average loss over 200 fixed (sprite, t, noise) triples
random.seed(999)
evals = [(random.choice(sprites), random.randrange(T),
          [random.gauss(0, 1) for _ in range(64)]) for _ in range(200)]
total = 0.0
for x0, tt, noise in evals:
    pred, _ = forward(q_sample(x0, tt, noise) + TE_CACHE[tt])
    total += sum((p_ - n) ** 2 for p_, n in zip(pred, noise)) / 64
print(f"eval loss: {total / 200:.4f}")
```

The loss curve, from the recorded history:

```python-exec
plt.plot([s for s, _ in history], [l for _, l in history],
         label="noise-prediction MSE")
plt.title("DDPM training loss")
plt.xlabel("step")
plt.ylabel("loss")
plt.show()
```

An eval loss around 0.4 means the network genuinely identifies about 60% of the added noise variance - impossible without having learned what sprites look like. (The loss near t = 0 stays high; extracting a whisper of noise from an almost-clean image is intrinsically the hardest task, and it matters least for generation.)

### Sampling: from pure noise to a new sprite

Generation walks the film backwards. Start from pure Gaussian noise, then for t = 199 down to 0: predict the noise, reconstruct an estimate of x0 (clipped to the data range [-1, 1], since our pixels are ±1), and step to t-1 using the exact posterior mean plus a little fresh noise (except at t = 0). Two hundred small denoising steps later, a sprite crystallizes out of static.

```python-exec
def sample():
    x = [random.gauss(0, 1) for _ in range(64)]     # pure noise
    for tt in range(T - 1, -1, -1):
        pred, _ = forward(x + TE_CACHE[tt])
        ab = alpha_bar[tt]
        ab_prev = alpha_bar[tt - 1] if tt > 0 else 1.0
        x0 = [(xi - math.sqrt(1 - ab) * e) / math.sqrt(ab)
              for xi, e in zip(x, pred)]
        x0 = [max(-1.0, min(1.0, v)) for v in x0]   # clip to data range
        c1 = math.sqrt(ab_prev) * betas[tt] / (1 - ab)
        c2 = math.sqrt(alphas[tt]) * (1 - ab_prev) / (1 - ab)
        mean = [c1 * a + c2 * xi for a, xi in zip(x0, x)]
        if tt > 0:
            z = [random.gauss(0, 1) for _ in range(64)]
            s = math.sqrt(betas[tt])
            x = [m + s * zi for m, zi in zip(mean, z)]
        else:
            x = mean
    return x

random.seed(123)
samples = [sample() for _ in range(6)]
for i, s in enumerate(samples):
    plt.imshow(show01(s), label=f"sample {i}")
plt.title("Generated sprites - from pure noise")
plt.show()

for r in range(8):      # the first one as ASCII art
    print("".join("#" if samples[0][r * 8 + c] > 0 else "."
                  for c in range(8)))
```

Be honest about what you see: these are blobby, imperfect, and none of them is a carbon copy of a training sprite. That is the correct result at this scale. The model has clearly learned the *style* - dense blobs of pixels with rough edges, holes, and near-symmetries, in the same proportions as the data - rather than memorizing individuals. A pure-noise image would be salt-and-pepper with no structure; these have mass and shape. With a bigger network, more steps, and a larger dataset, the same loop produces crisply recognizable characters. Scale it by a trillion and it produces photographs.

### Where this leads

Three jumps take this toy to the systems you have heard of:

- **Latent diffusion.** Instead of noising pixels, compress images with an autoencoder and run diffusion in the smaller latent space - that is what makes Stable Diffusion cheap enough to run on a home GPU.
- **Conditioning.** Our sprites needed no labels. But you *can* feed extra input alongside the time embedding - a text-prompt embedding, a class label - and train the same way. The network then learns "denoise, in the direction of this prompt." That is where prompts enter: conditioning is optional, added on top of the unsupervised base. **Classifier-free guidance** (train occasionally with the prompt dropped, then at sampling time extrapolate between the conditional and unconditional predictions) is the dial that controls how literally the model follows the prompt.
- **Better samplers.** We used all 200 ancestral steps. DDIM, DPM-Solver and friends take larger, smarter strides and cut sampling to 20-50 steps with little quality loss.

To go deeper: Lilian Weng's "What are Diffusion Models?" is the clearest long-form explanation; the original DDPM paper (Ho et al., 2020) is short and readable after this chapter; and Karpathy's nanoGPT-style minimalism has a diffusion counterpart in the tiny "mnist-diffusion" codebases floating around GitHub - you now know every line they contain.

### Practice checklist

- [ ] Explain in one paragraph why predicting the *noise* (rather than the clean image) makes the training target equally hard at every t.
- [ ] Change the beta schedule's final value from 0.05 to 0.02, retrain, and use the printed `alpha_bar[199]` to explain why sampling gets worse.
- [ ] Sample with the x0-clipping line removed; describe what changes in the outputs and why clipping is legitimate here.
- [ ] Train on a single family (aliens only) and compare sample sharpness to the four-family model.
- [ ] The time embedding has width 16 - retrain with `TE = 4` and explain the failure mode in terms of what the network cannot tell apart.
- [ ] Sketch how you would add a "family label" input to make a conditional sprite generator; which two functions change?
