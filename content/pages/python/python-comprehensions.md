---
layout: tutorial
title: "Chapter 8 &ndash; Comprehensions and Iteration"
permalink: /courses/python-basics/python-comprehensions/
difficulty: beginner
author: Pankaj Doharey
summary: Write list/dict/set comprehensions with conditions and nesting, loop idiomatically with enumerate and zip, and use generator expressions for lazy pipelines.
theme: pylearning
date: 2026-01-20
previous_tutorial:
  title: "Chapter 7: Dictionaries and Sets"
  url: /courses/python-basics/python-dicts-sets/
next_tutorial:
  title: "Chapter 9: Files and Exceptions"
  url: /courses/python-basics/python-files-exceptions/
related_tutorials:
  - title: "Lists and Tuples"
    url: /courses/python-basics/python-lists-tuples/
  - title: "Dictionaries and Sets"
    url: /courses/python-basics/python-dicts-sets/
---

A comprehension builds a collection from a loop in a single, readable expression. It's one of Python's most loved features &mdash; the closest thing to Ruby's `map`/`select` chains &mdash; and learning to read them fluently is a rite of passage.

### The anatomy of a list comprehension

Every comprehension answers: "for each item, give me *expression*, maybe *if condition* holds."

```python-exec
# The loop way:
squares = []
for n in range(6):
    squares.append(n * n)
print(squares)

# The comprehension way - same result:
squares = [n * n for n in range(6)]
print(squares)
```

Read it aloud: "`n * n` for each `n` in `range(6)`." The expression comes first, the loop second.

### Adding a condition

A trailing `if` filters which items make it in &mdash; like Ruby's `select` fused with `map`.

```python-exec
evens = [n for n in range(20) if n % 2 == 0]
print(evens)

words = ["hi", "hello", "hey", "howdy"]
long_words = [w.upper() for w in words if len(w) > 3]
print(long_words)   # ['HELLO', 'HOWDY']
```

There's also a *conditional expression* form (ternary inside the expression part), which transforms instead of filters:

```python-exec
nums = [-3, 0, 5, -1]
labels = ["pos" if n > 0 else "non-pos" for n in nums]
print(labels)
```

Careful with the order: filter-`if` goes at the **end** (`[x for x in xs if ...]`), ternary `if/else` goes at the **front** (`[a if c else b for x in xs]`).

### Dict and set comprehensions

Same idea, different brackets. Dict comprehensions produce `key: value` pairs.

```python-exec
words = ["apple", "banana", "cherry"]

lengths = {w: len(w) for w in words}
print(lengths)                    # {'apple': 5, 'banana': 6, 'cherry': 6}

first_letters = {w[0] for w in words}
print(first_letters)              # {'a', 'b', 'c'} - a set

# Inverting a dict (Chapter 7's exercise) in one line:
code = {"France": "FR", "Japan": "JP"}
inverted = {v: k for k, v in code.items()}
print(inverted)                   # {'FR': 'France', 'JP': 'Japan'}
```

There is no tuple comprehension &mdash; parentheses create a *generator* instead (more below).

### enumerate and zip: idiomatic looping

Need the index? Use `enumerate`, never `range(len(x))`.

```python-exec
languages = ["Python", "Ruby", "Go"]

for i, lang in enumerate(languages):
    print(f"{i}: {lang}")

for i, lang in enumerate(languages, start=1):   # 1-based
    print(f"{i}. {lang}")
```

Need to walk two lists in lockstep? `zip` pairs them up &mdash; and stops at the shorter one.

```python-exec
names = ["ada", "grace", "alan"]
years = [1815, 1906, 1912]

for name, year in zip(names, years):
    print(f"{name} born {year}")

# zip + dict = instant lookup table
born = dict(zip(names, years))
print(born)

# Transposing rows into columns is zip's party trick:
rows = [(1, "a"), (2, "b"), (3, "c")]
nums, letters = zip(*rows)
print(nums, letters)
```

Both compose beautifully with comprehensions:

```python-exec
names = ["ada", "grace"]
years = [1815, 1906]

report = [f"{n.title()} ({y})" for n, y in zip(names, years)]
print(report)

numbered = {i: name for i, name in enumerate(names, start=1)}
print(numbered)
```

