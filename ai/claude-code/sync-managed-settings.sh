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
#
# Deletion guard: if the live settings carry a hook command the merge would
# drop (e.g. hand-wired and never added to the managed set here), the script
# ABORTS and names it instead of silently deleting it. Deliberate hook
# retirement: re-run with SYNC_ALLOW_HOOK_DELETE=1.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="${SETTINGS:-$CLAUDE_DIR/settings.json}"   # override for isolated tests
HOOKS_DIR="$CLAUDE_DIR/hooks"

command -v jq >/dev/null || { echo "ERROR: jq not found" >&2; exit 1; }
[ -f "$SETTINGS" ] || { echo "ERROR: $SETTINGS not found (run install.sh first)" >&2; exit 1; }

TMP=$(mktemp)
SNAP=$(mktemp)
trap 'rm -f "$TMP" "$SNAP"' EXIT

# jq exits 0 on some parse errors, so plain `set -e` won't catch a malformed
# input — `-e` is required to actually detect it. Fail before touching anything.
jq -e 'type == "object"' "$SETTINGS" >/dev/null 2>&1 \
    || { echo "ERROR: $SETTINGS is not a valid JSON object; aborting" >&2; exit 1; }

# Snapshot the input once: the merge and the deletion guard below must judge
# the SAME state (the harness rewrites settings.json during live sessions).
cp "$SETTINGS" "$SNAP"

jq \
    --arg guard   "bash ${HOOKS_DIR}/pre-bash-guard.sh" \
    --arg numcheck "bash ${HOOKS_DIR}/flag-unbacked-numerics.sh" \
    --arg webfetch "bash ${HOOKS_DIR}/webfetch-allowlist.sh" \
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
        {"type": "command", "command": $guard},
        {"type": "command", "command": $numcheck}
    ]}, {"matcher": "WebFetch", "hooks": [
        {"type": "command", "command": $webfetch}
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
    del(.enabledPlugins."oh-my-claudecode@omc") |
    .skipDangerousModePermissionPrompt = true
    ' "$SNAP" > "$TMP"

# Fail closed: never overwrite settings.json with empty or non-object output
# (a parse error can leave $TMP empty while jq still exits 0).
if [ ! -s "$TMP" ] || ! jq -e 'type == "object"' "$TMP" >/dev/null 2>&1; then
    echo "ERROR: managed merge produced empty/invalid output; $SETTINGS left unchanged" >&2
    exit 1
fi

# Deletion guard: this script owns .hooks wholesale, so any hook wiring
# present in the live settings but absent from the merge output is about to
# be SILENTLY deleted — the failure shape that nearly killed the live
# webfetch-allowlist gate (hand-wired into settings, unknown to this script;
# see dotfiles f35a7d6). Compare [event, matcher, command] TUPLES (not bare
# command strings: the same script wired under a second event/matcher is a
# distinct wiring and must trip the guard) and refuse to proceed on any
# deletion. Entries without a string command are skipped: the harness cannot
# run them, so dropping them loses nothing. Both sides read post-snapshot
# state, so the verdict is about exactly what the merge consumed.
deleted=$(jq -r --slurpfile merged "$TMP" '
    def wirings: [.hooks // {} | to_entries[] | .key as $ev
        | .value[]? | (.matcher? // "") as $m
        | .hooks[]? | select((.command? | type) == "string")
        | [$ev, $m, .command]];
    wirings as $live
    | ($merged[0] | wirings) as $kept
    | ($live - $kept) | .[] | @json' "$SNAP")
if [ -n "$deleted" ]; then
    if [ "${SYNC_ALLOW_HOOK_DELETE:-0}" != "1" ]; then
        echo "ERROR: merge would DELETE hook wiring(s), shown as [event, matcher, command]:" >&2
        printf '%s\n' "$deleted" | sed 's/^/    /' >&2
        echo "If these are hand-wired hooks that should survive, add them to the managed" >&2
        echo "set in $0 instead." >&2
        echo "If the managed set deliberately retired or renamed them (the new form is" >&2
        echo "already in the merge), re-run the same command prefixed with" >&2
        echo "SYNC_ALLOW_HOOK_DELETE=1 — one-shot prefix only; do not export it." >&2
        echo "Nothing changed." >&2
        exit 1
    fi
    echo "NOTE: SYNC_ALLOW_HOOK_DELETE=1 — dropping hook wiring(s):" >&2
    printf '%s\n' "$deleted" | sed 's/^/    /' >&2
fi

mv "$TMP" "$SETTINGS"        # atomic rename; mktemp's 0600 becomes the file's mode
echo "synced managed settings → $SETTINGS"
