---
layout: tutorial
title: "Bonus &ndash; Backpropagation by Hand"
permalink: /courses/machine-learning/backpropagation-by-hand/
difficulty: intermediate
author: Pankaj Doharey
summary: Differentiate a tiny network on paper and in code at the same time, and internalize the chain rule the way practitioners actually use it.
theme: pylearning
previous_tutorial:
  title: "Chapter 20: MNIST: Recognizing Handwritten Digits"
  url: /courses/machine-learning/mnist-handwritten-digits/
next_tutorial:
  title: "Back to the course index"
  url: /courses/machine-learning/
date: 2026-07-29
---

Every chapter since Chapter 15 has used backpropagation, and every time the gradients appeared as a block of code you had to trust. This chapter removes the trust requirement. We take the smallest network that is still interesting, one hidden neuron with tanh and one output with squared-error loss, and differentiate it twice in parallel: once with pencil-and-paper algebra, once with code that prints every intermediate value. When the two agree, the chain rule stops being notation and becomes reflex.

### The smallest interesting network

#> mermaid: caption="The forward pass as a chain of computations"
graph LR
    X["x"] --> Z1["z1 = w1*x + b1"] --> H["h = tanh(z1)"] --> Z2["z2 = w2*h + b2"] --> L["loss = (z2 - y)^2"]
#!

One input, one hidden neuron, one output. We want the loss's gradient with respect to all four parameters: w1, b1, w2, b2.

Set concrete numbers: x = 1.5, target y = 1.0, and initial weights w1 = 0.8, b1 = 0.1, w2 = 0.5, b2 = -0.2.

```python-exec
import math

x, y = 1.5, 1.0
w1, b1, w2, b2 = 0.8, 0.1, 0.5, -0.2

z1 = w1 * x + b1
h = math.tanh(z1)
z2 = w2 * h + b2
loss = (z2 - y) ** 2
print(f"z1 = {z1:.4f}   h = tanh(z1) = {h:.4f}")
print(f"z2 = {z2:.4f}   loss = {loss:.4f}")
```

### The chain rule, one link at a time

Work backwards from the loss. Each step multiplies the gradient so far by one local derivative:

```text
d loss / d z2  = 2 * (z2 - y)
d loss / d w2  = (d loss / d z2) * h          because z2 = w2*h + b2
d loss / d b2  = (d loss / d z2) * 1
d loss / d h   = (d loss / d z2) * w2
d loss / d z1  = (d loss / d h) * (1 - h^2)   because d tanh/dz = 1 - tanh^2
d loss / d w1  = (d loss / d z1) * x
d loss / d b1  = (d loss / d z1) * 1
```

Now compute each value with the numbers from the forward pass:

```python-exec
d_z2 = 2 * (z2 - y)
d_w2 = d_z2 * h
d_b2 = d_z2
d_h  = d_z2 * w2
d_z1 = d_h * (1 - h ** 2)
d_w1 = d_z1 * x
d_b1 = d_z1

print(f"d loss / d z2 = {d_z2:+.4f}")
print(f"d loss / d w2 = {d_w2:+.4f}   d loss / d b2 = {d_b2:+.4f}")
print(f"d loss / d h  = {d_h:+.4f}    d loss / d z1 = {d_z1:+.4f}")
print(f"d loss / d w1 = {d_w1:+.4f}   d loss / d b1 = {d_b1:+.4f}")
```

### The verification habit: numerical gradients

Never trust a hand-derived gradient you have not checked. The check costs three lines: nudge each parameter by a tiny epsilon, recompute the loss, and divide the change by epsilon. If your analytic gradient and the numerical one agree to several decimals, the algebra is right:

```python-exec
def compute_loss(w1, b1, w2, b2):
    h = math.tanh(w1 * x + b1)
    return (w2 * h + b2 - y) ** 2

eps = 1e-6
num_d_w2 = (compute_loss(w1, b1, w2 + eps, b2) - compute_loss(w1, b1, w2 - eps, b2)) / (2 * eps)
num_d_w1 = (compute_loss(w1 + eps, b1, w2, b2) - compute_loss(w1 - eps, b1, w2, b2)) / (2 * eps)

print(f"analytic d_w2 = {d_w2:.6f}   numerical d_w2 = {num_d_w2:.6f}")
print(f"analytic d_w1 = {d_w1:.6f}   numerical d_w1 = {num_d_w1:.6f}")
```

They match. This trick, called *gradient checking*, is how practitioners debug backprop in real systems: derive by hand, verify numerically on a tiny case, then trust the code at scale.

### One step of gradient descent, felt in the numbers

Update each parameter against its gradient and watch the loss fall:

```python-exec
lr = 0.1
w1n = w1 - lr * d_w1
b1n = b1 - lr * d_b1
w2n = w2 - lr * d_w2
b2n = b2 - lr * d_b2

new_loss = compute_loss(w1n, b1n, w2n, b2n)
print(f"loss before update: {loss:.6f}")
print(f"loss after update:  {new_loss:.6f}")
```

The loss drops because every parameter moved opposite its gradient. That is the entire algorithm. Everything else in deep learning - momentum, Adam, learning-rate schedules - is a refinement of how big that step should be and in what direction.

### The pattern behind every backprop you will ever write

Notice the shape of what we did: forward pass *saves* intermediate values (z1, h, z2), backward pass reuses them, multiplying an incoming gradient by one local derivative at a time. Deep frameworks automate this by recording every operation on a tape and replaying it in reverse (that is what "autograd" means), but the arithmetic is identical to what you just did by hand. When a gradient in a real model looks wrong, the debugging skill is the one from this chapter: pick a tiny case, walk the chain link by link, and gradient-check.

### Where to go next

- **Try it:** add a second hidden neuron and derive d loss / d x. Where does the input gradient get used? (Answer: adversarial examples and saliency maps.)
- **[Autoencoders](/courses/image-generation/autoencoders/)** (Image Generation course) puts the same gradients to work on a stranger target: reconstructing the input itself through a one-number bottleneck.
