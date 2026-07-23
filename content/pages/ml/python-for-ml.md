---
layout: tutorial
title: "Chapter 2 &ndash; Python for ML"
permalink: /courses/machine-learning/python-for-ml/
difficulty: beginner
author: Pankaj Doharey
summary: The practical Python you actually need for machine learning - lists vs arrays, vectorization, a tiny numpy primer, and loading real data from a CSV.
theme: pylearning
previous_tutorial:
  title: "Chapter 1: What is Machine Learning"
  url: /courses/machine-learning/what-is-machine-learning/
next_tutorial:
  title: "Chapter 3: Linear Regression from Scratch"
  url: /courses/machine-learning/linear-regression-from-scratch/
---

In Chapter 1 we talked about machine learning as "fitting a function to data". That sounds abstract, so in this chapter we get concrete: what does "data" actually look like in Python, and what tools do we use to manipulate it? By the end you will know the small subset of Python - and an even smaller subset of numpy - that every chapter from now on relies on.

Every example in this chapter is a complete program. Save it to a file and run it with `python3 file.py`. No notebooks, no frameworks, no magic.

### What we are NOT going to use

A quick word on scope, because the Python data ecosystem is enormous:

- We do **not** use pandas, sklearn, or PyTorch. The whole point of this course is to build those ideas by hand.
- We **do** use plain Python lists, the built-in `csv` module, and - starting right here - a little bit of `numpy`.

If you do not have numpy yet:

```bash
pip install numpy
```

That is the only dependency in the entire course.

### Lists vs arrays: the core mental model

Plain Python already has a container for numbers: the list. So why does every ML tutorial immediately reach for numpy? Two reasons: speed and ergonomics. Let us feel the difference.

A Python list is a container of *pointers to objects*. Each element can be anything - an int, a string, another list. That flexibility costs memory and time. A numpy array is a contiguous block of same-typed numbers. The CPU can chew through it without stopping to ask "what kind of object is this?" at every element.

```python
# lists_vs_arrays.py

# A Python list: flexible, but slow for math
scores = [90, 72, 85, 60]

# Doubling every element requires an explicit loop or comprehension
doubled = []
for s in scores:
    doubled.append(s * 2)
print(doubled)  # [180, 144, 170, 120]

import numpy as np

# A numpy array: one type, stored contiguously
scores_arr = np.array([90, 72, 85, 60])
doubled_arr = scores_arr * 2
print(doubled_arr)  # [180 144 170 120]
```

Run it with `python3 lists_vs_arrays.py`. Both produce the same numbers, but notice the shape of the code: with a list you describe the *loop*; with an array you describe the *operation*. That shift - from "how to iterate" to "what to compute" - is the single most important habit in numerical programming.

There is also a trap worth knowing early. Multiplying a Python list by an integer does something completely different:

```python
print([1, 2, 3] * 2)          # [1, 2, 3, 1, 2, 3]  - repetition!
print(np.array([1, 2, 3]) * 2) # [2 4 6]             - elementwise math
```

### The vectorization idea

"Vectorization" just means: express an operation on a whole array at once, instead of looping element by element. Under the hood numpy hands the loop to compiled C code, which is typically 50-100x faster than a Python loop.

Let us time a real example: computing the dot product of two vectors of one million numbers, once with a Python loop and once with numpy.

```python
# vectorization.py
import time
import numpy as np

n = 1_000_000
a = [float(i % 7) for i in range(n)]
b = [float(i % 5) for i in range(n)]

# Version 1: pure Python loop
start = time.time()
total = 0.0
for i in range(n):
    total += a[i] * b[i]
print("loop result:", total, " took", round(time.time() - start, 4), "s")

# Version 2: numpy vector op
va = np.array(a)
vb = np.array(b)
start = time.time()
total2 = np.dot(va, vb)
print("dot  result:", total2, " took", round(time.time() - start, 4), "s")
```

On most machines the loop takes a few tenths of a second and the numpy call takes a couple of milliseconds - same answer, two orders of magnitude apart. When you get to gradient descent in Chapter 3, you will run operations like this thousands of times, so the difference stops being cosmetic and starts being the difference between "done" and "still running".

