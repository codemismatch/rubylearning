---
layout: tutorial
title: "Chapter 22 &ndash; Autoencoders"
permalink: /courses/machine-learning/autoencoders/
difficulty: intermediate
author: Pankaj Doharey
summary: Build an autoencoder in pure Python that squeezes 2D data through a 1-number bottleneck, and learn why compression is the road to generation.
theme: pylearning
previous_tutorial:
  title: "Chapter 21: Backpropagation by Hand"
  url: /courses/machine-learning/backpropagation-by-hand/
next_tutorial:
  title: "Chapter 23: Diffusion Models: DDPM from First Principles"
  url: /courses/machine-learning/ddpm-from-first-principles/
date: 2026-07-29
---

In Chapter 15 you trained a network to map inputs to *labels*. An autoencoder has a stranger target: map the input to **itself**, through a bottleneck so narrow the network cannot possibly copy. Whatever survives the squeeze is the data's essence. That idea, learning a compressed representation without any labels, is the foundation under modern generative models - and in Chapter 24 it becomes the "latent" in latent diffusion.

In this chapter we build one in pure Python: an encoder that crushes 2D points down to a single number, a decoder that tries to inflate that number back, and the training loop that teaches both at once.

### The bottleneck is the lesson

Our dataset is a noisy ring: points that live on a circle of radius 2, plus jitter. A circle is a 2D shape, but any point on it is described fully by one number - its angle. A good autoencoder should discover the angle all by itself, because that is the cheapest way to survive a 1-number bottleneck.

```python
import math, random
random.seed(11)

def make_ring(n=300, radius=2.0, noise=0.08):
    pts = []
    for _ in range(n):
        a = random.uniform(0, 2 * math.pi)
        r = radius + random.gauss(0, noise)
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts

data = make_ring()
print("points:", len(data), " first:", tuple(round(v, 3) for v in data[0]))
```

```python-exec
import math, random
random.seed(11)

def make_ring(n=300, radius=2.0, noise=0.08):
    pts = []
    for _ in range(n):
        a = random.uniform(0, 2 * math.pi)
        r = radius + random.gauss(0, noise)
        pts.append((r * math.cos(a), r * math.sin(a)))
    return pts

data = make_ring()
plt.scatter([p[0] for p in data], [p[1] for p in data], label="ring data")
plt.title("A circle is 2D, but one number describes any point on it")
plt.legend()
plt.show()
```

### Encoder and decoder

Both halves are one-layer networks with tanh activations, trained jointly by mean squared error between input and reconstruction. The middle value, the single number passing through the bottleneck, is called the **latent code**:

```python-exec
class Autoencoder:
    """2 -> 8 -> 1 -> 8 -> 2, pure Python."""
    def __init__(self, hid=8):
        self.We = [[random.gauss(0, 0.5) for _ in range(2)] for _ in range(hid)]
        self.be = [0.0] * hid
        self.wz = [random.gauss(0, 0.5) for _ in range(hid)]
        self.bz = 0.0
        self.Wd = [[random.gauss(0, 0.5)] for _ in range(hid)]
        self.bd = [0.0] * hid
        self.Wo = [[random.gauss(0, 0.5) for _ in range(hid)] for _ in range(2)]
        self.bo = [0.0, 0.0]

    def forward(self, x, y):
        h = [math.tanh(we[0] * x + we[1] * y + b) for we, b in zip(self.We, self.be)]
        z = sum(w * v for w, v in zip(self.wz, h)) + self.bz
        g = [math.tanh(w[0] * z + b) for w, b in zip(self.Wd, self.bd)]
        out = [sum(w[j] * g[j] for j in range(len(g))) + self.bo[i] for i, w in enumerate(self.Wo)]
        return out[0], out[1], (h, z, g)

ae = Autoencoder()
rx, ry, _ = ae.forward(2.0, 0.0)
print(f"untrained reconstruction of (2.0, 0.0): ({rx:+.3f}, {ry:+.3f})")
```

Untrained, the reconstruction is garbage. Training it is the same hand-written backprop you know, with the loss being plain MSE across the two output coordinates. Rather than repeat Chapter 15's gradient code line for line, here is the training loop with the gradients worked out for this exact architecture:

