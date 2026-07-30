---
layout: tutorial
title: "Chapter 2 &ndash; Training Tricks: Initialization, Normalization, ResNets"
permalink: /courses/image-generation/training-tricks/
difficulty: intermediate
author: Pankaj Doharey
summary: "Learn the three practical tricks that make deep networks trainable: smart initialization, input normalization, and residual connections."
theme: pylearning
previous_tutorial:
  title: "Convolutions & CNNs from Scratch"
  url: /courses/image-generation/convolutions-cnns-from-scratch/
next_tutorial:
  title: "Autoencoders"
  url: /courses/image-generation/autoencoders/
date: 2026-07-29
---

Deep networks fail in boring ways before they fail in interesting ones. Gradients shrink to nothing ten layers down, activations explode to ±1000, or the model just refuses to move. Three tricks fix most of it, and they are small enough to implement in a page each: initialize weights to preserve variance, normalize inputs to a friendly scale, and let layers learn *differences* instead of full transformations.

### Trick 1: initialize for the variance you want

Multiply enough random numbers together and the result either vanishes or explodes - it depends only on their variance. Xavier initialization picks the variance so signals pass through a layer unchanged in scale:

```python-exec
import math, random
random.seed(2)

def layer_out(x, W):
    return [math.tanh(sum(w * v for w, v in zip(row, x))) for row in W]

def run_depth(fan_in, scale, layers=20):
    x = [random.gauss(0, 1) for _ in range(fan_in)]
    hist = []                       # variance after each layer, for the plot below
    for _ in range(layers):
        W = [[random.gauss(0, scale) for _ in range(fan_in)] for _ in range(fan_in)]
        x = layer_out(x, W)
        hist.append(sum(v * v for v in x) / fan_in)
    return hist

hist_random = run_depth(64, 1.0)
hist_xavier = run_depth(64, math.sqrt(1.0 / 64))
var_random, var_xavier = hist_random[-1], hist_xavier[-1]
print(f"variance after 20 layers, naive init: {var_random:.6f}")
print(f"variance after 20 layers, xavier init: {var_xavier:.4f}")
```

The naive version dies exponentially; the Xavier-scaled version is still alive twenty layers in. Same architecture, same data - only the starting numbers changed. Here is the same experiment drawn layer by layer, on a log scale so the cliff is visible:

```python-exec
depths = list(range(1, 21))
log10 = lambda vs: [math.log10(max(v, 1e-30)) for v in vs]
plt.plot(depths, log10(hist_random), label="naive init (scale 1.0)")
plt.plot(depths, log10(hist_xavier), label="xavier init (scale 1/sqrt(fan_in))")
plt.title("Activation variance vs depth")
plt.xlabel("layer")
plt.ylabel("log10 variance")
plt.show()
```

### Trick 2: normalize the inputs

Gradient descent prefers features on comparable scales. If one feature is in thousands and another in fractions, the loss surface stretches into a canyon and training zig-zags:

```python-exec
def standardize(rows):
    cols = list(zip(*rows))
    means = [sum(c) / len(c) for c in cols]
    stds = [(sum((v - m) ** 2 for v in c) / len(c)) ** 0.5 or 1.0 for c, m in zip(cols, means)]
    return [[(v - m) / s for v, m, s in zip(row, means, stds)] for row in rows], means, stds

rows = [[800.0, 0.002], [1200.0, 0.004], [950.0, 0.001]]
scaled, means, stds = standardize(rows)
for raw, sc in zip(rows, scaled):
    print(f"{raw} -> [{sc[0]:+.2f}, {sc[1]:+.2f}]")
```

The rule that keeps you honest: compute the mean and std on the **training** set only, freeze them, and apply the same transform to validation and test. Computing them over all data leaks the future into the past.

### Trick 3: let layers learn the difference (ResNets)

Past some depth, adding layers makes training *worse*, not because of overfitting but because each layer must first learn to pass the input through unchanged before it can improve on it. The ResNet fix is one line: add the input to the output.

```text
plain:    y = F(x)
residual: y = F(x) + x     # F only learns the correction
```

If the best a layer can do is nothing, a residual layer just learns to push F toward zero and the identity passes through. Watch the difference over 30 layers:

```python-exec
norm = lambda v: (sum(t * t for t in v) / len(v)) ** 0.5

def deep_plain(x, layers=30, hist=None):
    for _ in range(layers):
        W = [[random.gauss(0, 0.15) for _ in range(len(x))] for _ in range(len(x))]
        x = layer_out(x, W)
        if hist is not None:
            hist.append(norm(x))
    return x

def deep_residual(x, layers=30, hist=None):
    for _ in range(layers):
        W = [[random.gauss(0, 0.15) for _ in range(len(x))] for _ in range(len(x))]
        fx = layer_out(x, W)
        x = [a + b for a, b in zip(fx, x)]
        if hist is not None:
            hist.append(norm(x))
    return x

x0 = [random.gauss(0, 1) for _ in range(16)]
hist_plain, hist_res = [], []
print(f"input magnitude:           {norm(x0):.3f}")
print(f"after 30 plain layers:     {norm(deep_plain(x0, hist=hist_plain)):.6f}")
print(f"after 30 residual layers:  {norm(deep_residual(x0, hist=hist_res)):.3f}")
```

The plain stack's signal fades to nothing; the residual stack passes it through. That one `+ x` is why networks hundreds of layers deep train at all, and why the U-Net in the next chapter can afford its depth. Same thing drawn over depth - the residual curve keeps the signal alive near the input's magnitude:

```python-exec
depths30 = list(range(1, 31))
plt.plot(depths30, hist_plain, label="plain stack")
plt.plot(depths30, hist_res, label="residual stack")
plt.plot(depths30, [norm(x0)] * 30, label="input magnitude")
plt.title("Signal magnitude vs depth, 30 layers")
plt.xlabel("layer")
plt.ylabel("RMS magnitude")
plt.show()
```

### Where these show up later

The denoiser U-Net inside Stable Diffusion uses residual blocks at every level, group normalization between them, and carefully scaled initialization - this chapter is literally the difference between their model training and not. You now have every prerequisite for the compression-and-generation arc: autoencoders, U-Net, GANs, and diffusion.

### Where to go next

- **Chapter 3: Autoencoders** - squeeze data through a bottleneck and make it learn its own coordinates.
