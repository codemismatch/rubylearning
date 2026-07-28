---
layout: tutorial
title: "Chapter 5 &ndash; Gradient Descent"
permalink: /courses/machine-learning/gradient-descent/
difficulty: intermediate
author: Pankaj Doharey
summary: Learn how gradient descent actually trains a model by walking downhill on the loss, one small step at a time, implemented in pure Python.
theme: pylearning
previous_tutorial:
  title: "Chapter 4: Linear Regression from Scratch"
  url: /courses/machine-learning/linear-regression-from-scratch/
next_tutorial:
  title: "Chapter 6: Logistic Regression & Classification"
  url: /courses/machine-learning/logistic-regression-classification/
date: 2026-01-27
---

In Chapter 4: Linear Regression from Scratch we fit a line to house prices with a closed-form formula. It worked, but we quietly skipped the interesting part: *how can a model improve its parameters step by step when no convenient formula exists?* That direction comes from the gradient, and the algorithm that follows it is called **gradient descent**. It is the engine inside nearly every model you will ever train, from a two-parameter line all the way up to large language models.

In this chapter we will:

- Build real intuition for derivatives and gradients as "the slope of the loss".
- See what the learning rate does, and what breaks when it is too big or too small.
- Implement gradient descent in pure Python for the house price model.
- Understand why we scale the feature first.
- Print the loss every epoch so you can watch it fall in your console.
- Compare batch gradient descent with stochastic gradient descent.

Every example in this chapter is copy-paste runnable with `python3 file.py`. No sklearn, no frameworks - just plain Python (and one optional numpy comparison at the end).

### The problem: minimizing a loss function

Recall our setup. We predict a price from a size:

```text
prediction = w * size + b
```

and we measure how wrong we are with mean squared error (MSE):

```text
loss = (1/n) * sum((prediction - actual) ** 2)
```

The loss is a function of `w` and `b`. For every possible pair `(w, b)` there is a number telling us how bad that pair is. Training means finding the pair where that number is as small as possible.

You could imagine trying every combination - a grid search - but that falls apart fast. A modern model has billions of parameters; you cannot enumerate that space. We need a method that, starting from any point, tells us which way is "downhill".

### Derivative intuition: the slope of the loss

A derivative answers one question: *if I nudge this parameter up a tiny bit, does the loss go up or down, and by how much?*

Picture standing on a hill in fog. You cannot see the valley, but you can feel the slope of the ground under your feet. If the ground rises to your right (positive slope), you step left. If it rises to your left (negative slope), you step right. The steeper the slope, the bigger the step you are tempted to take. That is the entire algorithm.

For MSE with one feature, the slopes (partial derivatives) work out to:

```text
dL/dw = (2/n) * sum((prediction - actual) * size)
dL/db = (2/n) * sum(prediction - actual)
```

Read them like this:

- If `prediction - actual` is positive (we predicted too high), increasing `w` increases the loss, so `dL/dw` is positive - we should *decrease* `w`.
- The errors are multiplied by `size` for `dL/dw`, because `w` gets scaled by the feature in the prediction. For `b` there is no feature attached, so it is just the average error.

The **gradient** is just both slopes bundled together: a vector pointing in the direction of steepest *ascent*. Since we want to go down, we move in the opposite direction - that is the "descent" in gradient descent.

You do not need to derive these formulas by hand to use them. SymPy or any calculus refresher can produce them; what matters is that they are computable from the data, and they always point uphill.

### The gradient descent loop

The update rule is:

```text
w = w - learning_rate * dL/dw
b = b - learning_rate * dL/db
```

Repeat until the loss stops improving. Here is the whole lifecycle as a diagram:

#> mermaid: caption="Figure 1: The gradient descent training loop"
graph TD
  A[Start: pick random w and b] --> B[Compute predictions]
  B --> C[Compute loss MSE]
  C --> D[Compute gradients dL/dw and dL/db]
  D --> E[Update w and b]
  E --> F{Loss still falling?}
  F -->|yes| B
  F -->|no| G[Done: converged]
#!

### Implementing it in pure Python

Save this as `gradient_descent.py` and run it with `python3 gradient_descent.py`.

