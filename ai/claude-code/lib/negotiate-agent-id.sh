#!/usr/bin/env bash
# Resolve the negotiate agent_id from the current repo's CLAUDE.md.
# Used by the negotiate skill at session start.
#
# Usage: ~/.claude/lib/negotiate-agent-id.sh
# Prints the agent_id (e.g. "cc-ntx") to stdout.

set -euo pipefail

if claude_md="$(git rev-parse --show-toplevel 2>/dev/null)/CLAUDE.md" && [[ -f "$claude_md" ]]; then
    :
elif [[ -f "./CLAUDE.md" ]]; then
    claude_md="./CLAUDE.md"
else
    echo "error: CLAUDE.md not found at repo root or ./CLAUDE.md" >&2
    echo "  add the agent_id line: 'My negotiate agent_id is: cc-<repo>'" >&2
    exit 1
fi

agent_id=$(grep -m1 "^My negotiate agent_id is:" "$claude_md" 2>/dev/null \
    | sed 's/^My negotiate agent_id is:[[:space:]]*//' \
    | sed 's/[[:space:]]*$//')

if [[ -z "$agent_id" ]]; then
    echo "error: 'My negotiate agent_id is: cc-X' line not found in $claude_md" >&2
    echo "  run: echo \"My negotiate agent_id is: cc-\$(basename \$PWD)\" >> CLAUDE.md" >&2
    exit 1
fi

echo "$agent_id"
