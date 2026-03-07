#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-03-07
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/yaml-validate.sh
#
# PostToolUse hook: validate YAML syntax after any Edit or Write to a .yml/.yaml file.
# Catches syntax errors immediately, before pre-commit hooks or deployment.
#
# Install in ~/.claude/settings.json:
#   "PostToolUse": [{"matcher": "Edit|Write", "hooks": [{"type": "command",
#     "command": "bash ~/.claude/hooks/yaml-validate.sh"}]}]

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    # PostToolUse: file path is in tool_input
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except Exception:
    pass
" 2>/dev/null)

[[ -z "$FILE_PATH" ]] && exit 0
echo "$FILE_PATH" | grep -qE '\.ya?ml$' || exit 0
[[ -f "$FILE_PATH" ]] || exit 0

python3 -c "
import yaml, sys
try:
    yaml.safe_load(open(sys.argv[1]))
except yaml.YAMLError as e:
    print(f'YAML VALIDATION FAILED: {e}', file=sys.stderr)
    sys.exit(1)
" "$FILE_PATH"

if [ $? -ne 0 ]; then
    echo "Fix YAML syntax in $FILE_PATH before proceeding." >&2
    exit 1
fi

exit 0
