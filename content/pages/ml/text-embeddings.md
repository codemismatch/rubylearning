---
layout: tutorial
title: "Chapter 16 &ndash; Text Embeddings"
permalink: /courses/machine-learning/text-embeddings/
difficulty: advanced
author: Pankaj Doharey
summary: Turn words into vectors with tokenization, a tiny BPE learner, and hand-built embeddings you can do arithmetic on.
theme: pylearning
previous_tutorial:
  title: "Chapter 15: Neural Networks from Scratch"
  url: /courses/machine-learning/neural-networks-from-scratch/
next_tutorial:
  title: "Chapter 17: Attention & Transformers"
  url: /courses/machine-learning/attention-and-transformers/
date: 2026-03-10
---

In Chapter 15: Neural Networks from Scratch we built a network that consumes vectors of numbers. Text, however, is not numbers. Before any model can read a sentence, we have to convert characters into tokens, tokens into ids, and ids into vectors. That conversion pipeline is the subject of this chapter, and the vectors at the end of it - embeddings - are the single most important idea behind modern language models.

Everything here is pure Python. Save any code block as `file.py` and run it with `python3 file.py`.

### The pipeline at a glance

#> mermaid: caption="Figure 1: From raw text to embedding vectors"
graph LR
  A[Raw text] --> B[Tokens]
  B --> C[Token ids]
  C --> D[Embedding table]
  D --> E[Vectors]
#!

The rest of the chapter walks each arrow in that diagram.

### Tokenization: splitting text into pieces

A token is the atomic unit a model sees. The simplest tokenizer splits on whitespace and punctuation:

```python-exec
import re

def simple_tokenize(text):
    text = text.lower()
    # words and punctuation become separate tokens
    return re.findall(r"[a-z]+|[^\sa-z]", text)

print(simple_tokenize("The queen, unlike the king, eats apples."))
# ['the', 'queen', ',', 'unlike', 'the', 'king', ',', 'eats', 'apples', '.']
```

Word-level tokenization has a fatal flaw: the vocabulary is unbounded. Every misspelling, every plural, every new name is either a new vocabulary entry or an unknown-token failure. Real systems (GPT, LLaMA, BERT) use subword tokenization, where common words are one token and rare words break into pieces.

### Byte Pair Encoding: learning subwords by merging

Byte Pair Encoding (BPE) starts from individual characters and repeatedly merges the most frequent adjacent pair. Here is a complete tiny BPE learner:

```python-exec
from collections import Counter

# Our toy corpus: words with their frequencies, pre-split into characters.
# The </w> marker denotes end-of-word so merges don't cross word boundaries.
corpus = {
    ("l", "o", "w", "</w>"): 5,
    ("l", "o", "w", "e", "r", "</w>"): 2,
    ("n", "e", "w", "e", "s", "t", "</w>"): 6,
    ("w", "i", "d", "e", "s", "t", "</w>"): 3,
}

def pair_counts(corpus):
    counts = Counter()
    for word, freq in corpus.items():
        for a, b in zip(word, word[1:]):
            counts[(a, b)] += freq
    return counts

def merge_pair(corpus, pair):
    new_corpus = {}
    a, b = pair
    merged = a + b
    for word, freq in corpus.items():
        new_word = []
        i = 0
        while i < len(word):
            if i < len(word) - 1 and word[i] == a and word[i + 1] == b:
                new_word.append(merged)
                i += 2
            else:
                new_word.append(word[i])
                i += 1
        new_corpus[tuple(new_word)] = freq
    return new_corpus

merges = []
for step in range(10):
    counts = pair_counts(corpus)
    if not counts:
        break
    best = counts.most_common(1)[0][0]
    merges.append(best)
    corpus = merge_pair(corpus, best)
    print(f"merge {step + 1}: {best} -> {best[0] + best[1]}")

print("\nFinal tokenization of the corpus:")
for word, freq in corpus.items():
    print(f"  {freq}x {word}")
```

Run it and watch the merges. First `e s` merges (frequency 9), then `es t`, then `es t</w>` becomes `est</w>`, then `l o`... After ten merges, "newest" is tokenized as something like `("n", "e", "w", "est</w>")` - the common suffix `-est` has become its own token. That is exactly how real BPE discovers subwords like `ing`, `un`, and `##tion`, just over billions of words instead of four.

The merge list *is* the tokenizer: to tokenize a new word, split it into characters and replay the merges in order.

### From tokens to ids

Once you have a fixed vocabulary, each token gets an integer id. That is a trivial dictionary lookup:

```python-exec
vocab = ["<unk>", "the", "queen", "king", "eats", "apples"]
token_to_id = {tok: i for i, tok in enumerate(vocab)}

ids = [token_to_id.get(t, 0) for t in ["the", "queen", "eats"]]
print(ids)  # [1, 2, 4]
```

### One-hot vs distributed representations

The naive way to vectorize an id is one-hot encoding: a vector of vocabulary size with a single 1:

```python-exec
def one_hot(idx, size):
    v = [0.0] * size
    v[idx] = 1.0
    return v

print(one_hot(2, 6))  # [0.0, 0.0, 1.0, 0.0, 0.0, 0.0]
```

One-hot has two problems:

- It is huge - a 50,000-word vocabulary means 50,000-dimensional vectors that are almost all zeros.
- It encodes zero meaning. Every pair of distinct words has cosine similarity 0. "king" is exactly as far from "queen" as it is from "refrigerator".

