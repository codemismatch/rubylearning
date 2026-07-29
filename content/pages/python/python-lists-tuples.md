---
layout: tutorial
title: "Chapter 6 &ndash; Lists and Tuples"
permalink: /courses/python-basics/python-lists-tuples/
difficulty: beginner
author: Pankaj Doharey
summary: "Work with Python's ordered collections: list methods, slicing, sorting, the mutability and aliasing traps, tuples, and unpacking."
theme: pylearning
date: 2026-01-06
previous_tutorial:
  title: "Chapter 5: Strings in Python"
  url: /courses/python-basics/python-strings/
next_tutorial:
  title: "Chapter 7: Dictionaries and Sets"
  url: /courses/python-basics/python-dicts-sets/
related_tutorials:
  - title: "Strings in Python"
    url: /courses/python-basics/python-strings/
  - title: "Comprehensions and Iteration"
    url: /courses/python-basics/python-comprehensions/
---

Python has two built-in ordered sequence types: the **list** (mutable, like a Ruby `Array`) and the **tuple** (immutable, like a frozen array). Knowing which to reach for &mdash; and how copying really works &mdash; will save you from the most classic Python bugs.

### Creating and reading lists

```python-exec
numbers = [3, 1, 4, 1, 5, 9, 2, 6]
mixed = [1, "two", 3.0, True]     # lists can hold anything
empty = []

print(numbers[0])      # 3 - first
print(numbers[-1])     # 6 - last
print(len(numbers))    # 8
print(4 in numbers)    # True - membership test
```

Indexing and slicing work exactly like strings (Chapter 5):

```python-exec
numbers = [3, 1, 4, 1, 5, 9, 2, 6]

print(numbers[2:5])    # [4, 1, 5]
print(numbers[::-1])   # reversed copy
print(numbers[::2])    # every second item
```

### Adding and removing

```python-exec
fruits = ["apple", "banana"]

fruits.append("cherry")          # add one at the end
fruits.insert(1, "apricot")      # insert at index 1
fruits.extend(["fig", "grape"])  # append many
print(fruits)

fruits.remove("banana")          # remove first match (ValueError if absent)
last = fruits.pop()              # remove and return the last item
first = fruits.pop(0)            # pop by index
print(first, last, fruits)

del fruits[0]                    # delete by index
print(fruits)
```

`append` vs `extend` trips everyone once: `append` adds its argument as a single element, `extend` merges another iterable in.

```python-exec
a = [1, 2]
a.append([3, 4])
print(a)        # [1, 2, [3, 4]] - nested!

b = [1, 2]
b.extend([3, 4])
print(b)        # [1, 2, 3, 4] - flat
```

### Sorting: sort vs sorted

`list.sort()` sorts **in place** and returns `None`; `sorted()` returns a **new sorted list** and leaves the original alone. Ruby's `sort!` vs `sort` &mdash; same idea.

```python-exec
scores = [42, 7, 19, 73]

asc = sorted(scores)
desc = sorted(scores, reverse=True)
print(asc, desc, scores)     # original untouched

scores.sort()
print(scores)                # now it changed

# Gotcha: sort() returns None!
result = scores.sort()
print(result)                # None - a classic bug source
```

Sort by anything with `key` &mdash; it takes a function applied to each element:

```python-exec
words = ["banana", "fig", "cherry", "date"]

print(sorted(words, key=len))                # by length
print(sorted(words, key=lambda w: w[-1]))    # by last letter

pairs = [("ada", 36), ("grace", 85), ("alan", 41)]
print(sorted(pairs, key=lambda p: p[1]))     # by second element
```

`reverse()` flips a list in place; `reversed()` gives you an iterator over a reversed view.

### Mutability and the aliasing trap

This is the most important section of the chapter. Assignment **never copies** a list &mdash; both names point at the same object.

```python-exec
original = [1, 2, 3]
alias = original            # NOT a copy - same list!

alias.append(99)
print(original)             # [1, 2, 3, 99] - oops
```

To actually copy, use a slice, `.copy()`, or `list()`:

```python-exec
original = [1, 2, 3]

copy1 = original[:]         # slice copy
copy2 = original.copy()
copy3 = list(original)

copy1.append(99)
print(original, copy1)      # original safe this time
```

