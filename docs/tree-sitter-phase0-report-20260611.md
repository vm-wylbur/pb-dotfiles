<!--
Author: PB and cc-dots 🧷
Date: 2026-06-11
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/docs/tree-sitter-phase0-report-20260611.md
-->

# Tree-sitter adoption, Phase 0 report: PARK

**Verdict: PARK Phases 1–3, per the pre-registered decision rule.** Tree-sitter (with prototype find-definition/find-callers verbs) is strictly better on 12% of sampled symbol-shaped greps — well under the 30% floor set in [the plan](tree-sitter-adoption-plan-20260611.md) before measurement.

## Method

`lib/grep-replay.sh` (new, this session) walks all session transcripts on this host, extracts every Bash `grep`/`rg` whose pattern is identifier-shaped (`[A-Za-z_][A-Za-z0-9_]*`, the plan's registered predicate), resolves the searched path to its enclosing git repo, and replays the symbol through prototype find-definition and find-callers indexes built per repo (one tree-sitter parse per supported file; python, bash, js, ts/tsx, go, rust). Each call is scored against the grep output the agent actually saw in the transcript: **win** = tree-sitter returned the definition/callers with materially less noise (≥3 fewer lines, or ≤half the grep's output); **tie** = returned hits without material reduction; **loss** = no def and no caller found.

## Numbers (porky, full retention window, 2026-06-11)

From 6,370 grep segments across all transcripts, 573 were identifier-shaped. Excluded as unreplayable: 207 path-gone (target deleted; 142 of them in removed hrdag-ansible worktrees), 37 not-a-repo (greps over `$HOME` config like `.zshenv`, `.ssh/config`), 67 git-fail (a broken `hrdag-ansible-impl` worktree). **Decided 262: 32 win / 13 tie / 217 loss = 12%.**

The result is stable under every sensitivity cut: single-grep commands only (clean output attribution) 13%; unique (repo, symbol) pairs 12%; def-anchored scoring (callers don't count) 12%. It also survived a review-driven round of harness fixes (untracked files added to the index, `grep -r` with no path operand recovered, subshell `cd` tracking, tsx given its own JSX-capable grammar, redirection-token cleanup): the rate did not move.

## Why tree-sitter loses: the greps aren't symbol-intent

Identifier-*shaped* is not symbol-*intent*. The loss pile is dominated by ansible hostnames (`ipfs1`, `bastion`, `scott`), YAML/config keys (`prometheus_exporters`, `par2_autorepair`), DB column names (`source_key`, `by_id`), doc tokens (`FIXME`, `Undocumented`), and env-var prefixes (`MCPMEM_`). No definition exists in the searched tree for these; grep was the right tool, and no find-definition verb would have helped. Hand-verification of sampled losses against the repos at HEAD confirmed the misses are real absences, not query blind spots (one blind spot found and fixed during validation: module-level constants like `_SIGNAL_VERIFY_BATCH = 50`).

## The conditional result worth keeping

When the greped symbol **is** defined in the searched repo — 36 of 262 code-repo calls, 14% — tree-sitter wins 72% (26/36). When the grep output was also noisy (≥10 lines), it wins **18/18**. The wins look exactly like the plan predicted: `OrgRecord`, `search_hybrid`, `_handle_verify_failure` — one definition plus a handful of callers versus 5–62 grep lines.

So the verbs are excellent precisely when applicable, but applicable at only ~36 moments in a ~30-day window (~1/day), and the predicate that makes them win ("a definition exists in this repo") is only checkable *by running tree-sitter*. A Phase-3-style hook could check the index before injecting, but building and maintaining MCP/hook infrastructure for one good moment a day fails the cost test. PARK.

## Caveats

- 54% of identifier greps were excluded as unreplayable (path-gone / not-a-repo / git-fail; composition computed above). Direction of bias: the dominant excluded populations are YAML-heavy ansible worktrees and `$HOME` config files, so their inclusion would push the rate further **down**, not up.
- `grep_lines` is the output the agent actually *saw* — post-pipe (`| head`), post `-c`/`-l`, post harness truncation. This is faithful to the registered rule ("the grep actually produced in the transcript") but understates noise where the agent had already narrowed the grep; it deflates wins, i.e. biases toward PARK, not against it.
- `grep_lines` is per-command, not per-segment, for multi-grep compound commands; the single-grep-only cut (13%) controls for this.
- Replay drift: repos have changed since the transcripts; hand-checks suggest this is noise, not bias.
- porky only. scott's sessions are sparse (per usage-scan experience); a plausibility argument, not a measurement, says they wouldn't move 12% to 30%. Native Grep tool calls are counted as a self-verifying scope check (0 on this host — all searches go through Bash).

## Residue discovered during measurement

The vendored `mcp_server_tree_sitter` 0.7.0 is **broken at the AST layer** against the installed `tree_sitter` 0.25.2 + `tree_sitter_language_pack` 1.8.1: its parsers reject bytes and its query helpers use the pre-0.25 captures API. Of the existing skill's verbs, `get-ast` errors outright, while `get-symbols` and `find-text` still work. The language pack itself is now a rust-based binding with native symbol extraction (`tlp.process()`, `StructureItem`, `SymbolInfo`) — if the verbs are ever revived, build directly on it (`lib/grep-replay-impl.py` demonstrates the working pattern: std `Parser`/`Query`/`QueryCursor` over pack grammars). The skill's description should stop promising "callers and definitions" it never had; `get-ast`'s breakage should either be fixed (one-line: decode bytes) or the verb dropped.

## Disposition

- Phases 1–3: **parked**. The plan doc is annotated with this verdict.
- `lib/grep-replay.sh` stays in lib/ — it is the re-measurement instrument if the workload shifts toward code-symbol greps (e.g. more time in tfcs/claude-mem-style repos, less in ansible/docs).
- The general finding stands and now has numbers: prefer-X-over-habit instructions don't land, and in this case the habit was *right* 88% of the time.
