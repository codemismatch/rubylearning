---
layout: tutorial
title: "Chapter 14 &ndash; K-Means Clustering"
permalink: /courses/machine-learning/k-means-clustering/
difficulty: intermediate
author: Neeraj Doharey
summary: Your first unsupervised algorithm - the assignment and update loop, inertia and the elbow method, initialization pitfalls, and k-means++ in pure Python.
theme: pylearning
previous_tutorial:
  title: "Chapter 13: Naive Bayes"
  url: /courses/machine-learning/naive-bayes/
next_tutorial:
  title: "Chapter 15: Neural Networks from Scratch"
  url: /courses/machine-learning/neural-networks-from-scratch/
date: 2026-02-24
---

Every algorithm so far has been **supervised**: each training example arrived with a label, and the model learned to predict it. K-means is your first **unsupervised** algorithm. The data has no labels at all - just points - and the goal is to discover structure: groups of points that huddle together. Clustering customers by behavior, grouping documents by topic, compressing image colors - all the same simple loop you will implement here in a few lines.

Everything here is pure Python. Save the snippets into `kmeans.py` and run with `python3 kmeans.py`.

### The problem, stated precisely

Given points and a number k, find k **centroids** (cluster centers) such that every point is close to its own centroid. "Close" is measured by total squared distance, called **inertia** or within-cluster sum of squares:

    inertia = sum over points of || point - its centroid ||^2

Minimizing inertia exactly is computationally hard (NP-hard, in fact), but there is a beautifully simple iterative scheme that gets a good answer fast.

### The assignment-update loop

K-means alternates two steps until nothing changes:

1. **Assignment**: give each point to its nearest centroid.
2. **Update**: move each centroid to the mean (average) of its points.

Each step can only lower inertia or leave it flat, so the loop always converges - though, as we will see, possibly to a mediocre answer.

#> mermaid: caption="Figure 1: K-means turns unlabeled points into clusters around centroids"
graph LR
  A[unlabeled points] --> B[pick k initial centroids]
  B --> C[assign points to nearest centroid]
  C --> D[move centroids to cluster means]
  D --> C
  D --> E[converged clusters]
#!

### A 2D dataset with obvious groups

Three blobs of points - you could circle them by eye, which makes it perfect for checking the algorithm.

```python-exec
import math
import random

random.seed(1)

points = [
    (1, 1), (2, 1), (1, 2), (2, 2), (1.5, 1.5),      # bottom-left blob
    (8, 8), (9, 8), (8, 9), (9, 9), (8.5, 8.5),      # top-right blob
    (1, 8), (2, 9), (1, 9), (2, 8), (1.5, 8.5),      # top-left blob
]
```

### K-means from scratch

```python-exec
def euclidean_sq(p, q):
    return sum((a - b) ** 2 for a, b in zip(p, q))

def assign(points, centroids):
    clusters = [[] for _ in centroids]
    for p in points:
        nearest = min(range(len(centroids)),
                      key=lambda i: euclidean_sq(p, centroids[i]))
        clusters[nearest].append(p)
    return clusters

def update(clusters, centroids):
    new = []
    for i, cluster in enumerate(clusters):
        if cluster:   # empty cluster: keep the old centroid
            dim = len(cluster[0])
            new.append(tuple(sum(p[d] for p in cluster) / len(cluster)
                             for d in range(dim)))
        else:
            new.append(centroids[i])
    return new

def kmeans(points, k, epochs=20, verbose=False):
    centroids = random.sample(points, k)          # naive init - more below
    for epoch in range(epochs):
        clusters = assign(points, centroids)
        new_centroids = update(clusters, centroids)
        if new_centroids == centroids:
            if verbose:
                print(f"converged after {epoch + 1} epochs")
            break
        centroids = new_centroids
    return centroids, assign(points, centroids)

centroids, clusters = kmeans(points, k=3, verbose=True)
for i, (c, cluster) in enumerate(zip(centroids, clusters)):
    nice = tuple(round(v, 2) for v in c)
    print(f"cluster {i}: centroid {nice}, {len(cluster)} points -> {cluster}")
```

```text
converged after 2 epochs
cluster 0: centroid (1.5, 1.5), 5 points -> [(1, 1), (2, 1), (1, 2), (2, 2), (1.5, 1.5)]
cluster 1: centroid (8.5, 8.5), 5 points -> [(8, 8), (9, 8), (8, 9), (9, 9), (8.5, 8.5)]
cluster 2: centroid (1.5, 8.5), 5 points -> [(1, 8), (2, 9), (1, 9), (2, 8), (1.5, 8.5)]
```

Three blobs found, centroids parked exactly on the blob means. That is the whole algorithm - assignment, update, repeat.

### Inertia and choosing k with the elbow method

Unlike classification, there are no labels to score against, so "which k is right?" needs a different tool. Plot inertia against k: inertia always falls as k grows (with k equal to the number of points it is zero), but the *rate* of improvement drops sharply once every true cluster has its own centroid. The bend is the **elbow**.

```python-exec
def inertia(points, centroids):
    total = 0.0
    for p in points:
        nearest = min(euclidean_sq(p, c) for c in centroids)
        total += nearest
    return total

for k in [1, 2, 3, 4, 5, 6]:
    best = min(inertia(points, kmeans(points, k)[0]) for _ in range(10))
    print(f"k = {k}: inertia {best:7.2f}")
```

