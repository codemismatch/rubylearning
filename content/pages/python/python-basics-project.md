---
layout: tutorial
title: "Chapter 12 &ndash; Capstone: Build a Word-Counter CLI"
permalink: /courses/python-basics/python-basics-project/
difficulty: beginner
author: Pankaj Doharey
summary: Tie the whole course together &mdash; functions, dicts, comprehensions, exceptions, and string methods &mdash; by building a text-analysis tool step by step on a bundled sample text.
theme: pylearning
date: 2026-02-17
previous_tutorial:
  title: "Chapter 11: Classes and Objects"
  url: /courses/python-basics/python-classes/
related_tutorials:
  - title: "Dictionaries and Sets"
    url: /courses/python-basics/python-dicts-sets/
  - title: "Strings in Python"
    url: /courses/python-basics/python-strings/
---

Time to put eleven chapters to work. We'll build a small **text-analysis tool** &mdash; the kind of script that counts words, finds the most frequent ones, and prints a tidy report. A real CLI version would read a file passed on the command line; here in the browser, our "input file" is a bundled sample text, and `print` is our interface. The logic is identical.

Every step reuses something you already know: string methods (ch5), dicts (ch7), comprehensions (ch8), exceptions (ch9), the standard library (ch10), and functions to glue it together (ch4).

### Step 0: the sample text

Our corpus is a few paragraphs about computing pioneers. In a file-based version this would come from `open("sample.txt").read()` &mdash; everything below works unchanged on that string.

```python-exec
SAMPLE_TEXT = """
Ada Lovelace wrote the first algorithm intended for a machine,
the Analytical Engine, and saw what others missed: that numbers
could represent music, images, and ideas.

Grace Hopper built the first compiler and popularized the idea
that machines should understand words, not just numbers. She found
the first real bug, a moth, taped into the logbook.

Alan Turing formalized computation itself, asking what it means
for a machine to compute, and answered with a machine of the mind:
the Turing machine, simple enough to reason about, powerful enough
to compute anything computable.
"""

print(f"{len(SAMPLE_TEXT)} characters loaded")
```

### Step 1: tokenize

Turn raw text into a list of clean words: lowercase it, strip punctuation from the edges, drop anything empty. All Chapter 5 material.

```python-exec
import string

def tokenize(text):
    """Split text into lowercase words with edge punctuation removed."""
    words = []
    for raw in text.split():
        word = raw.strip(string.punctuation).lower()
        if word:
            words.append(word)
    return words

tokens = tokenize(SAMPLE_TEXT)
print(len(tokens), "tokens")
print(tokens[:12])
```

### Step 2: count frequencies

A dict maps each word to its count &mdash; Chapter 7's core pattern, upgraded with `Counter` from Chapter 10. We'll show both, but keep the plain-dict version as our implementation so the mechanics stay visible.

```python-exec
def count_words(tokens):
    """Return a dict mapping each token to its frequency."""
    counts = {}
    for word in tokens:
        counts[word] = counts.get(word, 0) + 1
    return counts

counts = count_words(tokens)
print(len(counts), "unique words")
print("machine:", counts["machine"])
print("first:", counts["first"])
```

### Step 3: the report helpers

Small functions, each doing one job &mdash; and each testable in one line. Notice the comprehension from Chapter 8 doing the heavy lifting in `top_words`.

```python-exec
def top_words(counts, n=5):
    """Return the n most common (word, count) pairs, ties alphabetical."""
    ranked = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    return ranked[:n]

def longest_words(counts, n=5):
    """Return the n longest unique words."""
    return sorted(counts, key=len, reverse=True)[:n]

def stats(tokens, counts):
    """Return a small summary dict of corpus statistics."""
    return {
        "total_words": len(tokens),
        "unique_words": len(counts),
        "avg_length": round(sum(len(w) for w in tokens) / len(tokens), 1),
    }

print(top_words(counts, 5))
print(longest_words(counts, 5))
print(stats(tokens, counts))
```

### Step 4: guard the edges

Real input is hostile: empty strings, whitespace-only files. Chapter 9's answer &mdash; raise a clear error early, handle it at the boundary.

```python-exec
def analyze(text):
    """Analyze text and return (stats, top, longest). Raises ValueError on empty input."""
    tokens = tokenize(text)
    if not tokens:
        raise ValueError("no words to analyze")
    counts = count_words(tokens)
    return stats(tokens, counts), top_words(counts), longest_words(counts)

# The boundary: catch and report, never crash.
for sample in [SAMPLE_TEXT, "   \n  ", "!!! ???"]:
    try:
        s, top, long_ = analyze(sample)
        print("ok:", s["total_words"], "words")
    except ValueError as err:
        print(f"rejected input: {err}")
```

