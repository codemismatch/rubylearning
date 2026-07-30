---
layout: tutorial
title: "Chapter 9 &ndash; Latent Diffusion & Super-Resolution"
permalink: /courses/image-generation/latent-diffusion/
difficulty: advanced
author: Pankaj Doharey
summary: Combine the autoencoder and DDPM into latent diffusion, the architecture of Stable Diffusion, and see how the same machinery upscales images.
theme: pylearning
previous_tutorial:
  title: "Text-to-Image: Teaching Diffusion to Listen"
  url: /courses/image-generation/text-to-image-sprites/
next_tutorial:
  title: "Chapter 10: Style Transfer: Stealing the Statistics of Style"
  url: /courses/image-generation/style-transfer/
date: 2026-07-29
---

You now own every piece. Chapter 3's autoencoder compresses data into a latent code. Chapter 6's DDPM generates data by denoising. Latent diffusion (Rombach et al., 2022 - the paper behind Stable Diffusion) is simply these bolted together: **encode once, diffuse in the latent space, decode at the end.** In this chapter we wire exactly that in pure Python and see why it is the difference between a research toy and a product.

### Why diffuse in latent space at all

Pixel space is enormous and mostly redundant. A 512x512 image has 786,432 values, but almost all the *meaning* fits in a latent a hundred times smaller. Diffusing in pixels means the model spends most of its capacity relearning "neighbouring pixels correlate". Diffusing in latents means it spends capacity on structure. The autoencoder has already learned the correlation; the diffusion model should not have to.

#> mermaid: caption="Latent diffusion: encode once, diffuse in latent space, decode at the end"
graph LR
    I["image"] -->|encoder| Z["latent z"]
    Z -->|"DDPM forward/reverse"| Z2["z'"]
    Z2 -->|decoder| I2["image"]
#!

```python-exec
# reuse the ring autoencoder's idea: 2D point -> 1 latent number
import math, random
random.seed(4)

def encode(x, y):
    return math.atan2(y, x) + 0.1 * math.hypot(x, y)   # trained AE in ch.2; principle is the same

def decode(z):
    r = 2.0 * (z - math.floor(z / (2 * math.pi)) * 2 * math.pi)
    return 2.0 * math.cos(z), 2.0 * math.sin(z)

for p in [(2.0, 0.0), (0.0, 2.0)]:
    z = encode(*p)
    print(f"{p} -> z = {z:+.3f} -> decoded {tuple(round(v, 2) for v in decode(z))}")
```

### The full latent-DDPM loop

The workflow has three stages, and you have built each one:

#> mermaid: caption="The three stages"
graph LR
    E["1. ENCODE the dataset once into latents z (autoencoder, ch.3)"] --> T["2. TRAIN and SAMPLE the DDPM on latents (ch.6 code, unchanged)"] --> D["3. DECODE sampled latents back to data space"]
#!

Stage 2 is the remarkable one: the DDPM code from Chapter 6 runs *byte for byte unchanged*, because diffusion does not care what its coordinates mean. Swap "2D ring point" for "1D latent code" and everything - schedules, noise prediction, the reverse walk - just works:

```python-exec
# stage 1: encode a ring dataset into 1D latents
ring = []
for _ in range(300):
    a = random.uniform(0, 2 * math.pi)
    ring.append((2.0 * math.cos(a) + random.gauss(0, 0.05),
                 2.0 * math.sin(a) + random.gauss(0, 0.05)))
latents = [encode(x, y) for x, y in ring]
print("encoded", len(latents), "points; latent range",
      f"[{min(latents):+.2f}, {max(latents):+.2f}]")
# stage 2 is Chapter 6's TinyDenoiser trained on `latents` - identical code
# stage 3: decode whatever comes out
z_sample = random.choice(latents)
print("sampled latent %+.2f decodes to point %s" % (z_sample, tuple(round(v, 2) for v in decode(z_sample))))
```

In the real Stable Diffusion, the encoder maps 512x512x3 images to 64x64x4 latents (48x compression), the DDPM's U-Net (Chapter 4) denoises those latents, and the decoder renders the final pixels. Ours maps 2D to 1 number, but the data flow is identical.

