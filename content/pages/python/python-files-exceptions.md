---
layout: tutorial
title: "Chapter 9 &ndash; Files and Exceptions"
permalink: /courses/python-basics/python-files-exceptions/
difficulty: beginner
author: Pankaj Doharey
summary: Handle errors with try/except/else/finally, raise your own exceptions, and read and write text files safely with the with statement.
theme: pylearning
date: 2026-01-27
previous_tutorial:
  title: "Chapter 8: Comprehensions and Iteration"
  url: /courses/python-basics/python-comprehensions/
next_tutorial:
  title: "Chapter 10: Modules and the Standard Library"
  url: /courses/python-basics/python-modules/
related_tutorials:
  - title: "Control Flow in Python"
    url: /courses/python-basics/python-control-flow/
  - title: "Modules and the Standard Library"
    url: /courses/python-basics/python-modules/
---

Programs meet the messy real world through two doors: files (data that might be missing or malformed) and exceptions (errors that must not crash everything). Python's tools for both are elegant &mdash; and the browser editor below lets you practice file handling safely using in-memory files.

### The anatomy of try/except

Wrap risky code in `try`, and name the errors you're prepared to handle in `except`.

```python-exec
raw = "42a"

try:
    number = int(raw)
    print("parsed:", number)
except ValueError:
    print(f"'{raw}' is not a number - using 0")
    number = 0

print("program continues with", number)
```

Catch **specific** exceptions. A bare `except:` swallows everything &mdash; including bugs you never meant to hide &mdash; and is considered bad style, just like a bare `rescue` in Ruby.

### Handling several error types

```python-exec
def divide(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        print("can't divide by zero")
    except TypeError as err:
        print("wrong types:", err)

print(divide(10, 2))     # 5.0
print(divide(10, 0))     # message, then None
print(divide("10", 2))   # message, then None
```

`except SomeError as err` binds the exception object so you can inspect its message.

### else and finally

- `else` runs only when the `try` block **succeeded** &mdash; keeps the happy path separate.
- `finally` runs **no matter what** &mdash; cleanup like closing resources.

```python-exec
def parse_age(text):
    try:
        age = int(text)
    except ValueError:
        print("not a number")
        return None
    else:
        print(f"parsed successfully: {age}")
        return age
    finally:
        print("(finally always runs)")

parse_age("36")
print("---")
parse_age("abc")
```

### The exception zoo: types you'll meet

| Exception | Raised when |
|-----------|-------------|
| `ValueError` | right type, wrong value (`int("abc")`) |
| `TypeError` | wrong type entirely (`"2" + 3`) |
| `KeyError` | missing dict key |
| `IndexError` | list index out of range |
| `FileNotFoundError` | opening a file that isn't there |
| `ZeroDivisionError` | `x / 0` |
| `AttributeError` | calling a method an object doesn't have |

```python-exec
boom = [
    lambda: int("nope"),
    lambda: [1][5],
    lambda: {}["missing"],
    lambda: 1 / 0,
]

for f in boom:
    try:
        f()
    except Exception as err:
        print(f"{type(err).__name__}: {err}")
```

`Exception` is the base class of normal errors &mdash; catching it is acceptable at a program's top level, but inside library code, stay specific.

### Raising your own exceptions

Use `raise` when your function's contract is violated &mdash; Ruby's `raise` with the same name.

```python-exec
def set_age(age):
    if not isinstance(age, int):
        raise TypeError("age must be an int")
    if age < 0 or age > 150:
        raise ValueError(f"unrealistic age: {age}")
    return age

print(set_age(36))

try:
    set_age(-5)
except ValueError as err:
    print("rejected:", err)
```

For application-specific errors, subclass `Exception` (a taste of Chapter 11):

```python-exec
class InsufficientFundsError(Exception):
    """Raised when a withdrawal exceeds the balance."""

def withdraw(balance, amount):
    if amount > balance:
        raise InsufficientFundsError(f"need {amount}, have {balance}")
    return balance - amount

try:
    print(withdraw(100, 250))
except InsufficientFundsError as err:
    print("declined:", err)
```

