#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-03-07
# Updated: 2026-05-25 (cc-dots: emit terminalSequence for window title)
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/session-env.sh
#
# SessionStart hook: emit grounded environment facts before any task starts,
# and set the terminal window title via the terminalSequence hook field
# (Claude Code v2.1.141+).
#
# Output is a single JSON object with two fields:
#   additionalContext  — the env summary (becomes session context)
#   terminalSequence   — OSC 2 escape sequence setting the window title

LIB="${HOME}/.claude/lib"

CTX=$({
    echo "=== Session environment ==="
    bash "${LIB}/env.sh"
    echo "CWD: $(pwd)"
    bash "${LIB}/git-status.sh"
    bash "${LIB}/gh-issues.sh"
    bash "${LIB}/skills-list.sh"
    bash "${LIB}/claude-md-mtime.sh"
    bash "${LIB}/mcp-status.sh"
} 2>&1)

HOST=$(hostname -s)
DIR=$(basename "$(pwd)")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
TITLE="${HOST}:${DIR}${BRANCH:+@${BRANCH}}"
# OSC 2: window title only. \033]2;TITLE\007
SEQ=$(printf '\033]2;%s\007' "$TITLE")

jq -nc --arg ctx "$CTX" --arg seq "$SEQ" \
    '{additionalContext: $ctx, terminalSequence: $seq}'
