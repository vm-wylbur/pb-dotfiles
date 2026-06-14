#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-13
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/fleet-brief-run.sh
#
# Layer 2 chunk 2c: the launchd runner for the daily fleet brief. launchd
# starts jobs with a minimal environment (no interactive shell, sparse
# PATH), so this establishes a usable PATH and then invokes the
# /fleet-brief skill headless (`claude -p "/fleet-brief"` — `claude --help`
# confirms skills resolve via /skill-name in print mode). The skill does
# the gather + compose + write to ~/docs/fleet-brief-<date>.md itself.
#
# PERMISSIONS: a TTY-less launchd job that hits a permission prompt hangs
# forever. The /fleet-brief skill is strictly read-only (its gather scripts
# fetch but never mutate; it only WRITES under ~/docs) and it is PB's own
# skill on PB's own machine, so we run with --permission-mode
# bypassPermissions to guarantee the unattended run never blocks. Verified
# 2026-06-13: a real headless run produced a correct brief.
#
# NEGOTIATION-BLIND BY DESIGN: print mode does not inherit the interactive
# session's MCP servers, so the scheduled brief cannot reach the
# claude-negotiate MCP — it reports "negotiations: not checked" with a ⚠
# marker (the MCP is flaky even interactively, so wiring --mcp-config here
# would be fragile). Check negotiations from an interactive /fleet-brief.
#
# Logs to ~/Library/Logs/fleet-brief.log (append). Safe to run by hand to
# test the scheduled path: `bash ~/.claude/lib/fleet-brief-run.sh`.
#
# macOS-only by deployment (launchd); the script itself is portable enough
# to run anywhere claude is on PATH.

set -uo pipefail

# launchd PATH is bare; prepend the usual Homebrew / user locations so
# claude, gh, jq, node resolve. Keep any inherited PATH as a fallback tail.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:${HOME}/.local/bin:${PATH:-}"

LOG_DIR="${HOME}/Library/Logs"
mkdir -p "$LOG_DIR"
LOG="${LOG_DIR}/fleet-brief.log"

ts() { date +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo unknown; }

{
    echo "[$(ts)] fleet-brief run starting (host $(hostname -s 2>/dev/null || echo '?'))"
    if ! command -v claude >/dev/null 2>&1; then
        echo "[$(ts)] ERROR: claude not on PATH ($PATH) — aborting"
        exit 127
    fi
    cd "${HOME}" || { echo "[$(ts)] ERROR: cannot cd \$HOME"; exit 1; }
    # bypassPermissions: read-only skill, own machine, must never hang on a
    # prompt with no TTY (see header). --output-format text keeps the log plain.
    claude -p "/fleet-brief" --permission-mode bypassPermissions
    rc=$?
    echo "[$(ts)] fleet-brief run finished (claude exit=$rc)"
    exit "$rc"
} >>"$LOG" 2>&1