### EAFP vs LBYL

Ruby (and Python) culture prefers **EAFP** &mdash; *Easier to Ask Forgiveness than Permission*: try the operation, handle failure. The opposite, **LBYL** (*Look Before You Leap*), checks preconditions first.

```python-exec
config = {"host": "localhost"}

# LBYL - check first:
if "port" in config:
    port = config["port"]
else:
    port = 8080

# EAFP - just try:
try:
    port = config["port"]
except KeyError:
    port = 8080

print("port:", port)
```

EAFP avoids race conditions (the file could vanish between your check and your open) and often reads better. Both are valid; Pythonistas lean EAFP.

### The with statement: files that close themselves

`with` guarantees cleanup &mdash; the file closes even if an exception happens mid-block. It's Python's context manager protocol; think of it as Ruby's `File.open(...) do |f|` block form.

In a real script you'd write `open("notes.txt")`. In this browser-based editor, real files aren't available, so we'll use `io.StringIO` &mdash; an in-memory file object that behaves exactly the same and supports `with`.

```python-exec
import io

# Writing (StringIO starts empty; with a real file use open("notes.txt", "w"))
out = io.StringIO()
with out as f:
    f.write("line one\n")
    f.write("line two\n")
print("closed?", out.closed)

# Reading it back - fresh StringIO holding that content
content = "line one\nline two\n"
with io.StringIO(content) as f:
    for line in f:
        print(repr(line))
```

Key file facts that carry over to real `open()`:

- `open(path, "r")` reads (default), `"w"` **truncates and writes**, `"a"` appends.
- Iterating a file yields lines, newline included &mdash; that's why `repr` shows `\n`, and why `.strip()` is your friend.
- `f.read()` slurps the whole file; `f.readline()` takes one line.

### A realistic pattern: parse with forgiveness

Combining files + EAFP + specific handling is what production code looks like:

```python-exec
import io

data = io.StringIO("alice,30\nbob,notanumber\ncarol,25\n")

records = []
with data as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        name, age_text = line.split(",")
        try:
            age = int(age_text)
        except ValueError:
            print(f"skipping {name}: bad age {age_text!r}")
            continue
        records.append((name, age))

print(records)
```

Skip bad rows, keep good ones, never crash &mdash; that's the goal.

### Practice checklist

- [ ] Catch a specific exception and let the program continue.
- [ ] Use `else` for the success path and `finally` for cleanup.
- [ ] Raise `ValueError` from your own function and catch it at the call site.
- [ ] Rewrite a LBYL membership check in EAFP style.
- [ ] Write lines to an in-memory file with `with` and read them back.

#### Practice 1 - Safe parser

**Goal:** try/except with a fallback.

```python-exec
inputs = ["10", "20", "oops", "40"]

# TODO: Parse each string to int, replacing unparseable
# values with 0 (print a warning for those). Print the
# final list of ints and their sum.
```

#### Practice 2 - Validate and raise

**Goal:** Raise your own error.

```python-exec
# TODO: Define check_username(name) that raises ValueError
# if the name is shorter than 3 characters, and returns the
# name otherwise. Test it with "ab" (catch and print the
# error) and with "ada" (print the returned name).
```

#### Practice 3 - File round trip

**Goal:** Write then read with `with`.

```python-exec
import io

# TODO: Using io.StringIO() with a `with` block, write three
# lines: "red", "green", "blue". Then read the content back
# from a new io.StringIO containing those lines and print
# each line uppercased, without trailing newlines.
```

#### Practice 4 - Robust average

**Goal:** Combine everything.

```python-exec
import io

grades_file = io.StringIO("90\n75\nabc\n\n82\n")

# TODO: Read numeric grades line by line. Skip blank lines
# and non-numeric lines (warn about those). Print the count
# of valid grades and their average.
# Expected: 3 grades, average 82.333...
```

Next up: organize code and stand on giants' shoulders with modules and the standard library in Chapter 10.
