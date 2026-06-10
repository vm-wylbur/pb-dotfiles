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
# ~/.claude/lib/ (each invocable directly mid-session; the refresh skill that
# used to wrap them was retired 2026-06-10, unused since the hooks landed).
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
bash "${LIB}/triage-issues.sh" </dev/null | jq -r '
    if (.issues // []) | length == 0 then empty
    else
        "Triage queue (\(.signature), \(.issues | length) issue(s) you filed):",
        (.issues[] |
            "  #\(.number)  \(.title)",
            (if .body then
                "      body: " + (
                    (.body | gsub("\\s+"; " ") | .[0:140]) +
                    (if (.body | length) > 140 then "…" else "" end)
                )
             else empty end),
            (if .recent_comment then
                "      latest (\(.recent_comment.createdAt[0:10])): " + (
                    (.recent_comment.body | gsub("\\s+"; " ") | .[0:120]) +
                    (if (.recent_comment.body | length) > 120 then "…" else "" end)
                )
             else empty end)
        )
    end' 2>/dev/null
bash "${LIB}/skills-list.sh"
bash "${LIB}/claude-md-mtime.sh"
bash "${LIB}/mcp-status.sh"
echo "Run /inventory to list installed skills, agents, modules, hooks, MCPs."
