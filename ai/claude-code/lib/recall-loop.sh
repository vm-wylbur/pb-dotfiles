#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-09
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/recall-loop.sh
#
# Loop orchestrator for iterative recall over claude-mem (Workstream A,
# ratified neg-6b0a3bf5). Wraps mem-search.sh per iteration and owns the
# mechanical half of the loop: iteration budget, candidate-churn detection,
# the query-moved guard, suppress-list filtering, and unconditional local
# trajectory telemetry. The Claude seat owns judgment (reading content,
# deciding sufficiency); this script owns control.
#
# Subcommands (JSON on stdin, JSON on stdout):
#
#   iterate (default)
#     in:  {"query":"...", "limit":N?, "loop_id":"..."?, "floor":F?}
#          omit loop_id on the first iteration; reuse the returned one after
#     out: {"loop_id","iteration","stop_hint","new_count","seen_total",
#           "query_moved","max_similarity","above_floor","suppressed_count",
#           "memories":[...]}
#
#   verdict
#     in:  {"loop_id":"...", "iteration":N, "verdict":"sufficient|insufficient",
#           "outcome":"satisfied|budget-exhausted|escalated"?}
#          outcome only on the terminal iteration (the loop's stop step)
#     out: {"recorded":true, ...}
#
# stop_hint values (the structural critic — cascade rung 1; the agent's
# content judgment is rung 3 and always wins on "stop early because satisfied"):
#   continue-ok      — loop may continue if the agent judges insufficient
#   saturated        — no new candidates AND the query genuinely moved:
#                      more searching is unlikely to help; stop honestly
#   rephrase-harder  — no new candidates but the query barely changed
#                      (pseudo-saturation guard): a stop now would measure the
#                      reformulator's laziness, not corpus exhaustion
#   budget-exhausted — iteration cap reached (default 3); stop and record
#
# Telemetry: every iteration appends one JSONL line to
# ~/.claude/recall-loops/trajectory.jsonl UNCONDITIONALLY — a first-try miss
# is recorded even when a later iteration succeeds (the honesty interlock:
# the loop must not paper over single-shot recall gaps). Suppressed memories
# are filtered from DISPLAY only; they still count as retrieved in telemetry.
#
# Forward-compat (L4, engine-side, not yet deployed): when /search returns
# search_id and POST /search-verdict exists, `iterate` captures search_id per
# iteration and `verdict` POSTs {search_id, verdict, iteration, loop_id,
# outcome?} alongside the local JSONL (which stays, as the local mirror).
#
# Env overrides:
#   CLAUDE_MEM_URL          — passed through to mem-search.sh
#   RECALL_LOOP_DIR         — state root, default ~/.claude/recall-loops
#   RECALL_LOOP_MAX_ITER    — iteration budget, default 3
#   RECALL_LOOP_FLOOR       — cosine floor for the above_floor hint, default 0.35
#   RECALL_LOOP_MOVED_MAX   — max token-Jaccard for "query moved", default 0.6

set -uo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOOP_DIR="${RECALL_LOOP_DIR:-$HOME/.claude/recall-loops}"
MAX_ITER="${RECALL_LOOP_MAX_ITER:-3}"
DEFAULT_FLOOR="${RECALL_LOOP_FLOOR:-0.35}"
MOVED_MAX="${RECALL_LOOP_MOVED_MAX:-0.6}"
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-nosession}"

mkdir -p "$LOOP_DIR"

err() { jq -n --arg e "$1" '{error:$e}' >&2; exit 1; }

# Token-set Jaccard between two strings: lowercase, alnum-split, each token
# truncated to its first 5 chars (poor-man's stemming so "evals"/"eval",
# "results"/"result" count as the SAME token — a plural-swap rephrase must
# not register as a moved query), unique.
jaccard() {
    local a b
    a=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' | cut -c1-5 | sort -u | grep -v '^$')
    b=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '\n' | cut -c1-5 | sort -u | grep -v '^$')
    local inter union
    inter=$(comm -12 <(printf '%s\n' "$a") <(printf '%s\n' "$b") | grep -c . || true)
    union=$(printf '%s\n%s\n' "$a" "$b" | sort -u | grep -c . || true)
    if [ "$union" -eq 0 ]; then echo "0"; else
        awk -v i="$inter" -v u="$union" 'BEGIN{printf "%.3f", i/u}'
    fi
}