```python-exec
# gradient_descent.py
# Chapter 5: training the Chapter 4 house price model with real gradient descent.

# Same data as Chapter 4: size in sqft, price in dollars.
sizes = [500, 800, 1000, 1200, 1500, 1800, 2000, 2500]
prices = [150000, 200000, 230000, 260000, 300000, 340000, 360000, 420000]

# Scale the feature: work in "thousands of sqft" instead of raw sqft.
xs = [s / 1000 for s in sizes]
ys = prices

n = len(xs)


def predict(x, w, b):
    return w * x + b


def compute_loss(w, b):
    """Mean squared error over the whole dataset."""
    total = 0.0
    for i in range(n):
        error = predict(xs[i], w, b) - ys[i]
        total += error ** 2
    return total / n


def compute_gradients(w, b):
    """Partial derivatives of MSE with respect to w and b."""
    dw = 0.0
    db = 0.0
    for i in range(n):
        error = predict(xs[i], w, b) - ys[i]
        dw += error * xs[i]
        db += error
    return (2 / n) * dw, (2 / n) * db


# Training loop
w = 0.0
b = 0.0
learning_rate = 0.1
epochs = 100

for epoch in range(epochs):
    loss = compute_loss(w, b)
    dw, db = compute_gradients(w, b)
    w = w - learning_rate * dw
    b = b - learning_rate * db
    if epoch % 10 == 0 or epoch == epochs - 1:
        print(f"epoch {epoch:3d}  loss = {loss:,.0f}  w = {w:,.1f}  b = {b:,.1f}")

print()
print(f"Final model: price = {w:,.1f} * (size/1000) + {b:,.1f}")
print(f"Prediction for 1700 sqft: ${predict(1.7, w, b):,.0f}")
```

Run it and watch the console. The loss starts in the tens of billions and falls steadily:

```text
epoch   0  loss = 84,031,250,000  w = 168,500.0  b = 28,750.0
epoch  10  loss = 4,323,232,854   w = 156,006.9  b = 24,800.7
...
epoch  99  loss = 79,873,003      w = 161,377.4  b = 27,609.0
```

That printed column of shrinking losses is the most important debugging tool in machine learning. If it goes down smoothly, training is healthy. If it bounces or explodes, something (usually the learning rate) is wrong.

### Why we scale the feature first

Try the same code with raw square footage (`xs = sizes`) and `learning_rate = 0.1`. The loss will immediately blow up into absurd numbers or overflow. Why?

Look at `dL/dw = (2/n) * sum(error * size)`. With sizes around 1500 and errors around 150,000, each term is roughly 200,000,000. A learning rate of 0.1 times a gradient that large means a single update moves `w` by millions - we leap across the entire valley and land higher than we started, then leap further, forever.

There is a second, subtler problem. Because `size` is huge and prices are what they are, the loss surface becomes a long, narrow canyon: extremely steep in the `w` direction, nearly flat in the `b` direction. Gradient descent zigzags across the canyon walls and crawls toward the minimum at a painful pace.

Dividing sizes by 1000 puts the feature on a friendly scale (0.5 to 2.5), which:

1. Shrinks the gradients to a sane magnitude so one learning rate works.
2. Makes the canyon more bowl-shaped, so descent goes more or less straight to the bottom.

This trick generalizes: real pipelines standardize every feature (subtract the mean, divide by the standard deviation). Same idea, fancier formula.

### The learning rate: your one big dial

The learning rate controls step size. It is the single most important hyperparameter you will ever tune. Run these three experiments yourself by changing one line in the script.

**Too small (0.001):** the loss falls, but glacially. After 100 epochs you are still far from the bottom. Given infinite epochs it would get there, but you do not have infinite time. Wasted compute is the only cost - small steps are always safe.

**Just right (0.1):** smooth, fast convergence. The loss drops by orders of magnitude in the first few epochs, then flattens as the gradient itself shrinks near the minimum (the slope gets gentler as you approach the bottom, so steps naturally get smaller - that is the beauty of following the gradient).

**Too big (0.9 with scaled data, or anything with unscaled data):** each step overshoots the valley and lands on the opposite wall *higher* than before. The loss grows instead of shrinking, and the numbers explode to infinity in a handful of epochs. If you ever see `nan` or `inf` in your training logs, a too-large learning rate is suspect number one.

A practical rule: start small, increase until training becomes unstable, then back off by a factor of 3-10.

### Batch vs stochastic gradient descent

What we wrote above is **batch gradient descent**: every gradient is computed over *all* examples before a single update. With 8 houses that is fine. With 8 million it means reading the entire dataset to make one tiny step.

**Stochastic gradient descent (SGD)** takes the opposite approach: compute the gradient from *one* example, update immediately, move to the next example. One pass over the data (one epoch) now performs `n` updates instead of one.

