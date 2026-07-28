---
layout: tutorial
title: "Chapter 18 &ndash; How LLMs Work"
permalink: /courses/machine-learning/how-llms-work/
difficulty: advanced
author: Pankaj Doharey
summary: From the transformer to GPT - pretraining, scaling laws, RLHF, prompting, and why LLMs sometimes confidently get things wrong.
theme: pylearning
previous_tutorial:
  title: "Chapter 17: Attention & Transformers"
  url: /courses/machine-learning/attention-and-transformers/
next_tutorial:
  title: "Chapter 19: Building a Mini-GPT from Scratch"
  url: /courses/machine-learning/build-a-mini-gpt/
date: 2026-03-24
---

In Chapter 17: Attention & Transformers we built the architecture: self-attention, multi-head attention, positional encodings, and stacked transformer blocks. That machinery answers the question "how does the model process a sequence?" This final chapter answers the bigger question: "how does that architecture become a capable assistant?" The surprising answer is that much of the behavior is not in the architecture alone - it comes from the training objective, scale, data, and post-training steps that turn a raw text predictor into a helpful system.

We will keep everything in plain words, with one tiny pure-Python toy at the end that shows the seed of the whole idea.

### From transformer to GPT

A decoder-only transformer (the GPT family) is the architecture from the previous chapter with one simplification: it only looks left. Each position can attend to itself and everything before it, never to the future. That restriction exists for one reason - the training task is **next-token prediction**:

- Take a chunk of text: `the cat sat on the`
- The model outputs a probability distribution over every token in its vocabulary.
- The correct answer is `mat`.
- Adjust the weights so `mat` gets a slightly higher probability next time.

That is the entire pretraining objective. No labels, no humans annotating anything - the text supervises itself. Every sentence on the internet is a free training example, because the "label" (the next token) is already there.

A **token** is usually not a whole word. Modern tokenizers split text into subword pieces, so `unbelievable` might become `un`, `believ`, `able`. A typical vocabulary is 30,000-100,000 tokens. When people say a model has "175 billion parameters", they mean the weights of the attention layers and feed-forward networks inside the stacked transformer blocks - the numbers that get nudged, one gradient step at a time, to make next-token predictions better.

### What "a loss on text" means

Remember cross-entropy loss from the earlier chapters on classification? Next-token prediction is classification with a vocabulary-sized number of classes. For each position, the model produces a probability for every token; the loss is the negative log of the probability it assigned to the actual next token.

- If the model gives the true next token probability 0.9, the loss is about 0.105 - small, good.
- If it gives the true token probability 0.01, the loss is about 4.6 - large, bad.

Average that over billions of token positions and you get one number: the pretraining loss. When you read that a run "trained for 2.38 nats" or reports a perplexity, this is what is being measured. **Perplexity** is just exp(loss) - roughly, "on average the model is as uncertain as if it were choosing uniformly among this many tokens". A perplexity of 20 means the model has effectively narrowed the next token down to about 20 plausible candidates.

The deep, non-obvious fact of the field is this: pushing this single number down - getting better at predicting the next token of ordinary text - forces the model to learn grammar, facts, reasoning patterns, code syntax, and a great deal more. To predict what comes after "The capital of France is", you need to know geography. Prediction is compression, and compression requires understanding.

### Pretraining at scale

Pretraining means running that next-token loop over a giant corpus - hundreds of billions to trillions of tokens of web pages, books, and code - on thousands of GPUs for weeks or months. The result is called a **base model**. A base model is not an assistant. Given "How do I make pancakes?" it is as likely to continue with "is a question many people ask" or a list of more questions as it is to give a recipe, because it is mimicking text, not helping you.

#> mermaid: caption="Figure 1: The LLM pipeline from raw text to deployed assistant"
graph LR
  A[Raw text] --> B[Pretraining]
  B --> C[Base model]
  C --> D[Instruction tuning and RLHF]
  D --> E[Assistant]
  E --> F[Prompting and deployment]
#!

### Scaling laws: why bigger keeps working

One of the most important empirical discoveries in modern ML is that next-token loss falls **predictably** as you scale up three ingredients together:

- **Parameters** - a bigger model (more transformer blocks, wider layers).
- **Data** - more training tokens.
- **Compute** - more GPU-hours to actually run the training.

Plot loss against any of these on log-log axes and you get a nearly straight line. These are the "scaling laws". Two practical consequences:

