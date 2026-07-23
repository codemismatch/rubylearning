---
layout: tutorial
title: "Chapter 3 &ndash; Control Flow in Python"
permalink: /courses/python-basics/python-control-flow/
difficulty: beginner
author: Pankaj Doharey
summary: Branch with if/elif/else, loop with while and for over range(), steer loops with break/continue, and meet match/case and Python's truthiness rules.
theme: pylearning
previous_tutorial:
  title: "Chapter 2: Variables in Python"
  url: /courses/python-basics/python-variables/
next_tutorial:
  title: "Chapter 4: Functions in Python"
  url: /courses/python-basics/python-functions/
related_tutorials:
  - title: "Variables in Python"
    url: /courses/python-basics/python-variables/
  - title: "Functions in Python"
    url: /courses/python-basics/python-functions/
---

Control flow is how a program decides what to do next: run this block, skip that one, repeat these lines. Python's tools will look familiar if you know Ruby &mdash; with two twists: blocks are marked by indentation, and `elsif` is spelled `elif`.

### if, elif, else

A colon ends the condition, and the indented lines below form the block. There is no `end`.

```python-exec
temperature = 22

if temperature > 30:
    print("It's hot out!")
elif temperature > 15:
    print("Pleasant weather.")
else:
    print("Bring a jacket.")
```

Conditions don't need parentheses (though they're allowed). Comparison operators are the usual `==`, `!=`, `<`, `<=`, `>`, `>=`, combined with the English words `and`, `or`, `not` &mdash; Python spells out what Ruby writes as `&&`, `||`, `!`.

```python-exec
age = 25
has_ticket = True

if age >= 18 and has_ticket:
    print("Enjoy the show!")

if not has_ticket:
    print("Buy a ticket first.")  # not reached
```

### Indentation rules (the important part)

- Use **4 spaces per level**, consistently. Don't mix tabs and spaces.
- Every line at the same level belongs to the same block.
- A nested block needs another level of indentation.
- A one-liner is allowed: `if age >= 18: print("adult")` &mdash; but multi-line is clearer.

```python-exec
score = 88

if score >= 90:
    grade = "A"
else:
    if score >= 80:        # nested if - deeper indent
        grade = "B"
    else:
        grade = "C"

print(f"Score {score} -> grade {grade}")
```

### Truthiness: what's "false" in Python?

In Ruby only `nil` and `false` are falsy. Python's falsy club is bigger: `False`, `None`, `0`, `0.0`, `""` (empty string), `[]` (empty list), `{}` (empty dict), and `set()`. Everything else is truthy.

```python-exec
values = [0, "", [], None, "hello", 42, [0]]

for v in values:
    if v:
        print(f"{v!r} is truthy")
    else:
        print(f"{v!r} is falsy")
```

The `!r` in the f-string asks for the "repr" of the value so empty strings and `None` print visibly. Because emptiness is falsy, the idiomatic check is `if items:` rather than `if len(items) > 0:`.

### while loops

`while` repeats as long as its condition stays true &mdash; same idea as Ruby's `while`.

```python-exec
countdown = 5

while countdown > 0:
    print(f"T-minus {countdown}")
    countdown -= 1

print("Liftoff!")
```

### for loops and range()

Python's `for` always iterates *over something* &mdash; a list, a string, a range. There is no C-style `for (i = 0; i < n; i++)`; instead you use `range()`, which behaves like Ruby's `(0...n)`.

```python-exec
for i in range(5):          # 0, 1, 2, 3, 4
    print(f"i = {i}")

for n in range(2, 11, 2):   # start, stop (exclusive), step
    print(f"even: {n}")

for ch in "abc":            # strings are iterable too
    print(ch)
```

`range(start, stop, step)` produces numbers from `start` up to (but not including) `stop`. Looping directly over a collection is the common case:

```python-exec
languages = ["Python", "Ruby", "Go"]

for lang in languages:
    print(f"{lang} is fun!")

for index, lang in enumerate(languages):   # need the index too?
    print(f"{index}: {lang}")
```

`enumerate()` is Python's answer to Ruby's `each_with_index`.

### break, continue, and the loop else

- `break` exits the loop immediately.
- `continue` skips to the next iteration.
- Python also has a lesser-known trick: an `else` on a loop runs **only if the loop finished without `break`** &mdash; handy for "search and not found" logic.

```python-exec
for n in range(10):
    if n == 3:
        continue          # skip 3
    if n == 6:
        break             # stop at 6
    print(n, end=" ")
print()                   # prints: 0 1 2 4 5

# Loop-else: find a number divisible by 7
candidates = [10, 12, 15, 18]
for c in candidates:
    if c % 7 == 0:
        print(f"Found {c}")
        break
else:
    print("No multiple of 7 found")   # runs because no break happened
```

### match/case (Python 3.10+)

Python's structural pattern matching is the counterpart of Ruby's `case/in`. It can match literals, capture variables, and even unpack structures.

```python-exec
command = "quit"

match command:
    case "start":
        print("Starting...")
    case "stop" | "quit":            # | means "or"
        print("Shutting down.")
    case _:                          # _ is the catch-all
        print(f"Unknown command: {command}")
```

Matching on shapes is where it gets powerful:

```python-exec
point = (0, 5)

match point:
    case (0, 0):
        print("Origin")
    case (0, y):
        print(f"On the Y-axis at y={y}")
    case (x, 0):
        print(f"On the X-axis at x={x}")
    case (x, y):
        print(f"Somewhere at ({x}, {y})")
```

If your Python is older than 3.10, `match` won't exist &mdash; stick with `if`/`elif` chains there.

### Ternary expressions

Python's one-line conditional reads almost like English: `value_if_true if condition else value_if_false` (Ruby's `cond ? a : b`).

```python-exec
age = 20
status = "adult" if age >= 18 else "minor"
print(status)
```

### Practice checklist

- [ ] Write an `if`/`elif`/`else` chain with at least three branches.
- [ ] Print the numbers 1 to 10 with a `while` loop, then again with `for` + `range()`.
- [ ] Use `continue` to skip the even numbers and `break` to stop early.
- [ ] Try a `match`/`case` that handles at least two cases plus a catch-all.

#### Practice 1 - Grade classifier

**Goal:** Map a numeric score to a letter grade.

```python-exec
score = 73

# TODO: Print "A" for 90+, "B" for 80-89, "C" for 70-79,
# "D" for 60-69, and "F" below 60, using if/elif/else.
```

#### Practice 2 - FizzBuzz warmup

**Goal:** Classic loop practice.

```python-exec
# TODO: Loop over range(1, 16). For each number print
# "Fizz" if divisible by 3, "Buzz" if divisible by 5,
# "FizzBuzz" if divisible by both, otherwise the number.
```

#### Practice 3 - Search with loop-else

**Goal:** Find a value, and report when it's missing.

```python-exec
names = ["ada", "grace", "edsger"]
target = "guido"

# TODO: Loop over `names`; if you find `target`, print
# "Found!" and break. Use a loop `else` to print
# "Not in the list" when the loop ends without a break.
```

#### Practice 4 - Command dispatcher

**Goal:** Route commands with match/case (Python 3.10+).

```python-exec
command = "help"

# TODO: Use match/case to print a message for "start",
# "stop", and "help", with a catch-all case _ that prints
# "Unknown command". Try changing `command` to test each.
```

Next up: package your logic into reusable units with functions in Chapter 4.
