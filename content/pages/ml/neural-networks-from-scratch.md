---
layout: tutorial
title: "Chapter 6 &ndash; Neural Networks from Scratch"
permalink: /courses/machine-learning/neural-networks-from-scratch/
difficulty: intermediate
author: Pankaj Doharey
summary: Build a two-layer neural network in pure Python and watch it learn XOR with backpropagation.
theme: pylearning
previous_tutorial:
  title: "Chapter 5: Logistic Regression & Classification"
  url: /courses/machine-learning/logistic-regression-classification/
next_tutorial:
  title: "Chapter 7: Text Embeddings"
  url: /courses/machine-learning/text-embeddings/
date: 2026-02-10
---

In Chapter 5: Logistic Regression & Classification we trained a single neuron to draw one straight decision boundary. That worked for linearly separable data - but some problems fundamentally cannot be solved with one line. XOR is the classic example: four points, no straight line separates the 0s from the 1s. In this chapter we stack neurons into *layers* so the network can carve out curved boundaries, and we implement the whole thing - forward pass, loss, backpropagation, training - in pure Python. Every example is copy-paste runnable with `python3 file.py`; no libraries required.

### A neuron, revisited

A neuron is just a weighted sum followed by an activation function:

```text
z = w1*x1 + w2*x2 + b
a = activation(z)
```

In logistic regression the activation was the sigmoid, and that single neuron was the entire model. A neural network is what happens when you take several neurons, arrange them in layers, and feed the outputs of one layer as the inputs to the next. The layers between input and output are called *hidden layers*.

Here is the network we will build: 2 inputs, one hidden layer of 4 neurons, 1 output.

#> mermaid: caption="Figure 1: Our 2-4-1 network for XOR"
graph LR
  X1[x1] --> H1[h1]
  X1 --> H2[h2]
  X1 --> H3[h3]
  X1 --> H4[h4]
  X2[x2] --> H1
  X2 --> H2
  X2 --> H3
  X2 --> H4
  H1 --> Y[y]
  H2 --> Y
  H3 --> Y
  H4 --> Y
#!

Every arrow is a weight. Every hidden neuron and the output neuron also has a bias. That gives us 2*4 + 4 = 12 weights and 4 + 1 = 5 biases: 17 numbers to learn.

### Activation functions: relu and sigmoid

Why do we need an activation function at all? Because stacking weighted sums without a nonlinearity between them collapses back into a single weighted sum - a network of linear layers is still just a linear model, and we're back to XOR being impossible. The activation function is what gives the network its power to bend.

Two activations we will use:

- **relu(x) = max(0, x)** - fast, simple, the default choice for hidden layers. Its derivative is 1 for x > 0 and 0 for x <= 0.
- **sigmoid(x) = 1 / (1 + e^-x)** - squashes any number into (0, 1), so it is perfect for the output when we want a probability. Its derivative has a neat closed form: sigmoid'(x) = sigmoid(x) * (1 - sigmoid(x)).

```python
import math

def sigmoid(x):
    return 1.0 / (1.0 + math.exp(-x))

def relu(x):
    return max(0.0, x)

print(sigmoid(0.0))   # 0.5
print(sigmoid(2.0))   # ~0.88
print(relu(-3.0))     # 0.0
print(relu(1.5))      # 1.5
```

### Forward pass with concrete numbers

Before training anything, let's push one input through a tiny fixed network by hand so there is no mystery left. Take input (x1, x2) = (1, 0), and pretend the first hidden neuron has weights w1 = 0.5, w2 = -0.4, bias b = 0.1:

```text
z = 0.5*1 + (-0.4)*0 + 0.1 = 0.6
h1 = relu(0.6) = 0.6
```

Now suppose all four hidden neurons came out to h = [0.6, 0.0, 0.3, 0.9], and the output neuron has weights [0.7, 0.2, -0.5, 0.4] with bias 0.05:

```text
z_out = 0.7*0.6 + 0.2*0.0 + (-0.5)*0.3 + 0.4*0.9 + 0.05
      = 0.42 + 0.0 - 0.15 + 0.36 + 0.05
      = 0.68
y = sigmoid(0.68) = 0.664 (approximately)
```

