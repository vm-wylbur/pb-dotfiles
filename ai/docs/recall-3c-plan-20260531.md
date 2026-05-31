<!--
Author: PB and cc-dots 🧷
Date: 2026-05-31
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/ai/docs/recall-3c-plan-20260531.md
-->

# Track 3C — `/recall` skill: plan (DRAFT — open decisions inside)

**Status:** decisions RESOLVED 2026-05-31 (D1/D2/D3 in §4) — build-ready per §6. The three open levers are closed; remaining work is implementation + verification.

## 1. Purpose & where it sits

The memory work has two halves:
- **Capture (Track 2 — DONE, live):** memory files mirror into claude-mem
  (`mem-file-capture.sh` PostToolUse hook → `/store` with `source_key` upsert).
  The store accumulates durable lessons (feedback, bugfixes, project decisions).
- **Use (Track 3 — this work):** stored memory is worthless unless recalled at
  the right moment. `/recall` (3C) is the on-demand recall primitive. **3B**
  (next, depends on 3C) auto-fires `/recall` when the agent is thrashing /
  repeating an error.

Problem 3C solves: the agent re-derives something already learned, or repeats a
mistake PB already corrected, because the lesson sits unread in claude-mem.
SessionStart's `mem-inject.sh` injects *recent* memories generically; `/recall`
is the *query-specific, on-demand* complement.

## 2. Scope

- **Build now: Q1 + Q2.**
  - Q1: "Have we learned something relevant here?" (don't rediscover)
  - Q2: "Are we repeating a mistake we've fixed before?" (don't re-step)
- **Deferred: Q3** ("what's missing from current evidence, by analogy to a past
  situation?") — analogical gap-finding; its own design pass (likely a forked
  sub-agent reasoning over candidates). Leave a seam, don't build.
- Name: **`/recall`** (NOT `/think` — collides with the extended-thinking keyword).
- Both **user-invocable** (`/recall [topic]`) and **model-invocable**.

## 3. Architecture — thin retrieve-then-synthesize skill

The skill is mostly a prompt + a shim call; the model does the reasoning.

Flow:
1. Determine the query (open decision D1).
2. Call `~/.claude/lib/mem-search.sh` (`POST /search {query, limit}`) — semantic
   search over claude-mem.
3. Hand the returned memories to the model with a synthesis prompt: answer Q1
   (relevant prior knowledge) and Q2 (past mistakes/corrections that apply),
   citing the memories. **One search, two lenses** — not two searches.
4. **Noise gate:** `/search` always returns a top-N even for an irrelevant query
   (cosine always ranks something). The prompt must instruct the model to judge
   relevance (the `similarity` field is returned) and be willing to output
   **"nothing relevant / no prior mistake here."** A recall that always
   manufactures relevance is worse than none.
5. Output tight (per output-budget): a few bullets or "nothing relevant."

## 4. DECISIONS (resolved 2026-05-31)

### D1 — Query derivation (load-bearing)
**Resolved:** `/recall [topic]` uses the arg as the query. With no arg, the model composes the query from current context — retained because model-invoke and 3B have no human to type a topic, and bash can't read the transcript. One interface serves user-with-topic, user-bare, model-invoked, and 3B (passes error context as the query).

### D2 — Model-invoke trigger calibration
**Resolved:** the model self-fires `/recall` when the same question or problem has come up **more than twice** in the session — a concrete repeat threshold, NOT every turn and NOT every task-start. That `>2x` condition is the trigger wording for the SKILL `description`. User-invoke `/recall [topic]` remains for deliberate proactive recall. Forward-compat with 3B: 3B will automate detection of this same `>2x` repeat signal and fire `/recall`; until 3B lands, the model self-monitors the threshold. No conflict — 3C is the skill, 3B is the automation of its trigger.

### D3 — `/search` tags enhancement: now or later?
**Resolved:** later. Do Q2 via model judgment over retrieved content now (correction memories carry telltale "Why:/How to apply:" / root-cause structure). Add server-side tags to the `/search` response only as a follow-up, and only if Q2 precision proves bad — that is another claude-mem REST change + redeploy (tracked as a "maybe" in claude-mem#4).

## 5. Grounded constraints (verified facts)
- `/search` (`mem-search.sh`): `{query, limit?}` → `{memories:[{content,
  content_type, metadata, similarity, source_key, ...}]}`. Default limit 5, cap 50.
  **No tags in results.** Single dev-project store — "project" is only a tag, and
  `/search` doesn't filter by it (global semantic).
- `/recent` (`mem-recent.sh`) DOES return tags but is recency-ordered, not semantic.
- Skill mechanism: `ai/claude-code/skill-templates/recall/SKILL.template.md` with
  frontmatter `name` + `description`; `install.sh` `render-tree` picks it up
  automatically (no installer change). `description` drives model-invocation;
  `/recall` is the user path.
- Complements (does not duplicate) `mem-inject.sh` (generic SessionStart injection).

## 6. Build steps (after sign-off)
1. Create `ai/claude-code/skill-templates/recall/SKILL.template.md`:
   - frontmatter: `name: recall`; `description:` (trigger wording per D2).
   - body: query-derivation instruction (per D1), the `mem-search.sh` call (chosen
     `limit`, e.g. 8-10), the two-lens synthesis prompt, the noise-gate +
     "nothing relevant" escape, and tight output formatting.
2. Render: `bash ~/dotfiles/ai/claude-code/install.sh` (or `claude-md render-tree`
   for skills only) → `~/.claude/skills/recall/`. Confirm `/recall` appears.
3. Verify (§7).
4. Commit per the commit gate (non-trivial → /code-review, then human gate).

## 7. Verification plan
- **User path:** `/recall AskUserQuestion` — should surface the no-closed-questions
  feedback memory (Q1 hit). An irrelevant topic should yield "nothing relevant"
  (noise gate works).
- **Q2 path:** `/recall` near a known past mistake; confirm it's flagged as a
  repeat-to-avoid.
- **Model-invoke:** eyeball over a few tasks — fires at the right moments, not every
  turn (validates D2 wording).
- **3B forward-compat:** `/recall "<error context string>"` works as a programmatic
  call (3B passes error context as the query).

## 8. Relationship to 3B (forward-compat, don't build)
3B repurposes the (currently unregistered) `mem-capture.sh` degradation detector:
on a repeated-error/thrash signal, fire a `/recall` injection scoped to the recent
error context. So `/recall`'s interface must accept a query arg (D1 covers this).
NOTE: the detector code is NOT in the tree — see the project memory
`memory-mirror-recall-tracks` (git archaeology needed for 3B).

## 9. Out of scope
- Q3 analogical gap-finding (separate design pass).
- `/search` tags enhancement (D3 = later unless PB says now).
- Spaced-repetition / recall-tracking (dropped — REST has no recall-tracking).