```text
k = 1: inertia  332.67
k = 2: inertia  128.50
k = 3: inertia    6.00
k = 4: inertia    5.17
k = 5: inertia    4.54
k = 6: inertia    3.71
```

The curve falls off a cliff at k = 3 - from 128.5 to 6 - and then barely moves. The elbow says 3, which matches the blobs we planted. (Notice we run each k ten times and keep the best; the reason why is next.)

### The initialization pitfall

`random.sample(points, k)` can pick two initial centroids inside the same blob and none in another. K-means then splits one blob and merges two others - a **local optimum** the loop cannot escape, because assignment and update can only refine, never teleport a centroid across empty space.

Watch it happen with an unlucky seed:

```python-exec
random.seed(11)
centroids_bad, clusters_bad = kmeans(points, k=3)
print("inertia with unlucky init:", round(inertia(points, centroids_bad), 2))
for cluster in clusters_bad:
    print(" ", len(cluster), "points:", cluster[:3], "...")
```

```text
inertia with unlucky init: 127.67
  3 points: [(8, 8), (8, 9), (8.5, 8.5)] ...
  10 points: [(1, 1), (2, 1), (1, 2)] ...
  2 points: [(9, 8), (9, 9)] ...
```

There it is: two initial centroids landed in the top-right blob and none in the top-left, so the algorithm split one blob and merged the other two - inertia 127.67 against the optimum of 6.0, a 20x worse answer it cannot escape. Two standard defenses:

1. **Restarts**: run k-means 10-25 times with different random starts, keep the lowest-inertia result (as we did in the elbow loop). Cheap and effective.
2. **k-means++ initialization**: pick initial centroids that are deliberately spread out.

### k-means++: smarter starting points

The idea in plain text:

```text
pick the first centroid uniformly at random
repeat until k centroids:
    for each point, compute D = distance to its nearest chosen centroid
    pick the next centroid at random, with probability proportional to D^2
```

Far-away points are likely picks, so the starting centroids land in different blobs with high probability.

```python-exec
def kmeanspp(points, k):
    centroids = [random.choice(points)]
    while len(centroids) < k:
        weights = [min(euclidean_sq(p, c) for c in centroids) for p in points]
        total = sum(weights)
        r = random.random() * total
        cumulative = 0.0
        for p, w in zip(points, weights):
            cumulative += w
            if cumulative >= r and w > 0:   # w == 0 means already chosen
                centroids.append(p)
                break
    return centroids

def kmeans_plus(points, k, epochs=20):
    centroids = kmeanspp(points, k)
    for _ in range(epochs):
        clusters = assign(points, centroids)
        new_centroids = update(clusters, centroids)
        if new_centroids == centroids:
            break
        centroids = new_centroids
    return centroids, assign(points, centroids)
```

How much does the smarter start help? Run both initializers a hundred times each and count how often the algorithm finds the best clustering (inertia 6.0):

```python-exec
naive_ok = plusplus_ok = 0
for _ in range(100):
    c1, _ = kmeans(points, 3)
    if abs(inertia(points, c1) - 6.0) < 1e-9:
        naive_ok += 1
    c2, _ = kmeans_plus(points, 3)
    if abs(inertia(points, c2) - 6.0) < 1e-9:
        plusplus_ok += 1

print(f"random init found the best clustering {naive_ok}/100 times")
print(f"k-means++ init found the best clustering {plusplus_ok}/100 times")
```

```text
random init found the best clustering 71/100 times
k-means++ init found the best clustering 98/100 times
```

Random restarts alone leave a one-in-three chance of a bad answer on any single run; k-means++ cuts that to a few percent (it can still occasionally pick two centroids in one blob - nothing is free). Combine both defenses and failure becomes vanishingly rare. In libraries, `k-means++` is the default initializer - now you know what the `++` buys.

### Where clustering is used, and its limits

- **Customer segmentation**: group shoppers by purchase behavior and treat each segment differently.
- **Document grouping**: cluster articles by word counts before any human labels topics.
- **Color quantization**: cluster an image's pixels in RGB space with k = 16, replace each pixel by its centroid - instant palette compression.
- **Anomaly detection pre-step**: points far from every centroid are worth a second look.

Limits to respect: k-means assumes clusters are round and similarly sized (it carves space into Voronoi cells), needs k up front, is sensitive to feature scales just like Chapter 9: K-Nearest Neighbors (scale first!), and assigns every point to *some* cluster - there is no "does not belong" option. Odd-shaped or interleaved clusters call for density-based methods like DBSCAN.

### The full file

Assemble the snippets into `kmeans.py` in this order: imports and seed, points, `euclidean_sq`/`assign`/`update`/`kmeans`, the inertia function and elbow loop, the unlucky-init demo, and `kmeanspp`/`kmeans_plus`. Run `python3 kmeans.py` and reproduce every number. Then tinker: move the top-left blob closer to the bottom-left one and watch the elbow blur - real data rarely bends as cleanly as this toy.

### Practice checklist

- [ ] Explain in one sentence why the assignment-update loop must eventually stop.
- [ ] Compute the new centroid of the cluster `[(0, 0), (2, 0), (1, 3)]` by hand and verify with `update`.
- [ ] Explain why inertia can never increase from one epoch to the next.
- [ ] Run the elbow loop up to k = 8 and describe the shape of the curve in your own words.
- [ ] Describe a dataset where k-means with the "right" k still fails, and sketch it.
- [ ] Explain why k-means++ weights candidates by squared distance rather than by raw distance.
