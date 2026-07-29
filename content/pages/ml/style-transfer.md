---
layout: tutorial
title: "Chapter 10 &ndash; Style Transfer: Stealing the Statistics of Style"
permalink: /courses/image-generation/style-transfer/
difficulty: advanced
author: Pankaj Doharey
summary: No GAN, no training, no new model - match a photo's content features and a style's feature correlations, and gradient-descend the pixels themselves. Gatys style transfer, small enough for a browser tab.
theme: pylearning
previous_tutorial:
  title: "Chapter 9: Latent Diffusion & Super-Resolution"
  url: /courses/image-generation/latent-diffusion/
next_tutorial:
  title: "Back to the course index"
  url: /courses/image-generation/
date: 2026-07-29
---

Ask someone how "that app that repaints your photo as a Van Gogh" works and they will probably say "a GAN, right?" It is the natural guess after [Chapter 5](/courses/image-generation/gans-from-scratch/). But the algorithm that started the style transfer craze is not a GAN, not a diffusion model, not a generator of any kind. Gatys, Ecker and Bethge published it in 2015, and its shocking feature is this: **it trains nothing**. There is no dataset, no training loop over examples, no saved weights. Instead, a frozen network measures two distances - one to the content photo, one to the style painting - and gradient descent moves the *pixels of the output image itself* until both distances are small. The image is the model.

(GANs did the neighbouring trick: pix2pix and CycleGAN learn image-to-image translation with a generator and a critic, and they *do* train. One family optimizes a network to transform images; the other optimizes one image until a network approves of it. Never confuse them again.)

In this chapter we build the Gatys algorithm in pure Python, on real sprites, in this page. Content loss, Gram-matrix style loss, hand-written gradients flowing all the way back to individual pixels, and a few hundred steps of descent. By the end you will watch noise turn into a diamond that slowly puts on a dash texture.

### Two losses, and why one of them is a correlation

Take any conv net, trained or not, and run an image through it. The feature maps at some layer are that layer's *description* of the image. Gatys uses two different descriptions:

- **Content** = the feature activations themselves. If two images produce nearly the same activations at a deep layer, they have the same arrangement of "stuff" - same shapes in the same places. So the content loss is plain mean squared error between the output image's feature maps and the content image's feature maps.
- **Style** = the *correlations between* feature maps, captured by a **Gram matrix**. Flatten each feature map into a vector; the Gram entry `G[i][j]` is the dot product of map i and map j. A large entry means "wherever filter i fires, filter j fires too." That is texture: a stripe pattern is "vertical-edge detector and brightness detector co-fire," a canvas weave is "two diagonal detectors alternate." Crucially, the Gram matrix sums over all positions, so it throws away *where* anything happened. What is left is the statistics of the texture, position-free. That is exactly what we mean by "style" - Van Gogh's swirls are Van Gogh's swirls wherever they appear.

The total loss is `content_loss + style_weight * style_loss`, measured on one image being optimized. The full pipeline:

#> mermaid: caption="The whole algorithm: two fixed images produce two targets through a frozen conv net; gradient descent moves the pixels of a third image until both losses are small"
graph LR
    C["content image"] --> FE["frozen conv net<br/>(never trained)"]
    S["style image"] --> FE
    X["image being optimized<br/>(starts as noise)"] --> FE
    FE --> CF["layer-2 features<br/>= content target"]
    FE --> SG["layer-1 Gram matrices<br/>= style target"]
    CF --> L["content loss<br/>+ style_weight x style loss"]
    SG --> L
    L -. pixel gradient .-> X
#!

### A feature extractor nobody trained

The original paper measured its losses with VGG-19, a network pretrained on a million photographs. We cannot load VGG into a browser tab - but here is the cheat that makes this chapter possible: **even a conv net with random, never-trained weights extracts usable feature statistics**. A random 3x3 kernel still detects some oriented contrast pattern; a stack of them still responds systematically to edges, blobs and textures. The features are not semantic (no "nose detector"), but style transfer does not need semantics. It needs two rulers that measure content and texture consistently, and random filters are perfectly consistent rulers.

So our frozen network is two conv layers built from the `conv2d` we wrote by hand in [Chapter 1](/courses/image-generation/convolutions-cnns-from-scratch/): eight random 3x3 filters, ReLU, then eight more filters mixing those channels, ReLU again. It maps an 8x8 image to 8 maps of 6x6, then 8 maps of 4x4. The weights are drawn once, seeded, and never touched again.

Our data is the same real sprite set [Chapter 7](/courses/image-generation/diffusion-models-from-scratch/) trained on: 96 tiles of 8x8 pixel art. We need a **content tile** (clear structure: a diamond) and a **style tile** (clear texture: a repeating dash pattern).

