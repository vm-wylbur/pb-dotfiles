#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2026-06-09
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/webfetch-allowlist.sh
#
# PreToolUse(WebFetch) hard gate. The permissions allow-list does NOT restrict
# WebFetch under defaultMode:auto -- it only suppresses prompts; non-allowlisted
# domains are auto-approved (verified: a subagent fetched raw.githubusercontent.com
# despite only code.claude.com / docs.anthropic.com being allowlisted). This hook
# is the actual boundary: it DENIES any WebFetch whose host is not on ALLOWED.
# Allowlisted hosts pass through (exit 0, no output) so the existing
# permissions.allow rules approve them without a prompt.
# Rationale: the prompt-injection policy in ~/.claude/CLAUDE.md -- untrusted web
# text is an instruction-override / exfiltration vector; the bar is enforceability,
# not "this site looks safe".
#
# Fail-CLOSED posture: a gate that cannot parse its input must deny, not defer.
# Every unparseable state (jq missing, malformed stdin, absent url, ambiguous
# URL characters) emits a deny; only a cleanly-parsed allowlisted host passes.
# Known limitation: the gate fires once per tool call on the requested URL --
# if WebFetch follows a cross-host HTTP redirect after approval, the redirect
# target is not re-gated here.
#
# The ALLOWED list is duplicated as WebFetch(domain:...) entries in
# sync-managed-settings.sh (permissions.allow) -- update both together.

ALLOWED=("code.claude.com" "docs.anthropic.com")

# Deny with a CONSTANT message and no jq dependency -- the escape hatch for
# "we cannot even build JSON safely here". Never interpolate input into this.
static_deny() {
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"webfetch-allowlist.sh could not parse the WebFetch input (jq missing or malformed payload); failing closed."}}'
  exit 0
}

command -v jq >/dev/null 2>&1 || static_deny

input=$(cat)
url=$(printf '%s' "$input" | jq -r '.tool_input.url // empty' 2>/dev/null) || static_deny

# jq is present past this point: safe to JSON-escape a dynamic reason.
deny() {
  jq -nc --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# A WebFetch call always carries a url; absence means schema drift or a
# malformed call -- deny rather than guess.
[[ -z "$url" ]] && deny "WebFetch input carried no .tool_input.url; webfetch-allowlist.sh fails closed."

# WHATWG URL parsers strip embedded tab/CR/LF and treat backslash as slash
# before resolving the host, so these characters can make our parse diverge
# from the fetcher's. Reject them outright instead of trying to normalize.
case "$url" in
  *[[:space:][:cntrl:]]*|*\\*) deny "WebFetch URL contains whitespace/control/backslash characters; blocked (parser-divergence guard)." ;;
esac

# Extract the host: strip scheme, then path/query/fragment, then userinfo, then port.
rest=${url#*://}
authority=${rest%%[/?#]*}
host=${authority##*@}
host=${host%%:*}
host=$(printf '%s' "$host" | tr '[:upper:]' '[:lower:]')

# Fail CLOSED: a non-empty URL with no parseable host is denied.
[[ -z "$host" ]] && deny "WebFetch URL '$url' has no parseable host; blocked by webfetch-allowlist.sh."

for d in "${ALLOWED[@]}"; do
  [[ "$host" == "$d" ]] && exit 0   # allowlisted -> defer to permissions.allow
done

deny "WebFetch to non-allowlisted host '$host' blocked by webfetch-allowlist.sh. Permitted: ${ALLOWED[*]} (prompt-injection policy). For other web content, route the question to a web-claude session, or use the gh CLI for GitHub."
