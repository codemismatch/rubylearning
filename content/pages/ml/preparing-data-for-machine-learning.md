---
layout: tutorial
title: "Chapter 3 &ndash; Preparing Data for Machine Learning"
permalink: /courses/machine-learning/preparing-data-for-machine-learning/
difficulty: beginner
author: Pankaj Doharey
summary: Turn messy rows into trustworthy features and labels, split before preprocessing, handle missing values, encode categories, and scale numbers without leaking test data.
theme: pylearning
previous_tutorial:
  title: "Chapter 2: Python for ML"
  url: /courses/machine-learning/python-for-ml/
next_tutorial:
  title: "Chapter 4: Linear Regression from Scratch"
  url: /courses/machine-learning/linear-regression-from-scratch/
date: 2026-01-16
---

In Chapter 2: Python for ML we learned how tables become arrays. Before we fit a model, however, we need to decide what each column means, repair incomplete values, turn categories into numbers, and protect our test set from accidental leakage. This work is called **data preparation**. It is less glamorous than choosing a model, but it often determines whether the final result is trustworthy.

This chapter builds a small preprocessing pipeline in pure Python. By the end, you will be able to:

- Separate input features from the label the model should predict.
- Inspect rows for missing values, duplicates, impossible values, and inconsistent units.
- Split data before learning preprocessing statistics.
- Fill missing numeric values using information from the training set only.
- Encode categories without pretending that names have a numeric order.
- Standardize features so gradient descent sees comparable scales.
- Reuse the exact same fitted preprocessing steps during inference.

### Start with the question, not the columns

Suppose each house is represented by a dictionary:

```python
rows = [
    {"size_sqft": 750,  "bedrooms": 2, "neighborhood": "north", "price": 180000},
    {"size_sqft": 940,  "bedrooms": 2, "neighborhood": "south", "price": 220000},
    {"size_sqft": None, "bedrooms": 3, "neighborhood": "north", "price": 265000},
    {"size_sqft": 1300, "bedrooms": 3, "neighborhood": "west",  "price": 290000},
    {"size_sqft": 1600, "bedrooms": 4, "neighborhood": "south", "price": 340000},
    {"size_sqft": 1850, "bedrooms": 4, "neighborhood": "west",  "price": 375000},
]
```

Our question is: **given what we know about a house before it sells, can we predict its sale price?**

That sentence determines the roles:

- `price` is the **label** (also called target or `y`).
- `size_sqft`, `bedrooms`, and `neighborhood` are candidate **features** (the inputs, often called `X`).
- Each dictionary is one **example**, **sample**, or **observation**.

The phrase "before it sells" matters. A column such as `final_tax_amount`, calculated after the sale from the sale price, would reveal the answer. A model trained with it might look brilliant in a notebook and fail in production. That mistake is **target leakage**.

A useful test for every feature is:

> Would this value genuinely be available at the moment the prediction is made?

If the answer is no, do not give it to the model.

### Inspect before transforming

Never begin by blindly calling a training function. First inspect the data:

```python
def inspect_rows(rows):
    print("row count:", len(rows))
    print("columns:", sorted(rows[0]))

    for column in rows[0]:
        values = [row.get(column) for row in rows]
        missing = sum(value is None for value in values)
        print(f"{column:>14}: {missing} missing")

inspect_rows(rows)
```

For a real dataset, ask at least these questions:

- Are any values missing?
- Are duplicate rows present?
- Are numeric values plausible, or is there a house with `-3` bedrooms?
- Are units consistent, or are some sizes in square feet and others in square meters?
- Are categories spelled consistently (`"North"`, `"north"`, and `"NORTH"`)?
- Is the label available for every training example?
- Does any feature reveal the label or information from the future?

Cleaning is not about making the data look pretty. It is about making every value mean one consistent thing.

### Split before you learn from the data

Chapter 1 introduced the train/test split. The ordering is crucial:

1. Shuffle and split the raw rows.
2. Learn medians, means, standard deviations, and category vocabularies from the training rows.
3. Apply those learned values to both training and test rows.
4. Fit the model on training data.
5. Evaluate once on test data.

If you compute a mean using all rows before splitting, the test set has already influenced training. The model has seen a tiny summary of its exam answers.

Here is a reusable split:

```python
import random

def train_test_split(rows, test_fraction=0.25, seed=42):
    shuffled = rows[:]
    random.Random(seed).shuffle(shuffled)
    cut = max(1, int(len(shuffled) * (1 - test_fraction)))
    return shuffled[:cut], shuffled[cut:]

train_rows, test_rows = train_test_split(rows)
print(len(train_rows), "training rows")
print(len(test_rows), "test rows")
```

