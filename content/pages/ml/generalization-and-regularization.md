---
layout: tutorial
title: "Chapter 8 &ndash; Generalization & Regularization"
permalink: /courses/machine-learning/generalization-and-regularization/
difficulty: intermediate
author: Pankaj Doharey
summary: Diagnose underfitting and overfitting with learning curves, validation data, L1/L2 penalties, early stopping, and a disciplined model-selection loop.
theme: pylearning
previous_tutorial:
  title: "Chapter 7: Evaluating Classification Models"
  url: /courses/machine-learning/evaluating-classification-models/
next_tutorial:
  title: "Chapter 9: K-Nearest Neighbors"
  url: /courses/machine-learning/k-nearest-neighbors/
date: 2026-02-08
---

Chapter 7: Evaluating Classification Models gave us honest measurements on unseen data. Those measurements often reveal a frustrating pattern: training loss keeps improving while validation loss gets worse. The model is learning the training set more precisely and the real problem less accurately.

This chapter is about **generalization**: performing well on new examples drawn from the same real-world process. We will diagnose underfitting and overfitting, then control them with model complexity, L1/L2 regularization, early stopping, and better experiment discipline.

### Training is not the goal

A training algorithm minimizes loss on the examples it sees. We hope that this also discovers a pattern that transfers to examples it did not see, but the algorithm is not automatically required to do so.

Imagine fitting points with curves:

- A straight line may miss a genuine bend: **underfitting**.
- A 20th-degree polynomial may snake through every training point, including noise: **overfitting**.
- A moderately flexible curve can capture the trend without chasing every accident: good generalization.

Model complexity is not only the number of layers. It can come from:

- More features or polynomial terms.
- A deeper decision tree.
- More neurons and layers.
- Larger weights that create sharper decision boundaries.
- Training for more iterations.
- Weaker assumptions about what functions are allowed.

The best complexity is not the one with the lowest training loss. It is the one that performs best on validation data.

### The bias-variance mental model

Two kinds of error help organize the problem:

- **High bias** means the model's assumptions are too rigid. It misses the pattern in both training and validation data.
- **High variance** means the model reacts too strongly to the exact training sample. Training performance is strong, validation performance is much worse.

This gives a practical diagnosis:

| Training performance | Validation performance | Likely problem |
| --- | --- | --- |
| Poor | Poor | Underfitting / high bias |
| Strong | Much worse | Overfitting / high variance |
| Strong | Strong | Healthy fit |

These labels are clues, not proofs. Bad preprocessing, leakage, distribution shift, or a broken metric can create similar symptoms.

### Learning curves show where the gap appears

A **learning curve** records training and validation loss over epochs:

```python-exec
history = {
    "train_loss": [0.69, 0.51, 0.38, 0.27, 0.19, 0.13],
    "validation_loss": [0.70, 0.55, 0.46, 0.44, 0.49, 0.58],
}

for epoch, (train, validation) in enumerate(
    zip(history["train_loss"], history["validation_loss"]),
    start=1,
):
    gap = validation - train
    print(
        f"epoch {epoch}: train={train:.2f} "
        f"validation={validation:.2f} gap={gap:.2f}"
    )
```

Validation loss reaches its minimum at epoch 4, then rises while training loss keeps falling. Training longer makes the training metric prettier and the model worse.

The same learning curve as a picture:

```python-exec
epochs = list(range(1, len(history["train_loss"]) + 1))

plt.plot(epochs, history["train_loss"], label="training loss")
plt.plot(epochs, history["validation_loss"], label="validation loss")
plt.title("Training vs validation loss")
plt.xlabel("epoch")
plt.ylabel("loss")
plt.show()
```

The two curves part company right after epoch 4: the gap between them is the overfitting made visible.

Learning curves can also compare performance against the number of training examples:

- If validation performance keeps improving as data grows, collecting more representative data may help.
- If both curves plateau at poor performance, a more expressive model or better features may be needed.
- If a large train/validation gap remains, simplify or regularize the model.

### Regularization makes complexity expensive

Regularization adds a preference for simpler solutions. Instead of minimizing only data loss:

```text
total loss = data loss
```

we minimize:

```text
total loss = data loss + regularization strength * complexity penalty
```

The model may accept a slightly worse fit to training examples in exchange for a smoother, more reusable rule.

The regularization strength is commonly written as lambda (`lambda` is a Python keyword, so code often uses `l2` or `alpha`). It controls the tradeoff:

- `0` means no penalty.
- A small value gently discourages complexity.
- A very large value can shrink the model so much that it underfits.

Choose the value on validation data, never test data.

### L2 regularization shrinks weights smoothly

