#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-03-07
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/session-env.sh
#
# SessionStart hook: emit grounded environment facts before any task starts.
# Covers: host, arch, date, cwd, git status, open GH issues (current repo), skills.
#
# Install in ~/.claude/settings.json:
#   "SessionStart": [{"hooks": [{"type": "command",
#     "command": "bash ~/.claude/hooks/session-env.sh"}]}]

HOST=$(hostname -s)
ARCH=$(uname -m)
DATE=$(date +%Y-%m-%d)

echo "=== Session environment ==="
echo "Host: ${HOST} | Arch: ${ARCH} | Date: ${DATE}"
echo "CWD: $(pwd)"

# Git context + GH issues
if git rev-parse --git-dir &>/dev/null 2>&1; then
    REPO=$(basename "$(git rev-parse --show-toplevel)")
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    LAST=$(git log --oneline -1 2>/dev/null)

    if [ "$DIRTY" -gt 0 ]; then
        echo "Git: ${REPO} | ${BRANCH} (dirty: ${DIRTY} files) | ${LAST}"
    else
        echo "Git: ${REPO} | ${BRANCH} (clean) | ${LAST}"
    fi

    # Open GH issues for current repo (graceful no-op if gh unavailable or not a GH repo)
    if command -v gh &>/dev/null; then
        ISSUES=$(gh issue list --state open --limit 10 --json number,title 2>/dev/null \
            | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for i in data:
        print(f'  #{i[\"number\"]}  {i[\"title\"]}')
except Exception:
    pass
" 2>/dev/null)
        if [ -n "$ISSUES" ]; then
            echo "Open issues (${REPO}):"
            echo "$ISSUES"
        fi
    fi
fi

# Skills
SKILLS=$(find -L ~/.claude/skills -name SKILL.md 2>/dev/null \
    | while IFS= read -r f; do basename "$(dirname "$f")"; done \
    | sort | tr '\n' ',' | sed 's/,$//')
if [ -n "$SKILLS" ]; then
    echo "Skills: ${SKILLS}"
fi
