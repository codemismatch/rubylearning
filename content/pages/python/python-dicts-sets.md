---
layout: tutorial
title: "Chapter 7 &ndash; Dictionaries and Sets"
permalink: /courses/python-basics/python-dicts-sets/
difficulty: beginner
author: Pankaj Doharey
summary: Store key-value data with dicts (CRUD, get, items/keys/values, merging), count words like a pro, and use sets for uniqueness and membership math.
theme: pylearning
date: 2026-01-13
previous_tutorial:
  title: "Chapter 6: Lists and Tuples"
  url: /courses/python-basics/python-lists-tuples/
next_tutorial:
  title: "Chapter 8: Comprehensions and Iteration"
  url: /courses/python-basics/python-comprehensions/
related_tutorials:
  - title: "Lists and Tuples"
    url: /courses/python-basics/python-lists-tuples/
  - title: "Files and Exceptions"
    url: /courses/python-basics/python-files-exceptions/
---

The dictionary (`dict`) is Python's hash map &mdash; the counterpart of Ruby's `Hash` &mdash; and it's arguably the most-used data structure in the language. Sets handle uniqueness and membership. Both are built on hashing, so lookups are effectively instant.

### Creating dictionaries

```python-exec
person = {"name": "Ada", "born": 1815, "city": "London"}
empty = {}
from_pairs = dict([("a", 1), ("b", 2)])
with_keys = dict(name="Grace", born=1906)   # keyword style

print(person)
print(from_pairs, with_keys)
```

Keys must be hashable &mdash; strings, numbers, and tuples work; lists and dicts do not. Values can be anything.

### CRUD: create, read, update, delete

```python-exec
person = {"name": "Ada", "born": 1815}

person["city"] = "London"        # create / update - same syntax
person["born"] = 1816            # overwrite
print(person["name"])            # read

del person["city"]               # delete (KeyError if missing)
print(person)

born = person.pop("born")        # remove and return
print(born, person)
```

Reading a missing key with `[]` raises `KeyError`. Two safer options:

```python-exec
person = {"name": "Ada"}

print(person.get("city"))            # None - no exception
print(person.get("city", "unknown")) # 'unknown' - your default

if "city" in person:                 # membership test on keys
    print(person["city"])
else:
    print("no city key")
```

`setdefault` both reads and initializes a missing key in one step &mdash; handy when building up grouped data:

```python-exec
groups = {}
groups.setdefault("admins", []).append("ada")
groups.setdefault("admins", []).append("grace")
print(groups)   # {'admins': ['ada', 'grace']}
```

### Iterating: keys, values, items

Looping over a dict yields its **keys**. Use `.items()` to get pairs &mdash; like Ruby's `each` on a Hash.

```python-exec
capitals = {"France": "Paris", "Japan": "Tokyo", "Egypt": "Cairo"}

for country in capitals:              # keys
    print(country, end=" ")
print()

for capital in capitals.values():     # values
    print(capital, end=" ")
print()

for country, capital in capitals.items():
    print(f"{country} -> {capital}")
```

Since Python 3.7, dicts preserve **insertion order**, so iteration is predictable.

### Merging dictionaries

Python 3.9+ has the `|` operator; `update()` mutates in place; `{**a, **b}` unpacking works everywhere.

```python-exec
defaults = {"theme": "light", "font": "mono", "size": 12}
overrides = {"theme": "dark", "size": 14}

merged = defaults | overrides          # right side wins
print(merged)

also = {**defaults, **overrides}       # same result
print(also)

defaults.update(overrides)             # in place
print(defaults)
```

### Worked example: counting words

Counting is the "hello world" of dictionaries &mdash; and the seed of this course's capstone project.

```python-exec
text = "the cat sat on the mat the cat ran"
counts = {}

for word in text.split():
    counts[word] = counts.get(word, 0) + 1

print(counts)

# Sort by frequency, most common first:
ranked = sorted(counts.items(), key=lambda kv: kv[1], reverse=True)
for word, n in ranked:
    print(f"{word:>6}: {'#' * n}")
```

