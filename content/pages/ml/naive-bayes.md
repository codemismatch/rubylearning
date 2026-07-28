---
layout: tutorial
title: "Chapter 13 &ndash; Naive Bayes"
permalink: /courses/machine-learning/naive-bayes/
difficulty: intermediate
author: Pankaj Doharey
summary: Apply Bayes' rule with a bold independence assumption, build a spam filter with Laplace smoothing and log-probabilities, and learn when naive Bayes shines.
theme: pylearning
previous_tutorial:
  title: "Chapter 12: Support Vector Machines"
  url: /courses/machine-learning/support-vector-machines/
next_tutorial:
  title: "Chapter 14: K-Means Clustering"
  url: /courses/machine-learning/k-means-clustering/
date: 2026-02-21
---

Way back in Chapter 1: What is Machine Learning, spam filtering was our first example of a real ML problem. Every chapter since has circled it with geometric methods - lines, margins, trees, neighbors. This chapter closes the loop with a *probabilistic* method: naive Bayes, the algorithm that powered the first generation of working spam filters and still earns its keep today. It trains in one pass over the data, needs almost no memory, and is startlingly hard to beat on text.

Everything here is pure Python. Save the snippets into `naive_bayes.py` and run with `python3 naive_bayes.py`.

### Bayes' rule in one minute

We want `P(spam | words)` - the probability a message is spam given the words it contains. Bayes' rule flips the conditional into pieces we can estimate from data:

    P(spam | words) = P(words | spam) * P(spam) / P(words)

Read it as:

- `P(spam)` - the **prior**: how common spam is overall.
- `P(words | spam)` - the **likelihood**: how typical these words are in spam.
- `P(words)` - a normalizing constant, same for both classes, so we can ignore it when we only compare spam vs ham.

Classification rule: pick the class with the bigger `P(class) * P(words | class)`.

### The "naive" assumption

`P(words | spam)` for a whole sentence is impossible to estimate directly - no dataset has seen every sentence. The naive move: pretend every word is independent of the others, so the joint probability factorizes:

    P(words | spam) = P(word1 | spam) * P(word2 | spam) * ... * P(wordN | spam)

This is false - "dear" and "winner" are plainly correlated in spam - but it works anyway. Why? We do not need accurate probabilities; we only need the right class to score higher. Correlated words double-count evidence, but they usually double-count it in favor of the correct class.

#> mermaid: caption="Figure 1: Naive Bayes scores each class and picks the larger"
graph LR
  A[new message] --> B[split into words]
  B --> C[score spam class]
  B --> D[score ham class]
  C --> E[compare log scores]
  D --> E
  E --> F[predicted label]
#!

### A tiny corpus

Twelve short messages, six spam and six ham, with word counts kept small so you can verify every number by hand.

```python-exec
training = [
    ("win money now", "spam"),
    ("claim your free prize", "spam"),
    ("free money win win", "spam"),
    ("you won a free ticket", "spam"),
    ("cheap pills free shipping", "spam"),
    ("win a prize claim now", "spam"),
    ("meeting at noon tomorrow", "ham"),
    ("lunch with the team", "ham"),
    ("project deadline moved to friday", "ham"),
    ("can you review my code", "ham"),
    ("let us meet for coffee tomorrow", "ham"),
    ("the report is attached", "ham"),
]
```

### Training: count, smooth, take logs

For the **multinomial** flavor of naive Bayes (the standard for text), each class is a bag of words and `P(word | class)` is the word's share of all words in that class. Two practical details make the naive version production-ready.

**Laplace smoothing.** If "lottery" never appears in ham training messages, then `P(lottery | ham) = 0`, and one lottery sighting would zero out the entire ham score of any message forever. Add-one smoothing gives every vocabulary word a phantom count of 1:

    P(word | class) = (count(word, class) + 1) / (total_words(class) + vocab_size)

**Log-probabilities.** Multiplying forty tiny probabilities underflows floating-point arithmetic toward zero. Sum their logarithms instead - `log(a*b) = log(a) + log(b)` - and comparisons still work because log is monotonic.

```python-exec
import math
from collections import Counter

def train_naive_bayes(training):
    word_counts = {"spam": Counter(), "ham": Counter()}
    class_counts = Counter()
    for text, label in training:
        class_counts[label] += 1
        word_counts[label].update(text.split())
    vocab = set()
    for counts in word_counts.values():
        vocab.update(counts)
    return word_counts, class_counts, vocab

word_counts, class_counts, vocab = train_naive_bayes(training)
n_docs = sum(class_counts.values())

def log_prior(label):
    return math.log(class_counts[label] / n_docs)

def log_likelihood(word, label):
    count = word_counts[label][word]                 # Counter gives 0 for missing
    total = sum(word_counts[label].values())
    return math.log((count + 1) / (total + len(vocab)))

def score(text, label):
    total = log_prior(label)
    for word in text.split():
        if word in vocab:                            # skip never-seen words
            total += log_likelihood(word, label)
    return total

def predict(text):
    spam_score = score(text, "spam")
    ham_score = score(text, "ham")
    return ("spam" if spam_score > ham_score else "ham"), spam_score, ham_score
```

