---
layout: tutorial
title: "Chapter 10 &ndash; Decision Trees"
permalink: /courses/machine-learning/decision-trees/
difficulty: intermediate
author: Neeraj Doharey
summary: Learn splits with entropy and information gain, build a decision tree classifier recursively from scratch, and see why depth control prevents overfitting.
theme: pylearning
previous_tutorial:
  title: "Chapter 9: K-Nearest Neighbors"
  url: /courses/machine-learning/k-nearest-neighbors/
next_tutorial:
  title: "Chapter 11: Random Forests"
  url: /courses/machine-learning/random-forests/
date: 2026-02-14
---

In Chapter 9: K-Nearest Neighbors the model was the data itself. A decision tree is the opposite extreme: it compresses the training set into a flowchart of yes/no questions. Should the bank approve this loan? Ask a handful of questions in sequence - income above 50k? employed for over a year? - and arrive at an answer. Trees are fast, need no feature scaling, and you can read them out loud, which is why they underpin both business rule engines and the random forests we build in Chapter 11: Random Forests.

Everything here is pure Python. Save the snippets into one file, say `tree.py`, and run with `python3 tree.py`.

### What a tree looks like

A tiny dataset: deciding whether to play tennis based on the weather. Each row is (outlook, temperature in C, windy) plus the decision.

```python-exec
# (outlook, temp_c, windy), decision
data = [
    ("sunny",    30, False, "no"),
    ("sunny",    32, True,  "no"),
    ("overcast", 28, False, "yes"),
    ("rain",     18, False, "yes"),
    ("rain",     12, True,  "no"),
    ("rain",     20, False, "yes"),
    ("overcast", 15, True,  "yes"),
    ("sunny",    22, False, "yes"),
    ("sunny",    26, True,  "no"),
    ("rain",     24, False, "yes"),
]
```

A decision tree learning algorithm asks: which single question best splits this data into purer groups? Maybe "is the temperature at most 29 degrees?" cuts off the scorching no-days in one shot. Then it recurses on each group until the groups are pure or we tell it to stop.

#> mermaid: caption="Figure 1: A small decision tree for the tennis data"
graph TD
  A[is temp at most 29] -->|yes| B[is windy]
  A -->|no| C[play no]
  B -->|no| D[play yes]
  B -->|yes| E[is outlook overcast]
  E -->|yes| F[play yes]
  E -->|no| G[play no]
#!

### Impurity: entropy and gini

To pick the best question we need a number that says how "mixed" a group of labels is. Two standard measures exist.

**Entropy** comes from information theory. For a group with class proportions p1, p2, ... :

    entropy = - sum( p * log2(p) )

Pure group (all one class): entropy 0. A 50/50 binary mix: entropy 1, the maximum.

```python-exec
import math
from collections import Counter

def entropy(labels):
    n = len(labels)
    counts = Counter(labels)
    total = 0.0
    for c in counts.values():
        p = c / n
        total -= p * math.log2(p)
    return total

labels = [row[3] for row in data]
print("entropy of full set:", round(entropy(labels), 3))
print("entropy of pure set:", entropy(["yes", "yes", "yes"]))
```



**Gini impurity** is the other classic: the probability that two randomly drawn labels disagree.

    gini = 1 - sum( p^2 )

```python-exec
def gini(labels):
    n = len(labels)
    counts = Counter(labels)
    return 1.0 - sum((c / n) ** 2 for c in counts.values())
```

Both reach zero for pure groups and their maxima for even mixes, and in practice they rank splits almost identically. Entropy is the traditional choice (the ID3/C4.5 family); gini is slightly cheaper to compute (CART). We will use entropy below - swapping in `gini` is a one-line change.

### Information gain: scoring a split

A split divides a group into children. Its quality is the parent's impurity minus the weighted average impurity of the children. With entropy, that difference is called **information gain**:

    gain = entropy(parent) - sum( (size(child)/size(parent)) * entropy(child) )

For numeric features like temperature we test thresholds: sort the values, try the midpoint between each adjacent pair, keep the best.

