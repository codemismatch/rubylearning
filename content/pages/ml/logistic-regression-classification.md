---
layout: tutorial
title: "Chapter 6 &ndash; Logistic Regression & Classification"
permalink: /courses/machine-learning/logistic-regression-classification/
difficulty: intermediate
author: Pankaj Doharey
summary: Turn a linear score into a probability with the sigmoid function, train it with log loss and gradient descent, and make pass/fail predictions.
theme: pylearning
previous_tutorial:
  title: "Chapter 5: Gradient Descent"
  url: /courses/machine-learning/gradient-descent/
next_tutorial:
  title: "Chapter 7: Evaluating Classification Models"
  url: /courses/machine-learning/evaluating-classification-models/
date: 2026-02-03
---

In Chapter 5: Gradient Descent we trained a linear regression model by rolling downhill on a mean squared error surface. That model predicted a number - house prices, temperatures, exam scores. But a huge class of real problems is not about predicting a number. It is about predicting a *category*: spam or not spam, tumor benign or malignant, student passes or fails. This chapter builds the workhorse for those problems from scratch: logistic regression.

Everything here is pure Python. No sklearn, no numpy - just lists, `math`, and the gradient descent loop you already know.

### Regression vs classification

Linear regression answers "how much?" Classification answers "which one?"

- Regression: predict a continuous value, like a final exam score between 0 and 100.
- Binary classification: predict one of two classes, like pass (1) or fail (0).

You might be tempted to just fit a line to 0/1 labels and round the output. Two problems show up immediately:

1. A line happily outputs -3 or 17, which are meaningless as a class or a probability.
2. Squared error punishes the model in strange ways for 0/1 targets, giving a badly shaped loss surface.

The fix is to keep the linear machinery but squeeze its output through a function that always lands between 0 and 1, then interpret that number as a probability.

### The sigmoid function

The sigmoid (also called the logistic function) maps any real number z to the range (0, 1):

    sigmoid(z) = 1 / (1 + e^(-z))

Properties worth memorizing:

- `sigmoid(0) = 0.5`
- Large positive z gives a value close to 1.
- Large negative z gives a value close to 0.
- It is smooth and differentiable everywhere, which gradient descent loves.

Here it is in Python. Save every snippet in this chapter into one file, say `logistic.py`, and run it with `python3 logistic.py` - each example is copy-paste runnable.

```python-exec
import math

def sigmoid(z):
    return 1.0 / (1.0 + math.exp(-z))

for z in [-6, -2, 0, 2, 6]:
    print(z, round(sigmoid(z), 4))
```

Output:



### From score to decision

The full pipeline for one prediction looks like this:

#> mermaid: caption="Figure 1: From study hours to a pass/fail decision"
graph LR
  A[study hours x] --> B[linear score z = w*x + b]
  B --> C[sigmoid]
  C --> D[probability p]
  D --> E[threshold 0.5]
  E --> F[pass or fail]
#!

We compute a linear score `z = w * x + b` exactly like linear regression, push it through the sigmoid to get a probability `p`, and then apply a decision boundary: if `p >= 0.5` predict pass (1), otherwise predict fail (0).

The 0.5 cutoff is the default, not a law. In Chapter 7: Evaluating Classification Models we will see why a medical screening model might pick a much lower threshold.

### Log loss (binary cross-entropy)

We need a loss function that measures how wrong a *probability* is. Mean squared error is a poor fit here; the standard choice is log loss, also called binary cross-entropy.

For one training example with true label y (0 or 1) and predicted probability p:

    loss = -( y * log(p) + (1 - y) * log(1 - p) )

Read it piece by piece:

- If `y = 1`, the loss is `-log(p)`: the closer p is to 1, the smaller the loss. Predicting p = 0.01 for a true pass is catastrophically wrong, and `-log(0.01)` is large.
- If `y = 0`, the loss is `-log(1 - p)`: we want p near 0.

