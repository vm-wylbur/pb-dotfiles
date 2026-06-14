#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-13
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/fleet-brief-gather.sh
#
# Layer 2 (daily fleet brief), chunk 2a: gather the last-24h fleet
# activity into ONE JSON object for the /fleet-brief composition step.
# Deterministic and READ-ONLY — it only queries, never mutates.
#
# Reuses the existing changelog/triage primitives rather than
# reinventing them: gh-author-commits/issues/prs (GitHub, @me-scoped),
# mem-recent (claude-mem REST), qfix-list (claude-mem REST). All agents
# act under PB's GitHub account and commit under PB's git identity, so
# @me-scoped GitHub queries capture the whole fleet's work.
#
# NOT gathered here: negotiation state (claude-negotiate is MCP-only,
# unreachable from a shell script) — the composing agent adds it via
# the MCP at compose time. This script documents the gap rather than
# faking it.
#
# Output: a single JSON object on stdout:
#   {since, generated_at, host, commits[], issues[], merged_prs[],
#    recent_memories[], qfix_open[], sources{ok/failed per source}}
# Every source degrades to [] on failure and is flagged in .sources,
# so a missing gh/claude-mem never aborts the brief — it shows as a
# gap the composer can call out.
#
# Usage:
#   bash lib/fleet-brief-gather.sh                 # since yesterday
#   bash lib/fleet-brief-gather.sh --since 2026-06-01
#   bash lib/fleet-brief-gather.sh --mem-n 30      # recent-memory count

set -uo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SINCE=""
MEM_N=25
while [ $# -gt 0 ]; do
    case "$1" in
        --since)  SINCE="${2:-}"; shift 2 ;;
        --mem-n)  MEM_N="${2:-25}"; shift 2 ;;
        *)        echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# Portable "yesterday": BSD date (-v) first, GNU date (-d) fallback.
if [ -z "$SINCE" ]; then
    SINCE=$(date -v-1d +%Y-%m-%d 2>/dev/null \
            || date -d "1 day ago" +%Y-%m-%d 2>/dev/null \
            || date +%Y-%m-%d)
fi

# TSV (newline-delimited, tab-separated) -> JSON array of objects whose
# keys are the field names passed as args, in column order. Always emits
# valid JSON (at least []), so callers can --argjson it unconditionally.
tsv_to_json() {
    jq -Rs --args '
        ($ARGS.positional) as $keys
        | split("\n")
        | map(select(length > 0) | split("\t"))
        | map(. as $row | reduce range(0; $keys|length) as $i ({}; .[$keys[$i]] = $row[$i]))
    ' "$@"
}

# NOTE: the gh-author-* helpers exit non-zero in the normal (non-truncated)
# case — their last command is a `[ n -ge LIMIT ]` warn test that is false
# when results do NOT hit the cap. Their exit code is therefore meaningless;
# read stdout and ignore it. The pipe into tsv_to_json (which exits 0) also
# masks it. Health is probed reliably below, not from these exit codes.
commits=$(bash "$LIB_DIR/gh-author-commits.sh" "$SINCE" 2>/dev/null \
          | tsv_to_json repo sha date msg)
issues=$(bash "$LIB_DIR/gh-author-issues.sh" "$SINCE" 2>/dev/null \
          | tsv_to_json ref state title)
prs=$(bash "$LIB_DIR/gh-author-prs.sh" "$SINCE" 2>/dev/null \
          | tsv_to_json ref merged_at title)

# claude-mem sources already emit JSON; extract / default to [] and record
# whether the backend was actually reachable (valid JSON came back).
mem_raw=$(bash "$LIB_DIR/mem-recent.sh" --n "$MEM_N" 2>/dev/null)
if memories=$(jq -ce '.memories // []' <<<"$mem_raw" 2>/dev/null); then
    mem_ok=true
else
    memories='[]'; mem_ok=false
fi

qfix_raw=$(bash "$LIB_DIR/qfix-list.sh" --status open 2>/dev/null)
if qfix=$(jq -ce 'if type=="array" then . else [] end' <<<"$qfix_raw" 2>/dev/null); then
    qfix_ok=true
else
    qfix='[]'; qfix_ok=false
fi

# Reliable tool health (computed in the main shell, no subshell loss):
# gh presence is exact; claude-mem is reachable if either REST call parsed.
gh_status=missing
command -v gh >/dev/null 2>&1 && gh_status=present
cm_status=unreachable
{ [ "$mem_ok" = true ] || [ "$qfix_ok" = true ]; } && cm_status=reachable
sources=$(jq -n --arg gh "$gh_status" --arg cm "$cm_status" \
          '{gh:$gh, claude_mem:$cm}')

generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)
host=$(hostname -s 2>/dev/null || echo unknown)

jq -n \
    --arg since "$SINCE" \
    --arg generated_at "$generated_at" \
    --arg host "$host" \
    --argjson commits "${commits:-[]}" \
    --argjson issues "${issues:-[]}" \
    --argjson merged_prs "${prs:-[]}" \
    --argjson recent_memories "${memories:-[]}" \
    --argjson qfix_open "${qfix:-[]}" \
    --argjson sources "${sources:-{\}}" \
    '{since:$since, generated_at:$generated_at, host:$host,
      commits:$commits, issues:$issues, merged_prs:$merged_prs,
      recent_memories:$recent_memories, qfix_open:$qfix_open,
      negotiations:"MCP-only; added by the composing agent",
      sources:$sources}'