<div data-corpus-url="/assets/data/sprites.csv" data-corpus-var="sprites_text"></div>

```python-exec
rows = [r.split(",") for r in sprites_text.strip().split("\n")[1:]]
tiles = {r[0]: [float(v) for v in r[1:]] for r in rows}

def to_grid(flat):
    """64 flat pixels -> 8x8 grid."""
    return [[flat[r * 8 + c] for c in range(8)] for r in range(8)]

CONTENT = to_grid(tiles["tile_0060"])   # a diamond outline: the structure we keep
STYLE   = to_grid(tiles["tile_0040"])   # a dash texture: the statistics we steal

def show01(grid, lo=-1.0, hi=1.0):
    """Grid of -1..1 -> 0..1 for plt.imshow."""
    return [[max(0.0, min(1.0, (v - lo) / (hi - lo))) for v in row]
            for row in grid]

print(f"{len(tiles)} tiles loaded")
for name, g in [("content (diamond)", CONTENT), ("style (dashes)", STYLE)]:
    print(name)
    for row in g:
        print("".join("#" if v > 0 else "." for v in row))

plt.imshow(show01(CONTENT), label="content: the diamond")
plt.imshow(show01(STYLE), label="style: dash texture")
plt.title("Two sprites, two jobs")
plt.show()
```

Now the frozen extractor and the two targets. We compute the content image's layer-2 features once, and the style image's layer-1 Gram matrix once; after that, both source images are done - the optimization only ever compares against these fixed targets.

```python-exec
import math, random

def conv2d(image, kernel):
    """Slide kernel over image, valid (no padding) convolution - Chapter 1."""
    h, w = len(image), len(image[0])
    kh, kw = len(kernel), len(kernel[0])
    out = []
    for i in range(h - kh + 1):
        row = []
        for j in range(w - kw + 1):
            acc = 0.0
            for di in range(kh):
                for dj in range(kw):
                    acc += image[i + di][j + dj] * kernel[di][dj]
            row.append(acc)
        out.append(row)
    return out

def conv_pre(maps, kernels):
    """One conv layer, pre-activation: kernels is C_out x C_in of 3x3."""
    outs = []
    for ks in kernels:                    # one output channel
        acc = None
        for m, K in zip(maps, ks):        # sum convolutions over input channels
            fm = conv2d(m, K)
            acc = fm if acc is None else [
                [a + b for a, b in zip(ra, rb)] for ra, rb in zip(acc, fm)]
        outs.append(acc)
    return outs

def relu(maps):
    return [[[v if v > 0 else 0.0 for v in row] for row in m] for m in maps]

def flat(m):
    return [v for row in m for v in row]

def gram(maps):
    """Gram matrix of feature maps: G[i][j] = correlation of maps i and j."""
    F = [flat(m) for m in maps]
    C, N = len(F), len(F[0])
    return [[sum(F[i][p] * F[j][p] for p in range(N)) / N
             for j in range(C)] for i in range(C)]

C1, C2 = 8, 8                       # channels in layer 1 and layer 2
random.seed(7)
k1 = [[[ [random.gauss(0, 0.6) for _ in range(3)] for _ in range(3) ]]
      for _ in range(C1)]           # layer 1: 8 filters on the single image
k2 = [[[[random.gauss(0, 0.6) for _ in range(3)] for _ in range(3)]
       for _ in range(C1)] for _ in range(C2)]   # layer 2: 8 x 8 filters

def forward(img):
    """8x8 image -> (pre1, act1, pre2, act2): 8 maps of 6x6, then 8 of 4x4."""
    p1 = conv_pre([img], k1); a1 = relu(p1)
    p2 = conv_pre(a1, k2);    a2 = relu(p2)
    return p1, a1, p2, a2

_, _, _, A2C = forward(CONTENT)     # content target: layer-2 features
_, A1S, _, _ = forward(STYLE)       # style source: layer-1 features...
GS = gram(A1S)                      # ...and their Gram matrix, the style target

print("extractor: 1 -> 8 -> 8 channels, 8x8 -> 6x6 -> 4x4")
print("style Gram matrix (8x8), rounded:")
for row in GS:
    print(" ".join(f"{v:5.2f}" for v in row))
```

Look at the Gram matrix that was just printed. It is the entire "style" of the dash tile, frozen into 64 numbers. Nothing in it says where a dash sits - only which filters tend to fire together, and how strongly. And what do random filters even see? Here are four of the eight layer-1 feature maps of the style tile (each scaled by the brightest value so `plt.imshow` can show it):

```python-exec
mx = max(v for m in A1S for row in m for v in row)
for c in range(4):
    plt.imshow([[v / mx for v in row] for row in A1S[c]], label=f"filter {c}")
plt.title("What four untrained filters see in the style tile")
plt.show()
```