### Step 5: format the report

F-strings from Chapter 5 make the output something you'd actually show a user &mdash; aligned columns and a bar chart drawn with `"#" * n`.

```python-exec
def render_report(text, top_n=8):
    """Print a formatted word-frequency report for the given text."""
    s, top, long_ = analyze(text)

    print("=" * 40)
    print("WORD FREQUENCY REPORT")
    print("=" * 40)
    print(f"Words:  {s['total_words']}")
    print(f"Unique: {s['unique_words']}")
    print(f"Avg len: {s['avg_length']}")
    print("-" * 40)
    print(f"{'word':<14}{'count':>6}  bar")
    print("-" * 40)
    for word, n in top:
        print(f"{word:<14}{n:>6}  {'#' * n}")
    print("-" * 40)
    print("Longest:", ", ".join(long_[:5]))

render_report(SAMPLE_TEXT)
```

### The complete tool, assembled

Here's everything in one cell &mdash; the shape your final `wordcount.py` file would have, `__main__` guard included (Chapter 10). Rerun it after tweaking any step above.

```python-exec
import string

def tokenize(text):
    words = []
    for raw in text.split():
        word = raw.strip(string.punctuation).lower()
        if word:
            words.append(word)
    return words

def count_words(tokens):
    counts = {}
    for word in tokens:
        counts[word] = counts.get(word, 0) + 1
    return counts

def top_words(counts, n=8):
    ranked = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    return ranked[:n]

def render_report(text):
    tokens = tokenize(text)
    if not tokens:
        raise ValueError("no words to analyze")
    counts = count_words(tokens)
    print(f"{len(tokens)} words, {len(counts)} unique")
    for word, n in top_words(counts):
        print(f"{word:<14}{n:>4}  {'#' * n}")

def main():
    try:
        render_report(SAMPLE_TEXT)
    except ValueError as err:
        print(f"error: {err}")

if __name__ == "__main__":
    main()
```

To turn this into a true CLI on your own machine: replace `SAMPLE_TEXT` with `open(sys.argv[1]).read()` wrapped in a `try`/`except FileNotFoundError`, and you have a real tool.

### Where to go next

You've completed Python Basics! Natural next steps:

- The **[Machine Learning course](/courses/machine-learning/)** &mdash; put your Python to work on data, from first principles up to how large language models function.
- The standard library docs &mdash; revisit `pathlib`, `csv`, `re`, and `argparse` to make this tool production-grade.
- Practice sites like Exercism or the "Python Crash Course" problem sets &mdash; fluency comes from reps.

### Practice checklist

- [ ] Tokenize text with punctuation stripped and lowercase applied.
- [ ] Count word frequencies with a dict and `get`.
- [ ] Sort (word, count) pairs by frequency, breaking ties alphabetically.
- [ ] Raise and catch a `ValueError` for empty input.
- [ ] Format an aligned report with f-strings and a `#` bar chart.

#### Practice 1 - Your own corpus

**Goal:** Run the tool on new text.

```python-exec
my_text = """
Python is great. Ruby is great too. Is Python better?
Better is a strong word; great is a friendly word.
"""

# TODO: Call analyze(my_text) (defined above), unpack the
# three results, and print the stats dict plus the top 3
# (word, count) pairs.
```

#### Practice 2 - Filter stop words

**Goal:** Extend the pipeline.

```python-exec
STOP = {"the", "a", "an", "and", "is", "of", "to", "in", "it", "for"}

# TODO: Write a version of the top-words report that ignores
# words in STOP. Hint: build a filtered dict with a
# comprehension - {w: n for w, n in counts.items() if w not in STOP}
# - then reuse top_words(). Print the new top 5.
```

#### Practice 3 - Word-length histogram

**Goal:** New aggregation with the same tools.

```python-exec
# TODO: Build a dict mapping word length -> how many tokens
# have that length (use `tokens` from step 1). Print it as
# a histogram sorted by length:
#   3: ########  (8 words of length 3)
```

#### Practice 4 - Compare two texts

**Goal:** Sets meet the analyzer.

```python-exec
text_b = """
Katherine Johnson computed trajectories by hand and by machine,
checking the computers that checked her. Mathematics sent
astronauts around the machine of orbital mechanics.
"""

# TODO: Tokenize both SAMPLE_TEXT and text_b, turn each into
# a set of unique words, and print:
# - words appearing in BOTH texts
# - words unique to text_b
# sorted alphabetically.
```

Congratulations &mdash; you built a real tool from scratch. See you in the Machine Learning course!