The deeper point, though, is not the speed. Vectorized code is *shorter and closer to the math*. The formula "sum of products" is exactly `np.dot(a, b)`. Less code, fewer bugs.

### A tiny numpy primer

Everything we need from numpy fits in a few pages. Learn these four things and you can read all the code in this course.

**1. Creating and inspecting arrays**

```python
# numpy_basics.py
import numpy as np

x = np.array([1.0, 2.0, 3.0])          # 1-D array (a vector)
m = np.array([[1, 2, 3], [4, 5, 6]])   # 2-D array (a matrix)

print(x.shape)   # (3,)      -> one axis, three elements
print(m.shape)   # (2, 3)    -> two rows, three columns
print(m.dtype)   # int64
print(m[1, 2])   # 6         -> row 1, column 2
print(m[:, 0])   # [1 4]     -> every row, first column

zeros = np.zeros((2, 3))     # handy starting points
ones = np.ones(4)
r = np.arange(0, 10, 2)      # [0 2 4 6 8]
print(zeros)
print(ones)
print(r)
```

Think of `shape` as the array's "dimensions label". In ML, a dataset is almost always a 2-D array of shape `(n_examples, n_features)` - one row per example, one column per feature.

**2. Elementwise operations**

Arithmetic on arrays applies to every element at once:

```python
# elementwise.py
import numpy as np

temps_c = np.array([0.0, 10.0, 20.0, 30.0])

temps_f = temps_c * 9.0 / 5.0 + 32.0   # the whole formula at once
print(temps_f)  # [32. 50. 68. 86.]

# Array-with-array operations are elementwise too
a = np.array([1.0, 2.0, 3.0])
b = np.array([10.0, 20.0, 30.0])
print(a + b)   # [11. 22. 33.]
print(a * b)   # [10. 40. 90.]   (NOT a dot product!)
```

That last line trips everyone up at least once: `*` on two arrays multiplies element by element. For a dot product, use `np.dot` or the `@` operator.

**3. The dot product**

The dot product - sum of pairwise products - is the atom of machine learning. A linear model's prediction *is* a dot product between the weights and the features.

```python
# dot_product.py
import numpy as np

weights = np.array([0.5, 0.3, 0.2])
scores  = np.array([90.0, 70.0, 85.0])   # exam, homework, project

final_grade = weights @ scores            # same as np.dot(weights, scores)
print(final_grade)                        # 83.0

# What it means by hand:
manual = 0.5 * 90.0 + 0.3 * 70.0 + 0.2 * 85.0
print(manual)                             # 83.0
```

Read `weights @ scores` as "weighted sum". When Chapter 3 says "prediction = w · x + b", this is the exact line of code that implements it.

**4. Broadcasting**

Broadcasting is numpy's rule for combining arrays of different shapes: the smaller one is stretched (conceptually, without copying) to match. The most common case is array-with-scalar, which you already saw in the temperature conversion. The second most common case is adding a row vector to every row of a matrix:

```python
# broadcasting.py
import numpy as np

# 3 students, 2 test scores each
scores = np.array([
    [80.0, 90.0],
    [70.0, 85.0],
    [60.0, 75.0],
])

# Curve every test by adding 5 points: shape (2,) stretches over all 3 rows
curve = np.array([5.0, 5.0])
print(scores + curve)

# Center each column around its mean (you will do this for real data later)
column_means = scores.mean(axis=0)     # mean down the rows -> shape (2,)
print(column_means)                    # [70. 83.33...]
centered = scores - column_means       # broadcasting again
print(centered)
```

If the shapes are incompatible, numpy raises a clear error instead of guessing. When you see `operands could not be broadcast together`, check the `.shape` of both sides first - that one habit solves 90% of numpy debugging.

### Loading a dataset from CSV

Real data arrives as files, and the humblest format is CSV. Python's built-in `csv` module handles it with zero dependencies. Create this small dataset - house sizes and prices - as `houses.csv` in the same folder as your script:

```csv
size_sqft,bedrooms,price
750,2,180000
940,2,220000
1150,3,265000
1300,3,290000
1600,4,340000
1850,4,375000
```

Now load it, split it into a feature matrix `X` and a label vector `y`, and hand it to numpy:

