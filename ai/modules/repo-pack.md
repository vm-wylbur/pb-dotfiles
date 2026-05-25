## Repo orientation via repomix

This is a code repository. Before extensive grep/find or "where is X"
exploration, pack the repo with `repomix` and read the packed output.

**When to pack:**
- At session start, if no recent pack exists.
- Before any non-trivial task that needs broad repo understanding.
- After pulling new commits or switching branches that change substantial
  state.

**How to pack:**
- Use `mcp__repomix__pack_codebase` against the repo root.
- For large repos or focused work, scope to a subtree.

**How to use the pack:**
- Prefer reading the packed output for orientation questions ("where is X
  defined", "what files reference Y", "what's the structure of Z").
- Fall back to targeted `grep` / `Read` once you know what to look at.
- Re-pack rather than re-grep when the working tree has shifted.

Skip this module's directives only when the dir is genuinely not a repo
(scratch / data dirs); those should not have this module in their manifest.
