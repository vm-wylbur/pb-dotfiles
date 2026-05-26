---
name: survey
description: Understand a project, find todos, assess doc staleness, prioritize work
---

# Project Survey

## Purpose

Understand what a project does, find outstanding work, assess documentation
freshness, and return a prioritized todo list. Run when starting work in a
repo. Deterministic data gathering is delegated to `~/.claude/lib/` scripts;
the AI's job is judgment (staleness, categorization, prioritization).

## When to Use

- User says "survey", "what needs doing", "catch me up"
- First time working in a project this session

## Prerequisites

- Must be in a git repo (silent scripts exit cleanly if not — say so and stop)

## Workflow

### Phase 1: Re-sync from remote

```
bash ~/.claude/lib/git-pull-ff.sh
```

Silent on no-op. Prints one line if commits were pulled, or "skipped (dirty
tree)" / "FAILED — <reason>" if it didn't pull. Note any failure in the
output — findings may reflect stale local state.

### Phase 2: Understand the project (AI judgment)

Read these in order, skip if missing:
- `CLAUDE.md`, `README.md`, `AGENTS.md`, `TODAY.md`, `FIXME.md`

Identify: language, build system, test framework, deployment method. Use
`tree-sitter analyze_project` on large repos; otherwise `ls` top-level +
read key config (package.json, pyproject.toml, Makefile).

Summarize in 3-5 sentences: what this project is, does, how it's built.

### Phase 3: Gather outstanding work

Deterministic data — compose lib/ scripts:

```
bash ~/.claude/lib/gh-issues.sh         # open issues, top 10
bash ~/.claude/lib/code-todos.sh        # TODO/FIXME/HACK/XXX in source
```

Then read TODO/roadmap docs the AI can find via `ls` + Read:
- Root: `TODO.md`, `FIXME.md`, `ROADMAP.md`, `CHANGELOG.md`
- `docs/`: all `.md` files

Optional: claude-mem search for project name (skip if MCP unavailable).

### Phase 4: Assess staleness (per item)

For each pending item — issue, TODO entry, doc — run:

```
bash ~/.claude/lib/git-log-recent.sh <path-or-area> 20
```

Script prints commits + flags closure markers (`closes #`, `fixes #`,
`deploys`, `merged`, `re-enable`). **Demote any TODO to Completed/Verify
if git log shows it was closed.** Don't report stale "blocked" items.

Categorize each:
- **Active** — relevant, not done (no closure commit)
- **Completed** — git log or code shows done; archive/remove the doc entry
- **Superseded** — newer doc covers same ground
- **Unknown** — can't determine, flag for user

### Phase 5: Recommend doc cleanup

For completed/superseded: suggest remove, archive to `docs/completed/`, or
merge into the newer doc. Cite the file/function/commit that proves completion.

### Phase 6: Prioritized output

```
## Project: <name>
<3-5 sentence summary>

## Doc Cleanup (do first — low risk, high tidying value)
1. Remove TODO.md items 3,5,7 — implemented in src/foo.py (commit abc123)
2. Archive docs/old-plan.md — superseded by docs/v2-plan.md

## Outstanding Work
### From GitHub Issues
- #42: <title> (P1, stale 30d)

### From Docs
- ROADMAP.md item 2: <description>

### In-Code
- 12 TODOs across 5 files (highest: src/core.py with 4)
```

## Guardrails

- **Read-only.** Survey does not modify files.
- Large repos (>500 files): use tree-sitter compression or sample key dirs.
- All lib/ scripts are silent on no-data — absent output ≠ error.
- `code-todos.sh` may match its own regex strings when scanning tooling
  repos (the literal "TODO|FIXME" in the patterns). Discount obvious
  self-matches.
- Time budget: aim for 30 seconds, not 5 minutes.

## Notes

- The session-start banner already emitted env / git-status / open issues /
  user-wide CLAUDE.md mtime / MCP status — don't re-run those. Survey adds
  the remaining gathering + judgment work.
- If you wrote new lib/ primitives during a survey, add them here as a new
  composition step rather than inlining shell in the workflow.
