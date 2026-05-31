#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-31
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/sync-managed-settings.sh
#
# Merge the repo-MANAGED settings subset into ~/.claude/settings.json so
# every host converges to the same hooks, permissions, and capability env.
# Extracted from install.sh section 5 so it can run STANDALONE — without
# install.sh's heavy side effects (uv, venv, template renders, deploy-repos).
# That makes "keep the hosts moving together" a one-command operation:
#
#     bash ~/dotfiles/ai/claude-code/sync-managed-settings.sh
#
# Idempotent and mode-preserving (settings.json stays 600). install.sh
# calls this after it has ensured CLAUDE_MEM_SECRET is present.
#
# MANAGED (this script owns them — overwritten on every run, so they can't
# drift): all hooks (PreToolUse/PostToolUse/SessionStart/Stop), the
# permission allow/deny rules, and the capability env flags
# (ENABLE_TOOL_SEARCH, CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION).
#
# HOST-LOCAL (preserved untouched): CLAUDE_MEM_SECRET, SSH_ASKPASS_REQUIRE,
# permissions.defaultMode, editorMode, skipAutoPermissionPrompt, statusLine,
# effortLevel, model, and any other key not named above.
#
# Hook command paths are computed from $HOME at merge time, so porky
# (/Users/pball) and scott (/home/pball) each get correct absolute paths.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="${SETTINGS:-$CLAUDE_DIR/settings.json}"   # override for isolated tests
HOOKS_DIR="$CLAUDE_DIR/hooks"

command -v jq >/dev/null || { echo "ERROR: jq not found" >&2; exit 1; }
[ -f "$SETTINGS" ] || { echo "ERROR: $SETTINGS not found (run install.sh first)" >&2; exit 1; }

TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT

# jq exits 0 on some parse errors, so plain `set -e` won't catch a malformed
# input — `-e` is required to actually detect it. Fail before touching anything.
jq -e 'type == "object"' "$SETTINGS" >/dev/null 2>&1 \
    || { echo "ERROR: $SETTINGS is not a valid JSON object; aborting" >&2; exit 1; }

jq \
    --arg guard   "bash ${HOOKS_DIR}/pre-bash-guard.sh" \
    --arg inject  "bash ${HOOKS_DIR}/mem-inject.sh" \
    --arg sessenv "bash ${HOOKS_DIR}/session-env.sh" \
    --arg cmcheck "bash ${HOOKS_DIR}/claude-md-check.sh" \
    --arg yamlval "bash ${HOOKS_DIR}/yaml-validate.sh" \
    --arg memfile "bash ${HOOKS_DIR}/mem-file-capture.sh" \
    --arg stopoff "bash ${HOOKS_DIR}/stop-session-offers.sh" \
    '
    .env.CLAUDE_CODE_ENABLE_PROMPT_SUGGESTION = "false" |
    .env.ENABLE_TOOL_SEARCH = "true" |
    .permissions.deny = ((.permissions.deny // []) + [
        "AskUserQuestion",
        "WebSearch",
        "Bash(watch *)"
    ] | unique) |
    .permissions.allow = (
        ((.permissions.allow // [])
            | map(select(. != "mcp__repomix__*"
                         and . != "mcp__tree_sitter__*"
                         and . != "mcp__claude-mem__*")))
        + [
            "WebFetch(domain:code.claude.com)",
            "WebFetch(domain:docs.anthropic.com)"
        ]
        | unique
    ) |
    .hooks.PreToolUse = [{"matcher": "Bash", "hooks": [
        {"type": "command", "command": $guard}
    ]}] |
    .hooks.SessionStart = [{"hooks": [
        {"type": "command", "command": $inject},
        {"type": "command", "command": $sessenv},
        {"type": "command", "command": $cmcheck}
    ]}] |
    .hooks.PostToolUse = [{"matcher": "Edit|Write", "hooks": [
        {"type": "command", "command": $yamlval},
        {"type": "command", "command": $memfile}
    ]}] |
    .hooks.Stop = [{"hooks": [
        {"type": "command", "command": $stopoff}
    ]}] |
    .enabledPlugins."oh-my-claudecode@omc" = false |
    .skipDangerousModePermissionPrompt = true
    ' "$SETTINGS" > "$TMP"

# Fail closed: never overwrite settings.json with empty or non-object output
# (a parse error can leave $TMP empty while jq still exits 0).
if [ ! -s "$TMP" ] || ! jq -e 'type == "object"' "$TMP" >/dev/null 2>&1; then
    echo "ERROR: managed merge produced empty/invalid output; $SETTINGS left unchanged" >&2
    exit 1
fi
mv "$TMP" "$SETTINGS"        # atomic rename; mktemp's 0600 becomes the file's mode
echo "synced managed settings → $SETTINGS"
