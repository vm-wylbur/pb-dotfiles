#!/usr/bin/env bash
# Author: PB and cc-dots
# Date: 2026-05-25
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/claude-md-check.sh
#
# SessionStart hook: warn if this repo's CLAUDE.md is a managed file
# (declares a claude-md manifest comment) and has drifted from what the
# modules would render.
#
# Behaviors:
#   - No CLAUDE.md, or no manifest comment → silent (exit 0).
#   - Clean (rendered == on-disk) → silent (exit 0).
#   - Stale → emit a small warning block to stdout (becomes agent context).
#   - Renderer missing → silent (this hook never blocks the session).
#
# Install in ~/.claude/settings.json:
#   "SessionStart": [{"hooks": [{"type": "command",
#     "command": "bash ~/.claude/hooks/claude-md-check.sh"}]}]

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RENDERER="${HOME}/dotfiles/scripts/claude-md"

# If the renderer isn't present, do nothing — this hook must never break a session.
[[ -x "$RENDERER" ]] || exit 0

# Run check; capture combined output so we can relay the stale message.
output=$("$RENDERER" check "$PROJECT_DIR" 2>&1) && exit 0

# Non-zero from claude-md check means stale (or some structural issue like
# missing markers). Surface to the agent's startup context.
echo "=== claude-md ==="
echo "$output"
echo "Refresh: \`claude-md render\` in ${PROJECT_DIR}"