Training is just counting - one pass, no iteration, no learning rate. Compared to the gradient descent loops of earlier chapters, this feels almost like cheating.

### Classifying messages

```python-exec
tests = [
    "free prize claim now",
    "meeting moved to tomorrow",
    "win free coffee",
    "review the attached report",
]

for text in tests:
    label, s, h = predict(text)
    print(f"{text!r:35} -> {label:4} (spam {s:.2f}, ham {h:.2f})")
```

```text
'free prize claim now'              -> spam (spam -12.42, ham -17.51)
'meeting moved to tomorrow'         -> ham  (spam -17.33, ham -14.33)
'win free coffee'                   -> spam (spam -9.95, ham -12.61)
'review the attached report'        -> ham  (spam -17.33, ham -14.33)
```

All four correct, including the tricky "win free coffee", where spam vocabulary ("win", "free") outweighs the neutral "coffee". Note the log scores are negative (sums of logs of fractions) and we only ever compare them - we never convert back to raw probabilities.

Those two scores as a chart - the gap between the bars is the whole decision:

```python-exec
_, win_s, win_h = predict("win free coffee")
plt.bar(["spam", "ham"], [win_s, win_h])
plt.title("Per-class log scores for 'win free coffee'")
plt.xlabel("class")
plt.ylabel("log score")
plt.show()
```

If you do want a probability-like confidence, exponentiate the *difference*: `P(spam | words)` is approximately `1 / (1 + exp(ham_score - spam_score))` - a sigmoid of the score gap, the same shape you met in Chapter 6: Logistic Regression & Classification.

```python-exec
def spam_probability(text):
    _, s, h = predict(text)
    return 1.0 / (1.0 + math.exp(h - s))

for text in tests:
    print(f"{text!r:35} spam probability {spam_probability(text):.3f}")
```

```text
'free prize claim now'              spam probability 0.994
'meeting moved to tomorrow'         spam probability 0.048
'win free coffee'                   spam probability 0.935
'review the attached report'        spam probability 0.048
```

Take these numbers with a grain of salt: naive Bayes scores are notoriously overconfident (the independence assumption double-counts evidence - 0.994 from four words is bold), but their *ranking* is usually sound.

### Leave-one-out check

How good is the filter on its own training data, honestly? Reuse the leave-one-out trick from Chapter 9: K-Nearest Neighbors:

```python-exec
correct = 0
for i, (text, label) in enumerate(training):
    rest = training[:i] + training[i+1:]
    wc, cc, v = train_naive_bayes(rest)
    # temporarily use the retrained counts
    globals().update(word_counts=wc, class_counts=cc, vocab=v, n_docs=sum(cc.values()))
    guess, _, _ = predict(text)
    correct += (guess == label)

print(f"leave-one-out accuracy: {correct}/{len(training)}")
```

```text
leave-one-out accuracy: 10/12
```

Ten out of twelve - and the two misses are instructive. The misclassified messages are "project deadline moved to friday" and "can you review my code": hold either out, and its words appear in *no* remaining ham message, so every word scores via Laplace smoothing alone - and smoothed unseen words score slightly higher under spam, because spam has fewer total words and therefore a smaller denominator. Small vocabularies make individual messages brittle; real corpora with thousands of messages suffer far less, and accuracies above 95% with just this much code are common - exactly why naive Bayes was the original spam weapon.

### When naive Bayes shines (and when it does not)

- **Shines on**: text classification (spam, sentiment, topic tagging), small datasets, and any problem needing a model in milliseconds. It trains in one pass, handles thousands of word features gracefully (counting scales where geometry suffers - remember the curse of dimensionality from Chapter 9), and updates incrementally as new labeled mail arrives.
- **Struggles with**: features whose correlations carry the signal (it counts "not" and "good" independently and misses "not good"), numeric features without a distribution assumption (the **Gaussian** naive Bayes variant models each feature as a bell curve per class), and calibrated probability outputs.

The vocabulary also matters more than the algorithm: lowercasing, dropping punctuation, and sometimes removing ultra-common stop words are the unglamorous steps that decide real-world accuracy.

### The full file

Assemble the snippets into `naive_bayes.py` in this order: imports, training corpus, training and scoring functions, the four test messages, the probability helper, and the leave-one-out loop. Run `python3 naive_bayes.py` and reproduce every number. Then tinker: add the word "free" to a few ham messages and watch "win free coffee" tip the other way - a live demonstration of how the model weighs evidence.

### Practice checklist

- [ ] Write Bayes' rule from memory and label the prior, likelihood, and normalizing constant.
- [ ] Compute `P("free" | spam)` with Laplace smoothing by hand from the corpus and check it against the code.
- [ ] Explain in one sentence why we sum log-probabilities instead of multiplying probabilities.
- [ ] Classify "free meeting" by hand (roughly) and then with the code; explain which words pushed each side.
- [ ] Describe a two-word phrase that naive Bayes will systematically misunderstand, and why.
- [ ] Name one problem from earlier chapters where naive Bayes would likely beat KNN and one where it would lose to logistic regression, with reasons.
