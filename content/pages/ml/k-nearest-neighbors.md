---
layout: tutorial
title: "Chapter 9 &ndash; K-Nearest Neighbors"
permalink: /courses/machine-learning/k-nearest-neighbors/
difficulty: intermediate
author: Pankaj Doharey
summary: Classify points by their neighbors - distance metrics, choosing k, weighted votes, and why feature scaling matters, all in pure Python.
theme: pylearning
previous_tutorial:
  title: "Chapter 8: Generalization & Regularization"
  url: /courses/machine-learning/generalization-and-regularization/
next_tutorial:
  title: "Chapter 10: Decision Trees"
  url: /courses/machine-learning/decision-trees/
date: 2026-02-12
---

In Chapter 6: Logistic Regression & Classification we learned a single global rule - a weighted sum pushed through a sigmoid - and the whole dataset was compressed into two numbers, `w` and `b`. K-nearest neighbors takes the opposite approach: it keeps the entire training set as the "model" and classifies a new point by simply asking its closest neighbors what they are. No training loop, no gradients - just geometry and voting.

Everything here is pure Python. Save every snippet into one file, say `knn.py`, and run it with `python3 knn.py` - each example is copy-paste runnable.

### The idea in one picture

You have a scatter of labeled points - red circles and blue squares. A new point arrives with no label. KNN does the most human thing possible:

1. Measure the distance from the new point to every labeled point.
2. Pick the `k` closest ones (the "nearest neighbors").
3. Let them vote; the majority class wins.

#> mermaid: caption="Figure 1: A new point asks its k nearest neighbors to vote"
graph LR
  A[new unlabeled point] --> B[measure distances]
  B --> C[sort by distance]
  C --> D[take k closest neighbors]
  D --> E[majority vote]
  E --> F[predicted class]
#!

If `k = 3` and two of the three closest neighbors are red, the point is predicted red. That is the entire algorithm - the rest of this chapter is about making each step precise and avoiding its pitfalls.

### A tiny 2D dataset

We will classify fruit by weight in grams and sweetness on a 1-10 scale. Small and sweet is a berry; heavy and mild is a melon.

```python-exec
# (weight_grams, sweetness), label
data = [
    ((15, 9),  "berry"),
    ((20, 8),  "berry"),
    ((18, 10), "berry"),
    ((25, 7),  "berry"),
    ((22, 9),  "berry"),
    ((300, 3), "melon"),
    ((350, 4), "melon"),
    ((280, 2), "melon"),
    ((400, 5), "melon"),
    ((330, 3), "melon"),
]
```

The two features live on wildly different scales: weight runs to 400 while sweetness stays under 10. Keep that in the back of your mind - it will bite us soon.

The same data as a picture - note how the weight axis dwarfs the sweetness axis:

```python-exec
berry_x = [f[0] for f, label in data if label == "berry"]
berry_y = [f[1] for f, label in data if label == "berry"]
melon_x = [f[0] for f, label in data if label == "melon"]
melon_y = [f[1] for f, label in data if label == "melon"]

plt.scatter(berry_x, berry_y, label="berry")
plt.scatter(melon_x, melon_y, label="melon")
plt.scatter([100], [8], label="query (100, 8)")
plt.title("Fruit by weight and sweetness")
plt.xlabel("weight (grams)")
plt.ylabel("sweetness (1-10)")
plt.show()
```

### Measuring distance: Euclidean and friends

The default notion of "close" is Euclidean distance - straight-line distance, Pythagoras in any number of dimensions:

    distance(p, q) = sqrt( (p1 - q1)^2 + (p2 - q2)^2 + ... )

```python-exec
import math

def euclidean(p, q):
    total = 0.0
    for a, b in zip(p, q):
        total += (a - b) ** 2
    return math.sqrt(total)

print(round(euclidean((15, 9), (300, 3)), 2))   # far apart
print(round(euclidean((15, 9), (18, 10)), 2))   # close together
```

```text
285.06
3.16
```

Other metrics exist and are worth knowing by name:

- **Manhattan distance**: sum of absolute differences - distance along a city grid. More robust when a single feature can spike.
- **Minkowski distance**: the generalization of both (Euclidean is Minkowski with power 2, Manhattan with power 1).
- **Cosine distance**: compares the angle between vectors rather than their length - popular for text vectors like the embeddings in Chapter 16: Text Embeddings.

