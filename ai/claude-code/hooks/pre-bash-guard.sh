#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-04-28
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# ~/.claude/hooks/pre-bash-guard.sh
#
# PreToolUse hook for the Bash tool. Refuses argv patterns whose blast
# radius exceeded the agent's intent in incident 2026-04-28 (scott
# kill-cascade): negative-PID kills (process group), pkill -KILL/-9,
# kill -<sig> -1.
#
# Install in ~/.claude/settings.json:
#   "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command",
#     "command": "bash /home/pball/.claude/hooks/pre-bash-guard.sh"}]}]
#
# Exit 0 = allow. Exit 2 = block + stderr is fed back to Claude as the reason.
#
# Scope intentionally narrow: only catches the exact incident-class argv.
# A determined agent could still bypass via `bash -c '...'` or base64. This
# is a guardrail against accidents, not adversaries.

set -euo pipefail

INPUT=$(cat)

CMD=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', ''))
except Exception:
    pass
" 2>/dev/null)

[[ -z "$CMD" ]] && exit 0

block() {
    local pattern="$1"
    cat >&2 <<EOF
BLOCKED by ~/.claude/hooks/pre-bash-guard.sh

Detected dangerous pattern: $pattern

Background: 2026-04-28 scott incident. A 'kill -TERM -1748767' (PGID kill)
was issued under sudo and SIGTERMed ~30 system services. This hook refuses
that argv class at the Claude Code tool boundary, regardless of permission
mode.

If you mean to clean up tfcs orphan rsyncs, invoke the sanctioned script:
  sudo /usr/local/bin/reap-tfcs-rsync-orphans.sh --check
  sudo /usr/local/bin/reap-tfcs-rsync-orphans.sh --kill
The hook does not see the script's internal kill syscalls.

If you genuinely need this raw form, type it yourself outside Claude.
EOF
    exit 2
}

# kill <-signal> <-PGID> — process-group kill. Catches:
#   kill -TERM -1748767
#   kill -9 -1
#   kill -SIGKILL -- -1234
if printf '%s' "$CMD" | grep -qE '\bkill[[:space:]]+(--[[:space:]]+)?-[A-Za-z0-9]+[[:space:]]+(--[[:space:]]+)?-[0-9]+'; then
    block "kill with negative PID (process-group kill)"
fi

# kill -- -<n>  (no signal, explicit-end-of-options, negative target)
if printf '%s' "$CMD" | grep -qE '\bkill[[:space:]]+--[[:space:]]+-[0-9]+'; then
    block "kill -- -<n> (process-group / all-processes kill)"
fi

# pkill with KILL / -9 — uncatchable, no graceful shutdown
if printf '%s' "$CMD" | grep -qE '\bpkill\b[^|;&]*(-9\b|-KILL\b|--signal[[:space:]=]+(9|KILL)\b)'; then
    block "pkill -KILL / -9 (uncatchable signal)"
fi

# dd writing to a raw block device — overwrites filesystem irrecoverably
# Catches: dd of=/dev/sda, dd of=/dev/nvme0n1, dd of=/dev/mmcblk0, etc.
# Excludes loop devices (legitimate use with image files via losetup).
if printf '%s' "$CMD" | grep -qE '\bdd[[:space:]][^|;&]*\bof=/dev/(sd|nvme|hd|mmcblk|disk)'; then
    block "dd of=/dev/<disk> (raw block device write)"
fi

exit 0