Angles are a fine latent for a ring, but the claim was about *images*. So here is the same round trip at a scale this page can actually run: a tiny autoencoder - 64 pixels in, a **four-number latent** (a 2x2 grid), 64 pixels out - trained right here on four hand-drawn 8x8 sprites. Sixteen-to-one compression, the same ratio class as the real thing:

```python-exec
# a tiny image autoencoder: 64 pixels -> 4 latent numbers -> 64 pixels
rng = random.Random(11)          # private stream, so the cells above are untouched

def rows_to_img(rows):
    return [float(v) for r in rows for v in r]

PLUS = rows_to_img([[0,0,0,1,1,0,0,0],[0,0,0,1,1,0,0,0],[0,0,0,1,1,0,0,0],
                    [1,1,1,1,1,1,1,1],[1,1,1,1,1,1,1,1],[0,0,0,1,1,0,0,0],
                    [0,0,0,1,1,0,0,0],[0,0,0,1,1,0,0,0]])
BOX  = rows_to_img([[1,1,1,1,1,1,1,1],[1,0,0,0,0,0,0,1],[1,0,0,0,0,0,0,1],
                    [1,0,0,0,0,0,0,1],[1,0,0,0,0,0,0,1],[1,0,0,0,0,0,0,1],
                    [1,0,0,0,0,0,0,1],[1,1,1,1,1,1,1,1]])
CROSS = rows_to_img([[1,1,0,0,0,0,1,1],[1,1,1,0,0,1,1,1],[0,1,1,1,1,1,1,0],
                     [0,0,1,1,1,1,0,0],[0,0,1,1,1,1,0,0],[0,1,1,1,1,1,1,0],
                     [1,1,1,0,0,1,1,1],[1,1,0,0,0,0,1,1]])
SLASH = rows_to_img([[1,1,0,0,0,0,0,0],[1,1,1,0,0,0,0,0],[0,1,1,1,0,0,0,0],
                     [0,0,1,1,1,0,0,0],[0,0,0,1,1,1,0,0],[0,0,0,0,1,1,1,0],
                     [0,0,0,0,0,1,1,1],[0,0,0,0,0,0,1,1]])
ae_imgs = [PLUS, BOX, CROSS, SLASH]

def sig(v):
    return 1.0 / (1.0 + math.exp(-v))

LAT = 4                          # the whole image, squeezed into 4 numbers
W1 = [[rng.gauss(0, 0.3) for _ in range(64)] for _ in range(LAT)]
b1 = [0.0] * LAT
W2 = [[rng.gauss(0, 0.3) for _ in range(LAT)] for _ in range(64)]
b2 = [0.0] * 64

def ae_forward(x):
    """64 pixels -> (latent of 4, reconstructed 64 pixels)."""
    h = [sum(W1[k][i] * x[i] for i in range(64)) + b1[k] for k in range(LAT)]
    out = [sig(sum(W2[i][k] * h[k] for k in range(LAT)) + b2[i]) for i in range(64)]
    return h, out

def ae_decode(h):
    """Any point in latent space -> 64 pixels."""
    return [sig(sum(W2[i][k] * h[k] for k in range(LAT)) + b2[i]) for i in range(64)]

ae_steps, lr = 4000, 0.5
for step in range(1, ae_steps + 1):
    gW1 = [[0.0] * 64 for _ in range(LAT)]; gb1 = [0.0] * LAT
    gW2 = [[0.0] * LAT for _ in range(64)]; gb2 = [0.0] * 64
    loss = 0.0
    for x in ae_imgs:
        h, out = ae_forward(x)
        d = [2 * (out[i] - x[i]) * out[i] * (1 - out[i]) / 64 for i in range(64)]
        loss += sum((out[i] - x[i]) ** 2 for i in range(64)) / 64
        dh = [0.0] * LAT
        for i in range(64):
            for k in range(LAT):
                gW2[i][k] += d[i] * h[k]
                dh[k] += W2[i][k] * d[i]
            gb2[i] += d[i]
        for k in range(LAT):
            for i in range(64):
                gW1[k][i] += dh[k] * x[i]
            gb1[k] += dh[k]
    n = len(ae_imgs)
    for i in range(64):
        for k in range(LAT):
            W2[i][k] -= lr * gW2[i][k] / n
        b2[i] -= lr * gb2[i] / n
    for k in range(LAT):
        for i in range(64):
            W1[k][i] -= lr * gW1[k][i] / n
        b1[k] -= lr * gb1[k] / n
    if step % 1000 == 0:
        progress(step, ae_steps, suffix=f"recon loss {loss / n:.4f}")
print(f"trained: recon loss {loss / n:.4f} on {n} sprites")

def to_grid8(flat):
    return [[flat[r * 8 + c] for c in range(8)] for r in range(8)]

h_plus, out_plus = ae_forward(PLUS)
mx = max(abs(v) for v in h_plus)
latent_show = [[(v / mx + 1) / 2 for v in row] for row in
               [[h_plus[0], h_plus[1]], [h_plus[2], h_plus[3]]]]
print("the plus sprite, as 4 latent numbers:", [round(v, 2) for v in h_plus])
```

