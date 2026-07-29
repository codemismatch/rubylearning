---
layout: tutorial
title: "Chapter 11 &ndash; Classes and Objects"
permalink: /courses/python-basics/python-classes/
difficulty: beginner
author: Pankaj Doharey
summary: Define classes with __init__ and self, tell instance from class attributes, add dunder methods like __repr__ and __eq__, inherit sensibly, and meet dataclasses.
theme: pylearning
date: 2026-02-10
previous_tutorial:
  title: "Chapter 10: Modules and the Standard Library"
  url: /courses/python-basics/python-modules/
next_tutorial:
  title: "Chapter 12: Capstone - Build a Word-Counter CLI"
  url: /courses/python-basics/python-basics-project/
related_tutorials:
  - title: "Functions in Python"
    url: /courses/python-basics/python-functions/
  - title: "Capstone: Word-Counter CLI"
    url: /courses/python-basics/python-basics-project/
---

Everything in Python is an object &mdash; just like Ruby. Classes are how you define your own object types, bundling data (attributes) and behavior (methods) together. If you've written a Ruby class, the concepts transfer directly; only the spelling changes.

### Your first class

`class` starts the definition, `__init__` is the constructor (Ruby's `initialize`), and `self` is the explicit receiver &mdash; Python passes it as the first argument instead of hiding it.

```python-exec
class Dog:
    def __init__(self, name, breed):
        self.name = name        # instance attributes - like @name in Ruby
        self.breed = breed

    def describe(self):
        return f"{self.name} is a {self.breed}."

rex = Dog("Rex", "collie")
print(rex.describe())
print(rex.name)                 # attributes are public by default
```

Two rules to internalize: every instance method's first parameter is `self`, and you always write `self.name` to reach instance state &mdash; no bare `@name` shortcuts.

### Instance vs class attributes

Attributes set on `self` belong to one object. Attributes set in the class body are **shared by all instances** &mdash; Ruby's `@@class_var`, but saner.

```python-exec
class Dog:
    species = "Canis familiaris"     # class attribute - shared

    def __init__(self, name):
        self.name = name             # instance attribute - per object

a = Dog("Rex")
b = Dog("Fido")

print(a.species, b.species)          # both see the class attribute
print(a.name, b.name)                # each has its own name

Dog.species = "Good boy"             # change it for everyone
print(a.species, b.species)
```

Classic trap: a *mutable* class attribute shared by everyone.

```python-exec
class Cart:
    items = []          # DANGER: one list shared by all carts!

c1, c2 = Cart(), Cart()
c1.items.append("apple")
print(c2.items)         # ['apple'] - leaked into the other cart!

class CartFixed:
    def __init__(self):
        self.items = [] # a fresh list per instance

c3, c4 = CartFixed(), CartFixed()
c3.items.append("apple")
print(c4.items)         # [] - properly isolated
```

### Dunder methods: making objects behave

"Double underscore" methods hook your class into Python's syntax. You already know `__init__`; the everyday trio is `__repr__`, `__eq__`, and `__len__`.

```python-exec
class Book:
    def __init__(self, title, pages):
        self.title = title
        self.pages = pages

    def __repr__(self):
        return f"Book({self.title!r}, {self.pages})"

    def __eq__(self, other):
        if not isinstance(other, Book):
            return NotImplemented
        return self.title == other.title and self.pages == other.pages

    def __len__(self):
        return self.pages

b1 = Book("Dune", 412)
b2 = Book("Dune", 412)
b3 = Book("Foundation", 255)

print(b1)            # repr used for display (like Ruby's inspect)
print(b1 == b2)      # True - our __eq__ (was identity by default)
print(b1 == b3)      # False
print(len(b1))       # 412
print(b1 in [b2])    # True - uses __eq__
```

`__repr__` should be unambiguous &mdash; ideally something you could paste to recreate the object. `__str__`, when defined, is the friendly version used by `print`.

### Inheritance basics

Subclass with parentheses; `super()` calls the parent's version of a method. Ruby's `<` and `super` &mdash; same ideas.

```python-exec
class Animal:
    def __init__(self, name):
        self.name = name

    def speak(self):
        return "..."

class Cat(Animal):
    def speak(self):
        return "meow"

class Dog(Animal):
    def speak(self):
        base = super().speak()     # "..." from Animal
        return f"woof{base}"

animals = [Cat("Mochi"), Dog("Rex")]
for a in animals:
    print(f"{a.name} says {a.speak()}")

print(isinstance(animals[0], Animal))   # True - subclass passes
print(type(animals[0]).__name__)        # Cat
```

Polymorphism is the payoff: the loop doesn't care which subclass each animal is &mdash; it just calls `speak()`. Prefer small hierarchies; Pythonistas favor composition over deep inheritance trees.

### @property: computed attributes

Ruby lets `obj.name` be a method; Python needs `obj.name()`. `@property` bridges the gap &mdash; a method that looks like an attribute.

```python-exec
class Circle:
    def __init__(self, radius):
        self.radius = radius

    @property
    def diameter(self):
        return self.radius * 2

    @property
    def area(self):
        return 3.14159 * self.radius ** 2

c = Circle(2)
print(c.diameter, f"{c.area:.2f}")   # no parentheses - like attributes

c.radius = 3
print(c.diameter)                    # recomputed on access
```

### dataclasses: classes without the boilerplate

For "bags of data," `@dataclass` writes `__init__`, `__repr__`, and `__eq__` for you. It's the modern default for record-style classes.

```python-exec
from dataclasses import dataclass, field

@dataclass
class Task:
    title: str
    done: bool = False
    tags: list = field(default_factory=list)   # safe mutable default

t1 = Task("Write chapter 11")
t2 = Task("Write chapter 11")

print(t1)                  # readable repr, free
print(t1 == t2)            # True - compares by value, free
t1.tags.append("python")
print(t2.tags)             # [] - no shared-list bug
print(t1)
```

The `field(default_factory=list)` pattern solves the mutable-default trap from earlier in one stroke.

### Python classes vs Ruby classes, quickly

| Ruby | Python |
|------|--------|
| `initialize` | `__init__` |
| `@name` | `self.name` |
| `attr_accessor :name` | just assign `self.name` (attributes are public) |
| `def name` as getter | `@property` |
| `<` for inheritance | `class Child(Parent):` |
| `inspect` | `__repr__` |
| `==` | `__eq__` |

### Practice checklist

- [ ] Define a class with `__init__` and one method; create two instances.
- [ ] Show the shared mutable class-attribute bug, then fix it per-instance.
- [ ] Implement `__repr__` and `__eq__` and test equality of two objects.
- [ ] Override a parent method and call the parent's version with `super()`.
- [ ] Rewrite a record class as a `@dataclass`.

#### Practice 1 - Bank account

**Goal:** Basic class with state and methods.

```python-exec
# TODO: Define class Account with __init__(self, owner,
# balance=0), a deposit(amount) method that adds and
# returns the new balance, and a withdraw(amount) method
# that refuses (prints a warning) when funds are short.
# Create an account, deposit 100, withdraw 30, then try
# to withdraw 200.
```

#### Practice 2 - Comparable books

**Goal:** Dunder methods.

```python-exec
# TODO: Define class Movie with title and year. Give it a
# __repr__ like Movie('Up', 2009) and an __eq__ comparing
# title and year. Create two equal movies and one different
# one; print the results of both comparisons.
```

#### Practice 3 - Shape hierarchy

**Goal:** Inheritance and super().

```python-exec
# TODO: Define class Shape with a name() method returning
# "shape". Subclass it as Square and Circle; each overrides
# name() to return its own name, and Square also defines
# area(side) returning side**2. Loop over instances and
# print each name; print Square().area(4) too.
```

#### Practice 4 - Dataclass refactor

**Goal:** Let dataclass do the work.

```python-exec
from dataclasses import dataclass

# TODO: Define a @dataclass Point with x and y ints,
# plus a method distance_to(other) returning the
# Manhattan distance |dx| + |dy|.
# Print Point(0, 0).distance_to(Point(3, 4))  # expect 7
```

Next up: the capstone &mdash; assemble everything into a word-counter tool in Chapter 12.