For a dataset of m examples we average this over all of them. Log loss has a beautiful property: combined with the sigmoid, its gradient comes out clean and simple - which is exactly why this pairing is used everywhere.

### The gradient, derived in plain text

For one example, the derivative of the log loss with respect to the linear score z is:

    d(loss)/dz = p - y

That is it - the predicted probability minus the true label. Then by the chain rule:

- `d(loss)/dw = (p - y) * x`
- `d(loss)/db = (p - y)`

Averaged over the whole dataset, this looks identical in structure to the linear regression gradient from Chapter 5: Gradient Descent. The only change is that `p` comes from `sigmoid(w*x + b)` instead of `w*x + b`. Same loop, new prediction function.

### A tiny dataset: study hours to pass/fail

We will use ten students. Each row is hours studied and whether they passed the exam.

```python-exec
# hours studied, then 1 = pass, 0 = fail
data = [
    (0.5, 0),
    (1.0, 0),
    (1.5, 0),
    (2.0, 0),
    (3.0, 0),
    (4.0, 1),
    (5.0, 1),
    (6.0, 1),
    (7.0, 1),
    (8.0, 1),
]

xs = [row[0] for row in data]
ys = [row[1] for row in data]
```

Real datasets are never this clean - in practice the classes overlap, and some 2-hour students pass while some 6-hour students fail. Logistic regression handles that gracefully because it outputs a probability, not an absolute verdict.

### Training with gradient descent

Here is the complete training loop. Initialize `w` and `b` at zero, compute predictions for the whole dataset, average the gradients, and step downhill.

```python-exec
def predict_probability(w, b, x):
    return sigmoid(w * x + b)

def compute_loss(w, b, xs, ys):
    total = 0.0
    for x, y in zip(xs, ys):
        p = predict_probability(w, b, x)
        # clamp p away from 0 and 1 so log never explodes
        p = max(min(p, 1 - 1e-12), 1e-12)
        total += -(y * math.log(p) + (1 - y) * math.log(1 - p))
    return total / len(xs)

def train(xs, ys, learning_rate=0.5, epochs=2000):
    w = 0.0
    b = 0.0
    m = len(xs)
    for epoch in range(epochs):
        grad_w = 0.0
        grad_b = 0.0
        for x, y in zip(xs, ys):
            p = predict_probability(w, b, x)
            error = p - y
            grad_w += error * x
            grad_b += error
        grad_w /= m
        grad_b /= m
        w -= learning_rate * grad_w
        b -= learning_rate * grad_b
        if epoch % 400 == 0:
            loss = compute_loss(w, b, xs, ys)
            print(f"epoch {epoch:4d}  loss {loss:.4f}  w {w:.3f}  b {b:.3f}")
    return w, b

w, b = train(xs, ys)
print(f"\nfinal: w = {w:.3f}, b = {b:.3f}")
```

Running this prints the loss shrinking steadily:



The initial loss, before any training, is exactly `log(2)` ≈ 0.6931 - what you get by predicting 0.5 for everything, i.e. shrugging. The first printed epoch is already one gradient step better than that. From there the model learns that more hours means more pass probability.

Notice the loss never hits zero. That is expected and healthy: with a sigmoid, pushing the loss all the way to zero would require infinite weights, because the sigmoid only approaches 0 and 1 asymptotically.

### Making predictions and measuring accuracy

Now the payoff: predicted probabilities for a few students, a hard class from the 0.5 threshold, and accuracy on the training set.

```python-exec
def predict_class(w, b, x, threshold=0.5):
    return 1 if predict_probability(w, b, x) >= threshold else 0

def accuracy(w, b, xs, ys):
    correct = 0
    for x, y in zip(xs, ys):
        if predict_class(w, b, x) == y:
            correct += 1
    return correct / len(xs)

print("hours  probability  predicted  actual")
for x, y in data:
    p = predict_probability(w, b, x)
    print(f"{x:5.1f}  {p:11.3f}  {predict_class(w, b, x):9d}  {y:6d}")

print("\nnew students:")
for hours in [2.5, 3.4, 5.5]:
    p = predict_probability(w, b, hours)
    print(f"{hours} hours -> pass probability {p:.3f}")

print(f"\ntraining accuracy: {accuracy(w, b, xs, ys) * 100:.0f}%")
```

