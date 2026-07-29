---
layout: tutorial
title: "Chapter 11 &ndash; Random Forests"
permalink: /courses/machine-learning/random-forests/
difficulty: intermediate
author: Pankaj Doharey
summary: Combine many decision trees with bootstrap sampling and random feature subsets, vote across the forest, and understand why the crowd beats the single tree.
theme: pylearning
previous_tutorial:
  title: "Chapter 10: Decision Trees"
  url: /courses/machine-learning/decision-trees/
next_tutorial:
  title: "Chapter 12: Support Vector Machines"
  url: /courses/machine-learning/support-vector-machines/
date: 2026-02-17
---

In Chapter 10: Decision Trees we ended with a problem: a single tree is unstable. Move one training row and the top split flips, reshaping the whole tree. A random forest turns that weakness into a strength. Train many trees, each deliberately made a little different, and let them vote. The errors of individual trees cancel out; the shared pattern survives. Random forests were the default "just works" algorithm for tabular data for over a decade, and they remain an excellent baseline.

Everything here is pure Python, reusing a simplified tree from the last chapter. Save the snippets into `forest.py` and run with `python3 forest.py`.

### Two sources of randomness

A forest is not just "many copies of the same tree" - identical trees would vote identically and gain nothing. Each tree is trained differently in two ways:

1. **Bagging (bootstrap aggregating)**: each tree gets its own training set, sampled *with replacement* from the original data. A bootstrap sample of n rows leaves out about 37% of the rows and duplicates others, so every tree sees a slightly different world.
2. **Random feature subsets**: at each split, the tree may only consider a random subset of the features (commonly `sqrt(n_features)` for classification). The classic win: if one feature dominates, every bagged tree would still lead with it and stay correlated; forcing random subsets makes the trees explore genuinely different questions.

#> mermaid: caption="Figure 1: Many differently trained trees vote on each new example"
graph LR
  A[training data] --> B[bootstrap sample 1]
  A --> C[bootstrap sample 2]
  A --> D[bootstrap sample 3]
  B --> E[tree 1]
  C --> F[tree 2]
  D --> G[tree 3]
  E --> H[majority vote]
  F --> H
  G --> H
  H --> I[final prediction]
#!

### A simplified tree with feature subsampling

We reuse the entropy-based tree from Chapter 10: Decision Trees with one change: `best_split` only considers `max_features` randomly chosen features per split. To keep this chapter short the tree is trimmed to the essentials - numeric thresholds and categorical equality.

```python-exec
import math
import random
from collections import Counter

random.seed(7)   # reproducible runs

def entropy(labels):
    n = len(labels)
    return -sum((c / n) * math.log2(c / n)
                for c in Counter(labels).values())

def split_rows(rows, fi, threshold):
    left, right = [], []
    for row in rows:
        v = row[fi]
        ok = (v == threshold) if isinstance(v, str) else (v <= threshold)
        (left if ok else right).append(row)
    return left, right

def best_split(rows, feature_indices):
    best_gain, best_fi, best_t = 1e-9, None, None
    parent = entropy([row[-1] for row in rows])
    for fi in feature_indices:
        values = sorted(set(row[fi] for row in rows))
        if isinstance(values[0], str):
            candidates = values
        else:
            candidates = [(a + b) / 2 for a, b in zip(values, values[1:])]
        for t in candidates:
            left, right = split_rows(rows, fi, t)
            if not left or not right:
                continue
            n = len(rows)
            gain = parent - (len(left) / n) * entropy([r[-1] for r in left]) \
                          - (len(right) / n) * entropy([r[-1] for r in right])
            if gain > best_gain:
                best_gain, best_fi, best_t = gain, fi, t
    return best_fi, best_t

def build_tree(rows, depth, max_depth, max_features, n_features):
    labels = [row[-1] for row in rows]
    if len(set(labels)) == 1 or depth >= max_depth:
        return {"leaf": Counter(labels).most_common(1)[0][0]}
    subset = random.sample(range(n_features),
                           min(max_features, n_features))
    fi, t = best_split(rows, subset)
    if fi is None:
        return {"leaf": Counter(labels).most_common(1)[0][0]}
    left, right = split_rows(rows, fi, t)
    return {"fi": fi, "t": t,
            "yes": build_tree(left, depth + 1, max_depth, max_features, n_features),
            "no":  build_tree(right, depth + 1, max_depth, max_features, n_features)}

def predict_tree(tree, row):
    while "leaf" not in tree:
        v = row[tree["fi"]]
        ok = (v == tree["t"]) if isinstance(v, str) else (v <= tree["t"])
        tree = tree["yes"] if ok else tree["no"]
    return tree["leaf"]
```

### The dataset: fruit, round two

Back to the fruit world from Chapter 9: K-Nearest Neighbors, but with three features now - weight, sweetness, and crunchiness - and a bit of noise so single trees can stumble.

```python-exec
# (weight_g, sweetness, crunch), label
data = [
    ((15, 9, 8), "berry"), ((20, 8, 9), "berry"), ((18, 10, 7), "berry"),
    ((25, 7, 8), "berry"), ((22, 9, 6), "berry"),  ((12, 8, 9), "berry"),
    ((300, 3, 2), "melon"), ((350, 4, 3), "melon"), ((280, 2, 1), "melon"),
    ((400, 5, 2), "melon"), ((330, 3, 3), "melon"), ((310, 2, 2), "melon"),
]
rows = [f + (label,) for f, label in data]   # flatten for the tree code
```

### Training the forest

Two small functions: one draws a bootstrap sample, one trains the whole ensemble.