Sixty-four pixels became four numbers and back. Here is the whole compression in one row - the sprite, the 2x2 latent it was squeezed into (scaled to 0..1 for display), and what the decoder rebuilds from just those four numbers:

```python-exec
plt.imshow(to_grid8(PLUS), label="original: the plus sprite")
plt.imshow(latent_show, label="latent z (2x2, scaled)")
plt.imshow(to_grid8(out_plus), label="decoded back from z")
plt.title("Encode once: 64 pixels -> 4 numbers -> 64 pixels")
plt.show()
```

And sampling? Decoding points chosen in latent space shows exactly why the DDPM has to *walk* there: nudge a real sprite's latent and the plus survives; stop halfway to the box's latent and you get a genuine blend; jump to a blind random latent and you get mush - mush that the reverse diffusion process exists to walk away from, one denoising step at a time:

```python-exec
h_box, _ = ae_forward(BOX)
near  = [h_plus[k] + rng.gauss(0, 0.2) for k in range(LAT)]   # a small step off the plus
blend = [(h_plus[k] + h_box[k]) / 2 for k in range(LAT)]      # halfway to the box
blind = [rng.gauss(0, 1.0) for k in range(LAT)]               # no idea where we are

plt.imshow(to_grid8(ae_decode(near)),  label="near a real latent")
plt.imshow(to_grid8(ae_decode(blend)), label="halfway plus->box")
plt.imshow(to_grid8(ae_decode(blind)), label="blind random latent")
plt.title("Decoding sampled latents: structure near the data, mush far from it")
plt.show()
```

### Super-resolution: the same machine, pointed elsewhere

Super-resolution is not a new model - it is latent diffusion with a condition. Give the denoiser the low-resolution image alongside the noisy latent (concatenated at the input, or injected via cross-attention), and train on pairs: the forward process destroys the *high*-res latent, the reverse process rebuilds it while the low-res image guides every step. The model learns "hallucinate detail consistent with this small image". Nothing in the math changes; only the inputs get an extra passenger:

```text
reverse step:  eps_pred = UNet(noisy_latent, t, low_res_image)
```

That is the whole trick behind "AI upscalers": the SR3 and Stable Diffusion x4 upscaler papers are DDPM with a conditioning channel.

### The map of everything you have built

Convolutions (ch.1) gave models local vision. Training tricks keep deep stacks learnable. The autoencoder (ch.2) learned coordinates nobody labelled. The U-Net (ch.3) kept fine detail alive through a bottleneck. The GAN (ch.4) generated by duel. DDPM (ch.5) generated by demolition and repair. And this chapter assembled them into the architecture that runs the world's image generators. Every headline image model since 2022 is some permutation of these seven ideas.

### Where to go next

- **Read:** Rombach et al., *High-Resolution Image Synthesis with Latent Diffusion Models* - it will feel like a summary of this course.
- **Build:** condition Chapter 6's sampler on a class label (add the label to the time embedding). You have just made class-conditional diffusion, the seed of text-to-image.
