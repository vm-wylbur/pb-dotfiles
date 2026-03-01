#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-02-12
# License: (c) HRDAG, 2025, GPL-2 or newer
#
# ------
# dotfiles/ai/claude-code/install.sh
#
# Claude Code configuration installer
# Creates symlinks from ~/.claude/ to dotfiles repository

set -euo pipefail

DOTFILES="$HOME/dotfiles"
CLAUDE_DIR="$HOME/.claude"

# Verify dotfiles repo exists
if [ ! -d "$DOTFILES/ai/claude-code" ]; then
    echo "ERROR: $DOTFILES/ai/claude-code not found"
    exit 1
fi

mkdir -p "$CLAUDE_DIR"

# Symlink: ~/.claude/CLAUDE.md -> dotfiles/ai/docs/meta-CLAUDE.md
link_file() {
    local src=$1 dst=$2
    if [ -L "$dst" ]; then
        echo "  exists: $dst -> $(readlink "$dst")"
    elif [ -e "$dst" ]; then
        echo "  SKIP: $dst exists and is not a symlink (back up manually)"
    else
        ln -sf "$src" "$dst"
        echo "  created: $dst -> $src"
    fi
}

echo "Creating symlinks..."
link_file "$DOTFILES/ai/docs/meta-CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link_file "$DOTFILES/ai/claude-code/skills"  "$CLAUDE_DIR/skills"
link_file "$DOTFILES/ai/claude-code/hooks"   "$CLAUDE_DIR/hooks"

# ── settings.json: inject hooks + CLAUDE_MEM_SECRET ──────────────────────────
SETTINGS="$CLAUDE_DIR/settings.json"
if [ ! -f "$SETTINGS" ]; then
    echo '{}' > "$SETTINGS"
fi

# Read secret from ~/.zshenv (where it's exported on interactive machines)
MEM_SECRET=$(grep '^export CLAUDE_MEM_SECRET=' "$HOME/.zshenv" 2>/dev/null \
    | head -1 | cut -d'=' -f2 | tr -d "'\"" || true)

HOOKS_DIR="$CLAUDE_DIR/hooks"
TMP=$(mktemp)
jq \
    --arg secret  "$MEM_SECRET" \
    --arg capture "bash ${HOOKS_DIR}/mem-capture.sh" \
    --arg compact "bash ${HOOKS_DIR}/mem-precompact.sh" \
    --arg inject  "bash ${HOOKS_DIR}/mem-inject.sh" \
    --arg degrade "bash ${HOOKS_DIR}/mem-degradation.sh" \
    '
    .env.CLAUDE_MEM_SECRET = $secret |
    .hooks.Stop         = [{"hooks": [{"type": "command", "command": $capture}]}] |
    .hooks.PreCompact   = [{"hooks": [{"type": "command", "command": $compact}]}] |
    .hooks.SessionStart = [{"hooks": [{"type": "command", "command": $inject}]}] |
    .hooks.PostToolUse  = [{"matcher": "Bash|Edit|Write", "hooks": [
        {"type": "command", "timeout": 5, "command": $degrade}]}]
    ' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
echo "  updated: $SETTINGS (hooks + CLAUDE_MEM_SECRET)"

echo ""
echo "Next steps:"
echo "  1. Install MCPs: see $DOTFILES/ai/claude-code/MCP-INSTALLATION.md"
echo "  2. Copy claude-mem config: ~/.config/claude-mem/claude-mem.toml"
echo "  3. Verify: claude mcp list"
