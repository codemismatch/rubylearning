---
layout: tutorial
title: "Chapter 21 &ndash; MNIST: Recognizing Handwritten Digits"
permalink: /courses/machine-learning/mnist-handwritten-digits/
difficulty: intermediate
author: Pankaj Doharey
summary: Train a from-scratch neural network on real handwritten digit scans, this time with numpy - the payoff chapter for everything the course built by hand.
theme: pylearning
previous_tutorial:
  title: "Chapter 20: Diffusion Models from Scratch"
  url: /courses/machine-learning/diffusion-models-from-scratch/
date: 2026-04-14
---

This is the payoff chapter. MNIST - 70,000 scanned handwritten digits - has been the "hello world" of machine learning for three decades, and recognizing digits is where the ideas from this whole course come together: a neural network (Chapter 15), softmax and cross-entropy (Chapters 6 and 18), backpropagation, mini-batch training, and honest evaluation on a held-out test set (Chapter 7).

Two things are different here. First, the data is *real*: not toy points we planted, but scans of digits written by real people, messy and ambiguous. Second, after twenty chapters of pure Python lists, **we finally allow numpy** - and you will see exactly why the field abandoned raw lists for anything serious.

The full MNIST is 28x28 pixels and 11 MB - too heavy to train on in a browser tab. Scikit-learn ships a perfect miniature: the `load_digits` dataset, 1,797 real 8x8 scans from the same lineage. (In the browser, the first `import sklearn` downloads a few MB of package once; after that it is instant.) We use sklearn *only* for the data - the network, loss, backprop, and training loop are all written by hand below.

```python-exec
import numpy as np
from sklearn.datasets import load_digits

digits = load_digits()
print("images:", digits.data.shape)     # 1797 rows of 64 pixels
print("labels:", digits.target.shape)
print("pixel range:", digits.data.min(), "to", digits.data.max())
print("digits per class:", np.bincount(digits.target))
```

Roughly 180 examples of each digit 0-9 - nicely balanced, so plain accuracy is a fair metric (Chapter 7). Each image is 64 pixel values from 0 (white) to 16 (black). Here are eight of them, rendered as images:

```python-exec
for i in range(8):
    plt.imshow((digits.data[i] / 16).reshape(8, 8),
               label=f"label: {digits.target[i]}")
plt.title("Mini-MNIST: real 8x8 handwritten digits")
plt.show()
```

Even at 8x8 you can read most of them - and some are genuinely sloppy. That sloppiness is the point: this is the first chapter where the model has to cope with real-world mess.

### Why numpy: a 30-second interlude

In Chapters 15, 19 and 20 we wrote `matmul` by hand with nested loops and `dot`. Numpy does the same operation in one expression, `A @ B`, executed in compiled C over contiguous memory instead of interpreted Python objects. Here is the same matrix multiply both ways:

```python-exec
import time

def dot(a, b):
    return sum(x * y for x, y in zip(a, b))

def matmul_lists(A, B):
    Bt = [list(col) for col in zip(*B)]
    return [[dot(row, col) for col in Bt] for row in A]

rng = np.random.default_rng(0)
A_np = rng.normal(size=(100, 100))
B_np = rng.normal(size=(100, 100))
A_ls = A_np.tolist()
B_ls = B_np.tolist()

t0 = time.perf_counter()
matmul_lists(A_ls, B_ls)
t_lists = time.perf_counter() - t0

t0 = time.perf_counter()
A_np @ B_np
t_numpy = time.perf_counter() - t0

print(f"pure Python: {t_lists * 1000:.1f} ms")
print(f"numpy:       {t_numpy * 1000:.3f} ms")
print(f"speedup:     ~{t_lists / t_numpy:.0f}x")
```

A 100x100 multiply is a million inner products - tens of milliseconds of Python, microseconds of numpy, nearly three orders of magnitude. And our training loop below does dozens of such multiplies per step, hundreds of steps. Everything you learned about the *math* transfers unchanged; numpy just removes the waiting. (The full training run in this chapter takes about a second.)

