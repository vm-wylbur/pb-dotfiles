#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-11
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mem-forget.sh
#
# The agent "forget" verb (Workstream B item W5, ratified neg-6b0a3bf5;
# engine contract = claude-mem PR #20). Tombstones a memory via
# POST /memory/:id/evict — never erases: the row keeps serving on
# GET /memory/:id (recovery surface) and disappears from every search/read
# path (W3 sweep). First-evictor-wins: re-forgetting returns the ORIGINAL
# tombstone with already_evicted=true.
#
# EVIDENCE-GATED (the W5 guardrail): evict_reason must be evidence, not
# assertion — one of exactly:
#     superseded-by <memory_id>          (16-hex id of the LIVE replacement)
#     contradicted-by-disk <path>        (the file that proves it wrong)
#     stale-as-of <YYYY-MM-DD>           (the date it stopped being true)
# Free-text "forget this" is refused. For superseded-by, the replacement id
# is verified live (exists + not itself tombstoned) before the evict fires —
# a supersedes-pointer at a dead target is a broken edge, and the pointer is
# load-bearing: W8 binds the distiller to it (no resurrection past it).
#
# Input  (JSON on stdin):  {"memory_id": "...", "reason": "...",
#                           "evicted_by"?}   (default: resolved agent id)
# Output (JSON on stdout): the engine response (tombstone row;
#                           already_evicted=true on a re-forget)
#
# Flags:
#   --dry-run    validate + print what would be sent, send nothing.
#                NOTE: the superseded-by followability check (GET the target,
#                refuse dead/missing) is LIVE-ONLY — a clean dry-run does not
#                prove the supersedes edge; only the real run verifies it.
#   --unforget   explicit recovery: clears the tombstone via /unevict
#                (input {"memory_id": "..."}; PB-or-explicit only, per W5)
#
# Id format: 15-16 hex accepted until claude-mem#22 lands (ids are stored
# unpadded but echoed zero-padded, so ~1-in-16 echoed ids have a leading
# zero their stored row lacks); tighten to exactly 16 after the migration.

set -uo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
UNFORGET=false
for arg in "$@"; do
    case "$arg" in
        --dry-run)  DRY_RUN=true ;;
        --unforget) UNFORGET=true ;;
        *) echo "usage: mem-forget.sh [--dry-run] [--unforget] < input.json" >&2; exit 2 ;;
    esac
done

SETTINGS="${HOME}/.claude/settings.json"
SECRET=$(jq -r '.env.CLAUDE_MEM_SECRET // empty' "$SETTINGS" 2>/dev/null)
if ! $DRY_RUN && [ -z "$SECRET" ]; then
    echo '{"error":"CLAUDE_MEM_SECRET not in settings.json"}' >&2; exit 1
fi
URL="${CLAUDE_MEM_URL:-http://snowball:3456}"

INPUT=$(cat)
MEMORY_ID=$(jq -r '.memory_id // empty' <<<"$INPUT" 2>/dev/null)
if ! [[ "$MEMORY_ID" =~ ^[0-9a-f]{15,16}$ ]]; then
    echo '{"error":"memory_id must be a 15-16 hex id (see claude-mem#22)"}' >&2; exit 1
fi

if $UNFORGET; then
    $DRY_RUN && { echo "{\"would_unevict\":\"$MEMORY_ID\"}"; exit 0; }
    # --fail-with-body: nonzero exit on HTTP error but the engine's JSON
    # error envelope still prints (a bare `curl: (22)` diagnoses nothing).
    exec curl --fail-with-body -sS -m 30 -H "X-Claude-Mem-Secret: $SECRET" \
        -X POST "${URL}/memory/${MEMORY_ID}/unevict"
fi

REASON=$(jq -r '.reason // empty' <<<"$INPUT")