For the rest of the chapter we stick with Euclidean distance.

### KNN from scratch: majority vote

Here is the complete classifier. No training function exists - "fitting" a KNN model means storing the data.

```python-exec
def knn_predict(data, point, k=3):
    distances = []
    for features, label in data:
        d = euclidean(features, point)
        distances.append((d, label))
    distances.sort(key=lambda pair: pair[0])
    neighbors = distances[:k]

    votes = {}
    for d, label in neighbors:
        votes[label] = votes.get(label, 0) + 1
    winner = max(votes, key=votes.get)
    return winner, neighbors

for point in [(19, 9), (320, 3), (100, 8)]:
    winner, neighbors = knn_predict(data, point, k=3)
    print(f"point {point} -> {winner}")
    for d, label in neighbors:
        print(f"    neighbor {label:6s} at distance {d:8.2f}")
```

```text
point (19, 9) -> berry
    neighbor berry  at distance     1.41
    neighbor berry  at distance     1.41
    neighbor berry  at distance     3.00
point (320, 3) -> melon
    neighbor melon  at distance    10.00
    neighbor melon  at distance    20.00
    neighbor melon  at distance    30.02
point (100, 8) -> berry
    neighbor berry  at distance    75.01
    neighbor berry  at distance    78.01
    neighbor berry  at distance    80.00
```

The first two predictions are obviously right. The third is wrong-looking: a 100g fruit with sweetness 8 is probably not a berry, but distance-wise it is still closer to the berries than to the faraway melons. KNN has no notion of "far from everything" - it must pick a class no matter what.

### Choosing k

`k` is the only real hyperparameter, and it controls the bias-variance trade-off directly:

- **Small k (like 1)**: the decision boundary follows the training data tightly, including its noise. One mislabeled point creates a wrong island. Low bias, high variance.
- **Large k**: the vote is smoothed over many neighbors, so the boundary is calmer but blunter. With `k = len(data)`, every prediction is just the most common class overall. High bias, low variance.

```python-exec
def accuracy(data, k):
    correct = 0
    for i, (features, label) in enumerate(data):
        # leave-one-out: predict each point using all the others
        rest = data[:i] + data[i+1:]
        guess, _ = knn_predict(rest, features, k=k)
        if guess == label:
            correct += 1
    return correct / len(data)

for k in [1, 3, 5, 7, 9]:
    print(f"k = {k}: leave-one-out accuracy {accuracy(data, k) * 100:.0f}%")
```

```text
k = 1: leave-one-out accuracy 100%
k = 3: leave-one-out accuracy 100%
k = 5: leave-one-out accuracy 100%
k = 7: leave-one-out accuracy 100%
k = 9: leave-one-out accuracy 0%
```

Here is that same table as a chart:

```python-exec
ks = [1, 3, 5, 7, 9]
accs = [accuracy(data, k) * 100 for k in ks]

plt.plot(ks, accs, label="leave-one-out accuracy")
plt.title("Accuracy vs k")
plt.xlabel("k")
plt.ylabel("accuracy (%)")
plt.show()
```

Our toy data is perfectly separated, so any reasonable k works - but look at k = 9: each point's nine nearest "neighbors" now include all five points of the *other* class, so the majority is always wrong. On messy overlapping data you would see a gentler curve: accuracy rising as k grows past 1 (noise gets outvoted), peaking, then falling as k gets so large that the local neighborhood stops being local. Pick k at the peak - measured on validation data, as Chapter 8: Generalization & Regularization taught us, never on the test set. A common starting point is `k = sqrt(n)` rounded to an odd number to avoid ties in binary problems.

### Weighted votes: closer neighbors count more

Plain majority vote treats the 1st and the k-th neighbor identically. A natural fix: weight each vote by the inverse of its distance, so a very close neighbor outweighs several lukewarm ones.

