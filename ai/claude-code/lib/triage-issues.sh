#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-27
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/triage-issues.sh
#
# Session-start triage feed (B1 cell). Emits a JSON object describing
# open issues in the current repo that carry this agent's signature
# (e.g. "cc-dots") in the body — these are issues the agent itself
# filed and now needs to verify, follow up on, or close.
#
# Output shape (single JSON object on stdout):
#   {
#     "repo": "owner/name",
#     "signature": "cc-name",
#     "issues": [
#       {"number": N, "title": "...", "url": "...", "body": "...",
#        "recent_comment": {
#          "author": "...", "body": "...", "createdAt": "..."
#        } | null}
#     ]
#   }
#
# Fail-silent contract: emits "{}" (empty object) and exits 0 in any
# of these cases, so session-env composition stays robust:
#   - no gh CLI
#   - cwd not a git repo
#   - no GitHub remote (gh repo view fails)
#   - gh API errors
#
# Optional config via stdin (JSON):
#   {"limit": N, "signature_override": "cc-foo"}
#
# Default limit: 5 (caps per-session API cost — each kept issue costs
# one extra `gh issue view` call to pull the latest comment).
#
# Composition: session-env.sh pipes this through `jq -r` to format for
# human display; direct JSON consumers (tests, future tooling) read raw.

set -uo pipefail

LIMIT_DEFAULT=5
COMMENT_TAIL=1

empty_out() { echo '{}'; exit 0; }

command -v gh &>/dev/null   || empty_out
command -v jq &>/dev/null   || empty_out
git rev-parse --git-dir &>/dev/null || empty_out

CONFIG="{}"
if [ ! -t 0 ]; then
    CONFIG=$(cat)
    [ -z "$CONFIG" ] && CONFIG="{}"
fi

LIMIT=$(echo "$CONFIG" | jq -r '.limit // empty' 2>/dev/null)
LIMIT=${LIMIT:-$LIMIT_DEFAULT}
SIG_OVERRIDE=$(echo "$CONFIG" | jq -r '.signature_override // empty' 2>/dev/null)

REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null) || empty_out
[ -z "$REPO" ] && empty_out

# Discover the agent id (e.g. "cc-dots", "cc-ansible-impl"). Repos declare
# this in their CLAUDE.md identity section; older repos still have it only
# in recent commit trailers ("By PB & cc-XXX <emoji>"). Use the override if
# the caller passed one.
detect_agent_id() {
    local toplevel claude_md hit
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
    claude_md="${toplevel}/CLAUDE.md"
    if [ -f "$claude_md" ]; then
        hit=$(grep -oE '`cc-[a-z][a-z0-9-]*`' "$claude_md" 2>/dev/null \
              | head -1 | tr -d '`')
        [ -n "$hit" ] && { echo "$hit"; return 0; }
    fi
    hit=$(git log -n 20 --format=%B 2>/dev/null \
          | grep -oE 'cc-[a-z][a-z0-9-]*' | head -1)
    [ -n "$hit" ] && { echo "$hit"; return 0; }
    return 1
}

if [ -n "$SIG_OVERRIDE" ]; then
    SIG="$SIG_OVERRIDE"
else
    SIG=$(detect_agent_id) || empty_out
fi

ISSUES_JSON=$(gh issue list --state open --limit "$LIMIT" \
    --json number,title,body,url,author 2>/dev/null) || empty_out
[ -z "$ISSUES_JSON" ] && ISSUES_JSON="[]"

FILTERED=$(echo "$ISSUES_JSON" \
    | jq --arg sig "$SIG" \
        '[.[] | select(.body != null and (.body | contains($sig)))]')

# Enrich each kept issue with its most-recent comment. Loop is bounded
# by LIMIT so worst-case API calls = LIMIT + 1.
ENRICHED=$(echo "$FILTERED" | jq -c '.[]' | while IFS= read -r issue; do
    NUM=$(echo "$issue" | jq -r '.number')
    COMMENTS=$(gh issue view "$NUM" --json comments \
        --jq ".comments | sort_by(.createdAt) | .[-${COMMENT_TAIL}:]" \
        2>/dev/null)
    [ -z "$COMMENTS" ] && COMMENTS='[]'
    LATEST=$(echo "$COMMENTS" \
        | jq '.[-1] // null
              | if . == null then null
                else {author: .author.login, body: .body, createdAt: .createdAt}
                end')
    echo "$issue" | jq --argjson latest "$LATEST" \
        '. + {recent_comment: $latest}'
done | jq -s '.')

[ -z "$ENRICHED" ] && ENRICHED="[]"

jq -n --arg repo "$REPO" --arg sig "$SIG" --argjson issues "$ENRICHED" \
    '{repo: $repo, signature: $sig, issues: $issues}'
