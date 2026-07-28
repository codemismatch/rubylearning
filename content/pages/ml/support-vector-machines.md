---
layout: tutorial
title: "Chapter 12 &ndash; Support Vector Machines"
permalink: /courses/machine-learning/support-vector-machines/
difficulty: intermediate
author: Neeraj Doharey
summary: Maximize the margin between classes with hinge loss and subgradient descent, meet the support vectors, and grasp the kernel trick with a pure-Python example.
theme: pylearning
previous_tutorial:
  title: "Chapter 11: Random Forests"
  url: /courses/machine-learning/random-forests/
next_tutorial:
  title: "Chapter 13: Naive Bayes"
  url: /courses/machine-learning/naive-bayes/
date: 2026-02-19
---

Logistic regression from Chapter 6: Logistic Regression & Classification finds *a* line that separates the classes. A support vector machine (SVM) finds the *best* line: the one that stays as far away as possible from both classes. That single change of goal - from "separate" to "separate with maximum margin" - produces models that generalize remarkably well, and it leads to one of the most elegant ideas in all of machine learning: the kernel trick.

Everything here is pure Python. Save the snippets into `svm.py` and run with `python3 svm.py`.

### The margin idea

Many lines can separate two tidy classes. Which one do you trust on new data? Intuition says: the line down the middle of the "street" between the classes. The street's width is the **margin**, and the training points that touch the street's edges are the **support vectors** - they alone determine the line. Move or delete any other point and nothing changes; nudge a support vector and the whole boundary shifts.

#> mermaid: caption="Figure 1: The maximum-margin boundary and its support vectors"
graph LR
  A[labeled points of two classes] --> B[find separating line]
  B --> C[maximize street width]
  C --> D[edge points are support vectors]
  D --> E[final boundary depends only on them]
#!

Labels here are +1 and -1 (not 1 and 0), and the score is the familiar linear one: `f(x) = w . x + b`. A point is on the correct side of the street with clearance when:

    y * f(x) >= 1

The quantity `y * f(x)` is the **functional margin** of the point: positive means correctly classified, and bigger than 1 means safely outside the margin.

### Hard margin vs soft margin

If the classes are perfectly separable, we can demand `y * f(x) >= 1` for every point - a **hard margin**. Real data has overlap and outliers, so we relax: allow violations but pay for them. Each point's penalty is its hinge loss:

    loss_i = max(0, 1 - y_i * f(x_i))

- Correct and beyond the margin: penalty 0.
- Correct but inside the margin: small penalty.
- Wrong side: penalty grows linearly with how wrong.

The full soft-margin objective combines "keep the street wide" (which means keeping `||w||` small - the math works out so margin width is `2 / ||w||`) with "pay for violations":

    J = (1/2) * ||w||^2 + C * sum(loss_i)

`C` is the trade-off knob: large C punishes violations hard (narrower street, risk of overfitting); small C tolerates more mistakes for a wider, smoother boundary (risk of underfitting - the same dial as Chapter 8: Generalization & Regularization).

### Subgradient descent on hinge loss

Hinge loss has a kink at `y * f(x) = 1`, so it has no single gradient there - we use a **subgradient**, which just picks one valid slope at the kink. For the objective above (dropping the 1/2 for simplicity and folding C into a per-point weight), the update rules per epoch are:

```text
lam is a small constant (the regularization strength, playing C's role)
t counts steps; lr = 1 / (lam * t) shrinks as training proceeds
append a feature pinned to 1 so the bias b is learned as just another weight
for each step, pick one point (x, y):
    if y * (w . x) < 1:   w = (1 - lr * lam) * w + lr * y * x
    else:                 w = (1 - lr * lam) * w
```

Correct-and-safe points only shrink `w` slightly (the regularizer widening the street); points inside the margin or on the wrong side additionally push `w` toward classifying them correctly. This scheme is known as Pegasos.

Here is the complete trainer on a tiny 2D dataset: hours studied and hours slept, pass (+1) vs fail (-1).

```python-exec
# (hours_studied, hours_slept), label: +1 pass, -1 fail
data = [
    ((1, 5), -1), ((2, 6), -1), ((1.5, 7), -1), ((3, 5), -1), ((2, 8), -1),
    ((5, 6), +1), ((6, 5), +1), ((5, 8), +1), ((7, 6), +1), ((6, 8), +1),
]

def dot(w, x):
    return sum(wi * xi for wi, xi in zip(w, x))

def train_svm(data, lam=0.002, epochs=100000):
    # Pegasos: stochastic subgradient descent on the hinge-loss objective.
    # The bias b is just another weight whose feature is pinned to 1.
    w = [0.0] * (len(data[0][0]) + 1)
    for t in range(1, epochs + 1):
        x, y = data[t % len(data)]          # cycle through the points
        x = list(x) + [1.0]                 # bias feature
        lr = 1.0 / (lam * t)                # shrinking step size
        if y * dot(w, x) < 1:               # inside the margin or wrong
            w = [(1 - lr * lam) * wi + lr * y * xi for wi, xi in zip(w, x)]
        else:                               # safely classified: only shrink
            w = [(1 - lr * lam) * wi for wi in w]
        if t % 25000 == 0:
            violations = sum(1 for xx, yy in data
                             if yy * dot(w, list(xx) + [1.0]) < 1)
            print(f"step {t:6d}  w = [{w[0]:.3f}, {w[1]:.3f}]  b = {w[2]:.3f}  margin violations: {violations}")
    return w

w = train_svm(data)
```

