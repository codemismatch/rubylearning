---
layout: tutorial
title: "Chapter 4 &ndash; Linear Regression from Scratch"
permalink: /courses/machine-learning/linear-regression-from-scratch/
difficulty: beginner
author: Pankaj Doharey
summary: Fit a straight line to data by hand - derive w and b with the closed-form least-squares formulas in pure Python, then predict house prices and measure error with MSE.
theme: pylearning
previous_tutorial:
  title: "Chapter 3: Preparing Data for Machine Learning"
  url: /courses/machine-learning/preparing-data-for-machine-learning/
next_tutorial:
  title: "Chapter 5: Gradient Descent"
  url: /courses/machine-learning/gradient-descent/
date: 2026-01-20
---

Linear regression is the simplest model that still counts as machine learning: it learns a straight line that maps an input to an output. In Chapter 3: Preparing Data for Machine Learning we learned how to turn raw rows into trustworthy features and labels. Here we deliberately use one already-clean feature so the model's mathematics stays visible. You will fit a line to a tiny dataset of house sizes and prices, computing the best slope and intercept yourself with closed-form formulas - no sklearn, no numpy, just the Python lists and loops from Chapter 2: Python for ML.

Every code block below is a complete, copy-paste runnable script. Save any of them as `file.py` and run `python3 file.py`.

### The hypothesis: y = w*x + b

A straight line in one dimension is fully described by two numbers:

- `w` - the weight (slope): how much the output changes per unit of input.
- `b` - the bias (intercept): the output when the input is zero.

The model's hypothesis is:

```text
prediction = w * x + b
```

For house prices, `x` is the size in square meters and the prediction is the price in thousands of dollars. If `w = 2.5` and `b = 30`, a 100 m² house is predicted at `2.5 * 100 + 30 = 280` thousand dollars. Learning means choosing `w` and `b` so that predictions land as close as possible to the real prices in the training data.

Here is the hypothesis as a Python function:

```python-exec
# hypothesis.py
def predict(x, w, b):
    return w * x + b

print(predict(100, w=2.5, b=30))  # 280.0
```

Run it with `python3 hypothesis.py`. So far the numbers `2.5` and `30` were invented. The rest of the chapter is about computing them from data.

### A tiny dataset

We will use five houses. Each data point is a `(size, price)` pair:

```python-exec
# data.py
sizes  = [50, 60, 80, 100, 120]    # square meters
prices = [150, 180, 230, 290, 330] # thousands of dollars

for size, price in zip(sizes, prices):
    print(f"{size:>4} m^2  ->  ${price}k")
```

A quick sanity check by eye: as size goes up, price goes up roughly linearly, around 2 to 2.5 thousand dollars per square meter plus a base. The formulas below will pin that down exactly.

### Measuring error: mean squared error

To know whether a candidate line is good, we need a single number that measures how wrong it is. The standard choice is the mean squared error (MSE):

1. For each training example, compute the prediction `y_hat = w * x + b`.
2. Compute the error `y_hat - y` (how far the prediction is from the true value).
3. Square each error so positives and negatives do not cancel.
4. Average over all `n` examples.

Written out in plain text:

```text
MSE = (1/n) * sum over i of ( (w * x_i + b) - y_i )^2
```

In Python:

```python-exec
# mse.py
def mse(sizes, prices, w, b):
    total = 0.0
    for x, y in zip(sizes, prices):
        error = (w * x + b) - y
        total += error ** 2
    return total / len(sizes)

sizes  = [50, 60, 80, 100, 120]
prices = [150, 180, 230, 290, 330]

print(mse(sizes, prices, w=2.5, b=30))   # decent guess
print(mse(sizes, prices, w=1.0, b=0))    # bad guess
```

The bad guess produces a much larger MSE. Fitting the model means finding the `w` and `b` that make MSE as small as possible.

### Two ways to find the best line

There are two broad strategies for minimizing MSE:

- **Closed-form solution.** For simple linear regression there is a direct formula that jumps straight to the optimal `w` and `b` using means and variances. One pass through the data, exact answer.
- **Iterative learning.** Start with a guess, measure the error, nudge `w` and `b` downhill, repeat. This is gradient descent, and it is the subject of Chapter 5: Gradient Descent.

Why bother with the iterative way if a formula exists? Because the closed form only exists for linear regression. Neural networks and every larger model in this course have no closed-form solution - iterative learning is the only option. Learn the exact answer here so you can check gradient descent against it in the next chapter.

### The closed-form least-squares formulas

Minimizing MSE by setting its derivatives to zero (we will do that derivation properly in Chapter 5) gives:

```text
w = sum of (x_i - mean_x) * (y_i - mean_y)  /  sum of (x_i - mean_x)^2
b = mean_y - w * mean_x
```

In words: the numerator is the covariance between `x` and `y` (how they move together), and the denominator is the variance of `x` (how spread out the inputs are). The intercept then centers the line so it passes through the point `(mean_x, mean_y)`.