```python-exec
def bootstrap(rows):
    return [random.choice(rows) for _ in range(len(rows))]

def train_forest(rows, n_trees=25, max_depth=6, max_features=2):
    n_features = len(rows[0]) - 1
    return [build_tree(bootstrap(rows), 0, max_depth, max_features, n_features)
            for _ in range(n_trees)]

def predict_forest(forest, features):
    votes = Counter(predict_tree(tree, features) for tree in forest)
    return votes.most_common(1)[0][0], votes

forest = train_forest(rows)
for point in [(19, 9, 8), (320, 3, 2), (60, 6, 5)]:
    guess, votes = predict_forest(forest, point)
    print(f"{point} -> {guess}  (votes: {dict(votes)})")
```



Notice the third line: the vote tally itself is a free confidence estimate. 25-0 is a sure thing; 15-10 is "probably, but check". Single trees cannot tell you that.

### Forest vs single tree

The whole point is stability, so let us measure it. To make the task interesting we first corrupt 15% of the training labels with random noise, then train one tree and one forest on 90% of the data, evaluate on the held-out 10%, repeat many times, and average.

```python-exec
def flip_labels(train, noise=0.15):
    noisy = []
    for row in train:
        if random.random() < noise:
            flipped = "melon" if row[-1] == "berry" else "berry"
            noisy.append(row[:-1] + (flipped,))
        else:
            noisy.append(row)
    return noisy

def accuracy_single_vs_forest(trials=40):
    single_total, forest_total = 0.0, 0.0
    n = 0
    for _ in range(trials):
        shuffled = rows[:]
        random.shuffle(shuffled)
        cut = max(1, len(shuffled) // 10)
        test, train = shuffled[:cut], flip_labels(shuffled[cut:])
        tree = build_tree(bootstrap(train), 0, 6, 3, 3)
        forest = train_forest(train, n_trees=25)
        for row in test:
            single_total += (predict_tree(tree, row[:-1]) == row[-1])
            forest_total += (predict_forest(forest, row[:-1])[0] == row[-1])
            n += 1
    return single_total / n, forest_total / n

s, f = accuracy_single_vs_forest()
print(f"single tree: {s * 100:.1f}%   forest: {f * 100:.1f}%")
```



Here is that result as a chart:

```python-exec
plt.bar(["single tree", "forest"], [s * 100, f * 100])
plt.title("Held-out accuracy: one tree vs the forest")
plt.ylabel("accuracy (%)")
plt.show()
```

The forest beats the single tree by a clear margin, and its variance across runs is much smaller. Why it works, in one sentence: averaging many *decorrelated* overfitters cancels the idiosyncratic errors (bagging reduces variance) while random feature subsets keep the trees from all making the same mistake. A single deep tree chases the flipped labels; in a forest of 25, each noisy label poisons only a few bootstrap samples and gets outvoted.

### Out-of-bag evaluation: a free validation set

Remember that each bootstrap sample leaves out about 37% of the rows. Those left-out rows are called **out-of-bag (OOB)** for that tree. So every training row is OOB for roughly a third of the forest - and you can score each row using only the trees that never saw it. The result, the OOB error, is an honest generalization estimate without a separate validation split.

```python-exec
def oob_accuracy(rows, n_trees=25):
    n_features = len(rows[0]) - 1
    correct = total = 0
    for _ in range(n_trees):
        sample = bootstrap(rows)
        seen = set(map(id, sample))
        tree = build_tree(sample, 0, 6, 2, n_features)
        for row in rows:
            if id(row) not in seen:   # this tree never trained on this row
                if predict_tree(tree, row[:-1]) == row[-1]:
                    correct += 1
                total += 1
    return correct / total

print(f"OOB accuracy: {oob_accuracy(rows) * 100:.1f}%")
```



(The `id()` trick works here because every row is a distinct object; in real code you would track indices instead.) On large real datasets OOB error tracks test error closely - a genuine convenience when data is scarce.

### Strengths and weaknesses

- **Strengths**: strong accuracy on tabular data out of the box, resistant to overfitting as you add trees, free confidence via vote fractions and OOB error, handles mixed feature types, few knobs to tune.
- **Weaknesses**: the readable flowchart is gone (a forest is a black box), memory and prediction cost grow with the number of trees, and performance on very high-dimensional sparse data (like raw text) is mediocre.

Feature importance is the partial antidote to the black-box complaint: total up how much each feature contributed to information gain across all trees, and you get a ranking of what the forest actually relied on.

### The full file

Assemble the snippets into `forest.py` in this order: imports and seed, entropy/split/build/predict functions, dataset, forest training and prediction, the comparison experiment, and OOB evaluation. Run `python3 forest.py` and reproduce every number. Then tinker: set `max_features=3` (no randomness at splits) and watch OOB accuracy dip; set `n_trees=3` and watch vote tallies get noisy.

### Practice checklist

- [ ] Explain in one sentence why bagging identical trees (no random feature subsets) helps less than a true random forest.
- [ ] Compute by hand the probability that a given row is *not* picked in one bootstrap draw, and argue why about 37% of rows end up out-of-bag.
- [ ] Run the forest with `n_trees` of 1, 5, 25, and 100; describe how accuracy and run time change.
- [ ] Explain what a 13-12 vote tally tells you that a bare "berry" prediction hides.
- [ ] Describe, in your own words, why OOB accuracy is an honest estimate even though no explicit test set was held out.
- [ ] Predict what happens to forest accuracy if you duplicate every training row ten times, then check by running it.