cmd_verdict() {
    local input loop_id iteration verdict outcome state_file
    input=$(cat)
    loop_id=$(jq -r '.loop_id // empty' <<<"$input")
    iteration=$(jq -r '.iteration // empty' <<<"$input")
    verdict=$(jq -r '.verdict // empty' <<<"$input")
    outcome=$(jq -r '.outcome // empty' <<<"$input")
    [ -z "$loop_id" ] && err "verdict requires loop_id"
    [ -z "$iteration" ] && err "verdict requires iteration"
    case "$verdict" in sufficient|insufficient) ;; *) err "verdict must be sufficient|insufficient" ;; esac
    case "$outcome" in ""|satisfied|budget-exhausted|escalated) ;; *) err "outcome must be satisfied|budget-exhausted|escalated" ;; esac
    state_file="$LOOP_DIR/$loop_id.json"
    [ -f "$state_file" ] || err "unknown loop_id: $loop_id"

    jq -nc --arg loop_id "$loop_id" --arg session_id "$SESSION_ID" \
        --argjson iteration "$iteration" --arg verdict "$verdict" --arg outcome "$outcome" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{type:"verdict", ts:$ts, loop_id:$loop_id, session_id:$session_id,
          iteration:$iteration, verdict:$verdict,
          outcome:(if $outcome=="" then null else $outcome end)}' \
        >> "$LOOP_DIR/trajectory.jsonl"
    # L4 forward-compat: POST /search-verdict lands here once the endpoint exists.
    jq -n --arg loop_id "$loop_id" --argjson iteration "$iteration" \
        --arg verdict "$verdict" '{recorded:true, loop_id:$loop_id, iteration:$iteration, verdict:$verdict}'
}

