---
layout: tutorial
title: "Chapter 10 &ndash; Modules and the Standard Library"
permalink: /courses/python-basics/python-modules/
difficulty: beginner
author: Pankaj Doharey
summary: Master import forms, the __name__ == "__main__" idiom, how modules are loaded, and a runnable tour of math, random, datetime, collections, itertools, and json.
theme: pylearning
date: 2026-02-03
previous_tutorial:
  title: "Chapter 9: Files and Exceptions"
  url: /courses/python-basics/python-files-exceptions/
next_tutorial:
  title: "Chapter 11: Classes and Objects"
  url: /courses/python-basics/python-classes/
related_tutorials:
  - title: "Functions in Python"
    url: /courses/python-basics/python-functions/
  - title: "Capstone: Word-Counter CLI"
    url: /courses/python-basics/python-basics-project/
---

Python's motto is "batteries included": the standard library ships modules for math, dates, JSON, data structures, iteration tools, and far more &mdash; no installs needed. This chapter shows how imports work and tours the modules you'll use weekly.

### Import forms

```python-exec
import math                 # whole module; use math.sqrt
print(math.sqrt(16), math.pi)

from math import ceil, floor    # cherry-pick names
print(ceil(4.2), floor(4.8))

import random as rnd        # alias - common for long names
print(rnd.choice(["heads", "tails"]))
```

Guidelines:

- Prefer `import module` &mdash; the prefix makes origins obvious (`math.sqrt` vs a bare `sqrt`).
- `from module import name` is fine for a few well-known names.
- **Never** `from module import *` &mdash; it dumps unknown names into your namespace, like `eval`-ing a mystery file. Ruby's `include` at top level has the same smell.
- Imports conventionally go at the top of the file, stdlib first.

### What happens when you import

Importing a module **executes** its top-level code once, then caches the module object in `sys.modules`. Later imports reuse the cache &mdash; that's why circular imports and repeated imports are cheap.

```python-exec
import sys

print("math" in sys.modules)     # True - we imported it above

import math as m1, math as m2    # same object both times
print(m1 is m2)                  # True

# Modules are just objects - you can inspect them:
print(type(m1))
print(hasattr(m1, "sqrt"), hasattr(m1, "nope"))
```

### Your own module

A module is just a `.py` file; its name is the filename. In a real project, `greetings.py` sitting next to your script is importable as `import greetings`:

```text
# greetings.py (a separate file in a real project)
def hello(name):
    return f"Hello, {name}!"

# main.py
import greetings
print(greetings.hello("Ada"))
```

In this browser notebook everything already shares one namespace, so we can simulate the "module boundary" with a class-like bag of functions &mdash; but in your own projects, do create separate files:

```python-exec
# Simulating "greetings.py" as a namespace within one cell:
class greetings:
    @staticmethod
    def hello(name):
        return f"Hello, {name}!"

    @staticmethod
    def bye(name):
        return f"Bye, {name}!"

print(greetings.hello("Ada"))
print(greetings.bye("Ada"))
```

### The __name__ == "__main__" idiom

Every module has a `__name__` attribute. When you run a file directly, Python sets `__name__` to `"__main__"`; when the file is imported, `__name__` is the module's name. This lets a file be both an importable library and a runnable script:

```python-exec
# In this notebook, __name__ is "__main__" - the cell acts
# like the top-level script:
print(__name__)

def main():
    print("running as a script!")

if __name__ == "__main__":
    main()
```

Ruby's rough equivalent is `if __FILE__ == $0`. Adopt this idiom for every script: definitions up top, executable code under the guard.

### Tour: math and random

```python-exec
import math

print(math.sqrt(2), math.pi, math.e)
print(math.floor(3.7), math.ceil(3.2), math.factorial(5))
print(math.gcd(12, 18))              # 6
print(math.isqrt(17))                # 4 - integer square root

import random

random.seed(42)                      # reproducible runs
print(random.random())               # float in [0.0, 1.0)
print(random.randint(1, 6))          # a die roll
print(random.choice(["rock", "paper", "scissors"]))

deck = list(range(1, 11))
random.shuffle(deck)
print(deck)
print(random.sample(deck, 3))        # pick 3 without replacing
```

### Tour: datetime

