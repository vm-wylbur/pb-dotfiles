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

### Phase 2: Check Environment

2. MCP Servers
   - List connected servers with tool counts
   - Flag any expected servers that are missing (expected: tree-sitter, repomix, claude-mem, omc)

3. Skills
   - Scan `~/.claude/skills/*/SKILL.md` (use `find -L`, directory is symlinked)
   - Count registered vs on-disk
   - List by name only

### Phase 3: Repo Status

4. If in a git repo:
   - Branch name, clean/dirty
   - Commits ahead/behind remote
   - Last commit hash + subject
   - If dirty: list changed files (short format)

### Output Format

```
Context loaded
├─ meta-CLAUDE.md (date) ✓
├─ MCPs: N connected (list names)
├─ Skills: N on disk (list names)
└─ Repo: branch (clean|dirty, N ahead)
```

## Communication Style

- Facts only, no commentary
- Single structured block
- Flag problems, don't explain how to fix them