Typical output:



Every training point is classified correctly, though the model has to thread an abrupt jump in the toy data between 2 and 4 hours. On messier real data, 100% training accuracy on ten points would tell you almost nothing; that is why Chapter 7: Evaluating Classification Models introduces proper train/test splits and metrics beyond accuracy.

### Reading the model

The learned parameters are interpretable. The decision boundary sits where `p = 0.5`, which is where `z = 0`, i.e. where `w * x + b = 0`. Solving for x:

```python-exec
boundary = -b / w
print(f"decision boundary at {boundary:.2f} hours")
```

With `w = 3.563` and `b = -12.306` the boundary lands at 3.45 hours - students studying more than that are predicted to pass. This kind of transparency is a genuine advantage logistic regression holds over the neural networks we will build in Chapter 15: Neural Networks from Scratch, where individual weights lose their simple meaning.

The whole model as a picture - the students as dots, and the learned sigmoid as the probability curve:

```python-exec
fail_x = [x for x, y in data if y == 0]
fail_y = [0 for _ in fail_x]
pass_x = [x for x, y in data if y == 1]
pass_y = [1 for _ in pass_x]

curve_x = [0.0 + 8.0 * i / 80 for i in range(81)]
curve_y = [predict_probability(w, b, x) for x in curve_x]

plt.scatter(fail_x, fail_y, label="fail")
plt.scatter(pass_x, pass_y, label="pass")
plt.plot(curve_x, curve_y, label="learned sigmoid")
plt.title("Study hours vs pass/fail with logistic curve")
plt.xlabel("hours studied")
plt.ylabel("P(pass)")
plt.show()
```

### Scaling the input (a preview)

Our `x` values are small (0 to 8), so a learning rate of 0.5 works fine. If hours were measured in minutes (0 to 480), the gradients on `w` would blow up and training would wobble. The fix is feature scaling - dividing inputs by their range or standard deviation - using the training-only statistics introduced in Chapter 3: Preparing Data for Machine Learning. Keep the rule of thumb: when gradient descent diverges on real data, check feature scales first.

### The full file

Assemble all the snippets above into `logistic.py` in this order: sigmoid, data, predict/loss/train functions, training call, predictions, boundary, accuracy. Run `python3 logistic.py` and you should reproduce every number printed in this chapter. Then tinker: change the learning rate, flip a label, add a student, and watch the boundary move.

### Practice checklist

- [ ] Explain in one sentence why a plain line is a bad classifier for 0/1 labels.
- [ ] Compute `sigmoid(0)`, `sigmoid(10)`, and `sigmoid(-10)` by hand with a calculator and check them against the Python function.
- [ ] Write the log loss for a single example from memory, for both `y = 1` and `y = 0`.
- [ ] Run the training loop with `learning_rate=0.05` and `learning_rate=2.0` and describe what changes.
- [ ] Derive the gradient `d(loss)/dw = (p - y) * x` using the chain rule and the fact that `sigmoid'(z) = sigmoid(z) * (1 - sigmoid(z))`.
- [ ] Add a new student `(3.5, 0)` to the dataset, retrain, and report the new accuracy and decision boundary.
- [ ] Change the threshold from 0.5 to 0.3 and explain which mistakes increase and which decrease.
- [ ] Implement `predict_class` so it returns the strings `"pass"` / `"fail"` and format the output table accordingly.
- [ ] In your own words, state what `w` and `b` mean for this dataset.
- [ ] Sketch on paper how you would extend this model to two inputs (hours studied and hours slept) with `z = w1*x1 + w2*x2 + b`.
