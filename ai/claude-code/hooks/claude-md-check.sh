#!/usr/bin/env bash
# Author: PB and cc-dots
# Date: 2026-05-25
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/claude-md-check.sh
#
# SessionStart hook: warn if any composable artifact in the user-wide
# dotfiles trees or in the current project has drifted from what the
# modules would render.
#
# Walks:
#   - The current project's CLAUDE.md and CLAUDE.local.md (legacy in-place).
#   - The current project's CLAUDE.template.md if present.
#   - The dotfiles user-wide trees:
#       ~/dotfiles/ai/CLAUDE.template.md         → ~/.claude/CLAUDE.md
#       ~/dotfiles/ai/claude-code/skill-templates → ~/.claude/skills
#       ~/dotfiles/ai/claude-code/agent-templates → ~/.claude/agents
#
# Behavior:
#   - Renderer absent → silent exit 0 (this hook must never break sessions).
#   - All clean / unmanaged → silent exit 0.
#   - Any stale → emit a single warning block to stdout (becomes context).

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RENDERER="${HOME}/dotfiles/scripts/claude-md"
DOTFILES_AI="${HOME}/dotfiles/ai"

[[ -x "$RENDERER" ]] || exit 0

warnings=""

# Project-local files (legacy in-place; silent-skipped if no manifest).
for f in "$PROJECT_DIR/CLAUDE.md" "$PROJECT_DIR/CLAUDE.local.md" "$PROJECT_DIR/CLAUDE.template.md"; do
    [[ -f "$f" ]] || continue
    if ! out=$("$RENDERER" check "$f" 2>&1); then
        warnings+="${out}"$'\n'
    fi
done

# User-wide CLAUDE.template.md → ~/.claude/CLAUDE.md
if [[ -f "${DOTFILES_AI}/CLAUDE.template.md" ]]; then
    if ! out=$("$RENDERER" check "${DOTFILES_AI}/CLAUDE.template.md" 2>&1); then
        warnings+="${out}"$'\n'
    fi
fi

# Skill template tree
if [[ -d "${DOTFILES_AI}/claude-code/skill-templates" ]] && \
   [[ -d "${HOME}/.claude/skills" ]]; then
    if ! out=$("$RENDERER" check-tree "${DOTFILES_AI}/claude-code/skill-templates" \
                   --to "${HOME}/.claude/skills" 2>&1); then
        warnings+="${out}"$'\n'
    fi
fi

# Agent template tree
if [[ -d "${DOTFILES_AI}/claude-code/agent-templates" ]] && \
   [[ -d "${HOME}/.claude/agents" ]]; then
    if ! out=$("$RENDERER" check-tree "${DOTFILES_AI}/claude-code/agent-templates" \
                   --to "${HOME}/.claude/agents" 2>&1); then
        warnings+="${out}"$'\n'
    fi
fi

[[ -z "$warnings" ]] && exit 0

echo "=== claude-md ==="
printf '%s' "$warnings"
echo "Refresh stale files via \`claude-md render <path>\` or \`claude-md render-tree <src> --to <dst>\`"