Untrained, and still each filter lights up in a distinct, systematic pattern on the texture. That systematicity is all the algorithm needs.

### Gradient descent on the pixels themselves

Here is the unusual part. In every earlier chapter, gradients updated *weights* while data sat still. Now the network's weights are frozen and the "parameter" is the image: 64 pixel values, each one receiving a gradient. The chain rule is the one you know from [Chapter 3](/courses/image-generation/autoencoders/) and [backpropagation by hand](/courses/machine-learning/backpropagation-by-hand/) - content gradient flows from layer 2 back through its ReLU and convolutions into layer 1, the style gradient flows from the Gram matrix into layer 1, and both continue through the first ReLU into the pixels.

One detail worth reading slowly: the gradient of the Gram loss with respect to a feature value `F[i][p]` (channel i, position p) is `sum_j 2 * dG[i][j] * F[j][p] / N` - each Gram entry pulls the feature toward whatever its *correlated partners* look like. Style pressure is literally channels telling each other: fire together the way the style tile's channels fired together.

```python-exec
STYLE_W = 10.0        # style_weight: how loudly texture speaks vs structure

def loss_and_grad(img):
    """Total Gatys loss on img, plus d loss / d pixel (an 8x8 grid)."""
    p1, a1, p2, a2 = forward(img)
    # content loss: MSE between layer-2 features and the content target
    cl = 0.0
    dT = [[[0.0] * 4 for _ in range(4)] for _ in range(C2)]
    for c in range(C2):
        for i in range(4):
            for j in range(4):
                d = a2[c][i][j] - A2C[c][i][j]
                cl += d * d
                dT[c][i][j] = 2 * d / (C2 * 16)
    cl /= (C2 * 16)
    # style loss: MSE between layer-1 Gram and the style target Gram
    G = gram(a1)
    sl = 0.0
    dG = [[0.0] * C1 for _ in range(C1)]
    for i in range(C1):
        for j in range(C1):
            d = G[i][j] - GS[i][j]
            sl += d * d
            dG[i][j] = 2 * d / (C1 * C1)
    sl /= (C1 * C1)
    # style gradient into layer-1 activations
    F1 = [flat(m) for m in a1]
    da1 = [[[0.0] * 6 for _ in range(6)] for _ in range(C1)]
    for i in range(C1):
        for p in range(36):
            s = 0.0
            for j in range(C1):
                s += (dG[i][j] + dG[j][i]) * F1[j][p]
            da1[i][p // 6][p % 6] = STYLE_W * s / 36
    # content gradient: layer 2 -> layer 1 (through ReLU and the convs)
    for co in range(C2):
        for i in range(4):
            for j in range(4):
                if p2[co][i][j] <= 0:
                    continue
                g = dT[co][i][j]
                for ci in range(C1):
                    K = k2[co][ci]
                    for di in range(3):
                        for dj in range(3):
                            da1[ci][i + di][j + dj] += g * K[di][dj]
    # layer 1 -> pixels (through ReLU and the first convs)
    grad = [[0.0] * 8 for _ in range(8)]
    for c in range(C1):
        for i in range(6):
            for j in range(6):
                if p1[c][i][j] <= 0:
                    continue
                g = da1[c][i][j]
                K = k1[c][0]
                for di in range(3):
                    for dj in range(3):
                        grad[i + di][j + dj] += g * K[di][dj]
    return cl, sl, grad

cl0, sl0, _ = loss_and_grad(CONTENT)
print(f"sanity: content loss on the content image itself = {cl0:.2f} (zero)")
_, sl0c, _ = loss_and_grad(STYLE)
print(f"sanity: style loss on the style image itself   = {sl0c:.2f} (zero)")
```

The sanity checks matter: each loss is exactly zero when its own image goes in. The two targets are achievable - just not by the same image at once. The art of style transfer lives in the compromise, and `STYLE_W` is the negotiation weight.

Now the loop. Start from uniform noise in [-1, 1], descend 600 steps, clip pixels back into range after every step (our sprites live in ±1, and clipping keeps the optimizer honest). Snapshots along the way become the film strip.

```python-exec
random.seed(3)
img = [[random.uniform(-1, 1) for _ in range(8)] for _ in range(8)]
steps = 600
frames = {0: [row[:] for row in img]}
hist = []
cl0, sl0, _ = loss_and_grad(img)

for step in range(1, steps + 1):
    cl, sl, grad = loss_and_grad(img)
    for i in range(8):
        for j in range(8):
            img[i][j] -= 0.5 * grad[i][j]
            img[i][j] = max(-1.0, min(1.0, img[i][j]))
    if step % 25 == 0:
        hist.append((step, cl, sl))
        progress(step, steps, suffix=f"content {cl:.3f} style {sl:.3f}")
    if step in (25, 100, 600):
        frames[step] = [row[:] for row in img]

print(f"content loss  {cl0:8.2f} -> {cl:.3f}")
print(f"style loss    {sl0:8.3f} -> {sl:.3f}")
```

