#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/meta-claude-mtime.sh
#
# Print last-modified time of meta-CLAUDE.md. Silent if file missing.
# Resolves through symlink to report the true source-file mtime.

TARGET="$HOME/.claude/CLAUDE.md"
[ -e "$TARGET" ] || exit 0

# %Sm = formatted mtime (macOS BSD stat); -L follows symlink to source
MTIME=$(/usr/bin/stat -f "%Sm" -L "$TARGET" 2>/dev/null)
[ -n "$MTIME" ] && echo "meta-CLAUDE.md: ${MTIME}"
