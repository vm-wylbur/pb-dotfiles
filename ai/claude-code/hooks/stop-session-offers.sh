#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-05-28
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/stop-session-offers.sh
#
# Stop hook — end-of-session proactive handoff offer. Fires at most ONCE
# per session: once the session crosses a substantive-work threshold
# (assistant-turn count) and hasn't offered yet, it blocks a single time
# with a reason nudging /handoff (save state for the next session). A
# per-session flag in ~/.claude/state/<id>/ guarantees it never nags.
#
# Harness note: Stop fires on every turn end, and the only way to reach the
# model is decision:block (a forced continuation). There is no true
# "session end" signal, so this fires at the first turn past the threshold,
# not at the literal end. It is a one-shot backstop; /handoff (human-pulled)
# is the primary mechanism.
#
# Installed by install.sh section 5 jq as .hooks.Stop.
#
# stdin:  JSON with .session_id, .transcript_path
# stdout: nothing, or {"decision":"block","reason":...} to offer once
# exit:   always 0 (fail-safe — a Stop hook must never wedge the session)

MIN_TURNS="${CLAUDE_HANDOFF_MIN_TURNS:-8}"
STATE_ROOT="${CLAUDE_STATE_DIR:-$HOME/.claude/state}"

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

# Fail-safe: without a session id we cannot gate, so never offer (no nag risk).
[ -z "$SESSION_ID" ] && exit 0
[ -f "$TRANSCRIPT" ] || exit 0

STATE_DIR="$STATE_ROOT/$SESSION_ID"
FLAG="$STATE_DIR/handoff-offered"

# Once per session — hard guarantee.
[ -f "$FLAG" ] && exit 0

# Substantive-session signal: count assistant turns in the JSONL transcript.
# `-R` + `fromjson?` tolerates any malformed line without aborting the stream.
TURNS=$(jq -rR 'fromjson? | select(.type=="assistant") | "x"' "$TRANSCRIPT" 2>/dev/null | wc -l | tr -d ' ')
[ -z "$TURNS" ] && TURNS=0
[ "$TURNS" -lt "$MIN_TURNS" ] && exit 0

# Threshold crossed and not yet offered. Set the flag BEFORE emitting the
# block, so a flag-write failure fails toward "don't offer" rather than a
# re-offer loop. Only block if the flag was durably written.
mkdir -p "$STATE_DIR" 2>/dev/null
if : > "$FLAG" 2>/dev/null; then
    jq -n '{
        decision: "block",
        reason: "End-of-session check (fires once this session): substantive work happened here. If there is durable progress worth the next session knowing — decisions made, where things stand, gotchas, open threads — run /handoff to record it (it updates the project memory file). If nothing material needs saving, just stop again; this will not ask twice."
    }'
fi
exit 0
