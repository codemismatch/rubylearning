---
layout: tutorial
title: "Chapter 19 &ndash; Building a Mini-GPT from Scratch"
permalink: /courses/machine-learning/build-a-mini-gpt/
difficulty: advanced
author: Pankaj Doharey
summary: Assemble embeddings, causal multi-head attention, and a transformer block into a working GPT, train it with hand-written backprop on a tiny corpus, and generate text in the browser.
theme: pylearning
previous_tutorial:
  title: "Chapter 18: How LLMs Work"
  url: /courses/machine-learning/how-llms-work/
date: 2026-03-31
---

This is the capstone. In Chapter 16 you learned embeddings, in Chapter 17 you built causal multi-head attention and the transformer block, and in Chapter 18 you saw the objective that turns the architecture into a language model: predict the next token, score with cross-entropy, improve. Now we assemble all three into a **working GPT** - a real one, with masked attention, residuals, layer norm, an MLP, hand-written backpropagation, and temperature sampling - in pure Python, small enough to train right here in your browser. Nothing is faked and nothing is imported beyond `math` and `random`.

### Designing our mini-GPT

Here is the full architecture we are about to implement and train. It is exactly Chapter 17's transformer block, wrapped in an input embedding stage and an output prediction stage:

#> mermaid: caption="Figure 1: Mini-GPT architecture - one transformer block between embedding and unembedding"
graph TD
  T[Token ids] --> E[Token embedding + position embedding]
  E --> B[Transformer block: masked MHA + FFN + residuals + layernorm]
  B --> L[Final LayerNorm]
  L --> U[Unembedding: project to vocab]
  U --> S[Softmax over next-token probabilities]
#!

Our hyperparameters are tiny so everything runs in the page:

- **d_model = 16** - width of every token vector.
- **n_head = 2** - two attention heads of 8 dimensions each.
- **n_layer = 1** - a single transformer block (real GPTs stack 12-96).
- **d_ff = 32** - the feed-forward network's hidden width.
- **block_size = 16** - the context window: the model sees 16 characters at a time.
- **vocab** - character-level, built from a small corpus of cat-and-dog sentences.

One block and 16-dimensional vectors are laughably small - GPT-2 small has 12 blocks of width 768. But every mechanism is identical. Scale this file up and you get the real thing.

### The tokenizer and training data

We'll work at the character level (real models use subword tokenizers with 30k-100k tokens, but the idea is the same). The corpus is a handful of sentences repeated - small enough that the model can genuinely *memorize* its statistics, which makes the training result easy to interpret. Each code cell below builds on the previous ones, sharing one Python namespace, so run them in order.

Want to train on your own text instead? Upload any `.txt` file here, then re-run the cells below - the tokenizer cell prefers your upload when one is present.

<div data-corpus-upload="uploaded_corpus_text"></div>

```python-exec
# Use your uploaded corpus if present, otherwise the built-in tiny one.
if "uploaded_corpus_text" in dir() and uploaded_corpus_text.strip():
    corpus = uploaded_corpus_text
    print(f"using uploaded corpus ({len(corpus)} chars)")
else:
    corpus = ("the cat sat on the mat and the cat ate the rat. "
              "the dog ran to the log and the dog ate the hog. "
              "a cat and a dog sat on the mat in the sun. "
              "the rat ran and the cat ran after the rat. ") * 3

chars = sorted(set(corpus))
stoi = {c: i for i, c in enumerate(chars)}   # char -> id
itos = {i: c for c, i in stoi.items()}       # id -> char
data = [stoi[c] for c in corpus]
V = len(chars)

print(f"corpus: {len(corpus)} chars, vocab size: {V}")
print("vocab:", "".join(chars))
print("'the cat' as ids:", [stoi[c] for c in "the cat"])
```

### Matrix helpers

Pure Python means lists of lists for matrices. These are the same helpers Chapter 17 used, collected in one place.

