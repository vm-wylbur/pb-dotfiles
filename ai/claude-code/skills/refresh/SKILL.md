---
name: refresh
description: Reload behavioral guidelines and report environment status. Composes lib/ scripts for mid-session reload.
---

# Refresh Context

## Purpose

Mid-session context reload — re-read guidelines, re-check environment state.
The session-start banner is already emitted by `session-env.sh`; use refresh
when something has drifted (corrective feedback, long session, want to
re-verify).

## When to Use

- User says "refresh", "check your work", "read the guidelines"
- After corrective feedback from user
- Mid-session, when you suspect rules or environment have drifted

## Composition recipes

All deterministic steps live in `~/.claude/lib/` as standalone scripts.
Choose the recipe matching the situation:

### Default `refresh` (most common)

Use when the user just says "refresh" or "check the guidelines":

1. Use the Read tool on `~/.claude/CLAUDE.md` to reload meta-CLAUDE into context.
2. Run `bash ~/.claude/lib/meta-claude-mtime.sh` to confirm the mtime.
3. Run `bash ~/.claude/lib/mcp-status.sh` to confirm tools available.

### `refresh git` — current worktree state

Use when you've been working a while and want to re-sync your mental model
of the repo state:

```
bash ~/.claude/lib/git-status.sh
```

### `refresh issues` / `refresh prs` — queue state

Use when the user asks about queue state mid-session:

```
bash ~/.claude/lib/gh-issues.sh          # all open
bash ~/.claude/lib/gh-issues.sh ops      # filter by label
bash ~/.claude/lib/gh-prs.sh
```

### Full `refresh` (rare)

Re-emit everything `session-env.sh` did at session start:

```
bash ~/.claude/hooks/session-env.sh
```

## Output Format

Facts only, structured block, no commentary. Each script self-labels;
just print the output.

```
Context refreshed
├─ meta-CLAUDE.md (mtime) ✓
├─ MCPs: N connected [MISSING: ...]
└─ (any other components you ran)
```

## Communication Style

- Facts only, no commentary
- Single structured block
- Flag problems, don't explain how to fix them

## Notes

- The session-start banner (host/arch/date/git/issues/skills) is emitted
  by `session-env.sh` (a hook) at every session start. Don't re-run that
  unless the user asks for a full re-read.
- All lib/ scripts are idempotent and silent on no-data — safe to compose
  freely.
