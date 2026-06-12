#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-11
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/grep-replay.sh
#
# Phase 0 of the tree-sitter adoption plan: replay identifier-shaped
# greps from session transcripts through prototype find-definition /
# find-callers and report the win rate against the pre-registered
# 30% gate. See docs/tree-sitter-adoption-plan-20260611.md.
#
# Usage:
#   bash lib/grep-replay.sh [--since YYYY-MM-DD] [--rows out.jsonl] [--verbose]

set -uo pipefail

VENV_PY="${HOME}/.venv-mcp/bin/python"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPL="${SCRIPT_DIR}/grep-replay-impl.py"

if [ ! -x "$VENV_PY" ]; then
    echo "{\"error\":\"venv python not found at ${VENV_PY} — re-run install.sh\"}" >&2
    exit 1
fi
if [ ! -f "$IMPL" ]; then
    echo "{\"error\":\"impl script missing: ${IMPL}\"}" >&2
    exit 1
fi

exec "$VENV_PY" "$IMPL" "$@"