```python-exec
import math, random

def dot(a, b):
    return sum(x * y for x, y in zip(a, b))

def matmul(A, B):                    # (m x k) @ (k x n) -> (m x n)
    Bt = [list(col) for col in zip(*B)]
    return [[dot(row, col) for col in Bt] for row in A]

def transpose(A):
    return [list(col) for col in zip(*A)]

def add_rows(A, B):
    return [[a + b for a, b in zip(ra, rb)] for ra, rb in zip(A, B)]

def softmax_rows(M):
    out = []
    for row in M:
        m = max(row)
        exps = [math.exp(x - m) for x in row]
        s = sum(exps)
        out.append([e / s for e in exps])
    return out

def layer_norm_rows(X, eps=1e-5):
    out = []
    for x in X:
        mean = sum(x) / len(x)
        var = sum((v - mean) ** 2 for v in x) / len(x)
        inv = 1.0 / math.sqrt(var + eps)
        out.append([(v - mean) * inv for v in x])
    return out

def rand_matrix(rows, cols, scale):
    return [[random.gauss(0, scale) for _ in range(cols)]
            for _ in range(rows)]

print("helpers ready")
```

### Parameters

The weights are small random matrices. `We` is the token embedding table (one 16-dim vector per character), `Wp` is the learned position table (one per position in the window - unlike Chapter 17's sine waves, GPT learns its positions), and the rest are the attention projections, the feed-forward network, and the unembedding `Wu` that maps back to vocabulary-sized logits.

```python-exec
D, H, FF, T = 16, 2, 32, 16     # d_model, heads, ff width, block size
HD = D // H                      # head dimension
random.seed(42)

params = {}
params['We'] = rand_matrix(V, D, 0.08)     # token embeddings
params['Wp'] = rand_matrix(T, D, 0.08)     # position embeddings
for name in ['Wq', 'Wk', 'Wv', 'Wo']:      # attention projections
    params[name] = rand_matrix(D, D, 0.08)
params['W1'] = rand_matrix(D, FF, 0.08)    # feed-forward up
params['b1'] = [0.0] * FF
params['W2'] = rand_matrix(FF, D, 0.08)    # feed-forward down
params['b2'] = [0.0] * D
params['Wu'] = rand_matrix(D, V, 0.08)     # unembedding
params['bu'] = [0.0] * V

n_params = sum(len(r) if not isinstance(r[0], list)
               else sum(len(row) for row in r)
               for r in params.values())
print(f"total parameters: {n_params}")
```

Just under three thousand parameters - GPT-3's 175 billion is roughly 60 million times more, but shaped from the same parts.

### The forward pass

One pass maps a window of token ids to logits. Note the **causal mask**: position `i` may only attend to positions `<= i` (scores to the future are set to a huge negative number before softmax), because during training every position predicts its own next token and must not peek. The function also stashes every intermediate in `cache` - the backward pass will need them.

```python-exec
def linear(X, W, b=None):
    Y = matmul(X, W)
    if b is not None:
        Y = [[y + bb for y, bb in zip(row, b)] for row in Y]
    return Y

def forward(idx):
    """ids -> (logits, cache). logits[t] scores the token after idx[t]."""
    n = len(idx)
    cache = {'idx': idx}
    # embedding + positional
    X = [[params['We'][idx[t]][j] + params['Wp'][t][j] for j in range(D)]
         for t in range(n)]
    cache['X0'] = X
    # --- transformer block ---
    X1 = layer_norm_rows(X); cache['X1'] = X1
    Q = linear(X1, params['Wq']); K = linear(X1, params['Wk'])
    Vv = linear(X1, params['Wv'])
    cache['Q'], cache['K'], cache['V'] = Q, K, Vv
    attn_full = [[0.0] * D for _ in range(n)]
    cache['A'] = []
    scale = math.sqrt(HD)
    for h in range(H):                       # per-head causal attention
        q = [row[h*HD:(h+1)*HD] for row in Q]
        k = [row[h*HD:(h+1)*HD] for row in K]
        v = [row[h*HD:(h+1)*HD] for row in Vv]
        scores = matmul(q, transpose(k))
        for i in range(n):
            for j in range(n):
                scores[i][j] = -1e9 if j > i else scores[i][j] / scale
        A = softmax_rows(scores)
        cache['A'].append(A)
        out = matmul(A, v)
        for i in range(n):
            attn_full[i][h*HD:(h+1)*HD] = out[i]
    attn = linear(attn_full, params['Wo'])
    cache['attn_full'] = attn_full
    X2 = layer_norm_rows(add_rows(X, attn)); cache['X2'] = X2
    H1pre = linear(X2, params['W1'], params['b1']); cache['H1pre'] = H1pre
    H1 = [[x if x > 0 else 0.0 for x in row] for row in H1pre]
    cache['H1'] = H1
    F = linear(H1, params['W2'], params['b2']); cache['F'] = F
    X3 = layer_norm_rows(add_rows(X2, F)); cache['X3'] = X3
    # --- unembedding to logits ---
    logits = linear(X3, params['Wu'], params['bu'])
    return logits, cache

logits, _ = forward(data[:T])
print(f"input window: {T} tokens -> logits {len(logits)} x {len(logits[0])}")
print("P(next | 't') top-3:",
      sorted(zip(chars, softmax_rows([logits[0]])[0]),
             key=lambda p: -p[1])[:3])
```

The untrained model's distribution is nearly uniform - it has learned nothing yet. Also note the loss function and its gradient: for softmax + cross-entropy, the gradient of the loss with respect to the logits is simply `p - one_hot(target)`, one of the neatest identities in all of ML.

```python-exec
def loss_and_grads(logits, targets):
    """Mean cross-entropy over the window, plus d loss / d logits."""
    n = len(targets)
    P = softmax_rows(logits)
    loss = sum(-math.log(P[t][targets[t]] + 1e-12)
               for t in range(n)) / n
    dlogits = [row[:] for row in P]
    for t in range(n):
        dlogits[t][targets[t]] -= 1.0
        dlogits[t] = [x / n for x in dlogits[t]]
    return loss, dlogits

loss0, _ = loss_and_grads(logits, data[1:T+1])
print(f"untrained loss: {loss0:.4f}  (uniform would be ln({V}) = {math.log(V):.4f})")
```

### Backpropagation through the transformer

This is the cell most tutorials skip - but backprop is just the chain rule applied layer by layer in reverse, using the cached intermediates. The only non-obvious pieces:

- **softmax backward**: if `a = softmax(s)`, then `ds = a * (da - sum(da * a))` per row.
- **layer norm backward**: gradients are centered and de-scaled by the row's variance.
- **linear backward**: for `Y = X @ W`, the gradients are `dW = X^T @ dY` and `dX = dY @ W^T`.

Everything else is routing: residual branches just *add* the incoming gradients of both paths.

```python-exec
def layer_norm_backward(dY, X, eps=1e-5):
    dX = []
    for dy, x in zip(dY, X):
        n = len(x)
        mean = sum(x) / n
        var = sum((v - mean) ** 2 for v in x) / n
        inv = 1.0 / math.sqrt(var + eps)
        xhat = [(v - mean) * inv for v in x]
        d1 = sum(dy) / n
        d2 = sum(d * xh for d, xh in zip(dy, xhat)) / n
        dX.append([inv * (d - d1 - xh * d2) for d, xh in zip(dy, xhat)])
    return dX

def backward(dlogits, cache):
    grads = {}
    idx = cache['idx']; n = len(idx)
    # unembedding
    grads['Wu'] = matmul(transpose(cache['X3']), dlogits)
    grads['bu'] = [sum(col) for col in zip(*dlogits)]
    dX3 = matmul(dlogits, transpose(params['Wu']))
    # final residual + layernorm, then feed-forward
    dRes = layer_norm_backward(dX3, add_rows(cache['X2'], cache['F']))
    dX2, dF = dRes, [row[:] for row in dRes]
    grads['W2'] = matmul(transpose(cache['H1']), dF)
    grads['b2'] = [sum(col) for col in zip(*dF)]
    dH1 = matmul(dF, transpose(params['W2']))
    dH1pre = [[d * (x > 0) for d, x in zip(dr, xr)]
              for dr, xr in zip(dH1, cache['H1pre'])]
    grads['W1'] = matmul(transpose(cache['X2']), dH1pre)
    grads['b1'] = [sum(col) for col in zip(*dH1pre)]
    dX2 = add_rows(dX2, matmul(dH1pre, transpose(params['W1'])))
    # attention residual + layernorm, then output projection
    dRes2 = layer_norm_backward(
        dX2, add_rows(cache['X0'], linear(cache['attn_full'], params['Wo'])))
    dX0, dAttn = dRes2, [row[:] for row in dRes2]
    grads['Wo'] = matmul(transpose(cache['attn_full']), dAttn)
    dAttnFull = matmul(dAttn, transpose(params['Wo']))
    # per-head attention backward
    dQ = [[0.0] * D for _ in range(n)]
    dK = [[0.0] * D for _ in range(n)]
    dV = [[0.0] * D for _ in range(n)]
    scale = math.sqrt(HD)
    for h in range(H):
        A = cache['A'][h]
        q = [row[h*HD:(h+1)*HD] for row in cache['Q']]
        k = [row[h*HD:(h+1)*HD] for row in cache['K']]
        v = [row[h*HD:(h+1)*HD] for row in cache['V']]
        dOut = [row[h*HD:(h+1)*HD] for row in dAttnFull]
        dA = matmul(dOut, transpose(v))
        dv = matmul(transpose(A), dOut)
        dS = []
        for a, da in zip(A, dA):            # softmax backward
            s = sum(d * av for d, av in zip(da, a))
            dS.append([av * (d - s) for av, d in zip(a, da)])
        dS = [[x / scale for x in row] for row in dS]
        dq = matmul(dS, k)
        dk = matmul(transpose(dS), q)
        for i in range(n):
            dQ[i][h*HD:(h+1)*HD] = dq[i]
            dK[i][h*HD:(h+1)*HD] = dk[i]
            dV[i][h*HD:(h+1)*HD] = dv[i]
    grads['Wq'] = matmul(transpose(cache['X1']), dQ)
    grads['Wk'] = matmul(transpose(cache['X1']), dK)
    grads['Wv'] = matmul(transpose(cache['X1']), dV)
    dX1 = add_rows(add_rows(matmul(dQ, transpose(params['Wq'])),
                            matmul(dK, transpose(params['Wk']))),
                   matmul(dV, transpose(params['Wv'])))
    # input layernorm, then scatter gradients into the embedding tables
    dX0 = add_rows(dX0, layer_norm_backward(dX1, cache['X0']))
    grads['We'] = [[0.0] * D for _ in range(V)]
    grads['Wp'] = [[0.0] * D for _ in range(T)]
    for t in range(n):
        for j in range(D):
            grads['We'][idx[t]][j] += dX0[t][j]
            grads['Wp'][t][j] += dX0[t][j]
    return grads

print("backward ready - this is real backprop, no autodiff library")
```

### Training the mini-GPT

Now the training loop: sample a window of 16 tokens, forward, loss, backward, and nudge every parameter with gradient descent. We run 3000 steps with a learning-rate drop partway through, and we record the loss along the way so we can plot it. **This cell is the heavy one - expect roughly 20-30 seconds here, and about a minute in the browser** (Pyodide runs pure Python a few times slower than CPython). Watch the loss fall from `ln(vocab) ~ 2.89` (uniform guessing) toward memorization of the corpus.

```python-exec
lr = 0.1
steps = 3000
history = []                                     # (step, loss) for the plot
for step in range(steps + 1):
    start = (step * 7) % (len(data) - T - 1)      # stride through corpus
    idx = data[start:start + T]
    targets = data[start + 1:start + T + 1]
    logits, cache = forward(idx)
    loss, dlogits = loss_and_grads(logits, targets)
    grads = backward(dlogits, cache)
    for name, p in params.items():                # plain SGD update
        g = grads[name]
        if isinstance(p[0], list):
            for i in range(len(p)):
                for j in range(len(p[0])):
                    p[i][j] -= lr * g[i][j]
        else:
            for j in range(len(p)):
                p[j] -= lr * g[j]
    if step == 2000:
        lr = 0.02                                  # settle into the minimum
    if step % 100 == 0:
        history.append((step, loss))
    if step % 50 == 0 or step == steps:
        progress(step, steps, suffix=f"loss {loss:.4f}")   # PyTorch-style bar, updates in place

# honest evaluation: average loss over the whole corpus
total, nwin = 0.0, 0
for st in range(0, len(data) - T - 1, 8):
    lg, _ = forward(data[st:st + T])
    l, _ = loss_and_grads(lg, data[st + 1:st + T + 1])
    total += l; nwin += 1
print(f"full-corpus loss: {total / nwin:.4f}")
```

The recorded history makes the shape of learning visible - fast early progress, noisy middle, then the learning-rate drop at step 2000 settles it into a much deeper minimum:

```python-exec
plt.plot([s for s, _ in history], [l for _, l in history],
         label="training loss")
plt.title("Mini-GPT training loss (cross-entropy)")
plt.xlabel("step")
plt.ylabel("loss")
plt.show()
```

### Generating text

Generation is the loop from Chapter 18's bigram toy, but with the transformer producing the distribution: feed the last 16 characters, read off the next-token probabilities at the final position, sample (with **temperature** to sharpen or flatten the distribution - dividing logits by a temperature below 1 makes confident choices more likely), append, repeat.

```python-exec
def generate(seed_text, length=120, temperature=0.5):
    random.seed(1)
    idx = [stoi[c] for c in seed_text]
    for _ in range(length):
        logits, _ = forward(idx[-T:])
        row = logits[-1]
        m = max(row)
        exps = [math.exp((x - m) / temperature) for x in row]
        total = sum(exps)
        r = random.random() * total
        c, nxt = 0.0, len(exps) - 1
        for i, e in enumerate(exps):
            c += e
            if r <= c:
                nxt = i
                break
        idx.append(nxt)
    return "".join(itos[i] for i in idx)

print(repr(generate("the cat ", 120, 0.5)))
```

What did it learn? Mostly **memorization** - and that is the correct, explainable result at this scale. With ~2,900 parameters and a corpus of a few hundred characters seen thousands of times, the cheapest way to lower next-token loss is to store the corpus's statistics. Yet look at what memorization required it to learn: character spelling (`mat`, `rat`, `hog`), which words can follow which, and the rhythm of the sentences. It occasionally *recombines* memorized fragments into novel-but-grammatical strings. Scale this exact loop to trillions of tokens and those recombinations become what we call capability - Chapter 18 covers what happens next (pretraining at scale, instruction tuning, RLHF).

### You built the whole path

Step back and look at what you now hold: every piece of a real GPT, written by hand - the embeddings from Chapter 16 turned into learned lookup tables, the attention mechanism from Chapter 17 made causal and stacked into a block with residuals and layer norm, the next-token objective from Chapter 18 wired to a genuine backpropagation pass through all of it, and a sampler that turns logits into text. The gap between this page and GPT-4 is no longer a mystery of mechanism - it is a difference of scale: more layers, wider vectors, trillions of tokens, and thousands of GPUs running the exact loop you just ran.

#> mermaid: caption="Figure 2: The whole course in one pipeline - you implemented every box"
graph LR
  A[Raw text] --> B[Tokenizer]
  B --> C[Embeddings]
  C --> D[Transformer block]
  D --> E[Next-token softmax]
  E --> F[Cross-entropy loss]
  F --> G[Backprop + SGD]
  G --> D
  E --> H[Sampling: generated text]
#!

The best next project is this chapter, done bigger: stack a second transformer block, widen `d_model`, feed it a whole book. You already have every piece.

### Practice checklist

- [ ] Change the seed in `generate` and the temperature (try 0.2 and 1.5); explain the difference in outputs in terms of the softmax distribution.
- [ ] Retrain with `H = 1` (a single attention head) and compare the final loss - what did the second head buy?
- [ ] Increase `T` from 16 to 24 and note how training time changes; why does attention cost grow quadratically with the window?
- [ ] Verify the gradient identity by hand: show that for softmax + cross-entropy, d loss / d logits = `p - one_hot(target)`.
- [ ] Point at the exact line in `forward` that prevents the model from seeing the future, and explain what would leak without it.
- [ ] Plot the loss curve with the learning-rate drop removed (keep `lr = 0.1` throughout) and describe how the shape changes.
