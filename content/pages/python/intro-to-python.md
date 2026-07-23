---
layout: tutorial
title: "Chapter 1 &ndash; Introduction to Python"
permalink: /courses/python-basics/intro-to-python/
difficulty: beginner
author: Pankaj Doharey
summary: Meet Python, install it, run your first programs from the REPL and from script files, and see why it dominates scripting, data, and machine learning.
theme: pylearning
next_tutorial:
  title: "Chapter 2: Variables in Python"
  url: /courses/python-basics/python-variables/
related_tutorials:
  - title: "Variables in Python"
    url: /courses/python-basics/python-variables/
  - title: "Control flow in Python"
    url: /courses/python-basics/python-control-flow/
---

Python is a high-level, interpreted language that prizes readability above almost everything else. If you already know a little Ruby, Python will feel like a close cousin: both are dynamic, object-oriented, and friendly to beginners. The big philosophical difference is that Python prefers "one obvious way to do it," while Ruby celebrates having many ways.

### Why Python?

- **Readable syntax** &mdash; blocks are defined by indentation instead of `end` keywords.
- **Batteries included** &mdash; a huge standard library for files, networking, dates, math, and more.
- **Everywhere** &mdash; scripting, web backends (Django, Flask, FastAPI), data science (pandas, NumPy), and machine learning (PyTorch, TensorFlow, scikit-learn).

### Installing Python

Most macOS and Linux systems ship with some version of Python, but you usually want a current one. Check what you have:

```bash
python3 --version
```

If that prints `Python 3.x` you're set. If not:

- **macOS:** `brew install python3` or download from [python.org](https://www.python.org/downloads/).
- **Windows:** install from python.org, and tick "Add python.exe to PATH".
- **Linux:** use your package manager, e.g. `sudo apt install python3`.

Always use `python3` (and `pip3`) explicitly &mdash; the bare `python` command on older systems may still point to Python 2, which reached end-of-life in 2020.

### The REPL: your interactive playground

Type `python3` with no arguments and you land in the **REPL** (Read-Eval-Print Loop). It's like Ruby's `irb`: type an expression, hit Enter, see the result immediately.

```bash
$ python3
Python 3.12.2 (main, Feb  6 2024, 20:19:44)
>>> 2 + 3
5
>>> "hello" * 3
'hellohellohello'
>>> exit()
```

The REPL is perfect for quick experiments. For anything longer than a few lines, you'll want a script file.

### Your first program

Create a file called `hello.py`:

```python-exec
print("Hello, Python!")
print("I was written in a file and run as a script.")
```

Run it from your terminal:

```bash
python3 hello.py
```

Two things to notice already:

- `print()` is Python's equivalent of Ruby's `puts` &mdash; it prints its argument plus a newline.
- There are no braces, no `end` keywords, and (unlike Ruby) semicolons are neither needed nor welcome.

### Indentation is syntax

Python uses consistent indentation &mdash; conventionally four spaces &mdash; to mark code blocks. This is the first thing that trips up Rubyists, because `end` simply doesn't exist.

```python-exec
# A simple conditional - note the 4-space indent.
name = "Ada"

if name == "Ada":
    print("Hello, Ada!")     # inside the if-block
    print("Welcome back.")   # still inside
print("Done.")               # back outside the block
```

Get the indentation wrong and Python raises an `IndentationError`. The upside: every Python program you read is formatted the same way, which is a big part of why Python code is famously easy to read.

### Dynamic typing, Python flavor

Like Ruby, Python is dynamically typed: variables don't declare a type, and the same name can hold different kinds of values over its lifetime.

```python-exec
value = 42           # an integer
print(value, type(value))

value = 3.14         # now a float
print(value, type(value))

value = "forty-two"  # now a string
print(value, type(value))
```

`type()` returns the class of the object &mdash; the Python counterpart of Ruby's `.class`. One caution: Python is *strongly* typed, so it won't silently coerce for you. `"2" + 3` raises a `TypeError` (Ruby would also complain, but JavaScript would not). You'll see how to convert explicitly in the next chapter.

### Where Python shines

- **Scripting and automation** &mdash; glue scripts, file processing, quick CLI tools.
- **Web backends** &mdash; Django (batteries-included, like Rails), Flask and FastAPI (lean, like Sinatra).
- **Data science** &mdash; pandas, NumPy, and Jupyter notebooks are the industry default.
- **Machine learning** &mdash; PyTorch, TensorFlow, and scikit-learn make Python the lingua franca of AI.
- **Education** &mdash; its clean syntax makes it the most-taught first language in the world.

### Comments and the Zen of Python

Comments start with `#`, just like Ruby. And if you ever want a laugh (and some genuine wisdom), ask Python about its philosophy:

```python-exec
import this
```

`import this` prints the "Zen of Python" by Tim Peters &mdash; nineteen aphorisms like "Explicit is better than implicit" that capture the language's personality.

### Practice checklist

- [ ] Confirm `python3 --version` works on your machine and report the version.
- [ ] Open the REPL, evaluate a few expressions, and exit cleanly.
- [ ] Write a `hello.py` script and run it with `python3 hello.py`.
- [ ] Deliberately mis-indent a line and observe the `IndentationError`.

#### Practice 1 - Say hello

**Goal:** Print a greeting that includes your name.

```python-exec
# TODO: Create a variable `name` with your name,
# then print "Hello, <name>!" using print().
```

#### Practice 2 - Inspect some types

**Goal:** Use `type()` to reveal the class of three different values.

```python-exec
# TODO: Assign three values (a number, some text, a decimal)
# to variables, then print each value together with its type,
# e.g. print(value, type(value)).
```

#### Practice 3 - Fix the indentation

**Goal:** The code below has a broken indent. Fix it so it runs.

```python-exec
language = "Python"

if language == "Python":
print("Great choice!")   # TODO: indent this line to fix the error
    print("See you in the next chapter.")
```

Next up: learn how Python variables, types, and f-strings work in Chapter 2.
