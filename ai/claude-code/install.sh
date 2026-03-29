#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-03-29
# License: (c) HRDAG, 2025, GPL-2 or newer
#
# ------
# dotfiles/ai/claude-code/install.sh
#
# Claude Code configuration installer
# Sets up symlinks, settings, MCP servers, and dependencies.
# Idempotent — safe to re-run.

set -euo pipefail

DOTFILES="$HOME/dotfiles"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_JSON="$HOME/.claude.json"
VENV_MCP="$HOME/.venv-mcp"

# ── Preflight checks ────────────────────────────────────────────────────────

if [ ! -d "$DOTFILES/ai/claude-code" ]; then
    echo "ERROR: $DOTFILES/ai/claude-code not found"
    exit 1
fi

command -v jq >/dev/null || { echo "ERROR: jq not found"; exit 1; }
command -v node >/dev/null || { echo "ERROR: node not found"; exit 1; }

mkdir -p "$CLAUDE_DIR"

# ── Helpers ──────────────────────────────────────────────────────────────────

link_file() {
    local src=$1 dst=$2
    if [ -L "$dst" ]; then
        local current
        current=$(readlink "$dst")
        if [ "$current" = "$src" ]; then
            echo "  ok: $dst -> $src"
        else
            ln -sf "$src" "$dst"
            echo "  updated: $dst -> $src (was $current)"
        fi
    elif [ -e "$dst" ]; then
        echo "  SKIP: $dst exists and is not a symlink (back up manually)"
    else
        ln -sf "$src" "$dst"
        echo "  created: $dst -> $src"
    fi
}

# ── 1. Install uv if missing ────────────────────────────────────────────────

echo "Checking uv..."
if command -v uv >/dev/null 2>&1; then
    echo "  ok: uv $(uv --version 2>/dev/null || echo '(version unknown)')"
else
    echo "  installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # uv installs to ~/.local/bin; make sure it's on PATH for this script
    export PATH="$HOME/.local/bin:$PATH"
    if command -v uv >/dev/null 2>&1; then
        echo "  installed: uv $(uv --version 2>/dev/null)"
    else
        echo "  WARNING: uv installed but not on PATH; add ~/.local/bin to PATH"
    fi
fi

# ── 2. Set up .venv-mcp with tree-sitter ────────────────────────────────────

echo "Checking .venv-mcp..."
if [ -x "$VENV_MCP/bin/python" ] && "$VENV_MCP/bin/python" -c "import mcp_server_tree_sitter" 2>/dev/null; then
    echo "  ok: $VENV_MCP (tree-sitter installed)"
else
    echo "  creating $VENV_MCP with mcp-server-tree-sitter..."
    uv venv "$VENV_MCP"
    "$VENV_MCP/bin/pip" install --quiet mcp-server-tree-sitter
    echo "  installed: mcp-server-tree-sitter into $VENV_MCP"
fi

# ── 3. Symlinks ─────────────────────────────────────────────────────────────

echo "Creating symlinks..."
link_file "$DOTFILES/ai/docs/meta-CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
link_file "$DOTFILES/ai/claude-code/skills"  "$CLAUDE_DIR/skills"
link_file "$DOTFILES/ai/claude-code/hooks"   "$CLAUDE_DIR/hooks"

# ── 4. CLAUDE_MEM_SECRET in .zshenv ─────────────────────────────────────────

echo "Checking CLAUDE_MEM_SECRET..."
if grep -q '^export CLAUDE_MEM_SECRET=' "$HOME/.zshenv" 2>/dev/null; then
    echo "  ok: already in ~/.zshenv"
else
    if [ -n "${CLAUDE_MEM_SECRET:-}" ]; then
        echo "export CLAUDE_MEM_SECRET=$CLAUDE_MEM_SECRET" >> "$HOME/.zshenv"
        echo "  added to ~/.zshenv from environment"
    else
        echo "  MISSING: set CLAUDE_MEM_SECRET in env and re-run, or add manually to ~/.zshenv"
        echo "    echo 'export CLAUDE_MEM_SECRET=<secret>' >> ~/.zshenv"
    fi
fi

# Read it back for use in later steps
MEM_SECRET=$(grep '^export CLAUDE_MEM_SECRET=' "$HOME/.zshenv" 2>/dev/null \
    | head -1 | cut -d'=' -f2 | tr -d "'\"" || true)

# ── 5. settings.json ────────────────────────────────────────────────────────

echo "Configuring settings.json..."
SETTINGS="$CLAUDE_DIR/settings.json"
if [ ! -f "$SETTINGS" ]; then
    echo '{}' > "$SETTINGS"
fi

HOOKS_DIR="$CLAUDE_DIR/hooks"
TMP=$(mktemp)
jq \
    --arg secret  "$MEM_SECRET" \
    --arg inject  "bash ${HOOKS_DIR}/mem-inject.sh" \
    --arg sessenv "bash ${HOOKS_DIR}/session-env.sh" \
    --arg yamlval "bash ${HOOKS_DIR}/yaml-validate.sh" \
    '
    .env.CLAUDE_MEM_SECRET = $secret |
    .env.CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION = "false" |
    .permissions.deny = ["AskUserQuestion"] |
    .hooks.SessionStart = [{"hooks": [
        {"type": "command", "command": $inject},
        {"type": "command", "command": $sessenv}
    ]}] |
    .hooks.PostToolUse = [{"matcher": "Edit|Write", "hooks": [
        {"type": "command", "command": $yamlval}
    ]}] |
    .enabledPlugins."oh-my-claudecode@omc" = false |
    .skipDangerousModePermissionPrompt = true
    ' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"
echo "  updated: $SETTINGS"

# ── 6. MCP servers in .claude.json ──────────────────────────────────────────

echo "Configuring MCP servers..."
if [ ! -f "$CLAUDE_JSON" ]; then
    echo '{}' > "$CLAUDE_JSON"
fi

TMP=$(mktemp)
jq \
    --arg secret "$MEM_SECRET" \
    --arg venv_python "$VENV_MCP/bin/python" \
    '
    .mcpServers."claude-mem" = {
        "type": "http",
        "url": "http://snowball:3456/mcp",
        "headers": {"X-Claude-Mem-Secret": $secret}
    } |
    .mcpServers.repomix = {
        "type": "stdio",
        "command": "npx",
        "args": ["repomix", "--mcp"],
        "env": {}
    } |
    .mcpServers.tree_sitter = {
        "type": "stdio",
        "command": $venv_python,
        "args": ["-m", "mcp_server_tree_sitter.server"],
        "env": {}
    } |
    .mcpServers."claude-negotiate" = {
        "type": "http",
        "url": "http://snowball:7832/mcp"
    }
    ' "$CLAUDE_JSON" > "$TMP" && mv "$TMP" "$CLAUDE_JSON"
echo "  updated: $CLAUDE_JSON (claude-mem, repomix, tree_sitter, claude-negotiate)"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "Setup complete. Verify with: claude mcp list"