Here is the full pipeline at a glance:

#> mermaid: caption="Figure 1: From raw training data to a price prediction"
graph LR
  A[training data] --> B[fit: learn w and b]
  B --> C[model y = w*x + b]
  C --> D[predict new size]
  D --> E[price]
#!

### Implementing fit and predict in pure Python

Now the complete script. It computes the means, applies the closed-form formulas, and exposes `fit` and `predict` functions:

```python-exec
# linear_regression.py
def mean(values):
    return sum(values) / len(values)

def fit(xs, ys):
    """Closed-form least squares: returns (w, b) for y = w*x + b."""
    mean_x = mean(xs)
    mean_y = mean(ys)

    covariance = 0.0
    variance = 0.0
    for x, y in zip(xs, ys):
        covariance += (x - mean_x) * (y - mean_y)
        variance += (x - mean_x) ** 2

    w = covariance / variance
    b = mean_y - w * mean_x
    return w, b

def predict(x, w, b):
    return w * x + b

def mse(xs, ys, w, b):
    total = 0.0
    for x, y in zip(xs, ys):
        total += (w * x + b - y) ** 2
    return total / len(xs)

sizes  = [50, 60, 80, 100, 120]
prices = [150, 180, 230, 290, 330]

w, b = fit(sizes, prices)
print(f"learned w = {w:.4f}, b = {b:.4f}")

print("\ntraining examples:")
for x, y in zip(sizes, prices):
    print(f"  size {x:>4} -> true {y:>4}  predicted {predict(x, w, b):7.2f}")

print(f"\nMSE on training data: {mse(sizes, prices, w, b):.4f}")

new_size = 90
print(f"predicted price for {new_size} m^2: ${predict(new_size, w, b):.2f}k")
```

Run `python3 linear_regression.py` and you should see output close to:

```text
learned w = 2.4074, b = 27.4074

training examples:
  size   50 -> true  150  predicted  147.78
  size   60 -> true  180  predicted  171.85
  size   80 -> true  230  predicted  220.00
  size  100 -> true  290  predicted  268.15
  size  120 -> true  330  predicted  316.30

MSE on training data: 24.9627
predicted price for 90 m^2: $244.07k
```

The learned slope says each additional square meter adds about 2.41 thousand dollars, and the learned intercept is about 27.4. Every prediction sits within a few thousand dollars of the true price, and the MSE of roughly 25 is the smallest any straight line can achieve on this data - that is what "least squares" guarantees.

### Sanity-checking the fit

A good habit is to verify that the line passes through the mean point, which the formula for `b` guarantees:

```python-exec
# check.py
def mean(values):
    return sum(values) / len(values)

def fit(xs, ys):
    mean_x, mean_y = mean(xs), mean(ys)
    covariance = sum((x - mean_x) * (y - mean_y) for x, y in zip(xs, ys))
    variance = sum((x - mean_x) ** 2 for x in xs)
    w = covariance / variance
    return w, mean_y - w * mean_x

sizes  = [50, 60, 80, 100, 120]
prices = [150, 180, 230, 290, 330]

w, b = fit(sizes, prices)
mean_x, mean_y = mean(sizes), mean(prices)
print(f"line at mean_x: {w * mean_x + b:.4f}  vs mean_y: {mean_y:.4f}")
```

Both numbers print the same value, confirming the line is centered correctly. This version also shows the formulas compressed into generator expressions - same math, less code.

### What can go wrong

- **Zero variance.** If every `x` is identical, the variance denominator is zero and the formula divides by zero. Real datasets need variation in the input.
- **Outliers.** Squared errors punish big misses heavily, so one extreme house can drag the whole line toward it. Chapter 5's iterative view makes this behavior easier to observe.
- **Non-linear data.** If the true relationship curves, no straight line fits well regardless of how you pick `w` and `b`. Later chapters add features and non-linear models.

### Where this leads

You now have the two pieces that define any learning problem in this course: a hypothesis (`y = w*x + b`) and a cost function (MSE). The only thing that changes as models grow is how you minimize the cost. In Chapter 5: Gradient Descent you will replace the closed-form formula with an iterative loop that starts from a random guess and walks downhill on the MSE surface - and you will see it converge to the exact same `w` and `b` you computed today.

### Practice checklist

- [ ] Run `linear_regression.py` and confirm the learned `w` and `b` match the values shown above.
- [ ] Add a sixth house (e.g. 150 m² at $390k) to the dataset and re-fit; describe how `w` and `b` change.
- [ ] Modify the script to compute MSE with the *wrong* formula (forgetting to square the errors) and observe which large errors cancel out.
- [ ] Write a version of `fit` that raises a clear error when the input variance is zero, and test it with `xs = [100, 100, 100]`.
- [ ] Compute by hand (or with a one-liner) the prediction for a 75 m² house, then verify it with `predict`.
- [ ] Add one large outlier to the data, re-fit, and note how much the MSE and the slope move - keep this observation in mind for Chapter 5: Gradient Descent.
