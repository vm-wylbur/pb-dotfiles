#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/code-todos.sh
#
# Count TODO|FIXME|HACK|XXX markers in source files. Print total and
# top 5 files. Silent if none found, no git repo, or rg missing.
#
# Uses ripgrep type filters (py, js, ts, sh, rust, go, c, cpp, java, rb).
# Respects .gitignore by default. Skips test files heuristically.
#
# Usage: bash lib/code-todos.sh
#        N=10 bash lib/code-todos.sh        # top N files

git rev-parse --git-dir &>/dev/null || exit 0
command -v rg &>/dev/null || exit 0

N=${N:-5}

COUNTS=$(rg -c --no-heading 'TODO|FIXME|HACK|XXX' \
    -t py -t js -t ts -t sh -t rust -t go -t c -t cpp -t java -t ruby \
    --glob '!**/test_*' --glob '!**/*_test.*' --glob '!**/tests/**' \
    2>/dev/null | sort -t: -k2 -rn)

[ -z "$COUNTS" ] && exit 0

TOTAL=$(echo "$COUNTS" | awk -F: '{sum+=$2} END {print sum}')
NFILES=$(echo "$COUNTS" | wc -l | tr -d ' ')
TOP=$(echo "$COUNTS" | head -"${N}")

echo "Code TODOs: ${TOTAL} markers across ${NFILES} files (top ${N}):"
echo "$TOP" | awk -F: '{printf "  %4d  %s\n", $2, $1}'