```text
step  25000  w = [1.860, -0.560]  b = -3.800  margin violations: 0
step  50000  w = [1.530, -0.350]  b = -3.840  margin violations: 1
step  75000  w = [1.480, -0.240]  b = -3.953  margin violations: 1
step 100000  w = [1.390, -0.250]  b = -3.945  margin violations: 0
```

The weights wobble a little along the way - normal for stochastic updates with a shrinking step size - and settle near `w = [1.39, -0.25]`, `b = -3.95`. Study hours dominate, as they should: the fails all studied 3 hours or fewer, the passes 5 or more.

Predictions and accuracy:

```python-exec
def predict(w, x):
    return +1 if dot(w, list(x) + [1.0]) >= 0 else -1

correct = sum(1 for x, y in data if predict(w, x) == y)
print(f"training accuracy: {correct}/{len(data)}")
print("new student (4, 6):", predict(w, (4, 6)))
print("new student (1, 9):", predict(w, (1, 9)))
```

```text
training accuracy: 10/10
new student (4, 6): 1
new student (1, 9): -1
```

### Meeting the support vectors

Which points actually shaped this boundary? Sort the training points by their functional margin and look at the closest ones:

```python-exec
by_margin = sorted(data, key=lambda r: r[1] * dot(w, list(r[0]) + [1.0]))
for x, y in by_margin[:3]:
    m = y * dot(w, list(x) + [1.0])
    print(f"closest to the boundary: {x} (functional margin {m:.3f})")
```

```text
closest to the boundary: (5, 8) (functional margin 1.005)
closest to the boundary: (3, 5) (functional margin 1.025)
closest to the boundary: (5, 6) (functional margin 1.505)
```

The two points sitting right on the margin - the pass student at `(5, 8)` and the fail student at `(3, 5)` - are the support vectors, and they carry the model: everything else is comfortably far away, and deleting it would leave the boundary essentially unchanged. That sparsity is a big part of why SVMs generalize well and why they were the algorithm to beat in the 1990s and 2000s.

### When a line is not enough: the kernel trick

Our student data is linearly separable, but the XOR pattern from Chapter 15: Neural Networks from Scratch is not - no straight line separates it, no matter how you tune C. The SVM answer is beautiful: **map the points into a higher-dimensional space where a line does exist**.

For 2D points, add the product feature `x1 * x2`:

```python-exec
xor = [((0, 0), -1), ((0, 1), +1), ((1, 0), +1), ((1, 1), -1)]

def transform(x):
    return (x[0], x[1], x[0] * x[1])

lifted = [(transform(x), y) for x, y in xor]

w3 = train_svm(lifted, lam=0.01, epochs=8000)   # same trainer, one more feature
print("lifted weights:", [round(v, 3) for v in w3])
for x, y in xor:
    guess = predict(w3, transform(x))
    print(f"{x}: predicted {guess:+d}, actual {y:+d}")
```

```text
lifted weights: [2.0, 2.0, -4.013, -1.0]
(0, 0): predicted -1, actual -1
(0, 1): predicted +1, actual +1
(1, 0): predicted +1, actual +1
(1, 1): predicted -1, actual -1
```

Perfect - a flat plane in the lifted space corresponds to a curved boundary in the original 2D space. Look at the learned weights `[2, 2, -4, -1]`: the score is `2*x1 + 2*x2 - 4*x1*x2 - 1`, which is negative at the corners `(0, 0)` and `(1, 1)` and positive at `(0, 1)` and `(1, 0)` - exactly XOR, discovered by gradient descent.

The **kernel trick** takes this one step further. The full SVM math only ever needs *dot products* between points, never the points themselves. So instead of computing an expensive (possibly infinite-dimensional) transform, you plug in a **kernel function** that computes the dot product of the transformed points directly:

- **Polynomial kernel**: `(x . z + 1)^d` - implicitly uses all feature products up to degree d.
- **RBF (Gaussian) kernel**: `exp(-gamma * ||x - z||^2)` - corresponds to an infinite-dimensional transform; draws smooth, flexible boundaries around clusters.

We will not implement kernelized training here (it requires solving a quadratic program over dual variables), but you now know exactly what it buys: curved boundaries with linear-SVM machinery. When you meet `SVC(kernel='rbf')` in a library, it is doing what we just did by hand - minus the explicit `transform`.

### Strengths and weaknesses

- **Strengths**: maximum-margin boundary generalizes well in high dimensions, the solution depends only on support vectors, and kernels handle non-linear problems elegantly. Works well even when features outnumber examples.
- **Weaknesses**: needs feature scaling (like KNN - the margin is a distance), training is slow on very large datasets, no native probability output, and choosing C and a kernel requires validation.

### The full file

Assemble the snippets into `svm.py` in this order: dataset and `dot`, `train_svm` with its log lines, prediction and accuracy, the margin scan, then the XOR lift. Run `python3 svm.py` and reproduce every number. Then tinker: add an outlier pass student at `(1, 9)` and rerun with `lam=0.0001` (nearly hard margin) versus `lam=0.1` (very soft) - watch the boundary swing toward the outlier in the first case and ignore it in the second.

### Practice checklist

- [ ] Explain in one sentence what makes a point a support vector.
- [ ] Write the hinge loss for a point with `y = +1` and `f(x) = 0.4` and compute its value by hand.
- [ ] Describe what happens to the margin and to training accuracy as C grows very large.
- [ ] Modify the trainer to print `||w||` each epoch and confirm it shrinks once violations hit zero - why does it shrink?
- [ ] Explain why scaling features matters for an SVM, using the margin definition `2 / ||w||`.
- [ ] In your own words, what does the RBF kernel let you do that explicit feature transforms cannot conveniently do?