```python-exec
def knn_predict_weighted(data, point, k=3):
    distances = []
    for features, label in data:
        d = euclidean(features, point)
        distances.append((d, label))
    distances.sort(key=lambda pair: pair[0])

    votes = {}
    for d, label in distances[:k]:
        weight = 1.0 / (d + 1e-9)   # avoid dividing by zero
        votes[label] = votes.get(label, 0.0) + weight
    return max(votes, key=votes.get)

print(knn_predict_weighted(data, (100, 8), k=3))
```

```text
berry
```

Distance weighting softens the dependence on k: with plain voting, adding a distant 7th neighbor can flip the result; with weights, that neighbor's vote is tiny anyway.

### The curse of dimensionality

KNN lives or dies by the idea that "close" means something. In high dimensions that idea quietly dies.

Imagine points spread uniformly in a unit hypercube. In 2D, the nearest few points are genuinely nearby. In 100D, the volume of the cube concentrates near its corners, and the distance between any two random points clusters around a large value - the nearest neighbor is barely closer than the farthest one. Distances stop being informative, so voting stops being reliable.

The practical consequences:

- KNN shines on small, low-dimensional datasets (a handful of meaningful features).
- With many features, select or extract the informative ones first.
- Storage and prediction cost also grow: predicting means comparing against every training point. Real systems use spatial indexes (KD-trees, ball trees) to speed this up; our brute-force loop is fine for hundreds of points.

### Feature scaling: the pitfall that gets everyone

Look back at our dataset. Weight varies by hundreds; sweetness by single digits. In the Euclidean distance, weight dominates completely:

```python-exec
# distance between two berries, and between a berry and a melon
print(euclidean((15, 9), (25, 7)))    # both berries
print(euclidean((15, 9), (300, 3)))   # different fruits
```

The sweetness term contributes almost nothing - a difference of 3 in sweetness adds 9 to the sum of squares, while the weight difference adds tens of thousands. If two features carried information but one had bigger units, KNN would silently ignore the smaller one. Worse, change the units from grams to kilograms (divide weight by 1000) and the *predictions change* - nothing about the fruit did.

The fix is the same scaling you met in Chapter 3: Preparing Data for Machine Learning. Standardize each feature with training-set statistics:

```python-exec
def fit_scaler(data):
    columns = list(zip(*[features for features, _ in data]))
    stats = []
    for col in columns:
        mean = sum(col) / len(col)
        var = sum((x - mean) ** 2 for x in col) / len(col)
        stats.append((mean, math.sqrt(var)))
    return stats

def scale(features, stats):
    return tuple((x - mean) / std
                 for x, (mean, std) in zip(features, stats))

stats = fit_scaler(data)
scaled_data = [(scale(f, stats), label) for f, label in data]

print("unscaled:", knn_predict(data, (150, 6), k=3)[0])
print("scaled:  ", knn_predict(scaled_data, scale((150, 6), stats), k=3)[0])
```

Both agree on this dataset, but only because it is well separated. On real data, forgetting to scale is the single most common reason KNN underperforms - so scale first, always, using statistics from the training split only.

### Strengths and weaknesses

- **Strengths**: zero training time, trivially understandable, naturally multi-class, and a strong baseline for small problems. It also doubles as a regressor: average the neighbors' values instead of voting.
- **Weaknesses**: slow predictions on big datasets, breaks down in high dimensions, sensitive to feature scales and irrelevant features, and stores all the data.

### The full file

Assemble the snippets into `knn.py` in this order: imports and distance function, dataset, `knn_predict` and its calls, the leave-one-out accuracy loop, weighted prediction, and the scaler. Run `python3 knn.py` and you should reproduce every number in this chapter. Then tinker: change k, add a mislabeled melon at `(20, 9)`, and watch which predictions flip.

### Practice checklist

- [ ] Explain in one sentence why KNN is called a "lazy" learning algorithm.
- [ ] Compute the Euclidean distance between `(1, 2)` and `(4, 6)` by hand and verify with the code.
- [ ] Run leave-one-out accuracy for every k from 1 to 9 and plot (or tabulate) the result; explain the trend.
- [ ] Predict `(40, 6)` with k=1 and k=5, both unweighted and weighted, and explain any difference.
- [ ] Standardize the dataset by hand for one point and confirm your numbers match `scale()`.
- [ ] Describe, in your own words, why distances become less meaningful as the number of features grows.
