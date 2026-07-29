---
layout: tutorial
title: "Chapter 5 &ndash; GANs: A Generator and a Critic"
permalink: /courses/image-generation/gans-from-scratch/
difficulty: advanced
author: Pankaj Doharey
summary: "Train a tiny GAN in pure Python: a generator that learns to counterfeit a distribution and a discriminator that learns to catch it."
theme: pylearning
previous_tutorial:
  title: "U-Net: The Workhorse of Image Models"
  url: /courses/image-generation/unet/
next_tutorial:
  title: "Diffusion Models: DDPM from First Principles"
  url: /courses/image-generation/ddpm-from-first-principles/
date: 2026-07-29
---

Every model so far learned by comparing its output to a target. A GAN (Goodfellow et al., 2014) has no target. Instead it plays a game between two networks: a **generator** that counterfeits data, and a **discriminator** that guesses whether each sample it sees is real or fake. The generator wins when the discriminator cannot tell the difference. Training is the game itself - the forger gets better because the detective gets better.

In this chapter we play the whole game in pure Python on a 1D distribution: a discriminator that scores "real vs fake" and a generator that turns uniform noise into samples, trained against each other with hand-written gradients.

### The game, written down

```text
real data x  ---------.
                       -> D(x) -> "probability this is real"
noise z -> G(z) ------'

D trains to say: real -> 1, fake -> 0
G trains to make D say: fake -> 1
```

The discriminator is just logistic regression (Chapter 6!). The generator is a one-layer tanh network mapping a noise number to a data number. The loss for D is binary cross-entropy; the loss for G is the same BCE but with the labels flipped, and its gradient flows *through* D into G, which is the elegant part.

```python-exec
import math, random
random.seed(9)

def sigmoid(v):
    return 1.0 / (1.0 + math.exp(-v))

real = [random.gauss(2.0, 0.4) for _ in range(400)]   # the true distribution
print("real mean %.2f  real spread %.2f" % (sum(real) / len(real),
      (sum((v - 2.0) ** 2 for v in real) / len(real)) ** 0.5))

class Disc:
    def __init__(self):
        self.w, self.b = random.gauss(0, 0.5), 0.0
    def prob_real(self, x):
        return sigmoid(self.w * x + self.b)

class Gen:
    def __init__(self, hid=8):
        self.W1 = [random.gauss(0, 0.5) for _ in range(hid)]
        self.b1 = [0.0] * hid
        self.w2 = [random.gauss(0, 0.5) for _ in range(hid)]
        self.b2 = 0.0
    def forward(self, z):
        h = [math.tanh(w * z + b) for w, b in zip(self.W1, self.b1)]
        x = sum(w * v for w, v in zip(self.w2, h)) + self.b2
        return x, h

D, G = Disc(), Gen()
fake0 = [G.forward(random.uniform(-1, 1))[0] for _ in range(5)]
print("untrained fakes:", " ".join(f"{v:+.2f}" for v in fake0))
```

### Training: alternating moves

Each step has two moves. First D learns one gradient step telling real from fake. Then G learns one step *through* D: we feed D a fake, ask D to call it real, and push G's weights in the direction that makes D agree. Note how G's gradient reaches its weights by multiplying D's weight `D.w` at the boundary - the detective literally teaches the forger.

```python-exec
lr = 0.05
for step in range(4000):
    # move 1: train D on one real and one fake
    xr = random.choice(real)
    z = random.uniform(-1, 1)
    xf, h = G.forward(z)
    for x, target in [(xr, 1.0), (xf, 0.0)]:
        p = D.prob_real(x)
        d = (p - target) * p * (1 - p)
        D.w -= lr * d * x
        D.b -= lr * d
    # move 2: train G through D (flip the label: we WANT D to say real)
    p = D.prob_real(xf)
    d_score = (p - 1.0) * p * (1 - p)     # d loss / d xf
    d_xf = d_score * D.w                   # gradient arriving at G's output
    dw2 = [d_xf * v for v in h]
    db2 = d_xf
    dh = [d_xf * w for w in G.w2]
    for j in range(len(h)):
        dh_j = dh[j] * (1 - h[j] ** 2)
        G.W1[j] -= lr * dh_j * z
        G.b1[j] -= lr * dh_j
    for j in range(len(G.w2)):
        G.w2[j] -= lr * dw2[j]
    G.b2 -= lr * db2
    if step % 1000 == 0:
        print(f"step {step:5d}  D(real)={D.prob_real(random.choice(real)):.3f}  D(fake)={p:.3f}")
```

### Did the forger learn?

Sample the generator and compare its statistics with the real distribution:

```python-exec
fakes = [G.forward(random.uniform(-1, 1))[0] for _ in range(400)]
fm = sum(fakes) / len(fakes)
fs = (sum((v - fm) ** 2 for v in fakes) / len(fakes)) ** 0.5
print(f"real:  mean 2.00  spread 0.40")
print(f"fake:  mean {fm:.2f}  spread {fs:.2f}")
print(f"D says a fake is real with probability {D.prob_real(fakes[0]):.3f}")
```

The generator, which never saw a single real example - only the discriminator's verdicts - now produces numbers with roughly the right mean and spread, and the discriminator can no longer call them out. It learned the distribution *adversarially*, with no target ever shown.

### The game in the real world, and its price

The same loop at image scale is StyleGAN and every photoreal face generator: D becomes a deep CNN, G becomes a deep CNN with upsampling layers, but the loss is verbatim what you just ran. The price is instability: if D gets too strong, G's gradient vanishes (every fake is caught, nothing to learn); if G gets too strong, it collapses to one output that always works (*mode collapse*). Most GAN research is ways to keep the game fair. Diffusion models, the next chapter, sidestep the game entirely - they train with ordinary regression, which is a large part of why the field moved to them.

### Where to go next

- **Try it:** make `real` bimodal (half near -2, half near +2). Does G cover both modes, or collapse to one?
- **Chapter 6: DDPM from First Principles** - generation without the duel.