### Nested comprehensions

A comprehension can contain more than one `for`, reading left to right like nested loops.

```python-exec
# Flatten a matrix:
matrix = [[1, 2, 3], [4, 5, 6]]
flat = [x for row in matrix for x in row]
print(flat)                       # [1, 2, 3, 4, 5, 6]

# Coordinate pairs:
pairs = [(x, y) for x in range(3) for y in range(3) if x != y]
print(pairs)

# A multiplication table as a dict:
table = {(i, j): i * j for i in range(1, 4) for j in range(1, 4)}
print(table[(2, 3)])              # 6
```

Nested comprehensions are powerful but get unreadable fast. If you need more than two `for`s or a condition you can't say in one breath, write a plain loop &mdash; clarity wins.

### Generator expressions: lazy pipelines

Swap the square brackets for parentheses and you get a **generator** &mdash; values are produced on demand instead of building a whole list in memory.

```python-exec
total = sum(n * n for n in range(1_000_000))   # no million-item list!
print(total)

gen = (w.upper() for w in ["a", "bb", "ccc"])
print(gen)                # a generator object, not a list
print(next(gen))          # A - pull one value
print(list(gen))          # ['BB', 'CCC'] - consume the rest
```

Generators shine when feeding `sum`, `max`, `any`, `all`, or `join`:

```python-exec
words = ["python", "ruby", "go"]

print(any(len(w) > 5 for w in words))    # True - banana? no: 'python'
print(all(len(w) > 1 for w in words))    # True
print(", ".join(w.title() for w in words))
```

`any` and `all` **short-circuit**: they stop as soon as the answer is known, just like Ruby's `any?`/`all?`.

### map and filter: the functional cousins

Python also has `map()` and `filter()`, returning lazy iterators. Comprehensions are usually clearer, but you'll see both styles.

```python-exec
nums = [1, 2, 3, 4]

print(list(map(lambda n: n * 10, nums)))     # [10, 20, 30, 40]
print(list(filter(lambda n: n % 2 == 0, nums)))  # [2, 4]

# Same, more Pythonic:
print([n * 10 for n in nums])
print([n for n in nums if n % 2 == 0])
```

### Idiom review: which loop when?

- Transform + collect → comprehension.
- Side effects (printing, writing) → plain `for` loop.
- Need the index → `enumerate`.
- Parallel lists → `zip`.
- Feed one aggregate (`sum`/`max`/`any`) → generator expression.
- Can't read it at a glance → plain loop.

### Practice checklist

- [ ] Rewrite an append-loop as a list comprehension.
- [ ] Add a filter condition and a ternary transform to comprehensions.
- [ ] Build a dict with a dict comprehension from two zipped lists.
- [ ] Flatten a nested list with a double-`for` comprehension.
- [ ] Aggregate with a generator expression inside `sum` or `any`.

#### Practice 1 - Squares with a twist

**Goal:** Comprehension with a filter.

```python-exec
# TODO: In one line, build the list of squares of the
# numbers 0..20 that are divisible by 3, and print it.
# Expected to contain 0, 9, 36, 81, ...
```

#### Practice 2 - Price list

**Goal:** zip + dict comprehension.

```python-exec
items = ["apple", "banana", "cherry"]
prices = [0.5, 0.25, 0.75]

# TODO: Build a dict mapping item -> price using zip,
# then build a second dict with a 10% markup applied,
# and print both.
```

#### Practice 3 - Flatten and clean

**Goal:** Nested comprehension.

```python-exec
rows = [["  Ada", "GRACE "], ["alan ", "  GUIDO"]]

# TODO: Produce a flat list of names, stripped of
# whitespace and title-cased:
# ['Ada', 'Grace', 'Alan', 'Guido']
# Hint: two `for`s, call .strip().title() on each name.
```

#### Practice 4 - Lazy check

**Goal:** Generator expressions with any/all.

```python-exec
scores = [55, 62, 71, 48, 90]

# TODO: Using generator expressions (no lists!), print:
# - whether ANY score is 90 or above
# - whether ALL scores are above 40
# - how many scores are 60 or above (hint: sum of 1s)
```

Next up: make your programs robust with files and exceptions in Chapter 9.