The fixed seed makes the experiment reproducible. It does not make the split better; it simply ensures that two runs compare models on the same examples.

For classification, random splitting can accidentally put nearly all examples of a rare class on one side. A **stratified split** preserves approximately the same class proportions in each set. We will return to that in Chapter 7: Evaluating Classification Models.

### Missing values: fit on train, apply everywhere

Deleting every incomplete row can waste data and can introduce bias if values are not missing at random. A common numeric baseline is **median imputation**: replace a missing value with the median observed in training.

```python
def median(values):
    ordered = sorted(values)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return ordered[middle]
    return (ordered[middle - 1] + ordered[middle]) / 2

known_sizes = [
    row["size_sqft"]
    for row in train_rows
    if row["size_sqft"] is not None
]
training_size_median = median(known_sizes)

def fill_size(row, size_median):
    value = row["size_sqft"]
    return size_median if value is None else value
```

Notice that `training_size_median` comes only from `train_rows`. We use that same number when transforming a test row or a future house. We do **not** recalculate it for each dataset.

Sometimes the fact that a value was missing carries information. You can preserve it with an extra binary feature:

```python
size_was_missing = 1.0 if row["size_sqft"] is None else 0.0
```

That lets the model distinguish "a typical-sized house" from "a house whose size was unknown and therefore filled with the typical value."

### Categories need encoding, not arbitrary numbers

A model cannot multiply `"north"` by a weight. We need numbers, but this is wrong:

```python
# Bad: the numbers invent an order that does not exist.
codes = {"north": 1, "south": 2, "west": 3}
```

Those codes imply that west is greater than south and three times north. For unordered categories, use **one-hot encoding**: create one indicator per known category.

```python
neighborhoods = sorted({row["neighborhood"] for row in train_rows})
print(neighborhoods)

def one_hot(value, categories):
    return [1.0 if value == category else 0.0 for category in categories]

print(one_hot("south", neighborhoods))
```

The category vocabulary is also learned from training data. If an unseen category appears later, every known-category indicator can remain zero, or you can reserve an explicit `"other"` bucket. What matters is that inference uses the same columns in the same order as training.

### Standardization puts numeric features on comparable scales

`size_sqft` may be around 1,500 while `bedrooms` is around 3. Gradient descent reacts to those scales through the gradients, so the larger-numbered feature can dominate the updates. Standardization transforms each value into:

```text
standardized = (value - training_mean) / training_standard_deviation
```

Afterward, training values are centered near 0 with a spread near 1.

```python
import math

def fit_standardizer(values):
    mean = sum(values) / len(values)
    variance = sum((value - mean) ** 2 for value in values) / len(values)
    std = math.sqrt(variance)
    return mean, std if std > 0 else 1.0

def standardize(value, mean, std):
    return (value - mean) / std
```

Again, fit `mean` and `std` on training rows only, then freeze them. Standardization does not change the ordering of examples or erase information; it changes the coordinate system to one that is easier to optimize.

### A complete fitted preprocessor

The safest design separates **fitting** preprocessing from **transforming** rows. Fitting learns state from training data. Transforming reuses that frozen state.

