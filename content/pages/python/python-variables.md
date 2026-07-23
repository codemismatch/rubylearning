---
layout: tutorial
title: "Chapter 2 &ndash; Variables in Python"
permalink: /courses/python-basics/python-variables/
difficulty: beginner
author: Pankaj Doharey
summary: Master Python assignment, the core built-in types, casting between them, naming rules, multiple assignment, and f-strings.
theme: pylearning
previous_tutorial:
  title: "Chapter 1: Introduction to Python"
  url: /courses/python-basics/intro-to-python/
next_tutorial:
  title: "Chapter 3: Control Flow in Python"
  url: /courses/python-basics/python-control-flow/
related_tutorials:
  - title: "Introduction to Python"
    url: /courses/python-basics/intro-to-python/
  - title: "Functions in Python"
    url: /courses/python-basics/python-functions/
date: 2025-12-09
---

A variable in Python is simply a name that refers to an object. You create one by assigning a value with `=` &mdash; no declaration, no type annotation required, just like Ruby.

```python-exec
message = "Hello, variables!"
print(message)
```

Unlike Ruby, there is no `@` or `$` sigil prefix &mdash; instance variables, globals, and locals all look the same at first glance; context decides their scope (we'll cover scope in Chapter 4).

### Assignment basics

Assignment binds a name to an object. Reassigning just rebinds the name; the old object is forgotten if nothing else refers to it.

```python-exec
score = 10
print("score:", score)

score = score + 5   # same as: score += 5
print("score:", score)

score += 10         # augmented assignment works for +=, -=, *=, /=...
print("score:", score)
```

One operator Python 3.8 added that Ruby doesn't have: the "walrus" operator `:=`, which assigns *inside* an expression. You'll see it later; beginners can safely ignore it for now.

### The core types

Python's everyday built-in types cover the same ground as Ruby's:

| Python type | Example | Ruby cousin |
|-------------|---------|-------------|
| `int` | `42` | `Integer` |
| `float` | `3.14` | `Float` |
| `str` | `"hello"` | `String` |
| `bool` | `True`, `False` | `true`, `false` |
| `NoneType` | `None` | `nil` |

```python-exec
count = 42            # int
price = 9.99          # float
name = "Python"       # str
is_fun = True         # bool - capital T!
nothing = None        # NoneType - Python's nil

print(count, price, name, is_fun, nothing)
```

Two gotchas for Rubyists: booleans are capitalized (`True`/`False`, not `true`/`false`), and `nil` is spelled `None`.

### Inspecting types with type() and isinstance()

`type()` tells you the class of a value; `isinstance()` checks it, like Ruby's `.is_a?`.

```python-exec
value = 3.14
print(type(value))                 # <class 'float'>
print(isinstance(value, float))    # True
print(isinstance(value, int))      # False

# Note: booleans are a subclass of int in Python!
print(isinstance(True, int))       # True (quirky but true)
```

### Division and integer arithmetic

Division always returns a float in Python 3, even when the numbers divide evenly. Use `//` for floor division and `%` for remainder.

```python-exec
print(10 / 2)    # 5.0  - always a float
print(7 / 2)     # 3.5
print(7 // 2)    # 3    - floor division
print(7 % 2)     # 1    - remainder
print(2 ** 10)   # 1024 - exponent, like Ruby's **
```

### Casting between types

Python won't guess for you &mdash; convert explicitly with `int()`, `float()`, `str()`, and `bool()`. These mirror Ruby's `to_i`, `to_f`, and `to_s`.

```python-exec
age_text = "30"
age = int(age_text)      # string -> int
print(age + 5)           # 35

print(float("2.5") * 2)  # 5.0
print(str(99) + " red balloons")
print(bool(""))          # False - empty string is falsy
print(bool("anything"))  # True

# int("3.5") would raise ValueError - go through float first:
print(int(float("3.5")))  # 3
```

Unlike Ruby's forgiving `"3abc".to_i #=> 3`, Python raises a `ValueError` when a string isn't a clean number. Explicit and strict &mdash; very Pythonic.

### Naming rules

- Names may contain letters, digits, and underscores, but may not start with a digit.
- Convention is `snake_case` for variables and functions &mdash; same as Ruby.
- `UPPER_SNAKE_CASE` is used for constants (Python has no enforced constants; it's purely a convention).
- Reserved keywords (`if`, `for`, `class`, `def`, `None`, ...) can't be used as names.

```python-exec
user_name = "grace"      # good
MAX_RETRIES = 3          # constant by convention
# 2fast = "no"           # SyntaxError - can't start with a digit
# class = "no"           # SyntaxError - reserved keyword
print(user_name, MAX_RETRIES)
```

### Multiple assignment and swapping

Python lets you assign several variables in one line using tuple unpacking &mdash; and it makes swapping values a one-liner (no temporary variable needed, just like Ruby's `a, b = b, a`).

```python-exec
x, y, z = 1, 2, 3
print(x, y, z)

a, b = 10, 20
a, b = b, a          # swap!
print("a:", a, "b:", b)

# Unpacking from a list works too:
first, *rest = [1, 2, 3, 4]
print(first, rest)   # 1 [2, 3, 4]
```

### f-strings: interpolation the Python way

f-strings (Python 3.6+) are the counterpart of Ruby's `"#{...}"` interpolation &mdash; put an `f` before the quote and embed expressions in braces.

```python-exec
name = "Ada"
language = "Python"
year = 1991

print(f"{name} loves {language}, born in {year}.")
print(f"Next year it turns {2024 - year + 1}!")     # expressions work
print(f"Pi is roughly {3.14159:.2f}")               # formatting: 2 decimals
```

You can interpolate any expression inside the braces, and add a format spec after a colon (`.2f` = two decimal places, `>10` = right-align in width 10, and so on).

### Practice checklist

- [ ] Create variables of each core type and print them with `type()`.
- [ ] Convert a numeric string to an int, do math with it, and convert the result back to a string.
- [ ] Swap two variables in a single line and print both before and after.
- [ ] Build a sentence with an f-string that includes a calculation inside the braces.

#### Practice 1 - Types tour

**Goal:** Show the type of four different values.

```python-exec
# TODO: Create an int, a float, a string, and a boolean,
# then print each value alongside its type.
# Example: print(my_int, type(my_int))
```

#### Practice 2 - Cast and calculate

**Goal:** Turn text into numbers and do arithmetic.

```python-exec
price_text = "19.99"
quantity_text = "3"

# TODO: Convert both strings to numbers, compute the total
# cost, and print something like "Total: 59.97".
```

#### Practice 3 - The great swap

**Goal:** Swap two variables without a temporary variable.

```python-exec
left = "tea"
right = "coffee"

# TODO: Swap the values of `left` and `right` in one line,
# then print both to confirm left holds "coffee".
```

#### Practice 4 - f-string sentence

**Goal:** Build a sentence with interpolation and formatting.

```python-exec
name = "Ada"
birth_year = 1815

# TODO: Print a sentence like
# "Ada was born in 1815 and would be 210 years old in 2025."
# using one f-string, computing the age inside the braces.
current_year = 2025
```

Next up: make decisions and repeat work with control flow in Chapter 3.
