<!--
Author: PB and Claude
Date: 2026-06-01
License: (c) HRDAG, 2026, GPL-2 or newer

---
ai/docs/changelog-skill-improvements.md
-->

# Changelog skill — lessons & improvement plan

Captured 2026-06-01 from the `2026-05-15 → 2026-06-01` changelog run (cc-logwood, from `~/tmp`). These are defects and gaps the run surfaced, not polish. Canonical sources: lib scripts at `~/dotfiles/ai/claude-code/lib/`; skill at `~/.claude/skills/changelog/SKILL.md` (confirm/locate its source-of-record before editing — it may be deployed-only). Deployment is pull-based, so land in the source repo and let nodes pull; do not hand-edit deployed copies. Multi-file change to pb-dotfiles → run `/code-review` then one human gate per the commit rule before merge.

Recommended order: do 1–5 first (1–4 fix an actual correctness failure; 5 codifies voice while fresh). 6–7 can follow.

**Status (2026-06-02, cc-dots):** items 1–5 implemented and verified; the source-of-record open question (below) is **resolved**. Item 1 also surfaced — and fixed — a defect in its own prescription: `git rev-parse --abbrev-ref origin/HEAD` reads the *stale local* symref (dotfiles' `origin/HEAD` still pointed at the long-dead `master`), so resolution now goes through `git ls-remote --symref` (authoritative) with a cache→main→master fallback, factored into a shared `resolve-origin-default.sh`. **Items 6–7 done 2026-06-02:** item 6 = parallel-digest scaling guidance added to Phase 5; item 7 = `lib/suggest-changelog-start.sh` + a new Phase 0 (auto-suggests the last report's end − 1 day; verified it picks 2026-05-31 from the live `~/docs` set). All seven items now landed.

## 1. Diff `origin`, not local HEAD (highest impact)

The bug that produced a wrong first draft. `repo-diff-since.sh` skips the pull on a dirty working tree and then logs local HEAD, so it silently omits merged work that is on origin but not pulled. This run, hrdag-monitor was 43 merged commits behind locally and the first draft carried a bogus "hadn't landed in local trees" caveat as a result.

Change: `git fetch --quiet origin` (read-only, never touches the working tree), then `git log origin/<default-branch> …` instead of `git pull --ff-only` + local-HEAD log. Resolve `<default-branch>` from `git rev-parse --abbrev-ref origin/HEAD` (fall back to `origin/main`). Delete the dirty-tree special-case entirely — reading the origin ref makes WIP irrelevant. Apply the identical change to `git-version-tags-since.sh`.

Files: `ai/claude-code/lib/repo-diff-since.sh`, `ai/claude-code/lib/git-version-tags-since.sh`.

Acceptance: with a clone deliberately N commits behind a dirty origin, the diff output includes all N merged commits and leaves the working tree untouched (`git status` unchanged before/after).

## 2. Multi-base clone resolution

The skill hardcodes `~/projects/hrdag/{repo}`. Reality spans `~/projects/hrdag`, `~/projects/personal`, and `~/dotfiles`, and the GitHub name ≠ local dir (`pb-dotfiles` → `~/dotfiles`). Clones were located by hand this run.

Change: add `ai/claude-code/lib/resolve-clone.sh REPO_FULLNAME` that searches the known bases and matches on the origin remote URL (`git remote get-url origin`), printing the local path or empty. Skill Phase 2 calls it per repo instead of assuming a path; "no local clone" falls back to commit-message-only as today.

Files: new `ai/claude-code/lib/resolve-clone.sh`; SKILL.md Phase 2.

Acceptance: every repo in a run resolves to its real clone regardless of base dir or name mismatch; a genuinely-absent clone reports empty and triggers the messages-only path.

## 3. `/tmp` → `~/tmp`

The skill writes per-repo diffs to `/tmp/changelog-diff-*.txt` and the pr-gate log to `/tmp`, against the standing mac rule (use `~/tmp`). Hardcode `~/tmp` (or a `$CLAUDE`-scoped scratch dir).

