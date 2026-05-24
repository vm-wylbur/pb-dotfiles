#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mcp-status.sh
#
# Check MCP server connectivity. Print connected count and flag any
# expected servers that are missing/failed. Exits silently if `claude`
# CLI is unavailable.
#
# Expected list is intentionally narrow — extend via $EXPECTED env var
# (space-separated names).

command -v claude &>/dev/null || exit 0

EXPECTED=${EXPECTED:-"tree_sitter repomix claude-mem"}

OUTPUT=$(claude mcp list 2>&1)
# Lines look like: "name: url - ✓ Connected" or "name: ... - ✗ Failed to connect"
CONNECTED=$(echo "$OUTPUT" | grep -c "✓ Connected" 2>/dev/null | tr -d ' ')
FAILED=$(echo "$OUTPUT" | grep -E "✗ Failed|! Needs" | sed -E 's/:.*$//' | tr '\n' ',' | sed 's/,$//')

MISSING=""
for srv in $EXPECTED; do
    if ! echo "$OUTPUT" | grep -E "^${srv}.*✓ Connected" &>/dev/null; then
        MISSING="${MISSING}${srv},"
    fi
done
MISSING=${MISSING%,}

LINE="MCPs: ${CONNECTED} connected"
if [ -n "$MISSING" ]; then
    LINE="${LINE} [MISSING: ${MISSING}]"
fi
if [ -n "$FAILED" ]; then
    LINE="${LINE} [FAILED/AUTH: ${FAILED}]"
fi
echo "$LINE"
