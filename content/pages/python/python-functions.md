---
layout: tutorial
title: "Chapter 4 &ndash; Functions in Python"
permalink: /courses/python-basics/python-functions/
difficulty: beginner
author: Pankaj Doharey
summary: Define functions with def, use default and keyword arguments, *args and **kwargs, return values, lambdas, docstrings, and the LEGB scope rules.
theme: pylearning
previous_tutorial:
  title: "Chapter 3: Control Flow in Python"
  url: /courses/python-basics/python-control-flow/
related_tutorials:
  - title: "Control Flow in Python"
    url: /courses/python-basics/python-control-flow/
  - title: "Introduction to Python"
    url: /courses/python-basics/intro-to-python/
date: 2025-12-23
---

Functions are how you name and reuse a chunk of logic. Python defines them with `def` &mdash; no `end`, just a colon and an indented body.

```python-exec
def greet():
    print("Hello from a function!")

greet()
greet()   # call it as many times as you like
```

One habit to unlearn from Ruby: Python **always requires parentheses** when calling a function. `greet` without `()` refers to the function object itself instead of running it.

### Arguments and parameters

Pass values in, and the parameters bind to them inside the body.

```python-exec
def greet(name):
    print(f"Hello, {name}!")

greet("Ada")
greet("Grace")
```

### Default values and keyword arguments

Parameters can have defaults, making them optional &mdash; and callers can name arguments explicitly for clarity.

```python-exec
def greet(name, greeting="Hello", punctuation="!"):
    print(f"{greeting}, {name}{punctuation}")

greet("Ada")                                  # uses both defaults
greet("Grace", "Hi")                          # override one
greet("Linus", punctuation=".")               # keyword argument
greet(punctuation="?", name="Alan")           # any order when named
```

**Gotcha:** never use a mutable object (like a list) as a default value &mdash; Python evaluates defaults once at definition time, so all calls share the same list. Use `None` and create the list inside:

```python-exec
def add_item(item, items=None):
    if items is None:
        items = []
    items.append(item)
    return items

print(add_item("apple"))
print(add_item("banana"))   # a fresh list each call - correct!
```

### Return values

`return` sends a value back and exits the function. Without an explicit `return`, a function returns `None` (unlike Ruby, there's no implicit "last expression" return).

```python-exec
def square(n):
    return n * n

result = square(7)
print(result)

def no_return():
    print("I say things but return nothing")

print(no_return())   # prints the message, then None
```

### Returning multiple values

Return several values by packing them into a tuple &mdash; callers usually unpack them right away, exactly like Ruby's multiple assignment.

```python-exec
def min_max(numbers):
    return min(numbers), max(numbers)

low, high = min_max([4, 1, 9, 2])
print(f"low={low}, high={high}")
```

### *args and **kwargs

Sometimes you don't know how many arguments you'll get. `*args` collects extra positional arguments into a tuple; `**kwargs` collects extra keyword arguments into a dict (like Ruby's `*splat` and `**double_splat`).

```python-exec
def total(*numbers):
    print("got:", numbers)
    return sum(numbers)

print(total(1, 2, 3))
print(total(10, 20))

def describe(**details):
    for key, value in details.items():
        print(f"{key}: {value}")

describe(name="Ada", role="programmer", born=1815)
```

You can combine everything; the order in the definition must be: normal params, `*args`, keyword-only/defaults, `**kwargs`.

```python-exec
def order(main, *sides, drink="water", **extras):
    print(f"Main: {main}")
    print(f"Sides: {sides}")
    print(f"Drink: {drink}")
    print(f"Extras: {extras}")

order("pizza", "salad", "breadsticks", drink="cola", coupon=True)
```

### Lambda: tiny anonymous functions

A `lambda` creates a one-expression function without a name &mdash; roughly Ruby's `->(x) { x * 2 }`. Lambdas are limited to a single expression; use `def` for anything bigger.

```python-exec
double = lambda x: x * 2
print(double(21))

# Common use: sorting by a computed key
words = ["banana", "fig", "cherry"]
words.sort(key=lambda w: len(w))
print(words)   # ['fig', 'banana', 'cherry']

pairs = [(1, "one"), (3, "three"), (2, "two")]
pairs.sort(key=lambda p: p[0])
print(pairs)
```

### Docstrings

A string literal as the first line of a function becomes its **docstring** &mdash; accessible via `help()` and the `.__doc__` attribute. Python projects document with these instead of comments above the method.

```python-exec
def area(radius):
    """Return the area of a circle with the given radius."""
    return 3.14159 * radius ** 2

print(area(2))
print(area.__doc__)
```

Triple-quoted docstrings can span multiple lines and are the standard way to document functions, classes, and modules.

### Scope and the LEGB rule

When Python resolves a name, it searches four scopes in order &mdash; **L**ocal, **E**nclosing, **G**lobal, **B**uilt-in:

```python-exec
level = "global"          # G - module level

def outer():
    level = "enclosing"   # E - inside outer
    def inner():
        level = "local"   # L - inside inner
        print("inner sees:", level)
    inner()
    print("outer sees:", level)

outer()
print("module sees:", level)
print(len)                # B - built-in names resolve last
```

Assigning inside a function creates a *local* variable by default. To modify a global from inside a function you must declare it with `global` (rarely a good idea) &mdash; and `nonlocal` does the same for enclosing scopes:

```python-exec
count = 0

def bump():
    global count
    count += 1

bump()
bump()
print("count:", count)
```

In practice: pass values in as arguments and return results &mdash; reach for `global` only when you truly must.

### Functions are objects

Functions are first-class citizens: store them in variables, put them in lists, pass them to other functions &mdash; much like Ruby blocks and procs.

```python-exec
def shout(text):
    return text.upper() + "!"

def whisper(text):
    return text.lower() + "..."

def apply_all(funcs, text):
    for f in funcs:
        print(f(text))

apply_all([shout, whisper], "Python")
```

### Practice checklist

- [ ] Write a function with one required and one defaulted parameter; call it three different ways.
- [ ] Write a function that returns two values and unpack them at the call site.
- [ ] Write a function using `*args` that sums any number of inputs.
- [ ] Add a docstring to a function and print it via `.__doc__`.

#### Practice 1 - Greeter with defaults

**Goal:** Practice default and keyword arguments.

```python-exec
# TODO: Define greet(name, greeting="Hello") that prints
# "<greeting>, <name>!". Call it with just a name, then
# with a custom greeting passed as a keyword argument.
```

#### Practice 2 - Stats tuple

**Goal:** Return and unpack multiple values.

```python-exec
# TODO: Define stats(numbers) that returns a tuple of
# (count, total, average). Unpack the result for
# [10, 20, 30, 40] and print all three values.
```

#### Practice 3 - Flexible joiner

**Goal:** Use *args and **kwargs together.

```python-exec
# TODO: Define make_tag(tag, *classes, **attrs) that prints
# the tag name, the tuple of classes, and the dict of attrs.
# Call it like:
#   make_tag("div", "card", "highlight", id="main", hidden=True)
```

#### Practice 4 - Sort by lambda

**Goal:** Use a lambda as a sort key.

```python-exec
people = [("Ada", 36), ("Grace", 85), ("Alan", 41)]

# TODO: Sort the list by age (second element) using
# people.sort(key=lambda ...) and print the result.
# Then sort by name length and print again.
```

You've finished the Python Basics course! From here, explore the standard library (`json`, `datetime`, `pathlib`), try a web framework like Flask, or open a Jupyter notebook and meet pandas.