The network says "about 66% chance this input is a 1." That's the whole forward pass: weighted sums and activations, one layer at a time. Here it is in code:

```python
import math

def sigmoid(x):
    return 1.0 / (1.0 + math.exp(-x))

def relu(x):
    return max(0.0, x)

x1, x2 = 1.0, 0.0

# hidden neuron 1
z = 0.5 * x1 + (-0.4) * x2 + 0.1
h1 = relu(z)
print("h1 =", h1)  # 0.6

# output neuron from all four hidden values
h = [0.6, 0.0, 0.3, 0.9]
w_out = [0.7, 0.2, -0.5, 0.4]
b_out = 0.05
z_out = sum(w * hi for w, hi in zip(w_out, h)) + b_out
y = sigmoid(z_out)
print("y =", y)  # ~0.664
```

### Why XOR defeats a single neuron

XOR's truth table:

```text
x1 x2 | y
0  0  | 0
0  1  | 1
1  0  | 1
1  1  | 0
```

Plot those four points: the 1s sit on opposite corners. No straight line puts the 1s on one side and the 0s on the other, which is exactly why logistic regression fails here. A hidden layer fixes this by learning *intermediate features* - for example, one neuron can learn "is x1 OR x2 on" and another "are both on", and the output neuron combines them: "OR is on AND both-on is off." Curved boundary, problem solved.

### Backpropagation, step by step in plain words

Training means: adjust the 17 numbers so predictions get closer to the targets. Backpropagation is just the chain rule applied to compute, for every weight, *how much does the loss change if I nudge this weight?*