```python-exec
def train(ae, data, steps=3000, lr=0.02):
    for step in range(steps):
        x, y = random.choice(data)
        rx, ry, (h, z, g) = ae.forward(x, y)
        ex, ey = rx - x, ry - y
        # output layer
        dWo = [[2 * (ex if i == 0 else ey) * g[j] for j in range(len(g))] for i in range(2)]
        dbo = [2 * ex, 2 * ey]
        dg = [2 * ex * ae.Wo[0][j] + 2 * ey * ae.Wo[1][j] for j in range(len(g))]
        # decoder hidden
        dWd, dbd, dz = [], [], 0.0
        for j in range(len(g)):
            d = dg[j] * (1 - g[j] ** 2)
            dWd.append([d * z]); dbd.append(d)
            dz += d * ae.Wd[j][0]
        # latent -> encoder
        dwz = [dz * h[j] for j in range(len(h))]
        dbz = dz
        dh = [dz * ae.wz[j] for j in range(len(h))]
        dWe, dbe = [], []
        for j in range(len(h)):
            d = dh[j] * (1 - h[j] ** 2)
            dWe.append([d * x, d * y]); dbe.append(d)
        # SGD update
        for i in range(2):
            for j in range(len(g)): ae.Wo[i][j] -= lr * dWo[i][j]
            ae.bo[i] -= lr * dbo[i]
        for j in range(len(g)):
            ae.Wd[j][0] -= lr * dWd[j][0]; ae.bd[j] -= lr * dbd[j]
        for j in range(len(h)):
            ae.wz[j] -= lr * dwz[j]
            for k in range(2): ae.We[j][k] -= lr * dWe[j][k]
            ae.be[j] -= lr * dbe[j]
        ae.bz -= lr * dbz
        if step % 1000 == 0:
            print(f"step {step:5d}  mse = {(ex * ex + ey * ey) / 2:.5f}")
    return ae

ae = train(Autoencoder(), data)
```

### Did it find the angle?

If the bottleneck learned something meaningful, the latent code `z` should vary smoothly as we walk around the circle, and reconstructions should land back on the ring. Test both:

```python-exec
angles, zs, errs = [], [], []
for x, y in data[:60]:
    rx, ry, (h, z, g) = ae.forward(x, y)
    angles.append(math.atan2(y, x))
    zs.append(z)
    errs.append((rx - x) ** 2 + (ry - y) ** 2)

rx0, ry0, _ = ae.forward(2.0, 0.0)
rx1, ry1, _ = ae.forward(-2.0, 0.0)
print(f"reconstruct ( 2,0) -> ({rx0:+.2f}, {ry0:+.2f})")
print(f"reconstruct (-2,0) -> ({rx1:+.2f}, {ry1:+.2f})")
print(f"mean squared reconstruction error on 60 points: {sum(errs) / len(errs):.5f}")
print(f"latent range: [{min(zs):+.2f}, {max(zs):+.2f}]")
```

The reconstruction error collapses toward zero even though every coordinate round-trips through one number. And the latent code spreads across a real range - the network invented its own coordinate for "where on the circle". It will not be a clean angle (any monotone reparametrization works), but it *is* a one-dimensional description of a two-dimensional shape, found with no labels.

```python-exec
# reconstructed points vs real points
rec_x, rec_y, real_x, real_y = [], [], [], []
for x, y in data[:150]:
    rx, ry, _ = ae.forward(x, y)
    rec_x.append(rx); rec_y.append(ry)
    real_x.append(x); real_y.append(y)
plt.scatter(real_x, real_y, label="real")
plt.scatter(rec_x, rec_y, label="reconstructed")
plt.title("The ring, rebuilt through a 1-number bottleneck")
plt.legend()
plt.show()
```

### Why this matters for what comes next

Three things to carry forward. First, a network can learn coordinates for data without being told any - the bottleneck forces structure out of statistics. Second, the latent space is where generation gets easy: it is simpler to model one well-behaved number than two entangled coordinates. Third, this exact pairing - encoder to compress, decoder to reconstruct - is the front and back of a latent diffusion model. In Chapter 23 we generate data by denoising; in Chapter 24 we will do that denoising *inside* an autoencoder's latent space, which is why Stable Diffusion is fast enough to exist.

### Where to go next

- **Try it:** change the ring to a spiral (let the radius grow with the angle). Does the 1-number bottleneck survive?
- **Chapter 23: Diffusion Models: DDPM from First Principles** - generation by scheduled destruction and learned un-destruction.
