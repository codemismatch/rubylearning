---
layout: tutorial
title: "Chapter 7 &ndash; Evaluating Classification Models"
permalink: /courses/machine-learning/evaluating-classification-models/
difficulty: intermediate
author: Pankaj Doharey
summary: Evaluate classifiers with confusion matrices, precision, recall, F1, thresholds, baselines, validation data, and metrics that match the real cost of mistakes.
theme: pylearning
previous_tutorial:
  title: "Chapter 6: Logistic Regression & Classification"
  url: /courses/machine-learning/logistic-regression-classification/
next_tutorial:
  title: "Chapter 8: Generalization & Regularization"
  url: /courses/machine-learning/generalization-and-regularization/
date: 2026-02-06
---

In Chapter 6: Logistic Regression & Classification we trained a model that outputs a probability and turns it into a pass/fail decision. We printed training accuracy, but training accuracy answers the least interesting question: *how well does the model remember examples it already used?*

Evaluation asks the question we actually care about:

> How useful are the model's predictions on new examples, under the real costs of different mistakes?

There is no universally best metric. A spam filter, cancer screening system, and photo tagger may all be classifiers, but a false positive means something different in each one. This chapter gives you the vocabulary and code to choose honestly.

### Keep three jobs separate

As experiments become more realistic, data has three roles:

- **Training set** - fits weights and biases.
- **Validation set** - chooses thresholds, features, model size, learning rate, and other decisions.
- **Test set** - estimates final performance after all choices are frozen.

The test set is not a scoreboard to check after every edit. If you repeatedly choose changes because they improve the test score, the test set becomes part of training. You have overfit the exam.

For a small dataset, a common starting split is 70% train, 15% validation, and 15% test. The exact percentages matter less than keeping the roles separate.

### From probabilities to a confusion matrix

Suppose a model predicts the probability that a transaction is fraudulent:

```python-exec
y_true =  [0,    0,    1,    0,    1,    1,    0,    1,    0,    1]
probs =   [0.05, 0.62, 0.91, 0.10, 0.44, 0.81, 0.30, 0.72, 0.55, 0.20]
```

At threshold 0.5, probabilities greater than or equal to 0.5 become positive predictions:

```python-exec
def predict_classes(probabilities, threshold=0.5):
    return [1 if probability >= threshold else 0
            for probability in probabilities]

y_pred = predict_classes(probs)
print(y_pred)
```

Every decision belongs to one of four boxes:

- **True positive (TP):** predicted fraud, actually fraud.
- **True negative (TN):** predicted safe, actually safe.
- **False positive (FP):** predicted fraud, actually safe.
- **False negative (FN):** predicted safe, actually fraud.

```python-exec
def confusion_matrix(y_true, y_pred):
    tp = tn = fp = fn = 0
    for actual, predicted in zip(y_true, y_pred):
        if actual == 1 and predicted == 1:
            tp += 1
        elif actual == 0 and predicted == 0:
            tn += 1
        elif actual == 0 and predicted == 1:
            fp += 1
        else:
            fn += 1
    return {"tp": tp, "tn": tn, "fp": fp, "fn": fn}

print(confusion_matrix(y_true, y_pred))
```

For the example, the matrix is:

```text
TP = 3   FP = 2
FN = 2   TN = 3
```

The confusion matrix is more informative than a single score because it shows *which kind* of error the model makes.

### Accuracy: useful, but easy to fool

Accuracy is the fraction of all predictions that are correct:

```text
accuracy = (TP + TN) / (TP + TN + FP + FN)
```

Our example gets 6 out of 10 correct, so accuracy is 0.60.

Now imagine airport screening data with 9,990 safe bags and 10 dangerous bags. A model that always predicts "safe" has 99.9% accuracy and catches nothing. The right baseline is not zero; it is the simplest strategy you must beat. For imbalanced data, always compare against:

- The majority-class prediction.
- A simple rules-based system, if one exists.
- The previous production model.

Accuracy is most meaningful when classes are reasonably balanced and false positives and false negatives have similar costs.

### Precision: when a positive prediction must be credible

Precision asks:

> Of everything predicted positive, what fraction was truly positive?

```text
precision = TP / (TP + FP)
```

