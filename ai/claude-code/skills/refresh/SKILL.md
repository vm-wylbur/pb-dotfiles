---
name: refresh
description: Reload meta-CLAUDE.md guidelines mid-session, plus re-check mid-session state changes (git, issues, PRs).
---

# Refresh Context

## Purpose

Mid-session reload. The session-start hook (`session-env.sh`) already emitted
grounded facts once at start — env, git, issues, skills index, meta-CLAUDE
mtime, MCP status. Use this skill when you suspect rules or state have
drifted *during* the session.

## When to Use

- User says "refresh", "check the guidelines", after corrective feedback
- Long session; want to re-sync git state, issues queue, or behavioral rules

## Recipes

### Default `refresh` — reload behavioral guidelines

Use when the user just says "refresh" or "check the guidelines":

1. Use the Read tool on `~/.claude/CLAUDE.md` to reload meta-CLAUDE into context.

Skills index, MCP status, and meta-CLAUDE mtime are already in context from
the session-start banner — no need to re-emit.

### `refresh git` — current worktree state

Use when you've been editing for a while and want a fresh snapshot:

```
bash ~/.claude/lib/git-status.sh
```

### `refresh issues` / `refresh prs` — queue state mid-session

```
bash ~/.claude/lib/gh-issues.sh          # all open
bash ~/.claude/lib/gh-issues.sh ops      # filter by label
bash ~/.claude/lib/gh-prs.sh
```

### Full `refresh` (rare) — re-emit everything from session start

```
bash ~/.claude/hooks/session-env.sh
```

## Output Format

Facts only, no commentary. Each script self-labels; just print the output.

## Notes

- All lib/ scripts are idempotent and silent on no-data — safe to compose.
- If the session-start banner is missing facts you expect (e.g., MCP status
  line absent), the hook may have failed silently — run the full refresh.
