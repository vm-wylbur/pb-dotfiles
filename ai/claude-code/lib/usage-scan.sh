#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-10
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/usage-scan.sh
#
# Usage telemetry across the whole agent environment: which skills,
# agents, and lib scripts actually get used, scanned from Claude Code
# session transcripts. Generalizes recall-usage.sh (single-skill) to the
# full inventory — the prune-vs-invest evidence base.
#
# Counts BOTH invocation forms:
#   skills — model-invoked (Skill tool_use) AND user-typed (/command,
#            recorded as <command-name> in user messages)
#   agents — Agent/Task tool_use, with locally-maintained agents (from
#            ai/claude-code/agent-templates/) marked `*ours`
#   lib    — Bash tool_use whose command mentions a lib script by name
#
# Known undercounts, stated so the prune call is honest:
#   - lib-from-lib composition is invisible (recall-loop.sh calling
#     mem-search.sh internally logs only the outer command)
#   - hooks don't appear in transcripts at all (they run harness-side)
#   - the window is the transcript retention period (~cleanupPeriodDays),
#     and ONLY this host — run per host for the full picture
#
# Usage:
#   usage-scan.sh                # all transcripts under ~/.claude/projects
#   usage-scan.sh --since 2026-06-01
#
# Env:
#   CLAUDE_PROJECTS — transcripts root, default ~/.claude/projects
#   DOTFILES        — repo root, default ~/dotfiles

set -uo pipefail

ROOT="${CLAUDE_PROJECTS:-$HOME/.claude/projects}"
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
SINCE=""
[ "${1:-}" = "--since" ] && SINCE="${2:-}"

shopt -s nullglob
FILES=( "$ROOT"/*/*.jsonl )
[ ${#FILES[@]} -eq 0 ] && { echo "no transcripts under $ROOT" >&2; exit 0; }

# shellcheck disable=SC2012  # controlled dirs, no exotic filenames
LIB_NAMES=$(cd "$DOTFILES/ai/claude-code/lib" && ls -- *.sh *.py 2>/dev/null | jq -Rnc '[inputs]')
# shellcheck disable=SC2012
OUR_AGENTS=$(cd "$DOTFILES/ai/claude-code/agent-templates" 2>/dev/null \
    && ls -- *.md 2>/dev/null | sed 's/\.template//; s/\.md$//' | jq -Rnc '[inputs]' || echo '[]')

# One pass per transcript -> TSV events: kind, key, by, date
events() {
    local f
    for f in "${FILES[@]}"; do
        jq -r --argjson libs "$LIB_NAMES" '
          . as $top | ($top.timestamp // "" | .[0:10]) as $d
          | if .type == "assistant" and (.message.content | type == "array") then
              .message.content[]
              | select(.type == "tool_use")
              | if .name == "Skill" then
                  ["skill", (.input.skill // "?"), "model", $d]
                elif .name == "Agent" or .name == "Task" then
                  ["agent", (.input.subagent_type // "general-purpose"), "model", $d]
                elif .name == "Bash" then
                  (.input.command // "") as $cmd
                  | $libs[] | select(. as $l | $cmd | contains($l))
                  | ["lib", ., "model", $d]
                else empty end
            elif .type == "user"
                 and ((.message.content | tostring) | test("<command-name>/")) then
              ["skill",
               ((.message.content | tostring)
                | capture("<command-name>/(?<s>[A-Za-z0-9:_-]+)").s),
               "user", $d]
            else empty end
          | @tsv
        ' "$f" 2>/dev/null
    done
}

ALL=$(events)
[ -n "$SINCE" ] && ALL=$(awk -F'\t' -v s="$SINCE" '$4 >= s' <<<"$ALL")

section() {  # $1 kind  $2 title  $3 ours-json
    local kind=$1 title=$2 ours=${3:-[]}
    echo "== $title (total, user, model, last used)"
    awk -F'\t' -v kind="$kind" '
        $1 == kind {
            n[$2]++; if ($3 == "user") u[$2]++; else m[$2]++
            if ($4 > last[$2]) last[$2] = $4
        }
        END { for (k in n) printf "%d\t%d\t%d\t%s\t%s\n", n[k], u[k], m[k], last[k], k }
    ' <<<"$ALL" | sort -rn | while IFS=$'\t' read -r n u m d k; do
        mark=""
        [ "$kind" = "agent" ] && jq -e --arg k "$k" 'index($k) != null' <<<"$ours" >/dev/null 2>&1 && mark="  *ours"
        printf '  %5d  (u:%-3d m:%-3d)  %s  %s%s\n' "$n" "$u" "$m" "$d" "$k" "$mark"
    done
    echo
}

echo "scanned ${#FILES[@]} transcripts under $ROOT${SINCE:+ since $SINCE} ($(hostname -s))"
echo
section skill "SKILLS"
section agent "AGENTS" "$OUR_AGENTS"
section lib "LIB SCRIPTS"

used_skills=$(awk -F'\t' '$1=="skill"{print $2}' <<<"$ALL" | sort -u)
used_libs=$(awk -F'\t' '$1=="lib"{print $2}' <<<"$ALL" | sort -u)
used_agents=$(awk -F'\t' '$1=="agent"{print $2}' <<<"$ALL" | sort -u)

echo "== INSTALLED BUT UNUSED in this window"
# shellcheck disable=SC2012
echo "  skills: $(comm -23 <(ls "$HOME/.claude/skills" 2>/dev/null | sort -u) <(printf '%s\n' "$used_skills") | tr '\n' ' ')"
echo "  lib:    $(comm -23 <(jq -r '.[]' <<<"$LIB_NAMES" | sort -u) <(printf '%s\n' "$used_libs") | tr '\n' ' ')"
echo "  agents (ours): $(comm -23 <(jq -r '.[]' <<<"$OUR_AGENTS" | sort -u) <(printf '%s\n' "$used_agents") | tr '\n' ' ')"
echo
echo "caveats: lib-from-lib composition invisible; hooks not in transcripts; this host + retention window only."
