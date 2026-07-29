---
layout: tutorial
title: "Chapter 23 &ndash; Diffusion Models: DDPM from First Principles"
permalink: /courses/machine-learning/ddpm-from-first-principles/
difficulty: advanced
author: Pankaj Doharey
summary: Understand how diffusion models generate data by destroying it first, then train a tiny pure-Python DDPM on 1D data and sample from it.
theme: pylearning
previous_tutorial:
  title: "Chapter 19: Building a Mini-GPT from Scratch"
  url: /courses/machine-learning/build-a-mini-gpt/
date: 2026-07-29
---

In Chapter 22 we compressed data with autoencoders and reconstructed it. Diffusion models attack generation from the opposite direction. Instead of compressing data and hoping the decoder can dream, they ask a stranger question: *what if we destroy the data slowly, and then learn to un-destroy it?*

That single idea, Denoising Diffusion Probabilistic Models (DDPM, Ho et al. 2020), is the engine inside Stable Diffusion, DALL-E 2, and most modern image generators. In this chapter we build the entire thing in pure Python on 1D data: the forward noising process, the training objective, and the reverse sampling loop. No frameworks, no GPU. By the end, the phrase "diffusion model" will feel like something you could have invented.

### The forward process: scheduled destruction

Take one number from your dataset, call it x0. The forward process adds a little Gaussian noise to it, over and over, for T steps. After enough steps the number is indistinguishable from pure noise:

```text
x_t = sqrt(alpha_bar_t) * x0 + sqrt(1 - alpha_bar_t) * epsilon,   epsilon ~ N(0, 1)
```

`alpha_bar_t` is the fraction of the original signal left at step t. It starts near 1 (barely noisy) and decays toward 0 (pure noise). The schedule is fixed in advance; nothing is learned here.

```python
import math, random
random.seed(7)

T = 50
betas = [0.0001 + (0.02 - 0.0001) * t / (T - 1) for t in range(T)]  # linear schedule
alphas = [1.0 - b for b in betas]
alpha_bars = []
p = 1.0
for a in alphas:
    p *= a
    alpha_bars.append(p)

def q_sample(x0, t, eps=None):
    """Diffuse x0 to step t in closed form (no looping needed)."""
    if eps is None:
        eps = random.gauss(0, 1)
    ab = alpha_bars[t]
    return math.sqrt(ab) * x0 + math.sqrt(1 - ab) * eps, eps

x0 = 2.0
for t in [0, 10, 25, 49]:
    xt, _ = q_sample(x0, t)
    print(f"t={t:3d}  alpha_bar={alpha_bars[t]:.4f}  x_t ~ {xt:+.3f}")
```

Watch how the signal-to-noise ratio collapses as `alpha_bar` decays. By t=49, `x_t` carries almost none of the original 2.0.

### The trick that makes it learnable

Reversing the whole chain at once is hopeless. But reversing *one step* is tractable: if we had a function that, given `x_t` and `t`, predicts the noise that was added, we could subtract it and walk backwards, one step at a time, from pure noise to data.

So the model's job is unusual: **it does not generate data. It predicts noise.** The training loss is just mean squared error between the noise we actually added and the noise the model guesses:

```text
loss = mean((eps_true - eps_pred(x_t, t))^2)
```

Our noise predictor is a tiny two-layer network that takes `x_t` and a sinusoidal embedding of `t` (the same trick transformers use for positions):

```python
def time_embedding(t, dim=8):
    out = []
    for i in range(dim // 2):
        freq = 1.0 / (10000 ** (2 * i / dim))
        out.append(math.sin(t * freq))
        out.append(math.cos(t * freq))
    return out

class TinyDenoiser:
    """2 -> 16 -> 16 -> 1 MLP: input [x_t, time_embedding(t)]."""
    def __init__(self, dim=8, hid=16):
        fan = 1 + dim
        self.W1 = [[random.gauss(0, 0.3) for _ in range(fan)] for _ in range(hid)]
        self.b1 = [0.0] * hid
        self.W2 = [[random.gauss(0, 0.3) for _ in range(hid)] for _ in range(hid)]
        self.b2 = [0.0] * hid
        self.W3 = [random.gauss(0, 0.3) for _ in range(hid)]
        self.b3 = 0.0

    def forward(self, x, t):
        inp = [x] + time_embedding(t)
        h1 = [math.tanh(sum(w * v for w, v in zip(row, inp)) + b) for row, b in zip(self.W1, self.b1)]
        h2 = [math.tanh(sum(w * v for w, v in zip(row, h1)) + b) for row, b in zip(self.W2, self.b2)]
        out = sum(w * v for w, v in zip(self.W3, h2)) + self.b3
        return out, (inp, h1, h2)
```