1. **Forward pass.** Compute the prediction y_hat for an input, and the loss. We use mean squared error: loss = (y_hat - y)^2.
2. **Error at the output.** The output neuron's "fault" is d_loss/d_z_out. For MSE plus sigmoid this works out to 2 * (y_hat - y) * y_hat * (1 - y_hat). If the prediction is too high, this term pushes everything that fed it down.
3. **Blame the output weights.** Each output weight w_i contributed to z_out in proportion to the hidden value h_i that flowed through it. So d_loss/d_w_i = error_at_output * h_i. Bigger input through the weight means bigger blame.
4. **Send the error backwards.** Each hidden neuron also shares the blame: the error flowing back into hidden neuron i is error_at_output * w_i. Then multiply by the local derivative of its activation (relu': 1 if z > 0 else 0) to get that neuron's error term.
5. **Blame the input-layer weights.** Same rule as step 3, one layer earlier: d_loss/d_w_ij = hidden_error_i * x_j.
6. **Update.** Every weight moves a small step against its gradient: w = w - learning_rate * d_loss/d_w. Biases update the same way, with gradient equal to the neuron's error term (since d_z/d_b = 1).

That is the entire algorithm. The chain rule in plain words: *the effect of a weight on the loss is the error at its neuron's output, multiplied by whatever that weight was multiplied by during the forward pass.*

### The full XOR network in pure Python

Save this as `xor_network.py` and run `python3 xor_network.py`. It trains the 2-4-1 network and prints the loss falling, then the final predictions.

```python
import math
import random

def sigmoid(x):
    return 1.0 / (1.0 + math.exp(-x))

def relu(x):
    return max(0.0, x)

# --- data ---
X = [[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]]
Y = [0.0, 1.0, 1.0, 0.0]

# --- parameters: 2 -> 4 -> 1 ---
random.seed(42)
W1 = [[random.uniform(-1, 1) for _ in range(2)] for _ in range(4)]  # 4 neurons, 2 inputs
b1 = [0.0] * 4
W2 = [random.uniform(-1, 1) for _ in range(4)]                      # output neuron
b2 = 0.0

lr = 1.0
epochs = 20000

for epoch in range(epochs):
    total_loss = 0.0
    for x, y in zip(X, Y):
        # forward: hidden layer
        z1 = [sum(w * xi for w, xi in zip(wrow, x)) + b for wrow, b in zip(W1, b1)]
        h = [relu(z) for z in z1]
        # forward: output
        z2 = sum(w * hi for w, hi in zip(W2, h)) + b2
        y_hat = sigmoid(z2)

        loss = (y_hat - y) ** 2
        total_loss += loss

        # backward: output error
        d_z2 = 2.0 * (y_hat - y) * y_hat * (1.0 - y_hat)

        # gradients for output weights/bias
        d_W2 = [d_z2 * hi for hi in h]
        d_b2 = d_z2

        # backward: hidden errors (relu derivative: 1 if z > 0 else 0)
        d_z1 = [d_z2 * W2[i] * (1.0 if z1[i] > 0 else 0.0) for i in range(4)]

        # gradients for input weights/biases
        d_W1 = [[d_z1[i] * x[j] for j in range(2)] for i in range(4)]
        d_b1 = d_z1[:]

        # update
        for i in range(4):
            W2[i] -= lr * d_W2[i]
            b1[i] -= lr * d_b1[i]
            for j in range(2):
                W1[i][j] -= lr * d_W1[i][j]
        b2 -= lr * d_b2

    if epoch % 2000 == 0 or epoch == epochs - 1:
        print(f"epoch {epoch:5d}  loss {total_loss:.6f}")

# final predictions
print("\npredictions:")
for x, y in zip(X, Y):
    z1 = [sum(w * xi for w, xi in zip(wrow, x)) + b for wrow, b in zip(W1, b1)]
    h = [relu(z) for z in z1]
    z2 = sum(w * hi for w, hi in zip(W2, h)) + b2
    y_hat = sigmoid(z2)
    print(f"  {x} -> {y_hat:.4f}  (target {y})")
```

A typical run shows the average loss dropping from around 0.7 to under 0.01, and final predictions like:

```text
predictions:
  [0.0, 0.0] -> 0.0231  (target 0.0)
  [0.0, 1.0] -> 0.9785  (target 1.0)
  [1.0, 0.0] -> 0.9790  (target 1.0)
  [1.0, 1.0] -> 0.0244  (target 0.0)
```

Every prediction lands near the right 0 or 1 - the network learned XOR.

### Reading the code against the math

Match the code back to the six backpropagation steps:

- `d_z2` is step 2, the output error.
- `d_W2 = [d_z2 * hi for hi in h]` is step 3: error times the value that flowed through each weight.
- `d_z1 = [d_z2 * W2[i] * relu'...]` is step 4: error flowing backwards through the output weights, scaled by the relu derivative.
- `d_W1[i][j] = d_z1[i] * x[j]` is step 5.
- The update loop is step 6.

One subtlety: we update `W2` *after* computing `d_z1`... actually in the code above the hidden errors use the current `W2` because `d_z1` is computed before the update loop. Order matters - always compute all gradients from the old weights, then update.

### Things to try

- **Learning rate.** Set `lr = 0.1` and watch training crawl; set `lr = 5.0` and watch the loss bounce around or get stuck. There is a sweet spot, and finding it is a real job in practice.
- **Seed.** Change `random.seed(42)` to another number. Occasionally the network gets trapped in a bad local minimum and never learns XOR - that fragility is real too.
- **Sigmoid hidden layer.** Replace relu with sigmoid everywhere (derivative: `h * (1 - h)` using the already-computed activation). It still learns, just slower.
- **More neurons.** Try 8 hidden neurons. XOR becomes almost always solvable, faster.

Now that we can learn nonlinear functions of small inputs, the next question is how to represent *text* as numbers so networks can consume it. That is exactly what Chapter 7: Text Embeddings tackles.

### Practice checklist

- [ ] Explain why stacking linear layers without an activation function is useless.
- [ ] Compute a forward pass by hand for one neuron given weights, bias, and input.
- [ ] State the derivative of sigmoid in terms of the sigmoid output itself.
- [ ] Trace in words how the error reaches a weight in the first layer.
- [ ] Run `xor_network.py` and confirm the loss falls below 0.02.
- [ ] Change the learning rate and observe how training speed and stability change.
- [ ] Swap relu for sigmoid in the hidden layer and compare epochs to converge.
- [ ] Break the gradient order (update W2 before computing d_z1) and see what goes wrong.
