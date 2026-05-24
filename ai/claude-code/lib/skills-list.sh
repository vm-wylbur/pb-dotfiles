#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-23
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/skills-list.sh
#
# Print comma-separated names of installed user-wide skills.
# Silent if no skills found.

SKILLS=$(find -L ~/.claude/skills -name SKILL.md 2>/dev/null \
    | while IFS= read -r f; do basename "$(dirname "$f")"; done \
    | sort | tr '\n' ',' | sed 's/,$//')

if [ -n "$SKILLS" ]; then
    echo "Skills: ${SKILLS}"
fi
