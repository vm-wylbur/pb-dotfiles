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
#
# First install on a fresh host: pass the claude-mem secret via env:
#
#     CLAUDE_MEM_SECRET=<secret> bash ~/dotfiles/ai/claude-code/install.sh
#
# Subsequent runs need no env var — the secret is re-read from
# ~/.claude/settings.json (mode 600). See section 4.

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
    VIRTUAL_ENV="$VENV_MCP" uv pip install mcp-server-tree-sitter
    echo "  installed: mcp-server-tree-sitter into $VENV_MCP"
fi

# ── 3. Symlinks + rendered trees ────────────────────────────────────────────
#
# hooks/ and lib/ are plain shell scripts — symlinked for live editing.
# CLAUDE.md, skills/, agents/ are RENDERED outputs of composable templates;
# install.sh removes any prior symlink at the target and runs the renderer
# to materialize real files.

echo "Linking hooks and lib..."
link_file "$DOTFILES/ai/claude-code/hooks"   "$CLAUDE_DIR/hooks"
link_file "$DOTFILES/ai/claude-code/lib"     "$CLAUDE_DIR/lib"

RENDERER="$DOTFILES/scripts/claude-md"
if [[ ! -x "$RENDERER" ]]; then
    echo "ERROR: renderer not found at $RENDERER"
    exit 1
fi

echo "Rendering CLAUDE.md..."
if [ -L "$CLAUDE_DIR/CLAUDE.md" ]; then
    rm "$CLAUDE_DIR/CLAUDE.md"
    echo "  removed stale symlink"
fi
"$RENDERER" render "$DOTFILES/ai/CLAUDE.template.md"

echo "Rendering skills/..."
if [ -L "$CLAUDE_DIR/skills" ]; then
    rm "$CLAUDE_DIR/skills"
    echo "  removed stale symlink"
fi
mkdir -p "$CLAUDE_DIR/skills"
# Copy non-template files (e.g. README.md, full-mode-prompt.md) verbatim,
# then render templates over the top.
rsync -a --delete --exclude='*.template.md' \
    "$DOTFILES/ai/claude-code/skill-templates/" "$CLAUDE_DIR/skills/"
"$RENDERER" render-tree \
    "$DOTFILES/ai/claude-code/skill-templates" --to "$CLAUDE_DIR/skills"

echo "Rendering agents/..."
if [ -L "$CLAUDE_DIR/agents" ]; then
    rm "$CLAUDE_DIR/agents"
    echo "  removed stale symlink"
fi
mkdir -p "$CLAUDE_DIR/agents"
"$RENDERER" render-tree \
    "$DOTFILES/ai/claude-code/agent-templates" --to "$CLAUDE_DIR/agents"

# ── 4. CLAUDE_MEM_SECRET ────────────────────────────────────────────────────
#
# Resolved in priority order:
#   1. $CLAUDE_MEM_SECRET in env (first-time install)
#   2. .env.CLAUDE_MEM_SECRET in ~/.claude/settings.json (subsequent runs)
# Steady state: secret lives in settings.json (mode 600) and ~/.claude.json.
# Nothing reads it from the shell env after first install.

SETTINGS="$CLAUDE_DIR/settings.json"
echo "Resolving CLAUDE_MEM_SECRET..."
MEM_SECRET=""
if [ -n "${CLAUDE_MEM_SECRET:-}" ]; then
    MEM_SECRET="$CLAUDE_MEM_SECRET"
    echo "  source: env"
elif [ -f "$SETTINGS" ]; then
    MEM_SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS")
    [ -n "$MEM_SECRET" ] && echo "  source: settings.json (previous install)"
fi

if [ -z "$MEM_SECRET" ]; then
    echo "  MISSING: provide via env on first install:"
    echo "    CLAUDE_MEM_SECRET=<secret> bash $0"
    echo "  Subsequent runs re-read from $SETTINGS automatically."
    exit 1
fi

# ── 5. settings.json ────────────────────────────────────────────────────────
#
# The secret is the one per-host value that must be written here (it arrives
# via env on first install). Everything else managed — hooks, permissions,
# capability env — is applied by sync-managed-settings.sh, which is also
# runnable standalone to converge a host without re-running this whole
# installer. That script preserves the secret (and other host-local keys).