Our fraud model predicts positive five times, and three are correct:

```text
precision = 3 / 5 = 0.60
```

High precision matters when false alarms are expensive. If a model automatically blocks customer accounts, low precision means many innocent customers are disrupted.

### Recall: when missing a positive is dangerous

Recall asks:

> Of all actual positives, what fraction did the model find?

```text
recall = TP / (TP + FN)
```

There are five fraudulent transactions and the model catches three:

```text
recall = 3 / 5 = 0.60
```

High recall matters when false negatives are dangerous. A first-pass medical screening system may accept more false alarms to avoid missing a treatable disease.

Recall is also called **sensitivity** or **true positive rate**.

### F1 balances precision and recall

F1 is the harmonic mean of precision and recall:

```text
F1 = 2 * precision * recall / (precision + recall)
```

The harmonic mean is deliberately unforgiving. If precision is high but recall is near zero, F1 stays low. It is useful when you need one comparison number and both error types matter, especially with imbalanced classes.

F1 still hides the individual tradeoff, so report precision and recall beside it.

### Compute all metrics safely

Real code must handle denominators that can be zero:

```python-exec
def safe_divide(numerator, denominator):
    return numerator / denominator if denominator else 0.0

def classification_metrics(y_true, probabilities, threshold=0.5):
    y_pred = predict_classes(probabilities, threshold)
    counts = confusion_matrix(y_true, y_pred)
    tp, tn = counts["tp"], counts["tn"]
    fp, fn = counts["fp"], counts["fn"]

    accuracy = safe_divide(tp + tn, tp + tn + fp + fn)
    precision = safe_divide(tp, tp + fp)
    recall = safe_divide(tp, tp + fn)
    f1 = safe_divide(2 * precision * recall, precision + recall)

    return {
        **counts,
        "threshold": threshold,
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
    }

for name, value in classification_metrics(y_true, probs).items():
    if isinstance(value, float):
        print(f"{name:>10}: {value:.3f}")
    else:
        print(f"{name:>10}: {value}")
```

### The threshold is a product decision

Logistic regression produces probabilities. The threshold converts those probabilities into actions, and 0.5 is merely a default.

```python-exec
for threshold in [0.2, 0.4, 0.5, 0.7, 0.9]:
    result = classification_metrics(y_true, probs, threshold)
    print(
        f"threshold={threshold:.1f}  "
        f"precision={result['precision']:.2f}  "
        f"recall={result['recall']:.2f}  "
        f"F1={result['f1']:.2f}"
    )
```

Lowering the threshold usually predicts more positives:

- Recall tends to rise because fewer real positives are missed.
- Precision may fall because more negatives become false alarms.

Raising the threshold usually does the reverse.

Choose the threshold on validation data, based on the cost of mistakes. Then freeze it before touching the test set.

### Turn costs into an explicit score

Sometimes a business can estimate the relative cost of each error:

```python-exec
def mistake_cost(counts, false_positive_cost=1, false_negative_cost=5):
    return (
        counts["fp"] * false_positive_cost +
        counts["fn"] * false_negative_cost
    )

for threshold in [i / 10 for i in range(1, 10)]:
    result = classification_metrics(y_true, probs, threshold)
    cost = mistake_cost(result, false_positive_cost=1, false_negative_cost=5)
    print(f"{threshold:.1f} -> cost {cost}")
```

This is more honest than maximizing a fashionable metric when the real goal is known. The numbers do not need to be perfect; even an approximate statement such as "missing fraud costs about five times a manual review" makes the tradeoff explicit.

### ROC and precision-recall curves

Rather than inspect five hand-picked thresholds, evaluate many:

- An **ROC curve** plots recall (true positive rate) against false positive rate.
- A **precision-recall curve** plots precision against recall.

The area under a curve summarizes ranking quality across thresholds. ROC AUC is common, but it can look optimistic when positives are extremely rare because the large number of true negatives dominates. Precision-recall curves are often more revealing for rare-event detection.

You do not need plotting code to understand the core idea: a good model ranks actual positives above actual negatives across many possible cutoffs.

### Probability quality and calibration

Two classifiers can make the same 0/1 decisions while producing very different probabilities. If a model says "0.8" one hundred times, roughly eighty of those cases should be positive for the probability to be **calibrated**.

