#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/repomix-pack.sh
#
# Wraps the `repomix` CLI for skill-substrate use. Replaces the MCP
# `mcp__repomix__pack_codebase` tool with a thin shell shim — same
# underlying binary, no MCP server cost in the system prompt.
#
# Input (JSON on stdin):
#   {
#     "path":      "<repo path>",      # required; absolute or relative
#     "output":    "<output file>",    # required; absolute or relative
#     "style":     "xml|markdown|json|plain",  # default: xml
#     "compress":  true|false,         # default: false (tree-sitter compress)
#     "include":   ["glob", ...],      # optional; passed as --include
#     "ignore":    ["glob", ...]       # optional; passed as --ignore
#   }
#
# Output (JSON on stdout):
#   { "output": "<absolute path>", "size_bytes": N, "tokens_estimated": N? }
#
# Exit: 0 on success; 2 on bad input; 1 on repomix failure.

set -uo pipefail

command -v repomix >/dev/null || { echo '{"error":"repomix not on PATH"}' >&2; exit 1; }
command -v jq      >/dev/null || { echo '{"error":"jq not on PATH"}'      >&2; exit 1; }

CONFIG=$(cat)
[ -z "$CONFIG" ] && { echo '{"error":"empty stdin"}' >&2; exit 2; }

PATH_IN=$(echo "$CONFIG" | jq -r '.path     // empty')
OUTPUT=$( echo "$CONFIG" | jq -r '.output   // empty')
STYLE=$(  echo "$CONFIG" | jq -r '.style    // "xml"')
COMPRESS=$(echo "$CONFIG" | jq -r '.compress // false')

[ -z "$PATH_IN" ] && { echo '{"error":".path required"}' >&2; exit 2; }
[ -z "$OUTPUT" ]  && { echo '{"error":".output required"}' >&2; exit 2; }
[ -d "$PATH_IN" ] || { echo "{\"error\":\".path not a directory: $PATH_IN\"}" >&2; exit 2; }

ARGS=( --style "$STYLE" --output "$OUTPUT" --quiet )
[ "$COMPRESS" = "true" ] && ARGS+=( --compress )

# Optional includes / ignores — comma-joined per repomix CLI.
INCLUDE=$(echo "$CONFIG" | jq -r '(.include // []) | join(",")')
IGNORE=$( echo "$CONFIG" | jq -r '(.ignore  // []) | join(",")')
[ -n "$INCLUDE" ] && ARGS+=( --include "$INCLUDE" )
[ -n "$IGNORE" ]  && ARGS+=( --ignore  "$IGNORE" )

if ! repomix "${ARGS[@]}" "$PATH_IN" 2>/dev/null; then
    echo "{\"error\":\"repomix failed for $PATH_IN\"}" >&2
    exit 1
fi

OUT_ABS=$(cd "$(dirname "$OUTPUT")" && echo "$(pwd)/$(basename "$OUTPUT")")
SIZE=$(wc -c < "$OUT_ABS" | tr -d ' ')

jq -n --arg output "$OUT_ABS" --argjson size "$SIZE" \
    '{output: $output, size_bytes: $size}'
