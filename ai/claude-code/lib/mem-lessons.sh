#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-15
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/mem-lessons.sh
#
# Shared primitive: the recent LESSONS from claude-mem, date-windowed.
# A reusable mechanical surface that any consumer (the /fleet-brief skill,
# cc-hmon's report, ...) can call to get "what did we learn lately" as
# structured JSON. The SEMANTIC top-N selection ("the 2-3 most important
# lessons") is left to the calling agent — this script does the mechanical
# part the agent can't cheaply do: fetch, date-window, and shape-flag.
#
# Why a primitive and not skill-embedded logic: lesson extraction is wanted
# in more than one report. Build it once; both consumers render from the
# same JSON.
#
# How a "lesson" is identified (claude-mem has no first-class lesson type):
#   - TYPE pre-filter: keep type in {code, decision} — that is where
#     lessons live; `reference` is status/pointers and `conversation` is
#     context, both noise for a lessons digest. Override with --all-types.
#   - SHAPE flag: content matching lesson cues (don't/never/unreliable/
#     root cause/gotcha/beats/...) is flagged lesson_shaped=true. This is a
#     RANKING HINT, not a gate — the script returns all windowed
#     {code,decision} memories so the agent can still catch a semantic
#     lesson the cues missed; --shaped-only narrows to flagged ones.
# claude-mem auto-tags are noisy (a dotfiles memory gets tagged "react"),
# so tags are deliberately NOT used as the lesson signal.
#
# Date-windowing is client-side: the GET /recent endpoint
# (mem-recent.sh) takes a count, not a date. We fetch a cap and filter on
# the ISO-8601 `created` field by lexicographic comparison — which is
# CORRECT for ISO-8601 (it sorts chronologically as text), unlike the
# version-string footgun. `truncated:true` means the fetch cap was hit and
# older in-window lessons may be missing (raise --n).
#
# Usage:
#   bash mem-lessons.sh                       # lessons since yesterday 00:00
#   bash mem-lessons.sh --since 2026-06-14    # since a date (YYYY-MM-DD)
#   bash mem-lessons.sh --since 2026-06-14T08:00:00Z   # since an instant
#   bash mem-lessons.sh --n 200               # raise the fetch cap
#   bash mem-lessons.sh --project pb-dotfiles # one project's tag only
#   bash mem-lessons.sh --shaped-only         # only cue-flagged lessons
#   bash mem-lessons.sh --all-types           # include reference/conversation
#
# Output (JSON on stdout), always valid even when claude-mem is dark:
#   {since, source, fetched, windowed, returned, truncated,
#    lessons:[{id, created, age, type, lesson_shaped, content}]}

set -uo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SINCE=""
CAP=100
PROJECT=""
SHAPED_ONLY=false
ALL_TYPES=false
while [ $# -gt 0 ]; do
    case "$1" in
        # `shift 2` fails (rc!=0) when the flag is the last arg with no value;
        # catch that so a trailing `--since` errors cleanly instead of looping.
        --since)        SINCE="${2:-}";   shift 2 || { echo '{"error":"--since needs a value"}'   >&2; exit 2; } ;;
        --n)            CAP="${2:-}";     shift 2 || { echo '{"error":"--n needs a value"}'        >&2; exit 2; } ;;
        --project)      PROJECT="${2:-}"; shift 2 || { echo '{"error":"--project needs a value"}'  >&2; exit 2; } ;;
        --shaped-only)  SHAPED_ONLY=true; shift ;;
        --all-types)    ALL_TYPES=true;   shift ;;
        -h|--help)      sed -n '/^# Usage:/,/^set /p' "$0" | sed '/^set /d'; exit 0 ;;
        *)              echo "{\"error\":\"unknown flag: $1\"}" >&2; exit 2 ;;
    esac
done

# --n must be a positive integer, else the later `--argjson cap` crashes jq
# (no JSON on stdout, nonzero exit) — breaking the always-valid-JSON contract.
case "$CAP" in
    ''|*[!0-9]*) echo '{"error":"--n must be a positive integer"}' >&2; exit 2 ;;
esac

# Default window: start of yesterday (matches the fleet-brief day window).
# Portable: BSD date (-v) first, GNU date (-d) fallback.
if [ -z "$SINCE" ]; then
    SINCE=$(date -v-1d +%Y-%m-%d 2>/dev/null \
            || date -d "1 day ago" +%Y-%m-%d 2>/dev/null \
            || date +%Y-%m-%d)
fi

# Lesson cues (case-insensitive). A hint for ranking, not a hard filter.
CUES='lesson|gotcha|pitfall|caveat|footgun|root cause|do not |don'"'"'t|never |always |unreliable|beats |class to watch|watch for|the hard way|learned|supersed|correction to|trap\b'

mem_raw=$(bash "$LIB_DIR/mem-recent.sh" --n "$CAP" ${PROJECT:+--project "$PROJECT"} 2>/dev/null)

if ! memories=$(jq -ce '.memories // []' <<<"$mem_raw" 2>/dev/null); then
    # claude-mem dark: emit a valid empty result, flagged.
    jq -n --arg since "$SINCE" \
        '{since:$since, source:"unreachable", fetched:0, windowed:0,
          returned:0, truncated:false, lessons:[]}'
    exit 0
fi

# Pipe the (potentially large) memory blob via STDIN, not --argjson: a big
# claude-mem store (100 memories x several KB) overflows ARG_MAX as an argv
# value and jq fails to exec ("Argument list too long", exit 126, no JSON).
# stdin has no such ceiling. (Reported by cc-hmon on hrdag-monitor#32.)
printf '%s' "$memories" | jq \
    --arg since "$SINCE" \
    --arg cues "$CUES" \
    --argjson shaped_only "$SHAPED_ONLY" \
    --argjson all_types "$ALL_TYPES" '
    . as $mem
    | ($mem | length) as $fetched
    # Robust truncation: if the OLDEST memory we fetched is still inside the
    # window, the fetch ran out before the window did — older in-window
    # lessons may be missing. Catches a server-side cap below our --n too.
    # Drop null `created` first, else `min` returns null and masks truncation.
    | ($mem | map(.created) | map(select(. != null)) | min) as $oldest
    | (if $oldest == null then false else ($oldest >= $since) end) as $truncated
    | ($mem | map(select(.created >= $since))) as $windowed
    | ($windowed
        | (if $all_types then .
           else map(select(.type == "code" or .type == "decision")) end)
        | map(. + {lesson_shaped: ((.content // "") | test($cues; "i"))})
        | (if $shaped_only then map(select(.lesson_shaped)) else . end)
        # Order: lesson_shaped first, newest within each group. jq sort_by is
        # STABLE, so sort newest-first, then stably by the shaped key.
        | (sort_by(.created) | reverse)
        | sort_by(if .lesson_shaped then 0 else 1 end)
        | map({id, created, age, type, lesson_shaped, content})
      ) as $lessons
    | {since:$since, source:"reachable",
       fetched:$fetched, windowed:($windowed|length),
       returned:($lessons|length),
       truncated:$truncated,
       lessons:$lessons}
    '
