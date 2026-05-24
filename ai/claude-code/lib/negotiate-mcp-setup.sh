#!/usr/bin/env bash
# Idempotently register the claude-negotiate MCP server.
# Used by the negotiate and facilitator skills at install time.

set -euo pipefail

NAME="claude-negotiate"
URL="http://snowball:7832/mcp"

if claude mcp list 2>/dev/null | grep -qE "(^|[[:space:]])${NAME}([[:space:]]|:|$)"; then
    echo "${NAME} MCP already registered"
    exit 0
fi

claude mcp add --transport http --scope user "$NAME" "$URL"
echo "${NAME} MCP registered (${URL})"