These are **shallow** copies: the outer list is new, but nested objects are still shared. For nested structures use `copy.deepcopy`.

```python-exec
import copy

matrix = [[1, 2], [3, 4]]
shallow = matrix[:]
deep = copy.deepcopy(matrix)

shallow[0].append(99)
print(matrix)     # [[1, 2, 99], [3, 4]] - inner list still shared!

deep[0].append(7)
print(matrix)     # unchanged - deep copy is fully independent
```

The same aliasing logic explains the mutable-default-argument gotcha from Chapter 4 &mdash; and why you should compare identity with `is` only for singletons like `None`.

### Useful list utilities

```python-exec
nums = [5, 2, 8, 2, 9]

print(sum(nums))       # 26
print(min(nums), max(nums))
print(nums.count(2))   # 2 - occurrences
print(nums.index(8))   # 2 - first position (ValueError if missing)

nums.clear()
print(nums)            # []
```

### Tuples: immutable sequences

Tuples are created with parentheses (or just commas) and cannot be changed after creation.

```python-exec
point = (3, 4)
rgb = 255, 128, 0          # parentheses optional
single = (5,)              # one-element tuple needs the comma!

print(point[0], len(rgb))
print(type((5)), type(single))   # <class 'int'> vs <class 'tuple'>

# point[0] = 10            # TypeError - tuples are immutable
```

Why use tuples at all?

- **Safety** &mdash; they can't be modified accidentally.
- **Hashable** &mdash; tuples of hashable items can be dict keys or set members (Chapter 7); lists cannot.
- **Intent** &mdash; a tuple says "this is a fixed record," like `(latitude, longitude)`.

```python-exec
locations = {
    (40.71, -74.00): "New York",
    (51.50, -0.12): "London",
}
print(locations[(51.50, -0.12)])
```

### Unpacking and starred assignment

You saw basic unpacking in Chapter 2. Lists and tuples unpack the same way, and `*` collects the leftovers.

```python-exec
name, age = ("Ada", 36)
print(name, age)

first, *middle, last = [1, 2, 3, 4, 5]
print(first, middle, last)     # 1 [2, 3, 4] 5

# swap, no temp variable:
a, b = 1, 2
a, b = b, a
print(a, b)
```

For records you access often but don't want to unpack, `collections.namedtuple` gives named fields &mdash; a lightweight preview of classes (Chapter 11).

### When which?

- **List** &mdash; a collection you'll grow, shrink, sort, or filter. The default choice.
- **Tuple** &mdash; a fixed-size record, a dict key, or data that must not change.
- Rule of thumb: items of the *same kind* → list; a *record* of different fields → tuple.

### Practice checklist

- [ ] Build a list with `append` and `extend`, then remove items three different ways.
- [ ] Sort a list with `sorted(key=...)` without mutating the original.
- [ ] Demonstrate the aliasing trap, then fix it with a copy.
- [ ] Swap two variables and unpack a list with a starred name.
- [ ] Use a tuple as a dictionary key.

#### Practice 1 - List gym

**Goal:** Practice the core mutation methods.

```python-exec
tasks = ["email", "call"]

# TODO: Append "code", insert "standup" at position 0,
# then remove "call" by value and pop the last item.
# Print the final list.
```

#### Practice 2 - Safe sort

**Goal:** Sort without destroying the original order.

```python-exec
ranking = ["charlie", "al", "bobby"]

# TODO: Print the list sorted alphabetically WITHOUT
# changing `ranking`, then print `ranking` to prove it's
# still in the original order. Then sort by name length.
```

#### Practice 3 - Copy carefully

**Goal:** Fix the aliasing bug.

```python-exec
cart = ["milk", "eggs"]
gift_cart = cart          # TODO: this is an alias - fix it!
gift_cart.append("card")

# After your fix this should print two DIFFERENT lists:
print(cart)
print(gift_cart)
```

#### Practice 4 - Unpack the record

**Goal:** Use tuple unpacking and a starred catch-all.

```python-exec
record = ("Ada", "Lovelace", 1815, "London", "mathematician")

# TODO: Unpack so that `first` is "Ada", `last` is
# "mathematician", and `details` holds everything between.
# Print all three.
```

Next up: key-value data with dictionaries and unique values with sets in Chapter 7.
