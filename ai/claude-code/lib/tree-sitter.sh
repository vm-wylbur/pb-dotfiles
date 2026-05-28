#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/tree-sitter.sh
#
# Thin shell shim that invokes lib/tree-sitter-impl.py inside the venv
# where mcp_server_tree_sitter is installed. install.sh creates the
# venv at ~/.venv-mcp and installs the package via uv; this wrapper
# locates that python interpreter and forwards argv.
#
# Usage:
#   bash lib/tree-sitter.sh analyze --path /path/to/repo
#   bash lib/tree-sitter.sh find-text --path . --pattern 'TODO'
#   bash lib/tree-sitter.sh get-symbols --path . --file-path src/foo.py
#   bash lib/tree-sitter.sh get-ast --path . --file-path src/foo.py

set -uo pipefail

VENV_PY="${HOME}/.venv-mcp/bin/python"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPL="${SCRIPT_DIR}/tree-sitter-impl.py"

if [ ! -x "$VENV_PY" ]; then
    echo "{\"error\":\"venv python not found at ${VENV_PY} — re-run install.sh\"}" >&2
    exit 1
fi
if [ ! -f "$IMPL" ]; then
    echo "{\"error\":\"impl script missing: ${IMPL}\"}" >&2
    exit 1
fi

exec "$VENV_PY" "$IMPL" "$@"
