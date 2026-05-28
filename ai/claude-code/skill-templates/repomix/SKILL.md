---
name: repomix
description: Pack a repository into a single AI-friendly file for fast orientation, "where is X defined", "what references Y", or any broad-context question. Use before extensive Glob/Grep when you need to see the whole codebase, not just a few files. Trigger phrases — "orient me", "pack this repo", "show me the shape of this codebase", or any task that says "broadly understand X before changing it".
---

# Repomix

## Purpose

Pack a repo into a single XML/markdown file you can read once, then grep
locally — instead of issuing dozens of `Read` + `Glob` round-trips. The
backing CLI is `repomix` (`/opt/homebrew/bin/repomix` or wherever brew
installed it); this skill wraps it with sensible defaults via
`~/.claude/lib/repomix-pack.sh`.

This replaces the deprecated `mcp__repomix__pack_codebase` MCP tool —
same underlying binary, no system-prompt cost.

## When to use

- Starting work in an unfamiliar repo or subtree.
- Orientation questions: "where is X defined", "what files reference Y",
  "what's the structure of Z".
- Before designing a refactor that needs to see the whole picture.
- After pulling new commits that change substantial state.

Don't use for: a single targeted lookup (use `grep`/`find` directly), or
a repo you packed in the last few minutes with no working-tree changes.

## How to invoke

```bash
echo '{
    "path": "/Users/pball/dotfiles",
    "output": "/tmp/dotfiles-pack.xml",
    "style": "xml",
    "compress": false
}' | bash ~/.claude/lib/repomix-pack.sh
```

Optional fields:
- `style`: `xml` (default), `markdown`, `json`, `plain`.
- `compress`: `true` to extract just classes/functions via tree-sitter
  (cheaper to read; loses bodies).
- `include`: array of globs (`["src/**", "tests/**"]`).
- `ignore`: array of globs (`["dist/**", "*.lock"]`).

Stdout returns `{"output": "<abs path>", "size_bytes": N}`. Read the
file with the `Read` tool; treat the packed XML as your local index.

## After packing

- `grep` the packed file for symbols, paths, or strings. Faster than
  re-grepping the source tree.
- Once you've located the relevant file(s), switch back to `Read` /
  `Edit` on the live source — the pack is a snapshot, not the working
  copy.
- Re-pack rather than re-grep when the working tree has shifted.

## Direct CLI fallback

If you need flags this wrapper doesn't expose, call `repomix` directly
via `Bash`. The wrapper is a convenience over the canonical binary, not
a substitute.
