#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-13
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/fleet-brief-ledger.sh
#
# Layer 2 longitudinal ledger: append today's fleet-brief OBSERVATIONS to
# ~/.claude/fleet-brief/ledger.jsonl. Reads a JSON array of observation
# objects on stdin, validates them, stamps today's date, and appends each
# as one JSONL line.
#
# WHY this exists (capture-architecture, see the memory of that name): the
# prose brief is for daily reading and does not aggregate. To ever infer
# *process* patterns — chronic gates, gate dwell-time by category,
# recurring decision types — you need a structured, stable-keyed, append-
# only time-series. This file IS that corpus. Patterns are computed LATER,
# at analysis time, by grouping on the stable `key` across dates; the
# writer stays stateless (it just records what was observed today). Capture
# now (you cannot backfill a time-series); analyse later against a
# pre-registered question.
#
# It is STRUCTURED FACTS in a LOCAL file — deliberately NOT claude-mem.
# Writing synthesized daily summaries into the lessons store would
# duplicate already-stored data and manufacture paraphrase near-dupes at a
# daily cadence (the exact problem the layer-1 write-gate exists to stop).
#
# Observation schema (the /fleet-brief skill produces these; this script
# only enforces structure and stamps the date):
#   {type, key, category, title?, summary?, agent?, ref?}
#     type      "gate" | "decision"
#     key       STABLE id so the same item groups across days:
#               pr:owner/repo#N | issue:owner/repo#N | qfix:ID |
#               neg:ID | decision:slug | free:slug
#     category  short tag (pr-review, qfix, negotiation, versioning, ...)
# `date` is added here (today, LOCAL) — never trusted from input. Local, not
# UTC, so the ledger bucket matches the local-morning brief's filename and the
# session-start status check; all three must agree or analysis mis-joins.
#
# Idempotent per day: a manual /fleet-brief plus the scheduled run on the
# same date must not double-count, so today's existing records are dropped
# and replaced rather than appended twice. History for other dates is
# preserved untouched.
#
# Usage: echo '[{...},{...}]' | bash lib/fleet-brief-ledger.sh
# Env:   FLEET_BRIEF_DIR — ledger dir, default ~/.claude/fleet-brief

set -uo pipefail

LEDGER_DIR="${FLEET_BRIEF_DIR:-$HOME/.claude/fleet-brief}"
LEDGER="${LEDGER_DIR}/ledger.jsonl"
mkdir -p "$LEDGER_DIR"

today=$(date +%Y-%m-%d)

input=$(cat)
if ! arr=$(jq -ce 'if type=="array" then . else error("not array") end' <<<"$input" 2>/dev/null); then
    echo "fleet-brief-ledger: stdin is not a JSON array; nothing appended" >&2
    exit 1
fi

# Stamp today's date on each record (override any provided date), one per line.
stamped=$(jq -c --arg d "$today" '.[] | .date=$d' <<<"$arr")
n=$(printf '%s' "$stamped" | grep -c . || true)
if [ "$n" -eq 0 ]; then
    echo "fleet-brief-ledger: empty array; nothing appended" >&2
    exit 0
fi

tmp=$(mktemp "${LEDGER_DIR}/.ledger.XXXXXX")
# Carry forward all prior dates' records, dropping any for today (idempotent
# replace). Only filter when the existing ledger is fully valid JSONL; if it
# is somehow corrupt, preserve it verbatim and accept a possible same-day dup
# rather than risk dropping history.
if [ -f "$LEDGER" ]; then
    if jq -ce . "$LEDGER" >/dev/null 2>&1; then
        jq -c --arg d "$today" 'select(.date != $d)' "$LEDGER" > "$tmp"
    else
        echo "fleet-brief-ledger: WARN existing ledger not clean JSONL; preserving verbatim" >&2
        cp "$LEDGER" "$tmp"
    fi
fi
printf '%s\n' "$stamped" >> "$tmp"
mv "$tmp" "$LEDGER"
echo "fleet-brief-ledger: recorded $n observation(s) for $today -> $LEDGER" >&2