```python-exec
def split_labels(rows, feature_index, threshold=None):
    left, right = [], []
    for row in rows:
        value = row[feature_index]
        if threshold is None:
            (left if value else right).append(row)          # boolean feature
        elif isinstance(value, str):
            (left if value == threshold else right).append(row)  # categorical
        else:
            (left if value <= threshold else right).append(row)  # numeric
    return left, right

def information_gain(rows, feature_index, threshold=None):
    parent = entropy([row[3] for row in rows])
    left, right = split_labels(rows, feature_index, threshold)
    if not left or not right:
        return 0.0
    n = len(rows)
    child = (len(left) / n) * entropy([r[3] for r in left]) \
          + (len(right) / n) * entropy([r[3] for r in right])
    return parent - child

# categorical: outlook == "overcast"?
print("gain outlook=overcast:", round(information_gain(data, 0, "overcast"), 3))
# numeric: temp <= 21?
print("gain temp<=21:        ", round(information_gain(data, 1, 21), 3))
# boolean: windy?
print("gain windy:           ", round(information_gain(data, 2), 3))
# numeric: trying every temperature threshold finds the best one
print("gain temp<=29:        ", round(information_gain(data, 1, 29), 3))
```



"Is the temperature at most 29?" wins - it carves off the two scorching no-days into a pure group, exactly the root split in Figure 1. Note that "temp <= 21" is a poor question while "temp <= 29" is the best one: for numeric features the threshold matters as much as the feature, which is why the builder below searches every midpoint instead of guessing.

Those same gains as a picture - every candidate split the builder would consider, sorted best first:

```python-exec
candidates = [("windy", 2, None)]
candidates += [("outlook==" + v, 0, v) for v in sorted(set(r[0] for r in data))]
ordered = sorted(set(r[1] for r in data))
candidates += [("temp<=" + str((a + b) / 2), 1, (a + b) / 2)
               for a, b in zip(ordered, ordered[1:])]
scored = sorted(((information_gain(data, fi, t), name) for name, fi, t in candidates),
                reverse=True)
plt.bar([name for g, name in scored], [g for g, name in scored])
plt.title("Information gain per candidate split")
plt.xlabel("split question")
plt.ylabel("information gain")
plt.show()
```

### Building the tree recursively

The algorithm, in plain text:



And in Python. A node is a dict; a leaf just stores a label.

```python-exec
def best_split(rows):
    best = (0.0, None, None)   # gain, feature_index, threshold
    n_features = len(rows[0]) - 1
    for fi in range(n_features):
        values = [row[fi] for row in rows]
        if isinstance(values[0], bool):
            candidates = [None]
        elif isinstance(values[0], str):
            candidates = sorted(set(values))
        else:
            ordered = sorted(set(values))
            candidates = [(a + b) / 2 for a, b in zip(ordered, ordered[1:])]
        for t in candidates:
            gain = information_gain(rows, fi, t)
            if gain > best[0]:
                best = (gain, fi, t)
    return best[1], best[2]

def majority_label(rows):
    return Counter(row[3] for row in rows).most_common(1)[0][0]

def build_tree(rows, depth=0, max_depth=5):
    labels = [row[3] for row in rows]
    if len(set(labels)) == 1:
        return {"leaf": labels[0]}
    if depth >= max_depth:
        return {"leaf": majority_label(rows)}
    fi, t = best_split(rows)
    if fi is None:
        return {"leaf": majority_label(rows)}
    left, right = split_labels(rows, fi, t)
    return {"feature": fi, "threshold": t,
            "yes": build_tree(left, depth + 1, max_depth),
            "no":  build_tree(right, depth + 1, max_depth)}

tree = build_tree(data)
```

Predicting is just walking from the root to a leaf:

```python-exec
def predict(tree, row):
    while "leaf" not in tree:
        value = row[tree["feature"]]
        t = tree["threshold"]
        if t is None:
            tree = tree["yes"] if value else tree["no"]
        elif isinstance(value, str):
            tree = tree["yes"] if value == t else tree["no"]
        else:
            tree = tree["yes"] if value <= t else tree["no"]
    return tree["leaf"]

correct = sum(1 for row in data if predict(tree, row) == row[3])
print(f"training accuracy: {correct}/{len(data)}")
print("new day (sunny, 25, no wind):", predict(tree, ("sunny", 25, False, None)))
```



A mild, calm day gets a "yes" - trace the path by hand: temp 25 is at most 29, wind is calm, leaf says yes. You can also print the tree as text to inspect what it learned - highly recommended as a debugging habit:

```python-exec
NAMES = ["outlook", "temp", "windy"]

def show(tree, indent=""):
    if "leaf" in tree:
        print(indent + tree["leaf"])
        return
    fi, t = tree["feature"], tree["threshold"]
    if t is None:
        q = f"{NAMES[fi]} is true?"
    elif isinstance(t, str):
        q = f"{NAMES[fi]} == {t}?"
    else:
        q = f"{NAMES[fi]} <= {t}?"
    print(indent + q)
    print(indent + "|-- yes:")
    show(tree["yes"], indent + "|   ")
    print(indent + "`-- no:")
    show(tree["no"], indent + "    ")

show(tree)
```



Compare with Figure 1 - same tree, drawn two ways. Hot days (temp above 29) are an immediate no; mild days are yes unless it is windy and not overcast.

### Overfitting and depth

Unrestricted, a tree can always reach 100% training accuracy - worst case it memorizes every row into its own leaf. That is the overfitting pattern from Chapter 8: Generalization & Regularization in its purest form: zero training error, poor performance on new data.

Depth is the main knob. Try limiting `max_depth` and watch what happens on data with a noisy point:

```python-exec
noisy = data + [("overcast", 27, False, "no")]   # contradicts the pattern
for d in [1, 2, 3, 10]:
    t = build_tree(noisy, max_depth=d)
    correct = sum(1 for row in noisy if predict(t, row) == row[3])
    print(f"max_depth {d:2d}: training accuracy {correct}/{len(noisy)}")
```



The deep tree contorts itself to fit one contradictory example. A depth of 1 or 2 misclassifies the noisy row but captures the real pattern - exactly what we want. Choose `max_depth` (or a minimum leaf size) on validation data, not by gut feeling.

### Pruning, in one paragraph

The alternative to stopping early is growing the full tree and then *pruning*: repeatedly collapse a split whose removal does not hurt validation accuracy. Cost-complexity pruning (used by CART) formalizes this by penalizing trees with many leaves, trading a little training accuracy for a lot of simplicity. Intuitively: grow generously, then cut back the branches that only model noise.

### Strengths and weaknesses

- **Strengths**: human-readable decisions, handles numeric, categorical, and boolean features natively, needs no scaling, and predicts in microseconds.
- **Weaknesses**: unstable - tiny changes in data can flip the top split and reshape the whole tree; axis-aligned splits struggle with diagonal boundaries; deep unpruned trees overfit badly.

The instability is real, but it is also the seed of a fix: if one tree is a shaky expert, average many different trees. That is Chapter 11: Random Forests.

### The full file

Assemble the snippets into `tree.py` in this order: imports, dataset, entropy/gini, split and gain functions, `best_split`/`build_tree`, `predict`, `show`, and the depth experiment. Run `python3 tree.py` and reproduce every number. Then tinker: flip one label, raise `max_depth`, and watch the printed tree grow a branch that exists only to accommodate your edit.

### Practice checklist

- [ ] Compute the entropy of a group with 3 yes and 1 no by hand and verify with the function.
- [ ] Write the gini impurity of a 50/50 group from memory and check it equals 0.5.
- [ ] Explain in one sentence why information gain cannot be negative for a split the algorithm accepts.
- [ ] Add a fourth feature (humidity, numeric) with made-up values and see where it lands in the printed tree.
- [ ] Set `max_depth=1` and describe which single question the tree considers most important.
- [ ] In your own words, why does a very deep tree usually fail on new data even when it is perfect on training data?