Both losses fell together - the image moved toward the diamond's structure *and* toward the dash texture's statistics at the same time, which is the whole claim of the paper in one print statement. The curves, each as a fraction of where it started:

```python-exec
plt.plot([h[0] for h in hist], [h[1] / cl0 for h in hist], label="content")
plt.plot([h[0] for h in hist], [h[2] / sl0 for h in hist], label="style")
plt.title("Both losses fall on the same image")
plt.xlabel("gradient step")
plt.ylabel("loss, fraction of start")
plt.legend()
plt.show()
```

And the film strip: pure noise, the diamond condensing out of it by step 25, and then two hundred-plus steps of the flat regions filling in with mid-tone texture - the style arriving not as structure but as *weather*.

```python-exec
for s in (0, 25, 100, 600):
    plt.imshow(show01(frames[s]), label=f"step {s}")
plt.title("Noise becomes the diamond, then puts on the texture")
plt.show()
```

### The result

Be honest about what the 8x8 scale can show. The diamond survives - that is the content loss doing its job through layer 2. The flat black regions, inside and around the diamond, are no longer flat: they carry mottled mid-tones and little dashes, placed nowhere in particular, repeated everywhere in spirit - that is the Gram matrix doing its job through layer 1. Nothing was painted by hand, no generator was trained, and the two source sprites were only ever used to compute two fixed targets. Three sprites, one negotiation:

```python-exec
plt.imshow(show01(CONTENT), label="content: tile_0060")
plt.imshow(show01(STYLE), label="style: tile_0040")
plt.imshow(show01(img), label="transferred")
plt.title("Gatys in a browser tab: the diamond, repainted in dash-texture statistics")
plt.show()
```

Sprites: Kenney Tiny Dungeon, CC0 (kenney.nl).

### How the modern ones do it

Gatys' method is beautiful and slow: every single output image costs its own optimization loop. The field spent the next decade removing that loop.

- **Feed-forward style transfer (Johnson et al., 2016).** Train one network to do in a single forward pass what Gatys does in hundreds of iterations. The trick is the loss, not the architecture: the network is trained with *perceptual losses* - the same content-and-Gram losses, measured by a frozen VGG, averaged over a dataset. One style per trained network, but milliseconds per photo.
- **AdaIN (Huang & Belongie, 2017).** One network, any style. The decoder receives content features, and at each layer its activations are re-normalized to have the *mean and variance of the style image's features* - adaptive instance normalization. Matching first and second moments turns out to be most of what Gram matching was doing, so arbitrary styles work in one pass.
- **Diffusion models, today.** The generators you met in [Chapter 7](/courses/image-generation/diffusion-models-from-scratch/) and [Chapter 9](/courses/image-generation/latent-diffusion/) absorbed style transfer entirely: "a cat in the style of Van Gogh" is a prompt, not an optimization. The newest generators are diffusion transformers or U-Net and transformer hybrids - Stable Diffusion 3 and FLUX use transformer backbones outright, while SD 1.5 and SDXL are U-Nets with transformer cross-attention blocks inside. Style became a direction in the model's learned space, and the per-image loss negotiation disappeared into pretraining.

The line from 2015 to now is worth seeing plainly: first we optimized an image against a frozen network, then we optimized a network against frozen losses, then we optimized a network against all of the internet's images and let the losses go implicit. Same idea - features and their correlations are what images are made of - at three very different scales.

### Carry forward

- Style transfer is **not** a GAN and involves **no training**: Gatys optimizes pixels directly against two losses read off a frozen network.
- Content lives in feature *activations*; style lives in feature *correlations* (Gram matrices), which are texture statistics with position summed away.
- A random-weight conv net is a usable feature extractor - convolution plus ReLU already imposes enough structure before any learning.
- `STYLE_W` is the entire user interface of the algorithm: it sets the exchange rate between keeping structure and wearing texture.
- Pixels are differentiable parameters like any others. If you can write the gradient, you can optimize anything - including the input.

### Further reading

- Gatys, Ecker, Bethge, *A Neural Algorithm of Artistic Style* (2015) - the paper this chapter is a toy of; short, and its figures still stun.
- Johnson, Alahi, Fei-Fei, *Perceptual Losses for Real-Time Style Transfer* (2016) - style transfer in one forward pass.
- Zhu et al., *CycleGAN* (2017) - the GAN neighbour, unpaired image-to-image translation.
- Rombach et al., *High-Resolution Image Synthesis with Latent Diffusion Models* (2022) - where style went next, and the paper behind Stable Diffusion.