L2 adds the sum of squared weights:

```text
L2 penalty = w1^2 + w2^2 + ... + wk^2
```

For logistic regression, the regularized loss is:

```text
log loss + l2 * sum(weight^2)
```

Its gradient adds `2 * l2 * weight` to each weight update:

```python-exec
# Illustrative values - the full training loop comes below.
weights = [0.8, -0.5, 1.2]
data_gradient = [0.1, -0.2, 0.05]
learning_rate = 0.2
l2 = 0.1

for j in range(len(weights)):
    weights[j] -= learning_rate * (
        data_gradient[j] + 2 * l2 * weights[j]
    )

print("weights after one regularized step:", [round(w, 3) for w in weights])
```

That extra term pulls weights toward zero on every step. Large weights get a stronger pull. The bias is usually not regularized because shifting the overall baseline does not create the same kind of feature sensitivity.

L2 rarely makes weights exactly zero. It spreads influence across correlated features and is a strong default when many features each contribute a little.

### Why scaling and regularization belong together

Suppose one feature is measured in kilometers and another in millimeters. The same real-world influence requires very different numeric weights. An L2 penalty sees only the numeric weights, so it may punish one representation more than another.

Standardize numeric features using the training statistics from Chapter 3 before applying weight penalties. Then a one-unit weight has a more comparable meaning across features, and the regularizer treats them more fairly.

### L1 regularization can select features

L1 adds absolute weight values:

```text
L1 penalty = |w1| + |w2| + ... + |wk|
```

Its pressure is constant rather than proportional to weight size, so some weights can become exactly zero. That makes L1 useful when you suspect only a subset of features is necessary or when a sparse, easier-to-inspect model is valuable.

The rough distinction:

- **L2:** shrink all weights; stable default; keeps correlated features.
- **L1:** drive some weights to zero; can perform feature selection.

Real systems can combine them in **elastic net** regularization.

### Regularized logistic regression in pure Python

The following example extends Chapter 6's logistic regression to multiple standardized features and an L2 penalty:

```python-exec
import math

def sigmoid(z):
    if z >= 0:
        return 1 / (1 + math.exp(-z))
    ez = math.exp(z)
    return ez / (1 + ez)

def dot(a, b):
    return sum(x * y for x, y in zip(a, b))

def log_loss(X, y, weights, bias, l2=0.0):
    total = 0.0
    for features, actual in zip(X, y):
        probability = sigmoid(dot(weights, features) + bias)
        probability = min(max(probability, 1e-12), 1 - 1e-12)
        total += -(
            actual * math.log(probability) +
            (1 - actual) * math.log(1 - probability)
        )
    data_loss = total / len(X)
    penalty = l2 * sum(weight ** 2 for weight in weights)
    return data_loss + penalty

def train(X, y, l2=0.0, learning_rate=0.2, epochs=1000):
    weights = [0.0] * len(X[0])
    bias = 0.0

    for epoch in range(epochs):
        weight_gradients = [0.0] * len(weights)
        bias_gradient = 0.0

        for features, actual in zip(X, y):
            probability = sigmoid(dot(weights, features) + bias)
            error = probability - actual
            for j, value in enumerate(features):
                weight_gradients[j] += error * value
            bias_gradient += error

        n = len(X)
        for j in range(len(weights)):
            data_gradient = weight_gradients[j] / n
            weights[j] -= learning_rate * (
                data_gradient + 2 * l2 * weights[j]
            )
        bias -= learning_rate * bias_gradient / n

    return weights, bias

# Already-standardized features:
# [hours studied, practice tests completed, noisy feature]
X_train = [
    [-1.4, -1.2,  0.8],
    [-1.0, -0.8, -1.1],
    [-0.7, -0.3,  1.4],
    [-0.2, -0.5, -0.6],
    [ 0.1,  0.2,  1.0],
    [ 0.5,  0.4, -1.3],
    [ 0.8,  1.0,  0.7],
    [ 1.1,  0.8, -0.9],
    [ 1.3,  1.4,  1.2],
    [ 1.6,  1.1, -0.4],
]
y_train = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1]

for l2 in [0.0, 0.01, 0.1, 1.0]:
    weights, bias = train(X_train, y_train, l2=l2)
    loss = log_loss(X_train, y_train, weights, bias, l2=l2)
    print(
        f"l2={l2:>4}: weights="
        f"{[round(weight, 3) for weight in weights]} "
        f"loss={loss:.3f}"
    )
```

As `l2` grows, the weights become smaller. Training loss may rise because the objective is no longer "fit training data at any cost." To decide which value is best, compare validation loss or the validation metric selected in Chapter 7.

### Early stopping regularizes training time

