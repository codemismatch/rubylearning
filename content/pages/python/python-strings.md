---
layout: tutorial
title: "Chapter 5 &ndash; Strings in Python"
permalink: /courses/python-basics/python-strings/
difficulty: beginner
author: Pankaj Doharey
summary: Slice and index strings, master the everyday methods like split/join/strip/replace, go deeper with f-strings, and learn why immutability matters.
theme: pylearning
date: 2025-12-30
previous_tutorial:
  title: "Chapter 4: Functions in Python"
  url: /courses/python-basics/python-functions/
next_tutorial:
  title: "Chapter 6: Lists and Tuples"
  url: /courses/python-basics/python-lists-tuples/
related_tutorials:
  - title: "Variables in Python"
    url: /courses/python-basics/python-variables/
  - title: "Lists and Tuples"
    url: /courses/python-basics/python-lists-tuples/
---

Strings are the workhorse of almost every program &mdash; log messages, user input, file contents, API responses. Python's `str` type is rich, Unicode-aware, and immutable. This chapter covers the operations you'll reach for daily.

The cells below are editable and share one namespace, so you can tweak any example and re-run it right in the page.

### Indexing: picking out characters

Strings are sequences of characters. Index from 0, or count backwards with negative numbers &mdash; same as Ruby.

```python-exec
word = "Python"

print(word[0])    # P - first character
print(word[1])    # y
print(word[-1])   # n - last character
print(word[-2])   # o - second from the end

print(len(word))  # 6
```

Indexing past the end raises an `IndexError`, but negative indices that stay in range are perfectly fine.

### Slicing: cutting out substrings

The slice syntax `s[start:stop:step]` grabs a range &mdash; `start` inclusive, `stop` exclusive, just like `range()`.

```python-exec
word = "Python"

print(word[0:3])   # Pyt
print(word[2:])    # thon - from index 2 to the end
print(word[:4])    # Pyth - from the start to index 4
print(word[:])     # Python - a full copy
print(word[::2])   # Pto - every second character
print(word[::-1])  # nohtyP - reversed!
```

Unlike indexing, slicing never raises for out-of-range values &mdash; it just stops at the edge. That makes `"anything"[5:]` safe even on short strings.

### Immutability: strings can't change in place

This surprises many Rubyists: in Ruby you can do `s[0] = "J"`, but in Python strings are immutable. Every "modification" returns a *new* string.

```python-exec
name = "python"

# name[0] = "P"             # TypeError: 'str' object does not support item assignment

name = "P" + name[1:]       # build a new string instead
print(name)                 # Python

shout = name.upper()        # methods return new strings
print(shout, name)          # PYTHON Python - original untouched
```

Immutability makes strings safe to use as dictionary keys (Chapter 7) and cheap to share between variables.

### Searching and testing

Check content without any loops: `in`, `startswith`, `endswith`, `find`, `count`.

```python-exec
sentence = "the quick brown fox jumps over the lazy dog"

print("fox" in sentence)          # True - membership test
print("cat" not in sentence)      # True
print(sentence.startswith("the")) # True
print(sentence.endswith("dog"))   # True
print(sentence.find("fox"))       # 16 - index, or -1 if missing
print(sentence.find("cat"))       # -1
print(sentence.count("the"))      # 2
```

Ruby's `include?`, `start_with?`, and `index` map to `in`, `startswith`, and `find`. Note `find` returns `-1` when missing; its stricter sibling `index` raises `ValueError` instead.

### Splitting and joining

`split` chops a string into a list; `join` glues a list back into a string. These two are inseparable in real code.

```python-exec
csv = "apple,banana,cherry"
fruits = csv.split(",")           # -> list
print(fruits)

line = "one  two   three"
print(line.split())               # splits on any run of whitespace
print("a-b-c".split("-", 1))      # ['a', 'b-c'] - split at most once

print(" | ".join(fruits))         # apple | banana | cherry
print("".join(["P", "y"]))        # Py
```

The `join` direction feels backwards at first &mdash; the *separator* is the object, the list is the argument: `", ".join(items)`. Think of it as "the comma joins these items."

### Cleaning and replacing

`strip` trims whitespace (or given characters) from the ends; `replace` swaps substrings; `lstrip`/`rstrip` work on one side only.