```python
# load_csv.py
import csv
import numpy as np

features = []
labels = []

with open("houses.csv", newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        features.append([float(row["size_sqft"]), float(row["bedrooms"])])
        labels.append(float(row["price"]))

X = np.array(features)   # shape: (n_examples, n_features)
y = np.array(labels)     # shape: (n_examples,)

print("X shape:", X.shape)
print("y shape:", y.shape)
print("First example:", X[0], "->", y[0])

# Quick sanity statistics - always look at your data before modeling it
print("size range :", X[:, 0].min(), "to", X[:, 0].max())
print("mean price :", y.mean())
```

Run it with `python3 load_csv.py`. The pattern here - rows become examples, columns become features, one column becomes the label - is the standard contract for the rest of the course. `X` is a matrix, `y` is a vector, and a model is something that maps `X` to predictions that should look like `y`.

Notice we did the parsing in pure Python and only converted to numpy at the end. That split is deliberate: `csv` is good at reading text, numpy is good at math on numbers.

### The data flow, end to end

Here is the pipeline this chapter just built, and the one every supervised-learning chapter will follow:

#> mermaid: caption="Figure 1: From raw CSV to a model-ready feature matrix and label vector."
graph LR
  A[CSV file] --> B[csv module: parse rows]
  B --> C[features X]
  B --> D[labels y]
  C --> E[model]
  D --> E
#!

### Plotting, conceptually

We will not depend on matplotlib in this course, but you should know what you would look at if you used it. The workhorse plot for regression data is a **scatter plot**: one axis per variable, one dot per example. Plotting `size_sqft` on the x-axis against `price` on the y-axis for the houses above, you would see the dots climb from lower-left to upper-right - bigger houses, higher prices. That visible trend is exactly the pattern a linear model tries to capture with a line.

A scatter plot answers three questions before you write any model code:

- Is there a trend at all, or does it look like static?
- Is the trend roughly a straight line, or does it bend?
- Are there outliers - points far from the pack - that might dominate the fit?

If you have matplotlib installed (`pip install matplotlib`), five lines give you the picture:

```python
# optional_plot.py  (requires: pip install matplotlib)
import matplotlib.pyplot as plt
import numpy as np

X = np.array([750, 940, 1150, 1300, 1600, 1850])
y = np.array([180000, 220000, 265000, 290000, 340000, 375000])

plt.scatter(X, y)
plt.xlabel("size (sqft)")
plt.ylabel("price ($)")
plt.show()
```

### Common beginner pitfalls, collected

A short list, because you will hit all of these:

- `[1, 2, 3] * 2` repeats the list; `np.array([1, 2, 3]) * 2` doubles the numbers. Know which object you are holding.
- `a * b` on arrays is elementwise; `a @ b` is the dot product. Mixing them up produces silently wrong numbers.
- CSV values come back as strings - always convert with `float()` or `int()` before doing math.
- When numpy complains about broadcasting, print `.shape` on both operands and compare.
- Look at your data (min, max, mean, a scatter plot) *before* fitting anything. Models faithfully learn whatever the data says, including its mistakes.

### Where this leads

You now have the full toolkit for the next chapter: a feature matrix `X`, a label vector `y`, and the dot product. In Chapter 3: Linear Regression from Scratch, we will put them together into `prediction = X @ w + b`, measure how wrong the predictions are, and nudge the weights downhill until the line fits the houses data you loaded above.

### Practice checklist

- [ ] Run `lists_vs_arrays.py` and explain in one sentence why `[1, 2, 3] * 2` differs from the numpy version.
- [ ] Run `vectorization.py` and note the speed ratio between the loop and `np.dot` on your machine.
- [ ] From memory, write the one-liner that computes a weighted sum of `[10, 20, 30]` with weights `[0.2, 0.3, 0.5]` using `@`.
- [ ] Predict the output of `np.zeros((2, 3)) + np.array([1, 2, 3])`, then run it to check - what rule made it work?
- [ ] Add two more rows to `houses.csv`, rerun `load_csv.py`, and confirm the shapes grow as expected.
- [ ] Write a tiny script that loads `houses.csv`, computes the mean price per bedroom count, and prints it.
- [ ] Sketch (on paper or with matplotlib) the size-vs-price scatter plot and describe the trend in one sentence.
