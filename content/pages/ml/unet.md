---
layout: tutorial
title: "Chapter 4 &ndash; U-Net: The Workhorse of Image Models"
permalink: /courses/image-generation/unet/
difficulty: advanced
author: Pankaj Doharey
summary: Build a tiny U-Net in pure Python with encoder, decoder and skip connections, and understand why every diffusion model's denoiser is one.
theme: pylearning
previous_tutorial:
  title: "Autoencoders"
  url: /courses/image-generation/autoencoders/
next_tutorial:
  title: "GANs: A Generator and a Critic"
  url: /courses/image-generation/gans-from-scratch/
date: 2026-07-29
---

In the autoencoder chapter we squeezed data through a bottleneck and accepted that fine detail dies in the squeeze. For segmentation in 2015, Ronneberger and colleagues asked: what if the detail did not have to die? Their answer became the most reused architecture in image modeling: the **U-Net**.

The shape is simple to sketch and powerful in practice. An encoder downsamples the input, learning coarse structure ("what and where, roughly"). A decoder upsamples back to full resolution ("exact pixels"). And between matching levels run **skip connections** that hand the fine detail directly from encoder to decoder, bypassing the bottleneck entirely. Coarse reasoning flows down through the latent; pixel precision flows across the skips.

In this chapter we build a 1D U-Net in pure Python, small enough to print every tensor, and train it to clean a noisy signal. In the next course chapter you will meet it again as the denoiser inside every diffusion model.

### Down, then up, with a bridge across

```text
input (16)                skip copy
   |                          |
 conv -> down (8) --------- concat -> conv -> up (16)
   |                          |
 conv -> down (4) -- bottleneck -- up (8)
```

The encoder halves the signal twice. The decoder mirrors it, doubling back up. The skip connection takes the encoder's 8-wide feature map and *concatenates* it onto the decoder's 8-wide map, so the decoder sees both "what the structure is" and "what the exact local values were".

```python-exec
def conv1d(signal, w, b):
    """Same-weight 3-tap conv, padding by edge replication."""
    n = len(signal)
    pad = [signal[0]] + signal + [signal[-1]]
    return [w[0] * pad[i] + w[1] * pad[i + 1] + w[2] * pad[i + 2] + b for i in range(n)]

def downsample(x):
    return [(x[i] + x[i + 1]) / 2 for i in range(0, len(x), 2)]

def upsample(x, n):
    out = []
    for v in x:
        out += [v, v]
    return out[:n]

class TinyUNet:
    def __init__(self):
        import random
        random.seed(5)
        g = lambda: random.gauss(0, 0.4)
        self.w1 = [g(), g(), g()]; self.b1 = g()   # level 1 conv (16)
        self.w2 = [g(), g(), g()]; self.b2 = g()   # level 2 conv (8)
        self.wb = [g(), g(), g()]; self.bb = g()   # bottleneck conv (4)
        self.w3 = [g(), g(), g()]; self.b3 = g()   # level 2 conv after skip (8)
        self.w4 = [g(), g(), g()]; self.b4 = g()   # level 1 conv after skip (16)

    def forward(self, x):
        import math
        act = lambda v: math.tanh(v)
        e1 = [act(v) for v in conv1d(x, self.w1, self.b1)]      # 16
        e2 = [act(v) for v in conv1d(downsample(e1), self.w2, self.b2)]  # 8
        bn = [act(v) for v in conv1d(downsample(e2), self.wb, self.bb)]  # 4
        d2 = upsample(bn, 8)
        d2 = [act(v) for v in conv1d([a + s for a, s in zip(d2, e2)], self.w3, self.b3)]  # skip: add e2
        d1 = upsample(d2, 16)
        d1 = [act(v) for v in conv1d([a + s for a, s in zip(d1, e1)], self.w4, self.b4)]  # skip: add e1
        return d1

x = [0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0]
out = TinyUNet().forward(x)
print("input :", " ".join(f"{v:+.1f}" for v in x))
print("output:", " ".join(f"{v:+.2f}" for v in out))
```

Untrained, the output is noise-shaped, but notice it is *full length*: the architecture preserves resolution by construction. Training it is MSE against the clean signal with the same backprop you have written three times now - the only new wrinkle is that the skip gradient splits: part flows up through the decoder, part flows straight back into the encoder level that produced the skip.

### Why skips change everything

Without skips, a deep encoder-decoder forgets: by the bottleneck, the exact position and amplitude of a small pulse is gone. With skips, the decoder does not have to remember anything - it reads the fine detail off the skip and uses the bottleneck only for context. That is why the same U-shape keeps reappearing wherever pixel-exact output matters: medical segmentation (the original paper), image-to-image translation, super-resolution, and the denoising network inside Stable Diffusion.

```python-exec
# what the bottleneck sees vs what the skip preserves
net = TinyUNet()
e1_probe = conv1d(x, net.w1, net.b1)
e2_probe = conv1d(downsample(e1_probe), net.w2, net.b2)
bn_probe = conv1d(downsample(e2_probe), net.wb, net.bb)
print("bottleneck (4 values, coarse):", " ".join(f"{v:+.2f}" for v in bn_probe))
print("skip from level 1 (first 6 of 16, fine):", " ".join(f"{v:+.2f}" for v in e1_probe[:6]))
```

### The denoiser in a diffusion model

When Chapter 6 (DDPM) says "the model predicts noise", the model in question, at production scale, is a U-Net. The noisy image enters the encoder; the bottleneck, enriched with a time embedding of the noise level, holds the global structure ("a face, roughly here"); the decoder rebuilds the predicted-noise image at full resolution; and the skip connections are why generated images have crisp whiskers instead of smudges. Our DDPM chapter used a 16-neuron MLP because the math is identical at toy scale - but now you know the name and the shape of the real thing.

### Where to go next

- **Try it:** train `TinyUNet` to denoise: make targets `x` and inputs `x + gaussian noise`. Which skips carry the cleaning signal?
- **Chapter 5: GANs** - a completely different way to generate: no encoder at all, just a forger and a detective.
