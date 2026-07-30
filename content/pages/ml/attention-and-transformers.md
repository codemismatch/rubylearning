---
layout: tutorial
title: "Chapter 17 &ndash; Attention & Transformers"
permalink: /courses/machine-learning/attention-and-transformers/
difficulty: advanced
author: Pankaj Doharey
summary: Build self-attention from scratch in pure Python and understand the transformer block that powers every modern LLM.
theme: pylearning
previous_tutorial:
  title: "Chapter 16: Text Embeddings"
  url: /courses/machine-learning/text-embeddings/
next_tutorial:
  title: "Chapter 18: How LLMs Work"
  url: /courses/machine-learning/how-llms-work/
date: 2026-03-17
---

### Why sequence models are hard

In Chapter 16: Text Embeddings we turned words into vectors. A sentence, then, is a list of vectors. But a bag of vectors loses the one thing that makes language language: order and context. "The dog bit the man" and "The man bit the dog" contain exactly the same words, yet mean very different things. A good sequence model has to read each word *in the light of every other word*.

The older approaches each had a fatal flaw:

- Feed-forward networks see a fixed window. Word 1 can never influence how we interpret word 50.
- Recurrent networks process tokens one at a time, passing a hidden state forward. Information from token 1 has to survive 49 squeezes through the same bottleneck to reach token 50. In practice it fades - this is the long-range dependency problem.
- RNNs also can't be parallelized: you must finish token *t* before starting token *t+1*, which makes training on huge text corpora painfully slow.

Attention fixes both problems at once. Every token looks directly at every other token - one hop, no bottleneck - and the whole thing is just matrix math that runs in parallel. The transformer, introduced in the 2017 paper "Attention Is All You Need", stacks this idea into the architecture that every modern LLM (GPT, Llama, Claude) is built from. By the end of this chapter you will have computed attention by hand and implemented it in pure Python.

### Self-attention: queries, keys, and values

The core idea: each token should build a new representation of itself by mixing in information from the other tokens - weighted by how *relevant* they are.

To compute relevance, every token gets three vectors, all derived from its embedding by learned weight matrices:

- **Query (Q)** - "what am I looking for?"
- **Key (K)** - "what do I contain?"
- **Value (V)** - "what do I actually pass along if you attend to me?"

The attention recipe for one token:

1. Take its query, and dot it with every token's key → raw **scores**.
2. Scale the scores (divide by sqrt of the key dimension) so softmax doesn't saturate.
3. Softmax the scores → weights that sum to 1.
4. Take the weighted sum of all tokens' **values** → the token's new, context-aware representation.

### A worked example with tiny numbers

Let's do the arithmetic with 2 tokens and 2-dimensional vectors, so you can verify every step with pen and paper.

Token 1 ("cat"): embedding, query, key, value are all tiny vectors:

- q1 = [1, 0], k1 = [1, 0], v1 = [1, 2]

Token 2 ("sat"):

- q2 = [0, 1], k2 = [0, 1], v2 = [3, 4]

(In a real model, q/k/v come from multiplying the embedding by learned matrices Wq, Wk, Wv. Here we just pick numbers so the math is visible.)

**Step 1 - scores for token 1.** Its query q1 against both keys:

- score(q1, k1) = 1*1 + 0*0 = 1
- score(q1, k2) = 1*0 + 0*1 = 0

**Step 2 - scale.** Divide by sqrt(2) ≈ 1.4142:

- 1 / 1.4142 ≈ 0.7071
- 0 / 1.4142 = 0

**Step 3 - softmax.** exp(0.7071) ≈ 2.0281, exp(0) = 1. Sum = 3.0281.

- weight on token 1: 2.0281 / 3.0281 ≈ 0.6697
- weight on token 2: 1 / 3.0281 ≈ 0.3303

**Step 4 - weighted sum of values:**

- output_1 = 0.6697 * [1, 2] + 0.3303 * [3, 4]
- = [0.6697, 1.3394] + [0.9909, 1.3212]
- = [1.6606, 2.6606]

Token 1's new representation is a blend: 67% itself, 33% "sat". Do the same for token 2 (its query matches its own key perfectly and k1 not at all, so you get the mirrored weights) and every token now encodes its context.

### Self-attention in pure Python

