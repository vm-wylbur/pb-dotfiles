#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-03-07
# Updated: 2026-05-23 (cc-dots: refactor to compose lib/ scripts)
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/session-env.sh
#
# SessionStart hook: emit grounded environment facts before any task starts.
# Thin orchestrator — each line of output comes from a composable script in
# ~/.claude/lib/ that can also be invoked mid-session via the refresh skill.
#
# Install in ~/.claude/settings.json (handled by install.sh):
#   "SessionStart": [{"hooks": [{"type": "command",
#     "command": "bash ~/.claude/hooks/session-env.sh"}]}]

LIB="${HOME}/.claude/lib"

echo "=== Session environment ==="
bash "${LIB}/env.sh"
echo "CWD: $(pwd)"
bash "${LIB}/git-status.sh"
bash "${LIB}/gh-issues.sh"
bash "${LIB}/skills-list.sh"
bash "${LIB}/claude-md-mtime.sh"
bash "${LIB}/mcp-status.sh"
echo "Run /inventory to list installed skills, agents, modules, hooks, MCPs."
