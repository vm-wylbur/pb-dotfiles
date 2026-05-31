---
name: recall
description: Query claude-mem for prior lessons relevant to the current work — surfaces what we already learned (so you don't re-derive it) and past mistakes we already fixed (so you don't repeat them). Use when the user types /recall or asks "have we learned/seen this before", AND self-invoke when the SAME question or problem has come up more than twice in the session, or when you're about to commit to a non-trivial approach. Do NOT fire every turn — only on a genuine repeat (>2x) or an explicit ask.
---

# Recall — surface prior lessons from claude-mem

On-demand, query-specific recall over the durable memory store. Complements the SessionStart generic injection (`mem-inject.sh`), which is recent-and-generic; this is targeted and fired when it matters. Two lenses on one search:

- **Q1 — don't rediscover:** have we already learned something relevant to what I'm doing right now?
- **Q2 — don't re-step:** are we about to repeat a mistake we already diagnosed and fixed?

## When to fire

- **User-invoked:** `/recall [topic]`, or the user asks to recall / "have we seen this before".
- **Model-invoked (self):** when the *same* question or problem has come up **more than twice** this session (a repeat signal), or when you're about to commit to a non-trivial approach and want to check for a prior lesson first. Explicitly NOT every turn — a recall on every turn is noise and burns tokens.

## Flow

1. **Determine the query.** If a topic arg is given, use it as the query verbatim. If there's no arg, compose a concise query yourself from the current context — the thing you're stuck on, the decision you're about to make, or the error text. (Bash can't read the transcript; you have the context, so you write the query.)

2. **Search claude-mem** via the shim:

   ```bash
   echo '{"query":"<your query>","limit":10}' | bash ~/.claude/lib/mem-search.sh
   ```

   Returns `{"memories":[{content, score, similarity, memory_id, metadata, created_at, ...}]}`, ranked by `score` — Reciprocal Rank Fusion over FTS + fuzzy + vector legs (the hybrid retrieval live on snowball as of 2026-05-31). `similarity` is the cosine leg only. It's a global search over the whole store — no project filter, so cross-project lessons can surface (often useful, occasionally off-topic; the noise gate handles that).

3. **Synthesize, two lenses.** Read the returned memories and answer:
   - **Q1:** which results bear on the current work, and what do they say? Cite each by a short content gist (and `memory_id` if you need a stable handle) — `/search` returns no human-readable key.
   - **Q2:** do any read like a *correction* or *lesson* that applies here — telltales are the "**Why:** / **How to apply:**" structure, root-cause language, or feedback/bugfix framing? If so, flag it explicitly as a repeat-to-avoid.

4. **Noise gate.** `/search` always returns a top-N — the fused ranker orders *something* even for an irrelevant query. Results come pre-sorted by `score` (trust that relative order), but neither `score` (RRF — a small relative number, not an absolute relevance) nor `similarity` (cosine — absolute, but blind to exact-token matches) is a clean yes/no threshold. Judge relevance from the *content* itself; use the two scores only as supporting signals. Don't dismiss a top-ranked result just because its cosine `similarity` is moderate — exact identifier matches (hostnames, flags, PR numbers, hashes) rank high on `score` with modest cosine. If nothing genuinely applies, say so plainly: "nothing relevant" / "no prior mistake on this". A recall that manufactures relevance is worse than none.

5. **Output tight** (per the output budget): a few bullets, each citing the memory it draws on, or the one-line "nothing relevant." Don't dump raw search results.

## Notes

- The store is only as good as what's been captured. The `mem-file-capture` hook mirrors memory files going forward; older lessons land in the store as the corpus is harvested. A sparse result may mean "not yet harvested," not "never learned" — don't over-read an empty return.
- **Forward-compat (Track 3B):** 3B will call this programmatically, passing recent error context as the query when it detects a repeated-error / thrash signal. The query-arg path (step 1) is the interface it uses — keep it working.
