#!/usr/bin/env bash
# Resolve the negotiate agent_id from the current repo's CLAUDE.md.
# Used by the negotiate skill at session start.
#
# Resolution order:
#   1. An explicit line:        "My negotiate agent_id is: cc-<repo>"
#   2. The repo identity line:  "This repo's Claude is **`cc-<repo>`** ..."
# (2) lets a repo that already declares its agent identity in CLAUDE.md work
# without a duplicate registration line.
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
    exit 1
fi

# 1) Preferred: an explicit "My negotiate agent_id is:" line.
#    `|| true` keeps a no-match from tripping `set -e` so the fallback can run.
agent_id=$(grep -m1 "^My negotiate agent_id is:" "$claude_md" 2>/dev/null \
    | sed 's/^My negotiate agent_id is:[[:space:]]*//; s/[[:space:]]*$//' || true)

# 2) Fallback: the repo identity line, e.g. "This repo's Claude is **`cc-dots`** 🧷".
#    Pull the first cc-<repo> token regardless of the surrounding markdown.
if [[ -z "$agent_id" ]]; then
    agent_id=$(grep -m1 "^This repo's Claude is" "$claude_md" 2>/dev/null \
        | grep -oE 'cc-[a-z0-9][a-z0-9-]*' | head -1 || true)
fi

if [[ -z "$agent_id" ]]; then
    echo "error: could not resolve a negotiate agent_id from $claude_md" >&2
    echo "  add an explicit line:    My negotiate agent_id is: cc-<repo>" >&2
    echo "  or an identity line:     This repo's Claude is **\`cc-<repo>\`**" >&2
    exit 1
fi

echo "$agent_id"