Neural networks can overfit simply by training too long. **Early stopping** keeps the weights from the epoch with the best validation loss:

```python-exec
import copy

# Every model stores parameters differently, so these stand-ins
# simulate one: a single scalar "parameter" and a validation curve
# that improves until epoch 4, then gets worse (as above).
parameters = {"loss": 0.70}
validation_curve = [0.70, 0.55, 0.46, 0.44, 0.49, 0.58, 0.64]
epoch_counter = {"i": 0}

def train_one_epoch():
    parameters["loss"] = validation_curve[epoch_counter["i"]]

def evaluate_validation_loss():
    value = validation_curve[epoch_counter["i"]]
    epoch_counter["i"] += 1
    return value

def copy_parameters():
    return copy.deepcopy(parameters)

def restore_parameters(saved):
    parameters.update(saved)

best_validation_loss = float("inf")
best_parameters = None
epochs_without_improvement = 0
patience = 3

for epoch in range(100):
    train_one_epoch()
    validation_loss = evaluate_validation_loss()

    if validation_loss < best_validation_loss:
        best_validation_loss = validation_loss
        best_parameters = copy_parameters()
        epochs_without_improvement = 0
    else:
        epochs_without_improvement += 1

    if epochs_without_improvement >= patience:
        break

restore_parameters(best_parameters)
print(f"stopped at epoch {epoch + 1}, "
      f"best validation loss {best_validation_loss:.2f}")
print("restored parameters:", parameters)
```

The functions are simple stand-ins because every model stores parameters differently; these simulate one so the loop runs end to end. The pattern is what matters:

1. Evaluate validation loss after each epoch.
2. Save a copy when it improves.
3. Stop after a chosen patience period without improvement.
4. Restore the best copy, not merely the last copy.

The validation set guides *when* to stop; the test set remains untouched.

### Other ways to improve generalization

Regularization is one tool among several:

- **Collect more representative data.** Often the most reliable way to reduce variance.
- **Remove leakage and duplicates.** Apparent overperformance can be a split bug.
- **Simplify the model.** Fewer features, shallower trees, fewer neurons, or a lower polynomial degree.
- **Improve features.** A useful representation can reduce both bias and variance.
- **Data augmentation.** Create label-preserving variations, such as crops of an image.
- **Dropout.** During neural-network training, randomly omit activations so the network cannot depend too heavily on one path.
- **Ensembling.** Average several models whose errors differ.

Each choice must be evaluated on validation data with the same preprocessing and split.

### A disciplined model-selection loop

Use this sequence:

1. Choose the real-world metric and a simple baseline.
2. Create train, validation, and test sets.
3. Fit preprocessing on train only.
4. Train a baseline model.
5. Diagnose train versus validation performance.
6. Change one meaningful thing: complexity, regularization, features, or data.
7. Record the result on the same validation protocol.
8. Freeze the complete pipeline and threshold.
9. Evaluate once on test.
10. Report both performance and known limitations.

Keeping an experiment table prevents intuition from rewriting history:

| Experiment | Change | Train F1 | Validation F1 | Notes |
| --- | --- | ---: | ---: | --- |
| A | Baseline | 0.78 | 0.74 | Starting point |
| B | More features | 0.94 | 0.70 | Overfit |
| C | B + L2 | 0.88 | 0.79 | Better balance |

One change at a time makes the result explainable.

### Where this leads

We can now build a model, measure it honestly, and control its tendency to memorize. Chapters 9-14 tour the classic algorithms - KNN, decision trees, random forests, SVMs, naive Bayes, and k-means - and every one of them will lean on the discipline from this chapter. Then Chapter 15: Neural Networks from Scratch increases model complexity dramatically by stacking neurons into layers. The same rules remain in force: preprocess from training data, watch both training and validation loss, regularize when necessary, and trust the held-out test result rather than the training score.

### Practice checklist

- [ ] Given train loss 0.05 and validation loss 0.60, diagnose the likely problem and name two possible responses.
- [ ] Given both losses near 0.60, explain why adding regularization is unlikely to be the first fix.
- [ ] Run the L2 example and record how each weight changes as regularization grows.
- [ ] Add a fourth random feature and observe whether its unregularized weight becomes larger than expected.
- [ ] Split the student data into train and validation sets and choose `l2` using validation log loss.
- [ ] Explain why the test set must not choose the regularization strength.
- [ ] Implement early stopping in one of the earlier gradient-descent scripts.
- [ ] Draw learning curves for a healthy fit, underfit, and overfit.
- [ ] Explain why feature scaling affects the fairness of L1/L2 penalties.
- [ ] Create a one-row experiment log for every model change instead of replacing old results.