```python
import math
import random

rows = [
    {"size_sqft": 750,  "bedrooms": 2, "neighborhood": "north", "price": 180000},
    {"size_sqft": 940,  "bedrooms": 2, "neighborhood": "south", "price": 220000},
    {"size_sqft": None, "bedrooms": 3, "neighborhood": "north", "price": 265000},
    {"size_sqft": 1300, "bedrooms": 3, "neighborhood": "west",  "price": 290000},
    {"size_sqft": 1600, "bedrooms": 4, "neighborhood": "south", "price": 340000},
    {"size_sqft": 1850, "bedrooms": 4, "neighborhood": "west",  "price": 375000},
    {"size_sqft": 2100, "bedrooms": 4, "neighborhood": "north", "price": 410000},
    {"size_sqft": 2300, "bedrooms": 5, "neighborhood": "south", "price": 445000},
]

def median(values):
    ordered = sorted(values)
    middle = len(ordered) // 2
    if len(ordered) % 2:
        return ordered[middle]
    return (ordered[middle - 1] + ordered[middle]) / 2

def fit_standardizer(values):
    mean = sum(values) / len(values)
    variance = sum((value - mean) ** 2 for value in values) / len(values)
    std = math.sqrt(variance)
    return mean, std if std > 0 else 1.0

def fit_preprocessor(training_rows):
    known_sizes = [
        row["size_sqft"]
        for row in training_rows
        if row["size_sqft"] is not None
    ]
    size_median = median(known_sizes)
    filled_sizes = [
        size_median if row["size_sqft"] is None else row["size_sqft"]
        for row in training_rows
    ]
    bedrooms = [row["bedrooms"] for row in training_rows]

    return {
        "size_median": size_median,
        "size_stats": fit_standardizer(filled_sizes),
        "bedroom_stats": fit_standardizer(bedrooms),
        "neighborhoods": sorted({
            row["neighborhood"] for row in training_rows
        }),
    }

def transform_row(row, state):
    size_missing = 1.0 if row["size_sqft"] is None else 0.0
    size = state["size_median"] if size_missing else row["size_sqft"]
    size_mean, size_std = state["size_stats"]
    bedroom_mean, bedroom_std = state["bedroom_stats"]

    numeric = [
        (size - size_mean) / size_std,
        (row["bedrooms"] - bedroom_mean) / bedroom_std,
        size_missing,
    ]
    categories = [
        1.0 if row["neighborhood"] == name else 0.0
        for name in state["neighborhoods"]
    ]
    return numeric + categories

rng = random.Random(42)
rng.shuffle(rows)
cut = int(0.75 * len(rows))
train_rows, test_rows = rows[:cut], rows[cut:]

preprocessor = fit_preprocessor(train_rows)
X_train = [transform_row(row, preprocessor) for row in train_rows]
y_train = [row["price"] for row in train_rows]
X_test = [transform_row(row, preprocessor) for row in test_rows]
y_test = [row["price"] for row in test_rows]

print("feature order:")
print(["size_scaled", "bedrooms_scaled", "size_missing"] +
      [f"neighborhood_{name}" for name in preprocessor["neighborhoods"]])
print("X_train shape:", (len(X_train), len(X_train[0])))
print("y_train length:", len(y_train))
print("first training vector:", [round(value, 3) for value in X_train[0]])
print("test rows transformed with training statistics:", len(X_test))
```

This code deliberately keeps the preprocessor as a plain dictionary so every learned value is visible. Libraries package the same idea into transformers and pipelines, but the contract is unchanged:

```text
fit on training data -> freeze state -> transform training/test/future rows identically
```

### Data leakage has many disguises

Leakage is any path by which information unavailable at prediction time reaches the model. Common examples:

- Computing scaling statistics from the full dataset before splitting.
- Filling missing values with a median computed from train plus test.
- Selecting features after checking which ones perform best on the test set.
- Predicting hospital readmission using a billing code added after discharge.
- Randomly splitting time-series rows, allowing future events into training.
- Keeping duplicate customers or near-identical images on both sides of a split.

For time-ordered data, split chronologically: train on the past and test on the future. For repeated entities, group by entity so the same person, device, or document family cannot appear in both sets.

### A practical data contract

Before moving to a model, write down:

1. What one row represents.
2. What the label means.
3. When the prediction is made.
4. Which features are available at that exact time.
5. How missing values are handled.
6. Which category vocabulary and numeric statistics were fitted.
7. How the train, validation, and test sets were separated.

This short contract prevents many bugs that no amount of model tuning can repair.

### Where this leads

We now have trustworthy `X` and `y`: rows have consistent meanings, preprocessing learns only from training data, and the same transformation can be reused at inference time. In Chapter 4: Linear Regression from Scratch we will temporarily return to one clean numeric feature so the model's mathematics remains visible. The preparation habits from this chapter still apply to every real dataset we use afterward.

### Practice checklist

- [ ] Add a duplicate row and write a function that detects exact duplicates before splitting.
- [ ] Add a house with an impossible bedroom count and make `inspect_rows` print a warning.
- [ ] Explain why computing the size mean before the train/test split leaks test information.
- [ ] Add an `"east"` test row that never appears in training and inspect its one-hot vector.
- [ ] Add a missing-value indicator for `bedrooms` and update `transform_row`.
- [ ] Print the mean of the standardized training sizes and confirm it is approximately zero.
- [ ] Write the feature order to a text file, then explain why changing that order during inference would corrupt predictions.
- [ ] Give one example of target leakage from a domain you know.
- [ ] Describe how you would split a dataset containing five years of daily sales without allowing the future into training.