### Training: teach it what noise looks like

The dataset is a 1D two-bump mixture (points near -2 and +2). Each training step: pick a point, pick a random t, noise it, and penalize the model's noise guess with plain gradient descent. The gradients below are the same backprop you wrote in Chapter 15, just applied to MSE:

```python
def train(model, data, steps=4000, lr=0.02):
    for step in range(steps):
        x0 = random.choice(data)
        t = random.randrange(T)
        xt, eps_true = q_sample(x0, t)
        eps_pred, (inp, h1, h2) = model.forward(xt, t)
        err = eps_pred - eps_true
        # output layer gradients
        dW3 = [2 * err * v for v in h2]
        db3 = 2 * err
        dh2 = [2 * err * w for w in model.W3]
        # hidden layer 2 gradients
        dW2, db2, dh1 = [], [], [0.0] * len(model.b1)
        for j in range(len(model.b2)):
            d = dh2[j] * (1 - h2[j] ** 2)
            dW2.append([d * v for v in h1]); db2.append(d)
            for k in range(len(dh1)):
                dh1[k] += d * model.W2[j][k]
        # hidden layer 1 gradients
        dW1, db1 = [], []
        for k in range(len(model.b1)):
            d = dh1[k] * (1 - h1[k] ** 2)
            dW1.append([d * v for v in inp]); db1.append(d)
        # SGD update
        for j in range(len(model.W3)): model.W3[j] -= lr * dW3[j]
        model.b3 -= lr * db3
        for j in range(len(model.b2)):
            for k in range(len(model.W2[j])): model.W2[j][k] -= lr * dW2[j][k]
            model.b2[j] -= lr * db2[j]
        for k in range(len(model.b1)):
            for i in range(len(model.W1[k])): model.W1[k][i] -= lr * dW1[k][i]
            model.b1[k] -= lr * db1[k]
        if step % 1000 == 0:
            print(f"step {step:5d}  err^2 = {err * err:.4f}")
    return model

data = [-2.0 + random.gauss(0, 0.3) for _ in range(200)] + [2.0 + random.gauss(0, 0.3) for _ in range(200)]
model = train(TinyDenoiser(), data)
```

Loss will bounce around (every step uses a random t and a fresh noise draw) but trends down. That is normal for diffusion training.

### Sampling: the reverse walk

Now the payoff. Start from pure noise, and for t = 49 down to 0, ask the model what the noise is, remove most of it, and add a smaller fresh pinch (except at the last step). If training worked, the numbers that fall out should cluster near -2 and +2, the shape of our dataset:

```python
def p_sample(model, xt, t):
    eps_pred, _ = model.forward(xt, t)
    ab, ab_prev = alpha_bars[t], alpha_bars[t - 1] if t > 0 else 1.0
    beta = betas[t]
    mean = (xt - beta * eps_pred / math.sqrt(1 - ab)) / math.sqrt(alphas[t])
    if t == 0:
        return mean
    var = beta * (1 - ab_prev) / (1 - ab)
    return mean + math.sqrt(var) * random.gauss(0, 1)

samples = []
for _ in range(20):
    x = random.gauss(0, 1)
    for t in reversed(range(T)):
        x = p_sample(model, x, t)
    samples.append(x)

samples.sort()
lo = sum(1 for s in samples if s < 0)
print("samples near -2:", lo, "  near +2:", len(samples) - lo)
print("min/median/max: %+.2f  %+.2f  %+.2f" % (samples[0], samples[10], samples[-1]))
```

A model that only ever saw noisy numbers has learned the *shape* of the dataset: two clusters, roughly balanced. It has never been shown a clean example and told "draw this".

### What just happened, and why it scales

Three ideas carry all of DDPM. First, the forward process is fixed and closed-form, so training pairs `(x_t, eps)` are free and infinite. Second, the model predicts noise rather than data, which turns generation into ordinary regression. Third, sampling is a Markov walk: many small, easy denoising steps instead of one impossible leap.

Image diffusion models are exactly this, scaled up: the 1D point becomes a latent tensor, our 16-neuron MLP becomes a U-Net with attention (Chapter 17's mechanism, repurposed to look across pixels), and the time embedding stays almost identical. When you read that Stable Diffusion "denoises latents", you now know precisely which equation is running inside.

### Where to go next

- **Try it:** change the dataset to three bumps, or make `T` smaller. What breaks first, sample quality or training stability?
- **Chapter 24: Latent Diffusion & Super-Resolution** explains why modern systems diffuse in a compressed latent space (Chapter 22's autoencoder returns) instead of raw pixels, and how the same machinery upscales images.
- The original paper, Ho et al. 2020, *Denoising Diffusion Probabilistic Models*, reads very comfortably after this chapter.