```python-exec
from datetime import date, datetime, timedelta

today = date.today()
print(today, today.year, today.month, today.day)

birthday = date(1990, 6, 15)
age_days = (today - birthday).days
print(f"days old: {age_days}")

launch = datetime(2026, 3, 1, 14, 30)
print(launch.strftime("%A, %d %B %Y at %H:%M"))   # formatted

in_a_week = today + timedelta(days=7)
print("next week:", in_a_week)
```

`strftime` codes (`%Y`, `%m`, `%d`, `%H`...) mirror Ruby's `Time#strftime` &mdash; the letters are mostly the same.

### Tour: collections

`collections` upgrades the built-in containers. Two standouts:

```python-exec
from collections import Counter, defaultdict, namedtuple

# Counter - Chapter 7's word-count in one line:
words = "the cat sat on the mat the cat".split()
counts = Counter(words)
print(counts)
print(counts.most_common(2))         # [('the', 3), ('cat', 2)]

# defaultdict - no more .get(word, 0) dance:
by_length = defaultdict(list)
for w in words:
    by_length[len(w)].append(w)
print(dict(by_length))

# namedtuple - a mini-record type:
Point = namedtuple("Point", ["x", "y"])
p = Point(3, 4)
print(p.x, p.y, p)
```

### Tour: itertools

`itertools` is a treasure chest of fast, lazy iteration helpers:

```python-exec
import itertools as it

print("count() is infinite - slice it with islice, never list() it!")

print(list(it.islice(it.count(10, 5), 4)))     # [10, 15, 20, 25]
print(list(it.chain([1, 2], [3, 4], [5])))     # flatten streams
print(list(it.pairwise("ABCD")))               # [('A','B'), ('B','C'), ...]
print(list(it.permutations("abc", 2)))         # ordered pairs
print(list(it.combinations("abc", 2)))         # unordered pairs

grouped = it.groupby("aaabbbcc")
print([(k, len(list(g))) for k, g in grouped]) # run-length encoding!
```

### Tour: json

JSON is the lingua franca of APIs and config files. `json.dumps` serializes, `json.loads` parses &mdash; the "s" stands for *string*.

```python-exec
import json

data = {"name": "Ada", "skills": ["math", "poetry"], "active": True}

text = json.dumps(data, indent=2)
print(text)

back = json.loads(text)
print(back["skills"][0], type(back))

# JSON has no tuples or sets - they become lists or fail:
print(json.dumps({"point": (3, 4)}))
```

### Finding more

- The official docs: `docs.python.org/3/library/` &mdash; bookmark it.
- `dir(module)` lists a module's names; `help(module.func)` shows its docstring.
- Beyond the stdlib, third-party packages install with `pip` (outside this browser environment).

### Practice checklist

- [ ] Import a module three different ways (plain, from-import, alias).
- [ ] Guard executable code with `if __name__ == "__main__":`.
- [ ] Count items with `Counter` and group with `defaultdict`.
- [ ] Generate reproducible random picks with a seeded `random`.
- [ ] Serialize a dict to JSON and parse it back.

#### Practice 1 - Dice stats

**Goal:** random + Counter together.

```python-exec
import random
from collections import Counter

# TODO: Seed random with 7, roll two dice (randint 1-6)
# 100 times, count the sums with Counter, and print the
# three most common sums.
```

#### Practice 2 - Date math

**Goal:** datetime arithmetic.

```python-exec
from datetime import date, timedelta

# TODO: Starting from date(2026, 1, 1), print the date
# 100 days later, and print what weekday it falls on
# using strftime("%A").
```

#### Practice 3 - Group by first letter

**Goal:** defaultdict practice.

```python-exec
from collections import defaultdict

names = ["ada", "alan", "grace", "guido", "donald"]

# TODO: Build a dict mapping each first letter to the list
# of names starting with it, using defaultdict(list).
# Print it sorted by letter.
```

#### Practice 4 - JSON round trip

**Goal:** Serialize, parse, modify.

```python-exec
import json

config = {"debug": False, "retries": 3, "tags": ["web", "api"]}

# TODO: Dump `config` to a JSON string, parse it back,
# flip "debug" to True in the parsed copy, and print the
# final dict. (The original must stay unchanged.)
```

Next up: create your own types with classes and objects in Chapter 11.
