#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-09
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mem-index-add.sh
#
# Append one pointer line to a project's MEMORY.md index — the mechanical
# half of saving a file-based memory, so the save is Write + this one
# command instead of a second hand-rolled heredoc turn (profiled
# 2026-06-09: the index splice was a whole model turn of pure mechanics).
#
# Usage:
#   mem-index-add.sh <title> <file.md> <hook text...>
#
#   <file.md> must exist in the project's memory dir (sibling of MEMORY.md)
#   — this is the guard against indexing a memory that was never written.
#   The line lands as: - [<title>](<file.md>) — <hook text>
#
# The project memory dir is resolved from $CLAUDE_PROJECT_MEMORY if set,
# else derived from $PWD the same way the harness names project dirs
# (slashes -> dashes under ~/.claude/projects/<name>/memory).
#
# Idempotent: if a line for <file.md> already exists, it is REPLACED in
# place (memories get re-indexed when their hook changes), not duplicated.

set -uo pipefail

err() { echo "mem-index-add: $1" >&2; exit 1; }

[ $# -ge 3 ] || err "usage: mem-index-add.sh <title> <file.md> <hook text...>"
TITLE="$1"; FILE="$2"; shift 2; HOOK="$*"

case "$FILE" in
    */*) err "<file.md> is a bare filename in the memory dir, not a path" ;;
    *.md) ;;
    *) err "<file.md> must end in .md" ;;
esac

if [ -n "${CLAUDE_PROJECT_MEMORY:-}" ]; then
    MEMDIR="$CLAUDE_PROJECT_MEMORY"
else
    PROJ=$(pwd | tr '/' '-')
    MEMDIR="$HOME/.claude/projects/$PROJ/memory"
fi
INDEX="$MEMDIR/MEMORY.md"

[ -d "$MEMDIR" ] || err "no memory dir at $MEMDIR (set CLAUDE_PROJECT_MEMORY or run from the project root)"
[ -f "$MEMDIR/$FILE" ] || err "$FILE not found in $MEMDIR — write the memory file first"
[ -f "$INDEX" ] || err "no MEMORY.md at $INDEX"

LINE="- [$TITLE]($FILE) — $HOOK"

TMP=$(mktemp)
if grep -qF "]($FILE)" "$INDEX"; then
    # replace the existing pointer for this file, preserving its position
    awk -v line="$LINE" -v file="]($FILE)" \
        'index($0, file) && !done { print line; done=1; next } { print }' \
        "$INDEX" > "$TMP" && mv "$TMP" "$INDEX"
    echo "replaced: $LINE"
else
    cp "$INDEX" "$TMP" && printf '%s\n' "$LINE" >> "$TMP" && mv "$TMP" "$INDEX"
    echo "added: $LINE"
fi
