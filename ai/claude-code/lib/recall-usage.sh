#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-31
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/recall-usage.sh
#
# Usage telemetry for the /recall skill (Track 3C). Scans Claude Code
# session transcripts for invocations of a skill — both user-typed
# (a user message carrying <command-name>/recall</command-name>) and
# model-invoked (a Skill tool_use with input.skill == recall) — and
# prints a chronological index (when / by whom / which session / topic)
# plus a summary count.
#
# Invocation-level ONLY. It answers IF, WHEN, HOW OFTEN, and BY WHOM
# recall fired. It does NOT judge whether a given recall was useful or
# fired at the right moment, and it cannot see false negatives (a >2x
# repeat where recall should have fired but didn't) — those require
# reading the transcript, or, eventually, Track 3B's thrash detector.
# To assess usefulness, open the listed session .jsonl at the printed
# timestamp and read the surrounding turns. No metric substitutes for
# that read.
#
# Usage:
#   bash recall-usage.sh                  # all projects, skill=recall
#   bash recall-usage.sh <skill>          # any skill name (e.g. handoff)
#   bash recall-usage.sh <skill> '<glob>' # narrow the transcript glob
#
# Env:
#   CLAUDE_PROJECTS — transcripts root, default ~/.claude/projects

set -uo pipefail

SKILL="${1:-recall}"
ROOT="${CLAUDE_PROJECTS:-$HOME/.claude/projects}"

shopt -s nullglob
if [ -n "${2:-}" ]; then
    # shellcheck disable=SC2206  # intentional glob expansion
    FILES=( $2 )
else
    FILES=( "$ROOT"/*/*.jsonl )
fi

if [ ${#FILES[@]} -eq 0 ]; then
    echo "no transcripts under $ROOT" >&2
    exit 0
fi

# One TSV row per invocation: timestamp \t invoker \t session \t topic
rows() {
    local f sess
    for f in "${FILES[@]}"; do
        sess=$(basename "$f" .jsonl)
        jq -r --arg skill "$SKILL" --arg sess "$sess" '
          # collapse whitespace and cap a topic at 80 chars for the index
          def preview: gsub("\\s+"; " ") | if length > 80 then .[0:79] + "…" else . end;
          . as $top
          | if .type=="assistant" and (.message.content | type=="array") then
              .message.content[]
              | select(.type=="tool_use" and .name=="Skill" and .input.skill==$skill)
              | [$top.timestamp, "model", $sess, ((.input.args // "" | tostring) | preview)]
            elif .type=="user"
                 and ((.message.content | tostring) | test("<command-name>/" + $skill + "\\b")) then
              [$top.timestamp, "user", $sess,
               ((try ((.message.content | tostring) | capture("<command-args>(?<a>[^<]*)").a) catch "") | preview)]
            else empty end
          | @tsv
        ' "$f" 2>/dev/null
    done
}

ALL=$(rows | sort)

if [ -z "$ALL" ]; then
    echo "no /$SKILL invocations found across ${#FILES[@]} transcript(s)."
    exit 0
fi

printf '%-24s  %-6s  %-32s  %s\n' "TIMESTAMP (UTC)" "BY" "SESSION" "TOPIC/ARGS"
printf '%s\n' "$ALL" | while IFS=$'\t' read -r ts by sess topic; do
    printf '%-24s  %-6s  %-32s  %s\n' "$ts" "$by" "$sess" "$topic"
done

TOTAL=$(printf '%s\n' "$ALL" | grep -c .)
USERN=$(printf '%s\n' "$ALL" | awk -F'\t' '$2=="user"'  | grep -c .)
MODELN=$(printf '%s\n' "$ALL" | awk -F'\t' '$2=="model"' | grep -c .)
echo ""
echo "── /$SKILL: $TOTAL invocation(s) — $USERN user, $MODELN model — across ${#FILES[@]} transcript(s)."
echo "   Usefulness/timing isn't measurable here: open a session .jsonl at the listed timestamp and read the turns around it."