### Preparing the data

Standard moves from Chapter 3, in numpy form: scale pixels to [0, 1], one-hot encode the labels (a row of ten 0/1 values - the target distribution for softmax), and split into a fixed-seed train/test shuffle. We keep 1,500 images for training and 297 for a final, untouched test.

```python-exec
rng = np.random.default_rng(7)

X = digits.data / 16.0                    # scale to [0, 1]
Y = np.eye(10)[digits.target]             # one-hot labels

perm = rng.permutation(len(X))
X, Y = X[perm], Y[perm]

n_train = 1500
Xtr, Ytr = X[:n_train], Y[:n_train]
Xte, Yte = X[n_train:], Y[n_train:]

print("train:", Xtr.shape, Ytr.shape)
print("test: ", Xte.shape, Yte.shape)
```

### The network, in numpy

Same architecture as Chapter 15, wider: 64 inputs (the pixels) -> 32 hidden neurons with ReLU -> 10 outputs with softmax - one probability per digit.

#> mermaid: caption="Figure 1: From pixels to probabilities"
graph LR
  I[8x8 image] --> V[64-vector]
  V --> H[hidden layer: 32 ReLU]
  H --> S[softmax: 10 digit probabilities]
#!

The forward pass and the loss, with the gradients we need:

```text
forward:   Z1 = X @ W1 + b1     A1 = relu(Z1)
           Z2 = A1 @ W2 + b2    P  = softmax(Z2)
loss:      L = -mean( sum( Y * log(P) ) )

backward:  dZ2 = (P - Y) / B
           dW2 = A1.T @ dZ2          db2 = sum(dZ2)
           dZ1 = (dZ2 @ W2.T) * (Z1 > 0)
           dW1 = X.T @ dZ1           db1 = sum(dZ1)
```

That first line of backward - softmax plus cross-entropy collapses to `P - Y` - is the identity Chapter 19 used for logits; here it processes a whole batch at once, which is what the division by B is for.

```python-exec
W1 = rng.normal(0, np.sqrt(2 / 64), (64, 32)); b1 = np.zeros(32)
W2 = rng.normal(0, np.sqrt(2 / 32), (32, 10)); b2 = np.zeros(10)

def forward(X):
    Z1 = X @ W1 + b1
    A1 = np.maximum(Z1, 0)              # ReLU
    Z2 = A1 @ W2 + b2
    E = np.exp(Z2 - Z2.max(axis=1, keepdims=True))   # stable softmax
    P = E / E.sum(axis=1, keepdims=True)
    return P, A1

def accuracy(X, Y):
    P, _ = forward(X)
    return (P.argmax(axis=1) == Y.argmax(axis=1)).mean()

P, _ = forward(Xtr[:5])
print("untrained predictions:", P.argmax(axis=1))
print("true labels:          ", Ytr[:5].argmax(axis=1))
print(f"untrained train accuracy: {accuracy(Xtr, Ytr):.3f}")
```

Barely above the 10% of random guessing on ten classes. The network has opinions but no knowledge.

### Training

Mini-batch gradient descent: 600 steps, each on a random batch of 64 images, with the backprop from the box above written out in numpy. We record loss and training accuracy as we go.

```python-exec
lr = 0.5
B = 64
steps = 600
history = []

for step in range(steps + 1):
    idx = rng.choice(n_train, B, replace=False)
    xb, yb = Xtr[idx], Ytr[idx]
    P, A1 = forward(xb)
    loss = -(yb * np.log(P + 1e-12)).sum() / B

    dZ2 = (P - yb) / B                  # softmax + cross-entropy
    gW2 = A1.T @ dZ2;  gb2 = dZ2.sum(axis=0)
    dZ1 = (dZ2 @ W2.T) * (A1 > 0)       # back through ReLU
    gW1 = xb.T @ dZ1;  gb1 = dZ1.sum(axis=0)
    W1 -= lr * gW1;  b1 -= lr * gb1
    W2 -= lr * gW2;  b2 -= lr * gb2

    if step % 50 == 0:
        progress(step, steps, suffix=f"loss {loss:.4f}")
    if step % 100 == 0:
        acc = accuracy(Xtr, Ytr)
        history.append((step, loss, acc))
        print(f"step {step:4d}  loss {loss:.4f}  train acc {acc:.3f}")

print(f"\nfinal train accuracy: {accuracy(Xtr, Ytr):.4f}")
print(f"test accuracy:        {accuracy(Xte, Yte):.4f}")
```