# ── The evidence gate ─────────────────────────────────────────────────────
case "$REASON" in
    superseded-by\ *)
        TARGET="${REASON#superseded-by }"
        if ! [[ "$TARGET" =~ ^[0-9a-f]{15,16}$ ]]; then
            echo '{"error":"superseded-by needs a 15-16 hex memory_id"}' >&2; exit 1
        fi
        if [ "$TARGET" = "$MEMORY_ID" ]; then
            echo '{"error":"a memory cannot supersede itself"}' >&2; exit 1
        fi
        if ! $DRY_RUN; then
            # The pointer must land on a LIVE memory: W8 follows this edge.
            # Distinguish "target does not exist" (bad evidence) from "could
            # not verify" (auth/network/engine) — both abort, different words.
            HTTP=$(curl -sS -m 15 -o /tmp/mem-forget-row.$$ -w '%{http_code}' \
                -H "X-Claude-Mem-Secret: $SECRET" "${URL}/memory/${TARGET}" 2>/dev/null) || HTTP=000
            ROW=$(cat /tmp/mem-forget-row.$$ 2>/dev/null); rm -f /tmp/mem-forget-row.$$
            if [ "$HTTP" = "404" ]; then
                echo "{\"error\":\"superseding memory ${TARGET} not found; evidence must be followable\"}" >&2; exit 1
            elif [ "$HTTP" != "200" ]; then
                echo "{\"error\":\"could not verify superseding memory ${TARGET} (HTTP ${HTTP}); not forgetting on unverified evidence\"}" >&2; exit 1
            fi
            # Shape-check before trusting: an unexpected response must FAIL
            # the verification, not read as "live" (this edge is W8-load-bearing).
            if ! jq -e '.memory.memory_id' >/dev/null 2>&1 <<<"$ROW"; then
                echo "{\"error\":\"unexpected GET /memory response shape; not forgetting on unverified evidence\"}" >&2; exit 1
            fi
            if [ "$(jq -r '.memory.evicted_at // empty' <<<"$ROW")" != "" ]; then
                echo "{\"error\":\"superseding memory ${TARGET} is itself tombstoned; point at the live replacement\"}" >&2; exit 1
            fi
        fi
        ;;
    contradicted-by-disk\ *)
        TARGET="${REASON#contradicted-by-disk }"
        # Evidence must be path-SHAPED (this gate refuses free text); existence
        # is warn-only because the contradicting file may live on another host.
        # shellcheck disable=SC2088  # matching a LITERAL leading ~/ is the point
        if ! [[ "$TARGET" == /* || "$TARGET" == "~/"* ]]; then
            echo '{"error":"contradicted-by-disk needs an absolute path (/... or ~/...)"}' >&2; exit 1
        fi
        if ! [ -e "${TARGET/#\~/$HOME}" ]; then
            echo "mem-forget: warning — $TARGET not found on this host" >&2
        fi
        ;;
    stale-as-of\ *)
        TARGET="${REASON#stale-as-of }"
        if ! [[ "$TARGET" =~ ^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$ ]]; then
            echo '{"error":"stale-as-of needs a real YYYY-MM-DD date"}' >&2; exit 1
        fi
        ;;
    *)
        echo '{"error":"reason must be evidence: superseded-by <id> | contradicted-by-disk <path> | stale-as-of <date>"}' >&2
        exit 1
        ;;
esac

# evicted_by: caller wins, else the same identity resolution as mem-store.
EVICTED_BY=$(jq -r '.evicted_by // empty' <<<"$INPUT")
if [ -z "$EVICTED_BY" ]; then
    EVICTED_BY="${CLAUDE_MEM_AGENT_ID:-}"
    if [ -z "$EVICTED_BY" ] && [ -x "$LIB_DIR/negotiate-agent-id.sh" ]; then
        EVICTED_BY=$("$LIB_DIR/negotiate-agent-id.sh" 2>/dev/null || true)
    fi
fi
if [ -z "$EVICTED_BY" ]; then
    # Unlike a store, an ANONYMOUS forget is refused outright: the tombstone's
    # actor is what separates "agent said forget" from "policy evicted it".
    echo '{"error":"evicted_by did not resolve; an anonymous forget is not allowed"}' >&2; exit 1
fi

PAYLOAD=$(jq -nc --arg by "$EVICTED_BY" --arg r "$REASON" \
    '{evicted_by:$by, evict_reason:$r}')

if $DRY_RUN; then
    jq -nc --arg id "$MEMORY_ID" --argjson p "$PAYLOAD" \
        '{would_evict:$id, payload:$p}'
    exit 0
fi

exec curl --fail-with-body -sS -m 30 \
    -H "X-Claude-Mem-Secret: $SECRET" \
    -H 'Content-Type: application/json' \
    -X POST "${URL}/memory/${MEMORY_ID}/evict" \
    --data-binary "$PAYLOAD"