```python-exec
# sgd.py - stochastic gradient descent on the same data
import random

sizes = [500, 800, 1000, 1200, 1500, 1800, 2000, 2500]
prices = [150000, 200000, 230000, 260000, 300000, 340000, 360000, 420000]
xs = [s / 1000 for s in sizes]
ys = prices
n = len(xs)

w, b = 0.0, 0.0
learning_rate = 0.05
epochs = 30

for epoch in range(epochs):
    order = list(range(n))
    random.shuffle(order)          # shuffle so we do not learn in a fixed order
    for i in order:
        error = (w * xs[i] + b) - ys[i]
        w -= learning_rate * 2 * error * xs[i]   # gradient from ONE example
        b -= learning_rate * 2 * error

    # report the true full-dataset loss so we can compare with batch GD
    loss = sum((w * xs[i] + b - ys[i]) ** 2 for i in range(n)) / n
    print(f"epoch {epoch:3d}  loss = {loss:,.0f}")
```

Run it: the loss still falls, but it jitters instead of gliding. Each individual example pushes `w` and `b` in a slightly selfish direction - that noise is the price of speed, and it is usually worth it:

- **Batch GD:** exact, smooth gradients; one update per full pass. Great for small data.
- **SGD:** noisy gradients, many cheap updates per pass; converges far faster on big data and the noise can even help escape shallow local dips.

In practice everyone uses the middle ground, **mini-batch gradient descent**: shuffle, slice the data into batches of 32-512, and update per batch. You get mostly-smooth gradients at mostly-SGD speed, and the batches map nicely onto vectorized hardware. When people say "SGD" in the wild they almost always mean mini-batch SGD.

Here is the mini-batch version, batch size 4:

```python-exec
# minibatch.py
import random

sizes = [500, 800, 1000, 1200, 1500, 1800, 2000, 2500]
prices = [150000, 200000, 230000, 260000, 300000, 340000, 360000, 420000]
xs = [s / 1000 for s in sizes]
ys = prices
n = len(xs)

w, b = 0.0, 0.0
learning_rate = 0.05
epochs = 50
batch_size = 4

for epoch in range(epochs):
    order = list(range(n))
    random.shuffle(order)
    for start in range(0, n, batch_size):
        batch = order[start:start + batch_size]
        dw = db = 0.0
        for i in batch:
            error = (w * xs[i] + b) - ys[i]
            dw += error * xs[i]
            db += error
        m = len(batch)
        w -= learning_rate * (2 / m) * dw
        b -= learning_rate * (2 / m) * db

    loss = sum((w * xs[i] + b - ys[i]) ** 2 for i in range(n)) / n
    if epoch % 10 == 0:
        print(f"epoch {epoch:3d}  loss = {loss:,.0f}")
```

### A word on numpy

Everything above is deliberately list-based so the mechanics stay visible. The only change numpy buys you is speed and shorter code - the math is identical:

```python-exec
# numpy_version.py - same algorithm, vectorized
import numpy as np

xs = np.array([500, 800, 1000, 1200, 1500, 1800, 2000, 2500]) / 1000
ys = np.array([150000, 200000, 230000, 260000, 300000, 340000, 360000, 420000])

w, b = 0.0, 0.0
for epoch in range(100):
    errors = w * xs + b - ys
    loss = np.mean(errors ** 2)
    w -= 0.1 * 2 * np.mean(errors * xs)
    b -= 0.1 * 2 * np.mean(errors)
    if epoch % 25 == 0:
        print(f"epoch {epoch:3d}  loss = {loss:,.0f}")
```

Vectorization (whole arrays at once instead of Python loops) is why real training runs on GPUs - but it is the same gradients, same updates, same learning-rate drama.

### Where this goes next

You now know the complete training recipe: define a loss, compute its gradient, step downhill, repeat, and watch the printed loss to confirm it works. In Chapter 6: Logistic Regression & Classification we will swap the loss and the prediction shape to handle yes/no outcomes instead of prices - but the training loop itself will be exactly the one you wrote today.

### Practice checklist

- [ ] Run `gradient_descent.py` and confirm the loss decreases every printed epoch.
- [ ] Remove the `/ 1000` scaling, rerun, and observe the loss explode - then explain in one sentence why.
- [ ] Find by experiment the largest learning rate that still converges on the scaled data.
- [ ] Modify the loop to stop early when the loss improves by less than 1 between epochs.
- [ ] Run `sgd.py` and `minibatch.py` and compare how many epochs each needs to reach a similar loss.
- [ ] Add a second feature (e.g. number of bedrooms) and extend the gradient computation to a second weight.
