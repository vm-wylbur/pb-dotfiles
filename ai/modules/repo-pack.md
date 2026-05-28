## Repo orientation via repomix

This is a code repository. Before extensive grep/find or "where is X"
exploration, pack the repo with the `repomix` skill and read the packed
output.

**When to pack:**
- At session start, if no recent pack exists.
- Before any non-trivial task that needs broad repo understanding.
- After pulling new commits or switching branches that change
  substantial state.

**How to pack:** invoke the `repomix` skill (see
`~/.claude/skills/repomix/SKILL.md`) or call the underlying lib script
directly:

```bash
echo '{"path":"<repo root>","output":"<dest>.xml"}' \
    | bash ~/.claude/lib/repomix-pack.sh
```

For large repos or focused work, scope to a subtree by passing the
subtree path as `.path`.

**How to use the pack:**
- Prefer reading the packed output for orientation questions ("where is
  X defined", "what files reference Y", "what's the structure of Z").
- For semantic queries that grep handles badly (find-usage, list
  functions in a file, AST shape), reach for the `tree-sitter` skill
  instead — it's the right tool when grep is producing partial or
  overwhelming results.
- Fall back to targeted `grep` / `Read` once you know what to look at.
- Re-pack rather than re-grep when the working tree has shifted.

Skip this module's directives only when the dir is genuinely not a
repo (scratch / data dirs); those should not have this module in their
manifest.