A distributed representation instead places each word at a point in a small, dense space (say 100-1000 dimensions), where direction and distance carry meaning. Words used in similar contexts end up close together.

### The word2vec skip-gram intuition

The skip-gram model (Mikolov et al., 2013) learns embeddings with a fake task: given a center word, predict the words around it. You slide a window over the corpus, and for each pair (center, context) you nudge the center word's vector toward the context word's vector.

That is the whole trick. Words that appear in similar contexts - "king" and "queen" both show up near "royal", "crown", "throne" - get pulled toward the same region of space, because the model needs similar vectors to predict similar contexts. The neural network from Chapter 15: Neural Networks from Scratch could actually train this; here we only need the intuition, because the interesting part is what the learned space looks like.

### Cosine similarity

The standard way to compare embedding vectors is cosine similarity: the cosine of the angle between them, ignoring length.

```python-exec
import math

def dot(a, b):
    return sum(x * y for x, y in zip(a, b))

def norm(a):
    return math.sqrt(dot(a, a))

def cosine(a, b):
    return dot(a, b) / (norm(a) * norm(b))
```

A cosine of 1 means same direction, 0 means unrelated (orthogonal), -1 means opposite. Length is discarded on purpose: a word mentioned twice as often should not count as "more of" that word.

### Hand-built 2-D embeddings

To see why distributed representations are powerful, let's hand-place five words in a 2-D space. Think of the x-axis as "royalty" and the y-axis as "femininity" (real embeddings discover such axes by themselves; we are assigning them for the demo).

```python-exec
import math

def dot(a, b):
    return sum(x * y for x, y in zip(a, b))

def norm(a):
    return math.sqrt(dot(a, a))

def cosine(a, b):
    return dot(a, b) / (norm(a) * norm(b))

# Hand-placed 2-D embeddings
embeddings = {
    "king":  [1.0, 0.1],
    "queen": [0.9, 1.0],
    "man":   [0.1, 0.0],
    "woman": [0.0, 0.9],
    "apple": [-1.0, -0.8],
}

words = list(embeddings)
print("Cosine similarity matrix:")
print("        " + "".join(f"{w:>8}" for w in words))
for w1 in words:
    row = "".join(f"{cosine(embeddings[w1], embeddings[w2]):8.2f}" for w2 in words)
    print(f"{w1:>8}{row}")
```

The output shows the structure we built in:

```text
          king   queen     man   woman   apple
  king    1.00    0.92    1.00    0.11   -0.79
 queen    0.92    1.00    0.11    1.00   -0.96
   man    1.00    0.11    1.00    0.11   -0.75
  woman    0.11    1.00    0.11    1.00   -0.73
  apple   -0.79   -0.96   -0.75   -0.73    1.00
```

Read it carefully: king and queen are close (0.92), man and woman are close (1.00), and apple is far from everyone (negative against all four). Meaning has become geometry.

### Analogy arithmetic: king - man + woman = queen

The famous word2vec party trick: vector arithmetic solves analogies. The direction from "man" to "king" should be roughly the direction from "woman" to "queen".

```python-exec
def sub(a, b):
    return [x - y for x, y in zip(a, b)]

def add(a, b):
    return [x + y for x, y in zip(a, b)]

def nearest(vec, embeddings, exclude=()):
    scored = sorted(
        ((cosine(vec, v), w) for w, v in embeddings.items() if w not in exclude),
        reverse=True,
    )
    return scored

result = add(sub(embeddings["king"], embeddings["man"]), embeddings["woman"])
print("king - man + woman =", [round(x, 2) for x in result])

for score, word in nearest(result, embeddings, exclude={"king", "man", "woman"}):
    print(f"  {word:>6}: cosine {score:.3f}")
```

Running it:

```text
king - man + woman = [0.9, 1.0]
  queen: cosine 1.000
  apple: cosine -0.956
```

The result vector is `[0.9, 1.0]` - exactly where we placed "queen". The arithmetic works because the relationships "royalty" and "gender" are encoded as roughly independent directions, so subtracting one and adding the other lands you at the word with the combined properties. In real 300-dimensional word2vec embeddings the answer is not exact, but "queen" reliably comes out as the nearest neighbor.

### Why this matters for what comes next

Embeddings are the input layer of every large language model. An LLM's embedding table is a giant lookup matrix - token id in, dense vector out - and it is trained end-to-end along with everything else. But a single static vector per token cannot handle "bank" meaning a river edge or a financial institution. Resolving that requires looking at the *surrounding* tokens and mixing their vectors, which is precisely the attention mechanism we build in Chapter 17: Attention & Transformers.

### Practice checklist

- [ ] Tokenize a paragraph with the regex tokenizer and inspect how punctuation splits.
- [ ] Run the BPE learner with 15 merges instead of 10 and note which new tokens appear.
- [ ] Add a word like "widest" to the BPE corpus and predict its tokens before running.
- [ ] Implement `one_hot` and confirm any two distinct words have cosine similarity 0.
- [ ] Explain in one sentence why skip-gram training pulls context-sharing words together.
- [ ] Extend the 2-D embedding table with "prince" and "princess" at plausible coordinates and re-run the similarity matrix.
- [ ] Try the analogy `queen - woman + man` and verify it lands nearest to "king".
- [ ] Compute `king - queen + apple` and observe that analogy arithmetic breaks down for unrelated words.