```python-exec
messy = "   hello world   \n"
print(repr(messy.strip()))        # 'hello world'
print(repr(messy.rstrip()))       # trailing only

path = "/usr/local/bin/"
print(path.strip("/"))            # usr/local/bin - strips given chars

text = "I like ruby and ruby is fun"
print(text.replace("ruby", "python"))         # both occurrences
print(text.replace("ruby", "python", 1))      # only the first
```

### Case and classification helpers

```python-exec
print("hello world".title())      # Hello World
print("HELLO".lower())            # hello
print("hello".upper())            # HELLO
print("hELLO".swapcase())         # Hello

print("abc".isalpha())            # True - only letters
print("123".isdigit())            # True - only digits
print("abc123".isalnum())         # True - letters and digits
print("   ".isspace())            # True
```

These classifiers are great for validating input before you convert it.

### f-strings, deeper

You met f-strings in Chapter 2. Now the format-spec mini-language: alignment, padding, numbers, and dates all go after the `:`.

```python-exec
name = "Ada"
score = 91.456

print(f"[{name:>10}]")     # right-align in 10 chars
print(f"[{name:<10}]")     # left-align
print(f"[{name:^10}]")     # center
print(f"[{name:*^10}]")    # center, padded with *

print(f"{score:.1f}")      # 91.5 - one decimal
print(f"{1234567:,}")      # 1,234,567 - thousands separator
print(f"{0.852:.0%}")      # 85% - percentage
print(f"{255:x}")          # ff - hex
print(f"{42:05d}")         # 00042 - zero-padded width 5
```

Handy debugging shortcut (Python 3.8+): a trailing `=` prints the expression and its value.

```python-exec
x, y = 3, 4
print(f"{x=}, {y=}, {x * y=}")   # x=3, y=4, x * y=12
```

### When f-strings aren't enough: format() and %

Older code uses `str.format()` or the even older `%` operator. You'll see both in the wild, but for new code prefer f-strings.

```python-exec
print("{} + {} = {}".format(2, 3, 5))
print("{a} then {b}".format(a="first", b="second"))
print("%s is %d years old" % ("Ada", 36))   # legacy style
```

### Common gotchas

- **`+` in loops is slow.** Each `+` copies the whole string. Collect parts in a list and `"".join(parts)` at the end.
- **`==` vs `is`.** Always compare strings with `==`. `is` checks identity and only sometimes appears to work due to interning.
- **Case matters.** `"Python" == "python"` is `False`; normalize with `.lower()` or `.casefold()` before comparing user input.

```python-exec
# Fast concatenation pattern
words = ["python", "is", "fun"]
print(" ".join(words))

# Case-insensitive comparison
answer = "YES"
print(answer.casefold() == "yes")   # True
```

### Practice checklist

- [ ] Reverse a string with slicing and grab every second character.
- [ ] Split a CSV line, transform each item, and join it back with a different separator.
- [ ] Use `startswith`/`endswith` to filter a small list of filenames.
- [ ] Format a number three ways with f-strings (decimals, thousands, percent).
- [ ] Demonstrate immutability by "changing" a string into a new one.

#### Practice 1 - Slicing warmup

**Goal:** Extract and reverse parts of a string.

```python-exec
word = "comprehension"

# TODO: Print the first 5 characters, the last 4 characters,
# and the whole string reversed, using slices only.
```

#### Practice 2 - CSV round trip

**Goal:** Split, clean, and rejoin.

```python-exec
row = "  alice , bob ,carol,  dave "

# TODO: Split on commas, strip whitespace from each name,
# then print the names joined with " | ".
# Hint: a loop or a small helper can strip each item.
```

#### Practice 3 - File filter

**Goal:** Pick files by extension.

```python-exec
files = ["notes.txt", "photo.png", "todo.txt", "song.mp3", "app.py"]

# TODO: Loop over `files` and print only the ones ending
# in ".txt". Then print how many there were.
```

#### Practice 4 - Report line

**Goal:** Produce one neatly formatted line.

```python-exec
student = "grace hopper"
points = 87.654

# TODO: Print a line like:
# "GRACE HOPPER | score:  87.7 | rank: #001"
# using f-strings: uppercase the name, one decimal for the
# score (width 5), and zero-padded rank 1 to width 3.
```

Next up: ordered collections &mdash; lists and tuples &mdash; in Chapter 6.