Files: SKILL.md Phase 2 + Guardrails; any lib script writing scratch.

Acceptance: a full run writes no scratch under `/tmp`.

## 4. Gather merged PRs; fix issue-list truncation

PR messages were wanted and valuable (the 177 ansible PRs framed the IaC story); the skill only gathers commits + issues. And `gh-author-issues.sh` defaults `LIMIT=50` — it truncated at 200 this run with no warning.

Change: add `ai/claude-code/lib/gh-author-prs.sh DATE` emitting `repo#N<TAB>mergedAt<TAB>title` via `gh search prs --author=@me "merged:>=DATE"`, as a Phase 4 step. Raise the issues default LIMIT and emit an explicit "results truncated at N — widen LIMIT" warning when the cap is hit. Note in the skill that PR authorship is GitHub-account-scoped, so repos that merge via agent-authored PRs or direct-to-main will under-report here (use commits + diffs as the authoritative set for those).

Files: new `ai/claude-code/lib/gh-author-prs.sh`; `ai/claude-code/lib/gh-author-issues.sh`; SKILL.md Phase 4.

Acceptance: a run lists merged PRs per repo and prints a truncation warning rather than silently cutting off.

## 5. Changelog-specific voice rules (codify what PB steered this run)

Add to the skill's "Changelog-specific rules":

- Commit SHAs, PR/issue ids, **and version tags** go to footnotes; the body stays narrative. (This overrides the current "cite version tags inline as evidence" line — version tags are still navigation aids, just relocated to footnotes.)
- Describe internals; name a function, script, file, or metric only when that specific name illuminates the point for a reader who will never see the code. Keep concrete hardware, algorithm, threshold, and approach detail — that is what carries the narrative.
- Anonymize individuals (e.g. don't name whose key was lost); keep the story, drop the name.
- When the meta-process is itself a development that window, offer a two-part structure: "how it's built" (the system that produced the work) near the top, then "what it does / what it built." Name the agent fleet; no emojis in prose (agent glyphs only in commit trailers / GH footers).

Files: SKILL.md (Changelog-specific rules; reconcile with the pb-voice module).

## 6. Codify the scale approach

**Done 2026-06-02** — parallel-digest pattern added to Phase 5 (fan-out ≤3 concurrent, structured evidence incl. cc-\* agent identities, skip/down-weight generated blobs and report what was skipped).

21 MB of diff across 13 repos this run; one repo's diff was ~91% generated audit JSON. Solo reading is impossible and the generated blob nearly dominated the budget.

Change: in Phase 5, document the parallel-digest pattern — fan out digest sub-agents (≤3 concurrent per the user-wide rule) that return structured evidence (themes, concrete numbers, version tags, agent identities, issue/PR refs), then synthesize from those. Instruct the gather/digest to skip or down-weight generated/vendored/lockfile blobs and to **report what was skipped** (no silent truncation). Capture cc-* agent identities from commit trailers and branch names as first-class evidence (PB wants the fleet credited), not an afterthought.

Files: SKILL.md Phase 5.

## 7. Auto-suggest the start date

**Done 2026-06-02** — `lib/suggest-changelog-start.sh` + a new Phase 0; suggests the latest report's end − 1 day (verified = 2026-05-31), falls back to asking when no prior changelog exists.

The skill takes a start-date arg cold. This run, the wanted start was "1–2 days before the end of the last report."

Change: Phase 0 — read the most recent `~/docs/changelog-*.md`, parse its end date, and suggest `start = end − 1–2 days` (small overlap avoids seam gaps). Still accept an explicit arg to override.

Files: SKILL.md Arguments / new Phase 0.

## Open question — RESOLVED (2026-06-02)

Source-of-record confirmed: the skill is authored at `ai/claude-code/skill-templates/changelog/SKILL.template.md` (rendered to the deployed `~/.claude/skills/changelog/SKILL.md` via `claude-md render`; never hand-edit the deployed copy). The lib scripts are sourced at `ai/claude-code/lib/`. Both deploy pull-based — land in the source repo, let nodes pull.
