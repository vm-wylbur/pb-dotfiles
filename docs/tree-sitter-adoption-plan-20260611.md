<!--
Author: PB and cc-dots 🧷
Date: 2026-06-11
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/docs/tree-sitter-adoption-plan-20260611.md
-->

# Tree-sitter adoption plan: move the choice into the menu, not the prose

> **STATUS 2026-06-11: PARKED at the Phase 0 gate.** Win rate 12% vs the pre-registered 30% floor — see [the Phase 0 report](tree-sitter-phase0-report-20260611.md). The measurement instrument (`lib/grep-replay.sh`) stays for re-measurement if the workload shifts.

## The problem, with evidence

The tree-sitter skill carries a "STRONGLY PREFER over Bash grep" instruction and has never once been model-invoked (usage-scan, both hosts, full retention window). The 2026-06-11 session is the inside-view evidence: ~40 greps in one session, several exactly symbol-shaped (callers of `_post("/harvest")`, definition of `generateMemoryHash`), zero consideration of the skill. The failure mechanism is structural, not motivational: at tool-choice time the agent picks among TOOLS in the menu; tree-sitter is a skill description that must be *recalled*, and grep never punishes the habit (noisy results get narrowed, not switched away from). Prefer-X-over-habit instructions don't land — second independent confirmation after the recall-loop turn-economy work.

**Discovered while writing this plan (changes the scope):** `lib/tree-sitter-impl.py` exposes only `analyze`, `find-text`, `get-symbols`, `get-ast`. There is NO `find-definition` or `find-callers` verb — the skill description promises "find symbols, callers, and definitions" but the impl's nearest surface is `find-text`, which is itself grep-shaped. Part of why tree-sitter loses to grep is that the killer verbs were never built. The impl wraps the `mcp_server_tree_sitter` package (venv at `~/.venv-mcp`); check what that package already provides before writing AST queries from scratch.

## Pre-registered decision rule (Phase 0 gates everything)

If tree-sitter (with real definition/caller verbs) is strictly better on **< 30%** of sampled symbol-shaped greps, PARK the whole effort and record why — do not build Phases 2–3 on vibes. "Strictly better" = returns the definition/callers with materially less noise (fewer irrelevant hits) than the grep actually produced in the transcript. PB's prior is that tree-sitter always wins; this phase converts the prior into labeled evidence and yields the trigger predicate (which grep shapes benefit) that Phases 2–3 consume.

## Phase 0 — measure (an afternoon; no deploy)

Build `lib/grep-replay.sh` (or a one-off script under `docs/` if it stays single-use): walk session transcripts (same parsing prior art as `ai/claude-code/lib/usage-scan.sh` — Bash tool_use commands + Grep tool calls), extract searches whose pattern is identifier-shaped (single token, `[A-Za-z_][A-Za-z0-9_]*`, no spaces/regex metachars), scoped to repos that still exist on disk. Replay each through the tree-sitter verbs; emit per-call rows (pattern, repo, grep result size, tree-sitter result size, definition-found y/n) and a summary win-rate. Honest caveats to record in the output: replay drift (repos changed since the transcript), and the window is per-host retention. n ≥ 30 or widen the window.

Acceptance: a written report with the win-rate, the decision-rule verdict, and (if proceeding) the empirical trigger predicate — e.g. "identifier-shaped + grep returned >K lines".

## Phase 1 — build the killer verbs (prerequisite for 2 and 3)

Add `find-definition --path <repo> --symbol <name>` and `find-callers --path <repo> --symbol <name>` to `lib/tree-sitter-impl.py`, reusing whatever `mcp_server_tree_sitter` already exposes (check its API first — do not reinvent). Output JSON: file, line, snippet per hit. Update `lib/tree-sitter.sh` usage header and the skill's documented verbs to match reality.

Acceptance: both verbs return correct results on two known repos (e.g. `claude-mem-harvester`: callers of `_post`; dotfiles: definition of `seed_precommit`), verified against ground truth by hand.

## Phase 2 — the MCP shim (the structural fix: same menu as Grep)

Thin stdio MCP server (python, uv-run, same venv) exposing `find_definition`, `find_callers`, `get_symbols` as first-class MCP tools over the Phase-1 impl. Register in the MCP config so the tools appear in the TOOL list at decision time — that is the one place routing actually happens. Tool descriptions should name the trigger cases from Phase 0's predicate ("use when looking for where a symbol is defined or called"). Deploy both hosts via the managed-settings sync path; mind the [[dotfiles-managed-settings-sync]] deletion guard.

Acceptance: tools visible in a fresh session's tool list; then MEASURE adoption — after ~a week, transcripts show organic `mcp__tree_sitter__*` tool_use (usage-scan extension or a one-line grep over transcripts). The hypothesis under test: menu placement fixes routing without any instruction.

## Phase 3 — the demonstration hook (only if Phase 2 adoption is weak)

PostToolUse hook on grep-shaped calls: when the pattern matches Phase 0's predicate AND the result is noisy (>K lines, K from Phase 0) or empty, the hook itself runs `find-definition`/`find-callers` and appends the answer to the tool result. The agent experiences tree-sitter being better at exactly the failure moment — and even if the habit never forms, the answer arrived. Wire via `/update-config` (hooks belong to the harness, not memory); include a kill-switch env var and a latency budget (~1s; tree-sitter project registration is cached after first use). Risk to manage: noise on legitimately-broad greps — the predicate must be tight, and the hook silent when grep succeeded.

Acceptance: synthetic session where a noisy symbol grep gets the injected tree-sitter answer; no injection on non-symbol greps; both hosts.

## Sequencing and ownership

0 → 1 → 2, with 3 held back unless Phase-2 adoption measurement is weak — running both at once would confound the measurement of which mechanism worked. All cc-dots lane (skills/hooks/MCP config = the agent environment). The PARKED ruling on the prose instruction stands throughout: no more wording tweaks to the skill description; the existing description gets corrected (Phase 1) only to stop promising verbs that don't exist.

## What this is NOT

Not a prune (PB: tree-sitter beats grep in his experience; the lib gets direct use). Not another instruction. Not an MCP server from the registry — the `mcp_server_tree_sitter` package is already vendored in `~/.venv-mcp`; the shim is ours, thin, and auditable.