Save this as `attention.py` and run it with `python3 attention.py`. It uses only `math.sqrt` and `math.exp` - no libraries at all. Every example in this chapter is copy-paste runnable with `python3 file.py`.

```python-exec
import math

def dot(a, b):
    return sum(x * y for x, y in zip(a, b))

def softmax(xs):
    m = max(xs)                 # subtract max for numerical stability
    exps = [math.exp(x - m) for x in xs]
    total = sum(exps)
    return [e / total for e in exps]

def self_attention(Q, K, V):
    """Q, K, V: lists of token vectors. Returns one output vector per token."""
    d = len(K[0])
    scale = math.sqrt(d)
    outputs = []
    for q in Q:
        scores = [dot(q, k) / scale for k in K]
        weights = softmax(scores)
        out = [sum(w * v[i] for w, v in zip(weights, V)) for i in range(d)]
        outputs.append(out)
    return outputs

# The worked example from the text
Q = [[1, 0], [0, 1]]
K = [[1, 0], [0, 1]]
V = [[1, 2], [3, 4]]

for token, out in zip(["cat", "sat"], self_attention(Q, K, V)):
    print(token, "->", [round(x, 4) for x in out])
```

Run it and you should see:

```python
# cat -> [1.6605, 2.6605]
# sat -> [2.3395, 3.3395]
```

The code prints approximately 1.6605 rather than our hand-rounded 1.6606 because it uses the full precision of sqrt(2). That's the whole mechanism. Scale Q, K, V up to hundreds or thousands of dimensions and many tokens, add learned matrices to produce Q, K, V, and you have the beating heart of a transformer language model.

Here is the data flow for a single attention head:

#> mermaid: caption="Figure 1: Self-attention from embeddings to output"
graph TD
  E[Token embeddings] --> Q[Queries Q]
  E --> K[Keys K]
  E --> V[Values V]
  Q --> S[Scores = Q * K^T / sqrt d]
  K --> S
  S --> SM[Softmax over scores]
  SM --> W[Weighted sum of V]
  V --> W
  W --> O[Output: context-aware vectors]
#!

### Multi-head attention: parallel views

One attention head gives every token one way to look at the others. But language has many kinds of relationships at once: subject-verb agreement, pronoun references, phrase boundaries, sentiment. A single softmax has to average all of those into one set of weights, which blurs them.

Multi-head attention runs several attention heads in parallel, each with its own Wq, Wk, Wv matrices (usually on smaller slices of the vector - 8 heads on a 512-dim model means 64 dims per head). Each head is free to specialize: one head might learn "attend to the previous word", another "attend to the subject of the sentence". The head outputs are concatenated and passed through one more linear layer.

In code terms, it's just our function in a loop:

```python-exec
def multi_head_attention(Qs, Ks, Vs):
    """Qs, Ks, Vs: one (Q, K, V) triple per head."""
    head_outputs = [self_attention(Q, K, V) for Q, K, V in zip(Qs, Ks, Vs)]
    # Concatenate heads token-wise
    n_tokens = len(head_outputs[0])
    return [
        [x for head in head_outputs for x in head[token]]
        for token in range(n_tokens)
    ]

# Two toy heads on the same tokens
Qs = [[[1, 0], [0, 1]], [[1, 1], [1, -1]]]
Ks = [[[1, 0], [0, 1]], [[1, 0], [0, 1]]]
Vs = [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]

for row in multi_head_attention(Qs, Ks, Vs):
    print([round(x, 4) for x in row])
```

Each output row is now 4 numbers: head 1's 2-dim output glued to head 2's. Real transformers do exactly this, then apply a final weight matrix to mix the heads back together.

### Positional encoding: injecting order

Here's a subtle but crucial point: attention is *permutation-invariant*. Shuffle the input tokens and each output just shuffles along with it - the mechanism itself has no idea which token came first. "dog bit man" really would look like "man bit dog".

The transformer's fix is positional encoding: before attention ever runs, we add a position vector to each token's embedding. Now the embeddings themselves carry order, and attention can learn position-dependent patterns (e.g., "mostly attend to nearby tokens").

The original paper uses sine and cosine waves of different frequencies:

- For position `pos` and dimension `i`: even dimensions get sin(pos / 10000^(2i/d)), odd dimensions get cos(pos / 10000^(2i/d)).

In words: each dimension oscillates at a different wavelength, from very fast (dimension 0 changes every step) to very slow. Together they give every position a unique "fingerprint", and because waves are smooth and periodic, relative distances between positions show up as consistent patterns the model can learn. Here's the idea in a few lines:

```python-exec
import math

def positional_encoding(pos, d):
    return [
        math.sin(pos / 10000 ** (2 * (i // 2) / d)) if i % 2 == 0
        else math.cos(pos / 10000 ** (2 * (i // 2) / d))
        for i in range(d)
    ]

for pos in range(4):
    print(pos, [round(x, 3) for x in positional_encoding(pos, 4)])
```

Notice position 0 is [0, 1, 0, 1] and each later position shifts the pattern - unique, smooth, and computable for any length without learning anything. Modern models often use learned position vectors or rotary variants instead, but the motivation is identical: order must be injected, because attention alone is blind to it.

### The transformer block

A full transformer stacks identical blocks. Each block takes a sequence of vectors and returns a sequence of the same shape:

1. **Multi-head self-attention** - tokens exchange information.
2. **Add & norm** - add the block's input back to the attention output (a *residual connection*), then layer-normalize. Residuals let gradients flow through dozens of stacked blocks without vanishing.
3. **Feed-forward network** - a small MLP (two linear layers with a nonlinearity, typically expanding to 4x the width and shrinking back) applied to each token independently. This is where the model does its "thinking" per position; attention routes information, the MLP processes it.
4. **Add & norm** again.

As a diagram:

#> mermaid: caption="Figure: One transformer block - attention and feed-forward, each wrapped in a residual connection plus layer norm"
graph LR
  X[x] --> MHA[Multi-head attention]
  MHA --> A1((+))
  X --> A1
  A1 --> LN1[LayerNorm]
  LN1 --> FF[Feed-forward]
  FF --> A2((+))
  LN1 --> A2
  A2 --> LN2[LayerNorm]
  LN2 --> OUT[out]
#!

A toy pure-Python block (relu for the nonlinearity, plain mean/variance layer norm) looks like this:

```python-exec
import math

def relu(x):
    return x if x > 0 else 0.0

def layer_norm(xs, eps=1e-5):
    mean = sum(xs) / len(xs)
    var = sum((x - mean) ** 2 for x in xs) / len(xs)
    return [(x - mean) / math.sqrt(var + eps) for x in xs]

def feed_forward(xs, W1, b1, W2, b2):
    hidden = [relu(sum(w * x for w, x in zip(row, xs)) + b)
              for row, b in zip(W1, b1)]
    return [sum(w * h for w, h in zip(row, hidden)) + b
            for row, b in zip(W2, b2)]

def transformer_block(X, Qs, Ks, Vs, W1, b1, W2, b2):
    attn = multi_head_attention(Qs, Ks, Vs)
    X = [layer_norm([a + b for a, b in zip(x, a)]) for x, a in zip(X, attn)]
    ff = [feed_forward(x, W1, b1, W2, b2) for x in X]
    return [layer_norm([a + b for a, b in zip(x, f)]) for x, f in zip(X, ff)]
```

Stack many of these blocks, put an embedding layer plus positional encoding in front and a prediction layer on top, and you have the architecture we'll dissect next in Chapter 18: How LLMs Work. Everything else - scale, training data, and engineering refinements - builds on this skeleton.

### Practice checklist

- [ ] Recompute the worked example by hand: scores, scaling by sqrt(2), softmax, and the weighted sum for token 2, and confirm it matches `attention.py`'s output.
- [ ] Modify `attention.py` to use 3 tokens and verify the attention weights for each token sum to 1.
- [ ] Change token 2's key so token 1 attends to it almost exclusively; predict the output before running the code.
- [ ] Print per-head outputs in `multi_head_attention` and confirm concatenation order matches the text.
- [ ] Compute `positional_encoding` for positions 0-5 and convince yourself each position's fingerprint is unique.
- [ ] Explain in one sentence why attention alone cannot distinguish "dog bit man" from "man bit dog".
- [ ] Sketch the transformer block from memory: attention, add & norm, feed-forward, add & norm.
