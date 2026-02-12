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

echo ""
echo "Next steps:"
echo "  1. Install MCPs: see $DOTFILES/ai/claude-code/MCP-INSTALLATION.md"
echo "  2. Copy claude-mem config: ~/.config/claude-mem/claude-mem.toml"
echo "  3. Verify: claude mcp list"