Calibration matters when probabilities drive prices, risk scores, staffing, or human decisions. Accuracy alone cannot distinguish a careful 0.55 from an unjustifiably confident 0.99.

Log loss from Chapter 6 rewards calibrated probabilities and heavily punishes confident wrong answers. That is one reason we train logistic regression with log loss rather than accuracy, which is flat almost everywhere and gives gradient descent no useful slope.

### Evaluate slices, not only averages

One overall score can hide failures affecting a smaller group. Evaluate meaningful slices:

- New customers versus long-time customers.
- Daytime versus nighttime traffic.
- Short documents versus long documents.
- Different devices, regions, languages, or data sources.

A slice needs enough examples for its metric to be stable, and any use of sensitive attributes requires care. The general principle is simple: ask where the model fails, not only how often it succeeds on average.

### Cross-validation for small datasets

When data is scarce, one validation split can be noisy. In **k-fold cross-validation**:

1. Divide training data into `k` folds.
2. Train on `k - 1` folds and validate on the remaining fold.
3. Repeat until every fold has served as validation.
4. Average the metric.

Cross-validation helps compare model choices with less dependence on one lucky split. The final test set still remains untouched. After choosing the model, retrain it on all non-test data and evaluate once on test.

### A reusable evaluation report

Here is the whole chapter's core in one runnable file:

```python-exec
def safe_divide(a, b):
    return a / b if b else 0.0

def report(y_true, probabilities, threshold):
    predicted = [int(p >= threshold) for p in probabilities]
    tp = sum(a == 1 and p == 1 for a, p in zip(y_true, predicted))
    tn = sum(a == 0 and p == 0 for a, p in zip(y_true, predicted))
    fp = sum(a == 0 and p == 1 for a, p in zip(y_true, predicted))
    fn = sum(a == 1 and p == 0 for a, p in zip(y_true, predicted))

    precision = safe_divide(tp, tp + fp)
    recall = safe_divide(tp, tp + fn)
    return {
        "threshold": threshold,
        "accuracy": safe_divide(tp + tn, len(y_true)),
        "precision": precision,
        "recall": recall,
        "f1": safe_divide(2 * precision * recall, precision + recall),
        "tp": tp, "tn": tn, "fp": fp, "fn": fn,
    }

y_true = [0, 0, 1, 0, 1, 1, 0, 1, 0, 1]
probs =  [0.05, 0.62, 0.91, 0.10, 0.44, 0.81, 0.30, 0.72, 0.55, 0.20]

for threshold in [0.2, 0.4, 0.5, 0.7, 0.9]:
    result = report(y_true, probs, threshold)
    print(
        f"{threshold:.1f} | accuracy {result['accuracy']:.2f} | "
        f"precision {result['precision']:.2f} | "
        f"recall {result['recall']:.2f} | F1 {result['f1']:.2f} | "
        f"FP {result['fp']} FN {result['fn']}"
    )
```

Do not choose the row with the biggest number automatically. First state which mistake matters more, then choose the metric and threshold that represent that goal.

### Where this leads

Evaluation tells us whether a model generalizes and how it fails. The next question is what to do when training performance is excellent but validation performance is poor. Chapter 8: Generalization & Regularization introduces the tools for controlling model complexity, choosing settings without test leakage, and recognizing when more data is more valuable than a more complicated model.

### Practice checklist

- [ ] Compute the confusion matrix for the example by hand at threshold 0.5.
- [ ] Verify accuracy, precision, recall, and F1 against the code.
- [ ] Explain why an always-negative classifier can have excellent accuracy on rare-event data.
- [ ] Find the threshold with the lowest cost when a false negative costs five times a false positive.
- [ ] Change that ratio so false positives cost more and observe how the preferred threshold moves.
- [ ] Write down whether precision or recall matters more for spam filtering, disease screening, and automatic account suspension, and explain each choice.
- [ ] Add a majority-class baseline to the report.
- [ ] Split a labeled dataset into train, validation, and test sets and state the one job of each.
- [ ] Explain why repeatedly checking test F1 leaks information even though the test labels never enter gradient descent.
- [ ] Create two slices of the example data and compare their confusion matrices.
