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

2. **Search claude-mem** via the loop orchestrator:

   ```bash
   echo '{"query":"<your query>","limit":10}' | bash ~/.claude/lib/recall-loop.sh
   ```

   Returns the search results plus loop-control fields: `{loop_id, iteration, stop_hint, new_count, seen_total, query_moved, max_similarity, above_floor, suppressed_count, memories:[{content, score, similarity, memory_id, metadata, created_at, ...}]}`. Memories are ranked by `score` — Reciprocal Rank Fusion over FTS + fuzzy + vector legs. `similarity` is the cosine leg only. It's a global search over the whole store — no project filter, so cross-project lessons can surface (often useful, occasionally off-topic; the noise gate handles that). (The raw single-shot shim `mem-search.sh` still exists; the orchestrator wraps it and adds the loop state + telemetry.)

3. **Judge sufficiency, then loop or stop.** Read the returned memories: is this enough to answer the question you brought? Judge from CONTENT, not scores. Then:

   - **Sufficient** → record the verdict and synthesize (step 4):

     ```bash
     echo '{"loop_id":"<id>","iteration":N,"verdict":"sufficient","outcome":"satisfied"}' | bash ~/.claude/lib/recall-loop.sh verdict
     ```

   - **Insufficient and `stop_hint` allows continuing** → record `"verdict":"insufficient"` (no outcome — not terminal), then **reformulate and call the orchestrator again with the same `loop_id`**. The reformulation must GENUINELY move: different vocabulary, a different angle (symptom vs cause, tool name vs error text), or different terms entirely — not the same words reshuffled. The orchestrator checks this (`query_moved`); a lazy rephrase that returns nothing new yields `stop_hint: rephrase-harder`, which means *your rephrase failed, not the corpus* — try once more with genuinely different words.
   - **`stop_hint: saturated`** → the query moved and still nothing new surfaced: the store likely has no more on this. Record the terminal verdict honestly (`"outcome":"satisfied"` if what you have suffices, else note the miss in your synthesis) and stop.
   - **`stop_hint: budget-exhausted`** (3 iterations) → stop, record `"outcome":"budget-exhausted"`. Don't loop past the budget — a budget-hit is itself a miss signal worth recording, not a failure to push through.

   Always record a verdict per iteration — including iteration 1 when it missed and a later iteration succeeded. The first-try miss is real telemetry about search quality; the loop's job is to rescue you, not to hide the miss.

4. **Synthesize, two lenses.** Read the returned memories and answer:
   - **Q1:** which results bear on the current work, and what do they say? Cite each by a short content gist (and `memory_id` if you need a stable handle) — `/search` returns no human-readable key.
   - **Q2:** do any read like a *correction* or *lesson* that applies here — telltales are the "**Why:** / **How to apply:**" structure, root-cause language, or feedback/bugfix framing? If so, flag it explicitly as a repeat-to-avoid.

   If a result is clearly irrelevant noise you don't want resurfacing this session, suppress it (display-only mask, never touches the store): `bash ~/.claude/lib/mem-suppress.sh add <memory_id> "<why>"`.

5. **Noise gate.** `/search` always returns a top-N — the fused ranker orders *something* even for an irrelevant query. Results come pre-sorted by `score` (trust that relative order), but neither `score` (RRF — a small relative number, not an absolute relevance) nor `similarity` (cosine — absolute, but blind to exact-token matches) is a clean yes/no threshold. Judge relevance from the *content* itself; use the two scores only as supporting signals. Don't dismiss a top-ranked result just because its cosine `similarity` is moderate — exact identifier matches (hostnames, flags, PR numbers, hashes) rank high on `score` with modest cosine. If nothing genuinely applies, say so plainly: "nothing relevant" / "no prior mistake on this". A recall that manufactures relevance is worse than none — and a failed recall recorded honestly (insufficient verdict, terminal outcome) is worth more than a manufactured success.

6. **Output tight** (per the output budget): a few bullets, each citing the memory it draws on, or the one-line "nothing relevant." Don't dump raw search results.

## Notes

- The store is only as good as what's been captured. The `mem-file-capture` hook mirrors memory files going forward; older lessons land in the store as the corpus is harvested. A sparse result may mean "not yet harvested," not "never learned" — don't over-read an empty return.
- **Most recalls are one iteration.** The loop exists for the wrong-words case — when the first result set clearly misses something you have reason to believe is stored. Don't loop to be thorough; loop because iteration 1 genuinely failed the question. The conservative-entry rule (fire only on >2x repeat or explicit ask) stays exactly as it is — the loop changes what happens *inside* a recall, not when recall fires.
- **Trajectory telemetry** lands in `~/.claude/recall-loops/trajectory.jsonl` (every iteration + verdict, unconditional). When the engine's `/search-verdict` endpoint ships (neg-6b0a3bf5 item L4), the orchestrator will also emit there; the local file stays as the mirror.
- **Forward-compat (Track 3B):** 3B will call this programmatically, passing recent error context as the query when it detects a repeated-error / thrash signal. The query-arg path (step 1) is the interface it uses — keep it working.
