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

# Check CLAUDE.md and CLAUDE.local.md (each silently skipped by `claude-md
# check` if absent or unmanaged). Collect stale messages from either.
warnings=""
for f in "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.local.md"; do
    if out=$("$RENDERER" check "$f" 2>&1); then
        continue  # clean or skipped
    fi
    warnings+="${out}"$'\n'
done

[[ -z "$warnings" ]] && exit 0

echo "=== claude-md ==="
printf '%s' "$warnings"
echo "Refresh stale files via \`claude-md render <path>\`"
