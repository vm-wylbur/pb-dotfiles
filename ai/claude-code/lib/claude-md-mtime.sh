#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# Updated: 2026-05-25 (cc-dots: renamed from meta-claude-mtime.sh as part of
#          the composable-CLAUDE.md design; meta-CLAUDE.md is now ai/CLAUDE.md)
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/claude-md-mtime.sh
#
# Print last-modified time of the user-wide CLAUDE.md. Silent if missing.
# Resolves through symlink to report the true source-file mtime.

TARGET="$HOME/.claude/CLAUDE.md"
[ -e "$TARGET" ] || exit 0

# %Sm = formatted mtime (macOS BSD stat); -L follows symlink to source
MTIME=$(/usr/bin/stat -f "%Sm" -L "$TARGET" 2>/dev/null)
[ -n "$MTIME" ] && echo "user-wide CLAUDE.md: ${MTIME}"