echo "Configuring settings.json..."
if [ ! -f "$SETTINGS" ]; then
    echo '{}' > "$SETTINGS"
    chmod 600 "$SETTINGS"          # it will hold the secret; never leave it group-readable
fi

# Ensure the secret is present; the managed merge below preserves it. jq exits
# 0 on a parse error (empty output), so `set -e` alone won't catch a malformed
# input — guard input and output with `jq -e` and fail closed, or a corrupt
# pre-existing settings.json would be silently emptied here, destroying the
# secret. Same pattern as sync-managed-settings.sh.
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
jq -e 'type == "object"' "$SETTINGS" >/dev/null 2>&1 \
    || { echo "ERROR: $SETTINGS is not a valid JSON object; aborting" >&2; exit 1; }
jq --arg secret "$MEM_SECRET" '.env.CLAUDE_MEM_SECRET = $secret' "$SETTINGS" > "$TMP"
if [ ! -s "$TMP" ] || ! jq -e 'type == "object"' "$TMP" >/dev/null 2>&1; then
    echo "ERROR: secret write produced empty/invalid output; $SETTINGS left unchanged" >&2
    exit 1
fi
mv "$TMP" "$SETTINGS"

# Apply the repo-managed settings subset (hooks, permissions, capability env).
# Pass CLAUDE_DIR explicitly so the child can't diverge from this install's
# target; invoke via bash so it doesn't depend on the executable bit.
CLAUDE_DIR="$CLAUDE_DIR" bash "$DOTFILES/ai/claude-code/sync-managed-settings.sh"

# ── 6. MCP servers in .claude.json ──────────────────────────────────────────

echo "Configuring MCP servers..."
if [ ! -f "$CLAUDE_JSON" ]; then
    echo '{}' > "$CLAUDE_JSON"
fi

TMP=$(mktemp)
jq '
    .mcpServers."claude-negotiate" = {
        "type": "http",
        "url": "http://snowball:7832/mcp"
    } |
    del(.mcpServers.repomix,
        .mcpServers.tree_sitter,
        .mcpServers."claude-mem")
    ' "$CLAUDE_JSON" > "$TMP" && mv "$TMP" "$CLAUDE_JSON"
echo "  updated: $CLAUDE_JSON (claude-negotiate only; repomix, tree_sitter, claude-mem MCPs removed — now served by lib/ shims)"

# ── 7. Per-repo deploy (Phase 8 substrate) ─────────────────────────────────
# Walks ai/repos.txt; for each target that exists, creates the .claude/lib
# symlink and re-renders <repo>/ai/CLAUDE.template.md → <repo>/CLAUDE.md.
# Targets absent on this machine are skipped silently. Non-fatal if a
# template hasn't been authored yet (symlink-only).

echo "Per-repo deploy..."
if [ -x "$DOTFILES/scripts/deploy-repos" ] && [ -f "$DOTFILES/ai/repos.txt" ]; then
    "$DOTFILES/scripts/deploy-repos" || echo "  (deploy-repos reported issues; continuing)"
else
    echo "  skipped: deploy-repos or repos.txt missing"
fi

# ── 8. Reminder: per-machine CLAUDE.local.md files ─────────────────────────

cat <<'EOF'

────────────────────────────────────────────────────────────────────────────
PER-MACHINE files NOT installed by this script (gitignored, machine-local):

The hrdag-ansible worktrees (merger / impl / ops) each use a CLAUDE.local.md
file that declares identity and renders a per-role module. These files are
NOT in dotfiles. On a fresh machine, re-render them via:

  claude-md render ~/projects/hrdag/hrdag-ansible/CLAUDE.local.md
  claude-md render ~/projects/hrdag/hrdag-ansible-impl/CLAUDE.local.md
  claude-md render ~/projects/hrdag/hrdag-ansible-ops/CLAUDE.local.md

The CLAUDE.local.md "shell" (identity + manifest declaring roles-merger /
roles-impl / roles-ops) must exist first; copy from the source machine or
hand-author per the templates in dotfiles/ai/modules/roles-*.md.
────────────────────────────────────────────────────────────────────────────

EOF

# ── Done ─────────────────────────────────────────────────────────────────────

echo "Setup complete. Verify with: claude mcp list"
