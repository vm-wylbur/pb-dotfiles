---
name: refresh
description: Reload behavioral guidelines and report environment status
---

# Refresh Context

## Purpose

Quick context reload: re-read guidelines, verify tools are available, report environment. Use at session start or after corrective feedback.

## When to Use

- Session startup
- User says "refresh", "check your work", "read the guidelines"
- After corrective feedback from user

## Workflow

### Phase 1: Reload Guidelines

1. Read `~/dotfiles/ai/docs/meta-CLAUDE.md`
   - Report last modified date
   - Confirm loaded

### Phase 2: Check MCPs

2. List connected MCP servers with tool counts.
   Flag any expected servers that are missing (expected: tree-sitter, repomix, claude-mem, omc)

### Output Format

```
Context refreshed
├─ meta-CLAUDE.md (date) ✓
└─ MCPs: N connected (list names) [MISSING: x, y if any]
```

Note: host, arch, git status, and skills are injected automatically at session start
by the session-env.sh hook. Only use /refresh mid-session after corrective feedback.

## Communication Style

- Facts only, no commentary
- Single structured block
- Flag problems, don't explain how to fix them