1. **Gains are predictable.** Researchers can train tiny models, measure the slope, and extrapolate what a model 1000x bigger will achieve before spending the money. Pretraining runs costing millions of dollars are planned this way.
2. **You must scale all three together.** A huge model trained on too little data underperforms; so does a small model trained forever. Work like the Chinchilla paper showed many early models were undertrained - for a fixed compute budget, a smaller model trained on more data often wins. A rough rule of thumb from that work: about 20 training tokens per parameter.

Scaling laws explain why the field bet so heavily on "just make it bigger" - for years, that bet kept paying off exactly as the curves predicted.

### Instruction fine-tuning: from text predictor to assistant

A base model completes text; it does not follow instructions. The fix is a second, much smaller training phase called **instruction fine-tuning** (or supervised fine-tuning, SFT):

1. Humans write (or curate) a dataset of instruction/response pairs: "Summarize this article" followed by a good summary, "Explain recursion" followed by a clear explanation, and so on. Tens of thousands of high-quality examples go a long way.
2. Train the base model on these pairs with the exact same next-token loss - but now the text it learns to predict is *good assistant behavior*.
3. The model's style shifts: it stops imitating random internet text and starts imitating helpful answers.

Same architecture, same objective, different data. The base model already "knows" most of what it needs; SFT mostly teaches it the *format* of being an assistant.

### RLHF: learning from preferences

SFT gets you a decent assistant. **RLHF** (Reinforcement Learning from Human Feedback) makes it noticeably better - more helpful, more harmless, less likely to ramble. In plain words:

1. The SFT model generates several different answers to the same prompt.
2. Human raters rank the answers from best to worst. Ranking is much easier and cheaper than writing ideal answers from scratch.
3. A separate **reward model** is trained to predict those rankings - it learns to score any answer the way a human rater would.
4. The assistant model is then nudged (via a reinforcement learning algorithm like PPO, or simpler modern alternatives like DPO that skip the reinforcement learning entirely) to produce answers the reward model scores highly - with a constraint keeping it from drifting too far from the SFT model.

That is it. No new knowledge is added; RLHF tunes *which* of the many things the model could say it actually says. Newer variants replace human raters with AI feedback (RLAIF) or skip reinforcement learning altogether, but the spirit is the same: learn from preferences, not just from demonstrations.

### Prompting and the context window

Once deployed, you do not retrain the model - you **prompt** it. The prompt is simply text prepended to your conversation, and the model continues it. Everything about prompting follows from next-token prediction:

- **System prompts** set behavior because the model continues the pattern "a helpful assistant who...".
- **Few-shot examples** work because the model continues the pattern of the examples you show.
- **"Let's think step by step"** helps because writing out intermediate steps gives the model more tokens to condition on before committing to an answer.

The **context window** is how many tokens the model can attend to at once - its working memory. Early GPT models had 2,048 tokens (about 1,500 words); modern models range from 32k to over a million. Everything the model knows about your conversation must fit in that window. There is no persistent memory between sessions unless the application pastes history back into the prompt. Long documents that exceed the window get truncated, and the model silently forgets whatever fell off.

### Hallucination and limitations

LLMs fail in specific, predictable ways, and every one of them follows from how they are trained:

- **Hallucination.** The model is trained to produce plausible text, not true text. When it does not know something, the most probable continuation is often a confident, fluent, fabricated answer - fake citations, invented API functions, wrong dates, stated perfectly. There is no internal guarantee mechanism; fluency is not evidence.
- **Confident wrongness.** The model's tone does not reflect its accuracy. It states guesses and facts with the same calm authority, because tone is just another pattern learned from text.
- **Knowledge cutoff.** The model's knowledge is frozen at the end of pretraining. It cannot know what happened after that date unless the surrounding application feeds it fresh information in the prompt.
- **No guarantees.** Same prompt, different runs can give different answers. Small prompt changes can flip an answer. The model does arithmetic and logic by pattern-matching, so it can fail on problems unlike anything in its training data while acing harder-looking ones that match familiar patterns.

The practical rules: verify anything that matters, give the model the information it needs in the prompt rather than expecting it to know, and treat outputs as drafts, not verdicts.

### The seed of it all: a toy bigram predictor

Everything above is, at its core, "predict the next token". Here is that idea in its smallest possible form - a **bigram** model that predicts the next *word* using only the current word, trained on a few sentences. This is a toy: real models use tokens, attention over thousands of positions, and billions of parameters instead of one lookup table. But the train/predict loop is exactly the same shape. Save it as `bigram.py` and run it with `python3 bigram.py` - no dependencies at all.

