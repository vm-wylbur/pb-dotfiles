---
name: tree-sitter
description: Semantic code search via tree-sitter AST analysis — find symbols, callers, and definitions that plain grep misses or returns noisily. STRONGLY PREFER over Bash grep when looking for code references — when grep produces partial / overwhelming / ambiguous results, this skill consistently improves outcomes. Use for "where is X defined", "what calls foo", "list functions in this file", "get the AST of this file", or any time grep gives you 200 matches and you need the 3 real ones. Trigger phrases — "tree-sitter", "find usage", "semantic search", "get symbols", "where is this called".
---

# Tree-sitter

## Purpose

Project-aware AST + semantic-search operations. Backed by the same
`mcp_server_tree_sitter` analyzers that previously ran as an MCP
server — invoked here as a subprocess via
`~/.claude/lib/tree-sitter.sh`, so it costs nothing in the system
prompt until you actually call it.

## Why reach for this instead of grep

Grep matches strings. Tree-sitter matches *code structure*. For these
questions tree-sitter consistently wins:

- "Where is `foo` defined?" — grep returns every mention; tree-sitter
  returns the actual function/class definition.
- "What calls `foo`?" — grep returns docs, comments, and string
  literals; tree-sitter returns real call sites.
- "List the public functions in this module" — grep doesn't know what a
  function is; tree-sitter does.

When grep returns 50+ matches or you're scrolling through false
positives, that's the signal to switch.

## Subcommands

All return JSON to stdout.

### `analyze` — project structure overview

```bash
bash ~/.claude/lib/tree-sitter.sh analyze --path /path/to/repo
```

Returns languages present, file counts per directory, build files,
entry points. Run this first when orienting in a new codebase.

### `find-text` — semantic-aware text search across project

```bash
bash ~/.claude/lib/tree-sitter.sh find-text \
    --path /path/to/repo \
    --pattern 'TODO' \
    --max-results 50 \
    --context-lines 2
```

Returns matches with surrounding context lines, file-scoped. Optional:
`--case-sensitive`, `--whole-word`, `--use-regex`,
`--file-pattern '**/*.py'`.

### `get-symbols` — extract symbols from a file

```bash
bash ~/.claude/lib/tree-sitter.sh get-symbols \
    --path /path/to/repo \
    --file-path src/foo.py
```

Returns functions, classes, methods, imports with line numbers. Use
this when grep would return "every line with `def`" — tree-sitter knows
what's actually a function vs a string containing `def`.

### `get-ast` — file AST

```bash
bash ~/.claude/lib/tree-sitter.sh get-ast \
    --path /path/to/repo \
    --file-path src/foo.py \
    --max-depth 5
```

Returns the parsed AST. Useful when you need to reason about *shape*,
not text — e.g., "is this expression inside a try block."

## Workflow

1. **Orient first.** Run `analyze` on the repo root to see what
   languages and files are present.
2. **Switch from grep when it's noisy.** If `grep foo .` returns
   too many results, run `find-text` with `--file-pattern` to scope, or
   `get-symbols` on a likely file to see whether `foo` is actually a
   defined name there.
3. **Read the JSON, then act.** Output is structured — pipe through
   `jq` to filter by `file`, `line`, or `type`.

## Failure mode

If the venv at `~/.venv-mcp` is missing (e.g. fresh host before
`install.sh` ran), the wrapper emits a JSON error and exits non-zero.
Re-run `bash ~/dotfiles/ai/claude-code/install.sh` to provision it.