cmd_iterate() {
    local input query limit loop_id floor state_file prev_query iteration
    input=$(cat)
    query=$(jq -r '.query // empty' <<<"$input")
    [ -z "$query" ] && err "iterate requires query"
    limit=$(jq -r '.limit // 10' <<<"$input")
    # tonumber? guards a non-numeric floor (e.g. "abc") from reaching --argjson
    # downstream, where it would kill the pipeline mid-iteration.
    floor=$(jq -r --arg d "$DEFAULT_FLOOR" '(.floor | tonumber?) // ($d|tonumber)' <<<"$input")
    loop_id=$(jq -r '.loop_id // empty' <<<"$input")

    if [ -z "$loop_id" ]; then
        loop_id=$(uuidgen | tr '[:upper:]' '[:lower:]')
        state_file="$LOOP_DIR/$loop_id.json"
        jq -nc --arg loop_id "$loop_id" --arg session_id "$SESSION_ID" \
            --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '{loop_id:$loop_id, session_id:$session_id, started_at:$ts, queries:[], seen_ids:[]}' \
            > "$state_file"
    else
        state_file="$LOOP_DIR/$loop_id.json"
        [ -f "$state_file" ] || err "unknown loop_id: $loop_id (omit loop_id to start a new loop)"
    fi

    iteration=$(( $(jq '.queries | length' "$state_file") + 1 ))
    prev_query=$(jq -r '.queries[-1] // empty' "$state_file")

    # --- the query-moved guard (pseudo-saturation twin, L3) ---
    local moved jac="1.000"
    if [ -z "$prev_query" ]; then
        moved=true
    else
        jac=$(jaccard "$query" "$prev_query")
        moved=$(awk -v j="$jac" -v m="$MOVED_MAX" 'BEGIN{print (j<m) ? "true" : "false"}')
    fi

    # --- search ---
    local results
    results=$(jq -nc --arg q "$query" --argjson l "$limit" '{query:$q, limit:$l}' \
        | bash "$LIB_DIR/mem-search.sh") || {
        jq -nc --arg loop_id "$loop_id" --arg session_id "$SESSION_ID" \
            --argjson iteration "$iteration" --arg q "$query" \
            --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '{type:"search-error", ts:$ts, loop_id:$loop_id, session_id:$session_id,
              iteration:$iteration, query:$q}' >> "$LOOP_DIR/trajectory.jsonl"
        err "mem-search.sh failed (iteration $iteration logged)"
    }
    # Guard: a response jq cannot parse (e.g. unescaped control chars in stored
    # content), or one that is not EXACTLY one JSON document (a corrupted /
    # interleaved body parses as a multi-doc stream and silently doubles every
    # downstream jq read), must fail loudly WITH the payload preserved for
    # diagnosis, not die mid-pipeline with a cryptic parse error.
    if [ "$(jq -s 'length' 2>/dev/null <<<"$results")" != "1" ]; then
        local badfile
        badfile="$LOOP_DIR/bad-response-$(date -u +%Y%m%dT%H%M%SZ).json"
        printf '%s' "$results" > "$badfile"
        jq -nc --arg loop_id "$loop_id" --arg session_id "$SESSION_ID" \
            --argjson iteration "$iteration" --arg q "$query" --arg f "$badfile" \
            --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            '{type:"bad-response", ts:$ts, loop_id:$loop_id, session_id:$session_id,
              iteration:$iteration, query:$q, saved_to:$f}' >> "$LOOP_DIR/trajectory.jsonl"
        err "unparseable /search response saved to $badfile (iteration $iteration logged)"
    fi

    # --- churn vs seen (rung 1 structural critic) ---
    local returned_ids new_ids new_count seen_total max_sim above_floor
    returned_ids=$(jq -c '[.memories[].memory_id]' <<<"$results")
    new_ids=$(jq -c --argjson ret "$returned_ids" \
        '.seen_ids as $seen | [$ret[] | select(. as $id | ($seen | index($id)) | not)]' \
        "$state_file")
    new_count=$(jq 'length' <<<"$new_ids")
    max_sim=$(jq '[.memories[].similarity] | max // 0' <<<"$results")
    above_floor=$(jq --argjson f "$floor" '[.memories[] | select(.similarity >= $f)] | length' <<<"$results")

    # --- update state ---
    local tmp
    tmp=$(mktemp)
    jq --arg q "$query" --argjson ret "$returned_ids" \
        '.queries += [$q] | .seen_ids = ((.seen_ids + $ret) | unique)' \
        "$state_file" > "$tmp" && mv "$tmp" "$state_file"
    seen_total=$(jq '.seen_ids | length' "$state_file")

    # --- stop hint ---
    local stop_hint
    if [ "$iteration" -ge "$MAX_ITER" ]; then
        stop_hint="budget-exhausted"
    elif [ "$new_count" -eq 0 ] && [ "$moved" = "true" ]; then
        stop_hint="saturated"
    elif [ "$new_count" -eq 0 ]; then
        stop_hint="rephrase-harder"
    else
        stop_hint="continue-ok"
    fi

    # --- telemetry, UNCONDITIONAL, before output (honesty interlock, L5) ---
    jq -nc --arg loop_id "$loop_id" --arg session_id "$SESSION_ID" \
        --argjson iteration "$iteration" --arg q "$query" \
        --argjson returned "$returned_ids" --argjson new_count "$new_count" \
        --argjson moved "$moved" --arg jac "$jac" \
        --argjson max_sim "$max_sim" --arg stop_hint "$stop_hint" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{type:"iteration", ts:$ts, loop_id:$loop_id, session_id:$session_id,
          iteration:$iteration, query:$q, returned_ids:$returned,
          new_count:$new_count, query_moved:$moved, query_jaccard:($jac|tonumber),
          max_similarity:$max_sim, stop_hint:$stop_hint}' \
        >> "$LOOP_DIR/trajectory.jsonl"

    # --- suppress-list filter (W6): display-only, never the canonical store,
    #     and never the telemetry above. Read via mem-suppress.sh ids so the
    #     file schema (and the TTL prune) has exactly one owner. ---
    local suppressed_ids
    suppressed_ids=$(bash "$LIB_DIR/mem-suppress.sh" ids 2>/dev/null || echo '[]')
    jq -e 'type == "array"' >/dev/null 2>&1 <<<"$suppressed_ids" || suppressed_ids='[]'

    jq -c --arg loop_id "$loop_id" --argjson iteration "$iteration" \
        --arg stop_hint "$stop_hint" --argjson new_count "$new_count" \
        --argjson seen_total "$seen_total" --argjson moved "$moved" \
        --argjson max_sim "$max_sim" --argjson above_floor "$above_floor" \
        --argjson sup "$suppressed_ids" \
        '{loop_id:$loop_id, iteration:$iteration, stop_hint:$stop_hint,
          new_count:$new_count, seen_total:$seen_total, query_moved:$moved,
          max_similarity:$max_sim, above_floor:$above_floor,
          suppressed_count:([.memories[] | select(.memory_id as $id | $sup | index($id))] | length),
          memories:[.memories[] | select(.memory_id as $id | ($sup | index($id)) | not)]}' \
        <<<"$results"
}

case "${1:-iterate}" in
    iterate) cmd_iterate ;;
    verdict) cmd_verdict ;;
    *) err "unknown subcommand: $1 (iterate|verdict)" ;;
esac
