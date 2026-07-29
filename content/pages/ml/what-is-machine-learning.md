---
layout: tutorial
title: "Chapter 1 &ndash; What is Machine Learning"
permalink: /courses/machine-learning/what-is-machine-learning/
difficulty: beginner
author: Pankaj Doharey
summary: Learn what machine learning actually is, how it differs from traditional programming, and the core vocabulary - supervised, unsupervised, reinforcement, training, inference, overfitting, and the train/test split.
theme: pylearning
next_tutorial:
  title: "Chapter 2: Python for ML"
  url: /courses/machine-learning/python-for-ml/
date: 2026-01-06
---

Welcome to the first chapter of "Machine Learning: From Zero to LLMs". In this course we build everything by hand, in plain Python, so that by the end you genuinely understand what is happening inside the tools everyone else treats as black boxes. This first chapter sets the vocabulary and the mental model. There is some code - every example is copy-paste runnable with `python3 file.py` - but mostly this chapter is about learning to think the way machine learning thinks.

### Traditional programming: you write the rules

In traditional programming, a human figures out the rules and writes them down. The computer then applies those rules to data to produce answers.

Suppose you want to filter spam email. The traditional approach is to sit down, think hard about what spam looks like, and encode your knowledge as rules:

```python-exec
# spam_rules.py
def is_spam(email):
    """Hand-written rules for spam detection."""
    text = email.lower()

    spammy_words = ["free", "winner", "click here", "urgent", "lottery"]
    score = 0

    for word in spammy_words:
        if word in text:
            score += 1

    if text.count("!") > 3:
        score += 1

    return score >= 2


emails = [
    "Congratulations! You are a WINNER. Click here to claim your free prize!!!",
    "Hi Pankaj, are we still meeting at 3pm tomorrow?",
    "URGENT: your account needs verification. Click here now!",
    "Lunch on Friday? The new place near the office is free at noon.",
]

for email in emails:
    print(f"{'SPAM' if is_spam(email) else 'OK  '} | {email[:60]}")
```

Run it:



It works - sort of. Notice the last email contains the word "free" but is not spam, and our rule nearly catches it anyway. Now imagine maintaining this function for real: spammers change tactics weekly, legitimate mail keeps tripping rules, and the function grows into hundreds of brittle `if` statements. You are encoding *your* guess about what spam looks like, and your guess is always incomplete.

### Machine learning: the computer learns the rules

Machine learning flips the flow around. Instead of writing rules yourself, you give the computer **data plus the correct answers** (called *labels*), and the computer figures out the rules by itself.

- Traditional programming: Data + Rules -> Computer -> Answers
- Machine learning: Data + Answers -> Computer -> Rules

The "rules" the computer produces are called a **model**. You never read or edit the rules directly - they might be thousands of numbers - but you can *use* them on new data.

#> mermaid: caption="Figure 1: Traditional programming vs machine learning"
graph LR
  A[Data] --> C1[Computer]
  B[Rules] --> C1
  C1 --> D[Answers]
  A2[Data] --> C2[Computer]
  B2[Answers] --> C2
  C2 --> D2[Rules / Model]
#!

Here is the key idea in miniature. Instead of hand-picking spammy words, imagine we have labeled examples and we *count* which words appear in spam versus ham. The counts become our learned rules:

```python-exec
# learn_rules.py
# Labeled training data: (email, is_spam)
training_data = [
    ("win a free prize now", True),
    ("click here to claim your free money", True),
    ("urgent winner notification click now", True),
    ("are you free for lunch tomorrow", False),
    ("the meeting is now at three", False),
    ("click the link to read the report", False),
]

# "Learn" the rules: count word frequencies in spam vs ham
spam_counts = {}
ham_counts = {}

for text, is_spam in training_data:
    counts = spam_counts if is_spam else ham_counts
    for word in text.split():
        counts[word] = counts.get(word, 0) + 1

def predict(email):
    """Use the learned counts as rules."""
    spam_score = 0
    ham_score = 0
    for word in email.lower().split():
        spam_score += spam_counts.get(word, 0)
        ham_score += ham_counts.get(word, 0)
    return spam_score > ham_score

# Inference: use the learned rules on emails we have never seen
new_emails = [
    "free money click now",
    "lunch meeting tomorrow at noon",
]

for email in new_emails:
    print(f"{'SPAM' if predict(email) else 'OK  '} | {email}")
```

Run it with `python3 learn_rules.py`. The function `predict` contains no hand-written spammy-word list at all - it learned from the labeled examples that "free", "money", and "click" lean spam. That is the entire core idea of machine learning in fifteen lines of Python. Real systems do the same thing with better math and millions of examples, and we will build toward that over the next chapters.

### The three big flavors of machine learning

Machine learning is a family of techniques, not one technique. Three flavors cover most of what you will encounter.

**Supervised learning** - you have examples with correct answers, and the model learns to map inputs to outputs. Our spam filter above is supervised learning: the labels (spam / not spam) supervise the learning. Other examples:

- House price prediction: input is square meters, location, rooms; the label is the sale price.
- Image classification: input is a photo; the label is "cat" or "dog".
- LLM training (which we reach at the end of this course) is also supervised at heart: the input is a piece of text, and the label is the next word.

**Unsupervised learning** - you have data but no labels, and the model finds structure on its own. Examples:

