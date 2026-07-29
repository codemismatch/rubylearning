---
layout: tutorial
title: "Chapter 1 &ndash; Convolutions & CNNs from Scratch"
permalink: /courses/image-generation/convolutions-cnns-from-scratch/
difficulty: intermediate
author: Pankaj Doharey
summary: Implement 2D convolution in pure Python, watch hand-made edge detectors fire on a tiny image, then train a small CNN to classify it.
theme: pylearning
previous_tutorial:
  title: "Course: Machine Learning: From Zero to LLMs"
  url: /courses/machine-learning/
next_tutorial:
  title: "Training Tricks: Initialization, Normalization, ResNets"
  url: /courses/image-generation/training-tricks/
date: 2026-07-29
---

Until now every model in this course treated its input as a flat list of numbers. Images do not work that way: a pixel means something because of its *neighbours*. A cat's ear is a local pattern, and it is the same pattern whether it appears top-left or bottom-right. The convolution is the operation that exploits exactly that: slide a tiny filter over the image and ask, at every position, "how much does this neighbourhood look like my pattern?"

In this chapter we implement 2D convolution in pure Python, use classical hand-built filters to find edges in a tiny image, and then train a small convolutional network end to end. No NumPy, no frameworks.

### The sliding dot product

A convolution takes a small grid of weights (the *kernel*, often 3x3) and computes a dot product at every position of the image. The output is a *feature map*: high values where the local patch matches the kernel.

#> mermaid: caption="A 6x6 image convolved with a 3x3 kernel produces a 4x4 feature map; each output cell is the sum of the 3x3 patch, element by element, times the kernel"
graph LR
    I["image (6x6)"] --> OP["* kernel (3x3)<br/>1&nbsp;&nbsp;0&nbsp;&nbsp;-1<br/>1&nbsp;&nbsp;0&nbsp;&nbsp;-1<br/>1&nbsp;&nbsp;0&nbsp;&nbsp;-1"] --> F["feature map (4x4)"]
#!

```python-exec
def conv2d(image, kernel):
    """Slide kernel over image, valid (no padding) convolution."""
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

img = [
    [0, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 0, 0],
    [0, 1, 1, 0, 0, 0],
    [0, 0, 0, 1, 1, 0],
    [0, 0, 0, 1, 1, 0],
    [0, 0, 0, 0, 0, 0],
]
vertical_edge = [[1, 0, -1],
                 [1, 0, -1],
                 [1, 0, -1]]
for row in conv2d(img, vertical_edge):
    print(" ".join(f"{v:+.0f}" for v in row))
```

Read the output: the left block (bright-then-dark) lights up with one sign, the right block with the other. The kernel is literally measuring "bright on my left, dark on my right" at every spot.

### Filters worth knowing by name

Sobel and friends are just hand-picked kernels. Watch a horizontal-edge detector ignore the vertical edges the first kernel found:

```python-exec
kernels = {
    "vertical (Sobel-x)": [[1, 0, -1], [1, 0, -1], [1, 0, -1]],
    "horizontal (Sobel-y)": [[1, 1, 1], [0, 0, 0], [-1, -1, -1]],
    "sharpen": [[0, -1, 0], [-1, 5, -1], [0, -1, 0]],
    "blur (box)": [[1/9, 1/9, 1/9], [1/9, 1/9, 1/9], [1/9, 1/9, 1/9]],
}
for name, k in kernels.items():
    fm = conv2d(img, k)
    total = sum(sum(abs(v) for v in row) for row in fm)
    print(f"{name:22s} total activation {total:.1f}")
```

For sixty years these kernels were designed by hand. The deep-learning move was to stop designing them and **learn the kernel values by gradient descent**, exactly the way we learned weights in Chapter 15.

### A trainable convolution layer

The training task: our 6x6 image contains a small square either top-left or bottom-right. A single 3x3 learned kernel plus a score should tell us which. The forward pass is convolution, global sum-pooling, and a logistic output; backprop is the chain rule threaded through the same loops:

```python-exec
import math, random
random.seed(3)

def with_square(x, y):
    im = [[0.0] * 6 for _ in range(6)]
    for i in range(y, y + 2):
        for j in range(x, x + 2):
            im[i][j] = 1.0
    return im

train = [(with_square(0, 0), 1), (with_square(3, 3), 0),
         (with_square(0, 1), 1), (with_square(3, 2), 0),
         (with_square(1, 0), 1), (with_square(2, 3), 0)]

K = [[random.gauss(0, 0.1) for _ in range(3)] for _ in range(3)]
w, b = 0.0, 0.0

def sigmoid(v):
    return 1.0 / (1.0 + math.exp(-v))

for step in range(3000):
    im, label = random.choice(train)
    fm = conv2d(im, K)
    pooled = sum(sum(row) for row in fm)
    p = sigmoid(w * pooled + b)
    d = (p - label) * p * (1 - p)      # d loss / d pooled
    dw, db = d * pooled, d
    for i in range(4):
        for j in range(4):
            for di in range(3):
                for dj in range(3):
                    K[di][dj] -= 0.05 * d * w * im[i + di][j + dj]
    w -= 0.05 * dw
    b -= 0.05 * db

for im, label in train:
    fm = conv2d(im, K)
    p = sigmoid(w * sum(sum(row) for row in fm) + b)
    print(f"label {label}  predicted {p:.3f}")
print("learned kernel:")
for row in K:
    print(" ".join(f"{v:+.2f}" for v in row))
```

Every training example classifies correctly, and the learned kernel has grown large weights in the patch positions that distinguish top-left from bottom-right. It *invented* a position detector, the same way a Sobel was invented by hand, except nobody told it what an edge is.

### Why this scales to real vision

Three ideas do the heavy lifting in every CNN you will ever meet. **Locality:** a neuron looks at a small patch, not the whole image. **Weight sharing:** the same kernel is reused at every position, so a pattern learned once is detected everywhere. **Pooling:** sum or max over regions to shrink maps while keeping the strongest signals. Stack conv -> pool -> conv -> pool and each layer sees progressively larger context: edges become textures, textures become parts, parts become objects. AlexNet, ResNet, and the vision tower of every multimodal LLM are these three ideas with better engineering.

### Where to go next

- **Try it:** give the model an 8x8 image with two squares and train it to count them. What does the kernel learn?
- **Chapter 21: Backpropagation by Hand** slows the gradient computation down to one neuron and one number at a time, so the chain rule stops being a formula and becomes a habit.