The standard library's `collections.Counter` does this in one line &mdash; you'll meet it in Chapter 10 &mdash; but writing the loop yourself is the best way to internalize `get`.

### Sets: uniqueness as a type

A `set` is an unordered collection of unique, hashable items &mdash; Ruby's `Set`, but built in with literal syntax.

```python-exec
tags = {"python", "ruby", "python", "go"}
print(tags)                 # duplicates vanish

tags.add("rust")
tags.discard("go")          # remove, no error if missing
# tags.remove("go")         # would raise KeyError now
print("python" in tags)     # True - fast membership

letters = set("banana")
print(letters)              # {'b', 'a', 'n'}
```

Beware: `{}` creates an empty **dict**, not a set. Use `set()` for an empty set.

### Set operations

The classic math operations map to operators &mdash; perfect for comparing groups:

```python-exec
python_devs = {"ada", "grace", "guido"}
ruby_devs = {"grace", "matz", "ada"}

print(python_devs | ruby_devs)    # union - in either
print(python_devs & ruby_devs)    # intersection - in both
print(python_devs - ruby_devs)    # difference - python only
print(python_devs ^ ruby_devs)    # symmetric difference - exactly one

print({"ada"} < python_devs)      # proper subset - True
```

Practical use: deduplicating while ignoring order.

```python-exec
visitors = ["us", "uk", "us", "jp", "uk", "uk"]
unique = set(visitors)
print(len(visitors), "visits from", len(unique), "countries:", unique)
```

### frozenset: the immutable set

`frozenset` is to `set` what `tuple` is to `list` &mdash; immutable, and therefore hashable, so it can be a dict key or live inside another set.

```python-exec
permissions = frozenset({"read", "write"})

roles = {
    frozenset({"read"}): "viewer",
    frozenset({"read", "write"}): "editor",
}
print(roles[permissions])   # editor
# permissions.add("admin")  # AttributeError - immutable
```

### When which?

- **dict** &mdash; you look things up by a key: config, records, counts, indexes.
- **set** &mdash; you care about membership or uniqueness, not order or payloads.
- **list** &mdash; order matters and duplicates are meaningful.

### Practice checklist

- [ ] Build a dict, then update, read with `get`, and delete keys.
- [ ] Iterate `.items()` and print a formatted table.
- [ ] Merge two dicts so the second one's values win.
- [ ] Count word frequencies with `get(word, 0) + 1`.
- [ ] Compute an intersection and a difference of two sets.

#### Practice 1 - Contact book

**Goal:** Basic dict CRUD.

```python-exec
contacts = {"ada": "ada@analytical.engine"}

# TODO: Add "grace" with any email, update "ada"'s email,
# print grace's email with [] and a missing key "alan"
# with .get() and a default. Finally delete "ada" and
# print the dict.
```

#### Practice 2 - Word frequencies

**Goal:** Count words with a dict.

```python-exec
sentence = "to be or not to be that is the question"

# TODO: Build a dict mapping each word to its count,
# then print each word and count sorted alphabetically.
# Expected: 'be' and 'to' should both count 2.
```

#### Practice 3 - Set math

**Goal:** Compare two groups with set operators.

```python-exec
team_a = {"ada", "grace", "edsger"}
team_b = {"grace", "donald", "ada"}

# TODO: Print who is on both teams, who is only on team A,
# and the full roster of distinct people.
```

#### Practice 4 - Invert a dictionary

**Goal:** Swap keys and values.

```python-exec
country_to_code = {"France": "FR", "Japan": "JP", "Egypt": "EG"}

# TODO: Build `code_to_country` mapping "FR" -> "France" etc.
# by looping over .items(), then print it.
# (Look up "JP" in your new dict to prove it works.)
```

Next up: build lists, dicts, and sets the idiomatic way with comprehensions in Chapter 8.
