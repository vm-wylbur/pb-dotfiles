#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-09
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mem-suppress.sh
#
# Session-scoped suppress-list for recall results (Workstream B item W6,
# ratified neg-6b0a3bf5). "Stop showing me this memory for the rest of this
# session" — a read-time mask that recall-loop.sh applies at DISPLAY time.
# It NEVER touches the canonical store: suppression here is deliberately a
# different thing from a durable forget (the evidence-gated tombstone verb,
# W5, gated on the engine's read-path sweep). The separation is the
# archive-integrity guarantee — session noise provably never reaches the
# archive.
#
# Usage:
#   mem-suppress.sh add <memory_id> [reason]
#   mem-suppress.sh list
#   mem-suppress.sh ids        # TTL-pruned ["id",...] — the read surface
#                              # recall-loop.sh filters against; keeps the
#                              # file schema owned by this script alone
#   mem-suppress.sh remove <memory_id>
#   mem-suppress.sh clear
#
# The list is keyed by CLAUDE_CODE_SESSION_ID and entries expire after
# RECALL_SUPPRESS_TTL_HOURS (default 24) — a stale suppression must not
# silently outlive the session that judged the memory irrelevant.
#
# Env:
#   RECALL_LOOP_DIR            — state root, default ~/.claude/recall-loops
#   RECALL_SUPPRESS_TTL_HOURS  — entry TTL, default 24

set -uo pipefail

LOOP_DIR="${RECALL_LOOP_DIR:-$HOME/.claude/recall-loops}"
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-nosession}"
TTL_HOURS="${RECALL_SUPPRESS_TTL_HOURS:-24}"
FILE="$LOOP_DIR/suppress-$SESSION_ID.json"

mkdir -p "$LOOP_DIR"

err() { jq -n --arg e "$1" '{error:$e}' >&2; exit 1; }

now_epoch() { date -u +%s; }

ensure_file() {
    [ -f "$FILE" ] || jq -nc --arg s "$SESSION_ID" '{session_id:$s, entries:[]}' > "$FILE"
}

# Drop entries older than the TTL on every read/write touch.
prune() {
    local cutoff tmp
    cutoff=$(( $(now_epoch) - TTL_HOURS * 3600 ))
    tmp=$(mktemp)
    jq --argjson cutoff "$cutoff" \
        '.entries = [.entries[] | select(.added_epoch >= $cutoff)]' \
        "$FILE" > "$tmp" && mv "$tmp" "$FILE"
}

cmd="${1:-list}"
case "$cmd" in
    add)
        mid="${2:-}"
        [ -z "$mid" ] && err "add requires a memory_id"
        reason="${3:-}"
        ensure_file; prune
        tmp=$(mktemp)
        jq --arg mid "$mid" --arg reason "$reason" \
            --argjson epoch "$(now_epoch)" \
            --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '.entries = ([.entries[] | select(.memory_id != $mid)]
                + [{memory_id:$mid, reason:(if $reason=="" then null else $reason end),
                    added_at:$ts, added_epoch:$epoch}])' \
            "$FILE" > "$tmp" && mv "$tmp" "$FILE"
        jq -c '{suppressed: (.entries | length), session_id}' "$FILE"
        ;;
    remove)
        mid="${2:-}"
        [ -z "$mid" ] && err "remove requires a memory_id"
        ensure_file; prune
        tmp=$(mktemp)
        jq --arg mid "$mid" '.entries = [.entries[] | select(.memory_id != $mid)]' \
            "$FILE" > "$tmp" && mv "$tmp" "$FILE"
        jq -c '{suppressed: (.entries | length), session_id}' "$FILE"
        ;;
    list)
        ensure_file; prune
        jq -c '{session_id, ttl_hours: '"$TTL_HOURS"', entries}' "$FILE"
        ;;
    ids)
        if [ -f "$FILE" ]; then
            prune
            jq -c '[.entries[].memory_id]' "$FILE"
        else
            echo '[]'
        fi
        ;;
    clear)
        ensure_file
        tmp=$(mktemp)
        jq '.entries = []' "$FILE" > "$tmp" && mv "$tmp" "$FILE"
        jq -c '{suppressed: 0, session_id}' "$FILE"
        ;;
    *)
        err "unknown command: $cmd (add|remove|list|clear)"
        ;;
esac