- Customer segmentation: group shoppers by purchasing behavior without telling the model what the groups should be.
- Topic discovery: cluster thousands of news articles so similar ones land together.
- Anomaly detection: learn what "normal" server traffic looks like and flag anything weird.

**Reinforcement learning** - an agent learns by acting in an environment and receiving rewards or penalties. There is no labeled dataset; there is trial, error, and feedback. Examples:

- A program learning to play chess by playing millions of games against itself, rewarded for winning.
- A robot learning to walk: falling over is a negative reward, forward motion is positive.
- Fine-tuning chat models with human preference ratings is a form of reinforcement learning.

Most of this course focuses on supervised learning, because it is the foundation everything else builds on - but keep the other two in the back of your mind.

### Training vs inference

Two words you will see constantly:

- **Training** is the process of learning the rules from data. It is usually slow and expensive. In `learn_rules.py`, the counting loop over `training_data` is training.
- **Inference** is using the trained model on new, unseen inputs. It is usually fast. The `predict(...)` calls are inference.

The distinction matters practically. Training a large language model costs millions of dollars of compute; asking it a question (inference) costs a fraction of a cent. When people say a model is "deployed", they mean inference is running somewhere, long after training finished.

A useful mental image: training is studying for the exam, inference is taking it. You study once, then take many exams.

### Overfitting vs underfitting: memorizing vs learning

Here is the central failure mode of machine learning. A model that **overfits** has memorized the training data instead of learning the underlying pattern. A model that **underfits** has not even learned the training data.

Think of a student preparing for a math exam:

- **Underfitting**: the student did not study at all and fails both the practice problems and the exam.
- **Overfitting**: the student memorized every practice problem word-for-word. Perfect score on the practice set, total failure on the exam, because the exam has *new* problems.
- **Just right**: the student learned the underlying technique, scores well on practice problems, and generalizes to new ones.

You can feel overfitting in our tiny spam learner. In the training data, the word "report" appears only in a ham email. If a new spam email contains the word "report", our model gets a small push toward ham for no good reason - it memorized an accident of the tiny training set. With six training examples, everything is an accident. With six million, the accidents wash out.

Signs to watch for later in the course:

- Training accuracy near 100% but test accuracy much lower -> overfitting.
- Both training and test accuracy poor -> underfitting (or a bad model choice).

The fix is almost always some combination of: more data, a simpler model, or regularization (deliberately discouraging the model from memorizing). We will meet all three concretely in later chapters.

### Train/test split: the exam you grade honestly

If a model could be tested on the same data it trained on, a memorizing model would look perfect. So we never do that. We split the data:

- **Training set** - the majority (commonly 80%), used for learning the rules.
- **Test set** - the remainder (commonly 20%), locked away and used exactly once, at the end, to estimate how the model will perform on truly new data.

The intuition is simple: the test set is a mock exam made of questions the student has never seen. Here is a split in pure Python:

```python-exec
# train_test_split.py
import random

data = [
    ("win a free prize now", True),
    ("click here to claim your free money", True),
    ("urgent winner notification click now", True),
    ("congratulations you won the lottery", True),
    ("are you free for lunch tomorrow", False),
    ("the meeting is now at three", False),
    ("click the link to read the report", False),
    ("can you review my code today", False),
]

random.seed(42)  # fixed seed so the split is reproducible
shuffled = data[:]
random.shuffle(shuffled)

cut = int(0.75 * len(shuffled))
train, test = shuffled[:cut], shuffled[cut:]

print(f"Training examples: {len(train)}")
print(f"Test examples:     {len(test)}")
print("Held-out test set:")
for text, label in test:
    print(f"  {'spam' if label else 'ham '} | {text}")
```

Two details matter more than they look:

1. **Shuffle before splitting.** If your data is ordered (all spam first, then all ham), a naive split gives you a training set of only spam and a test set of only ham. Shuffling mixes the classes.
2. **The test set is sacred.** Every time you peek at it and adjust your model based on the result, you leak information and the test set stops being an honest exam. Professionals often keep a third split - a **validation set** - for tuning, so the test set stays untouched until the very end.

From Chapter 2: Python for ML onward, every model we build will follow this ritual: split, train on the training set, evaluate on the test set, and only then believe the numbers.

### What comes next

You now have the map: machine learning learns rules from data and answers instead of taking rules from a programmer; it comes in supervised, unsupervised, and reinforcement flavors; models are trained once and used for inference; the great dangers are overfitting (memorizing) and underfitting (not learning); and the train/test split is how we keep ourselves honest.

In the next chapter, Python for ML, we sharpen the exact Python tools this course relies on - lists, dictionaries, functions, and a first taste of numerical work - so that nothing in the later chapters feels like syntax magic.

### Practice checklist

- [ ] Explain the difference between the traditional programming flow (Data + Rules -> Answers) and the machine learning flow (Data + Answers -> Rules) in your own words.
- [ ] Run `spam_rules.py` and `learn_rules.py` with `python3` and confirm the outputs match your expectations.
- [ ] Add two more labeled examples to `learn_rules.py` and observe how the predictions change.
- [ ] Give one real-world example each of supervised, unsupervised, and reinforcement learning that is not mentioned in this chapter.
- [ ] Describe, without looking, what overfitting and underfitting mean and one symptom of each.
- [ ] Modify `train_test_split.py` to use an 80/20 split, and explain why shuffling before splitting matters.
- [ ] Explain why evaluating on the training set is dishonest, using the student-and-exam analogy or one of your own.