The curves tell the story - loss collapses in the first hundred steps, and accuracy climbs past 95%:

```python-exec
plt.plot([s for s, _, _ in history], [l for _, l, _ in history],
         label="loss")
plt.plot([s for s, _, _ in history], [a for _, _, a in history],
         label="train accuracy")
plt.title("Mini-MNIST training")
plt.xlabel("step")
plt.show()
```

### How did it do? Honest evaluation

The test set never touched training. Let us look not just at the number but at the *mistakes* - on real data, the errors are the interesting part:

```python-exec
P, _ = forward(Xte)
pred = P.argmax(axis=1)
true = Yte.argmax(axis=1)
wrong = np.where(pred != true)[0]

print(f"test accuracy: {(pred == true).mean():.4f}")
print(f"misclassified: {len(wrong)} of {len(true)}")
for i in wrong[:8]:
    print(f"  true {true[i]}  predicted {pred[i]}")

for i in wrong[:6]:
    plt.imshow(Xte[i].reshape(8, 8),
               label=f"true {true[i]}, pred {pred[i]}")
plt.title("The mistakes - can you blame it?")
plt.show()
```

Ninety-six percent of held-out digits recognized by 9,000 weights trained for one second. And look at the failures: a 1 so wide it reads as an 8, a 9 with an open loop that reads as a 1, a 4 drawn like a 7. These are the genuinely ambiguous corner cases - several of them would make *you* hesitate. That is what a healthy error analysis looks like: the model is not broken, the data is hard at the margins.

### From 8x8 to the real MNIST

Everything above transfers to the full 28x28 MNIST with three changes:

- **Bigger input.** 784 pixels instead of 64; the same code runs, just wider matrices.
- **More data.** 60,000 training images - which is exactly why full MNIST reaches 99%+ where our 1,500 images plateau at ~96%. Data scale still beats cleverness (Chapter 18's scaling laws, applied to digits).
- **Convolutions.** Our network flattens the image into a vector, throwing away "which pixels are neighbors." A convolutional network slides small filters across the image, sharing weights across positions - the same "look at local structure" idea as Chapter 16's windows and Chapter 20's pixels, made architectural. That is the leap from 99% to 99.7%+ and the beginning of modern computer vision.

Where to go next: the classic references are LeCun et al.'s 1998 paper "Gradient-Based Learning Applied to Document Recognition" (the original MNIST result) and Michael Nielsen's free online book *Neural Networks and Deep Learning*, whose first chapters build full-MNIST in numpy at exactly this course's altitude.

### Practice checklist

- [ ] Retrain with the hidden layer shrunk to 8 neurons, then widened to 64; plot or record the test accuracy each time and relate the pattern to Chapter 8's bias-variance tradeoff.
- [ ] Remove the ReLU (make the network purely linear) and measure the test accuracy drop; explain why two linear layers collapse into one.
- [ ] Print the model's predicted probabilities for one test image and verify they sum to 1; find the test image where the model is least confident and visualize it.
- [ ] Add L2 regularization (`l2 * (W1**2).sum() + (W2**2).sum()` to the loss, and its gradient) and check whether the train/test gap narrows.
- [ ] Compute the full 10x10 confusion matrix on the test set (`np` makes it a one-liner with `np.add.at` or a loop); which digit pair is confused most often?
- [ ] Explain to a beginner why flattening an image into a vector loses information, and what a convolution would preserve instead.