```python-exec
import random
from collections import defaultdict

# A tiny training corpus. Real pretraining uses trillions of tokens.
corpus = [
    "the cat sat on the mat",
    "the cat ate the fish",
    "the dog sat on the rug",
    "the dog ate the bone",
    "the cat chased the dog",
]

# Split into word "tokens" (real tokenizers use subwords).
sentences = [s.split() for s in corpus]

# --- Training: count what word follows each word ---
counts = defaultdict(lambda: defaultdict(int))
for words in sentences:
    for current, nxt in zip(words, words[1:]):
        counts[current][nxt] += 1

# Turn counts into probabilities: P(next | current).
vocab = sorted({w for s in sentences for w in s})
probs = {}
for word, next_counts in counts.items():
    total = sum(next_counts.values())
    probs[word] = {w: c / total for w, c in next_counts.items()}

# --- What "loss on text" means for the toy ---
# Cross-entropy: average of -log P(actual next word | current word).
import math
total_loss, n = 0.0, 0
for words in sentences:
    for current, nxt in zip(words, words[1:]):
        p = probs[current][nxt]
        total_loss += -math.log(p)
        n += 1
loss = total_loss / n
print(f"training loss: {loss:.3f}  perplexity: {math.exp(loss):.2f}")

# --- Generation: the next-token prediction loop ---
def generate(start, length=8, seed=0):
    random.seed(seed)
    words = [start]
    for _ in range(length - 1):
        current = words[-1]
        if current not in probs:      # unseen word: stop
            break
        choices = list(probs[current].items())
        options, weights = zip(*choices)
        nxt = random.choices(options, weights)[0]
        words.append(nxt)
    return " ".join(words)

print(generate("the", seed=1))
print(generate("the", seed=7))
print(generate("the", seed=42))
```

Typical output:

```text
training loss: 0.995  perplexity: 2.70
the cat sat on the mat
the cat sat on the bone
the dog ate the bone
```

Read the `generate` function slowly - it *is* an LLM in miniature:

1. Look at the current context (here, just one word; in a transformer, the whole context window).
2. Produce a probability distribution over what comes next.
3. Sample from it (that sampling is why outputs vary between runs).
4. Append the result and loop, feeding the new word back in as context.

Scale the context from one word to 100k tokens, the lookup table to a transformer, and the corpus from five sentences to the internet, and you have GPT. The loop never changes.

### Where to go next

You have reached the end of the course - from linear regression by hand to the training pipeline behind modern LLMs. To keep going deeper:

- **"Attention Is All You Need"** (Vaswani et al., 2017) - the original transformer paper. Short and surprisingly readable after Chapter 17.
- **Andrej Karpathy's "Zero to Hero" video series** - builds GPT from scratch in code, the perfect next step from this course's style. His "Let's reproduce GPT-2" video is the pretraining chapter done for real.
- **fast.ai (Practical Deep Learning)** - free, top-down, code-first deep learning course.
- **Hugging Face courses and documentation** - the practical ecosystem: tokenizers, pretrained models, fine-tuning, and deployment.
- **The Chinchilla paper** ("Training Compute-Optimal Large Language Models") - the scaling-laws result in its primary source.
- **"Training language models to follow instructions with human feedback"** (the InstructGPT paper) - RLHF explained by the people who shipped it.

The best next project is the one from this course, done bigger: take the toy bigram above, replace the lookup table with a tiny neural network, then with a single attention head. You will have rebuilt the whole ladder yourself.

### Practice checklist

Capstone-style: these tie together the whole course, not just this chapter.

- [ ] Explain in your own words why next-token prediction forces a model to learn facts and grammar, not just spelling.
- [ ] Modify `bigram.py` to train on your own five sentences and verify the loss changes as predicted.
- [ ] Extend the toy to a trigram model (condition on the previous two words) and compare its perplexity to the bigram's.
- [ ] Explain what perplexity measures and why exp(loss) has an intuitive "effective number of guesses" reading.
- [ ] Describe the three ingredients that must scale together, and what goes wrong if you scale only one.
- [ ] Explain the difference between a base model and an instruction-tuned model, and why SFT uses the same loss as pretraining.
- [ ] Sketch the RLHF loop (generate, rank, reward model, optimize) from memory.
- [ ] Give three concrete reasons an LLM might confidently state something false, tied to how it was trained.
- [ ] Explain what the context window is and why a model "forgets" the start of a very long conversation.
- [ ] Write a short essay: pick one topic from this course (regression, classification, backpropagation, attention, pretraining) and teach it to a beginner in your own words - teaching is the final exam.
