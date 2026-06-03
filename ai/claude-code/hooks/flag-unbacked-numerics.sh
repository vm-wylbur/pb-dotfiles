#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-06-02
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# ~/.claude/hooks/flag-unbacked-numerics.sh
#
# PreToolUse(Bash) hook. On `gh issue comment` / `gh pr comment`, flags
# metric-flavored numbers in the comment body that do NOT appear in recent TOOL
# OUTPUT (the transcript), i.e. likely-fabricated metrics. Resolves dotfiles #2
# (composable-artifacts Phase 2): the original `type:"prompt"` design saw only
# the tool call; a `command` hook gets `transcript_path` (verified) so it can
# compare against real output, and fires BEFORE the post.
#
# Decision: `permissionDecision: "ask"` (advisory) — never deny. Selectivity is
# deliberately tight (percentages, unit-numbers, decimals, ratios; NOT #refs,
# ISO dates, vX.Y.Z, hex SHAs, bare ints/years) so a false positive costs one
# keystroke, not a blocked action.
#
# Install (settings.json):
#   "PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command",
#     "command": "bash ~/.claude/hooks/flag-unbacked-numerics.sh"}]}]
#
# Silent (exit 0) = allow. Prints an "ask" JSON decision when it flags.

set -euo pipefail

HOOK_INPUT=$(cat)
export HOOK_INPUT

python3 <<'PY'
import os, sys, json, re

data = json.loads(os.environ.get("HOOK_INPUT", "{}") or "{}")
cmd = (data.get("tool_input", {}) or {}).get("command", "") or ""
transcript = data.get("transcript_path", "") or ""

# Only gh issue/pr comment commands.
if not re.search(r'\bgh\s+(?:issue|pr)\s+comment\b', cmd):
    sys.exit(0)


def extract_body(cmd):
    parts = []
    # heredoc: <<'DELIM' ... \nDELIM  (bare or quoted delimiter, optional <<-)
    for m in re.finditer(r"<<-?\s*[\"']?([A-Za-z_][A-Za-z0-9_]*)[\"']?\r?\n(.*?)\r?\n[ \t]*\1\b",
                         cmd, re.DOTALL):
        parts.append(m.group(2))
    # --body / -b "..." or '...'
    for m in re.finditer(r"(?:--body|-b)[ =]+(?:\"([^\"]*)\"|'([^']*)')", cmd):
        parts.append(m.group(1) or m.group(2) or "")
    # --body-file / -F <path> (skip '-', that's stdin/heredoc)
    for m in re.finditer(r"(?:--body-file|-F)[ =]+(\S+)", cmd):
        p = m.group(1)
        if p not in ("-",) and not p.startswith("<"):
            try:
                parts.append(open(os.path.expanduser(p)).read())
            except Exception:
                pass
    return "\n".join(parts)


def metric_tokens(text):
    """Metric-flavored numeric tokens only — bare ints, #refs, ISO dates, semver,
    and hex SHAs are intentionally not collected."""
    toks = set()
    for m in re.finditer(r'(\d+(?:\.\d+)?)\s?%', text):                       # 43%, 0.5%
        toks.add(m.group(1))
    for m in re.finditer(r'(\d+(?:\.\d+)?)\s?(?:ms|µs|us|ns|s|MB|GB|KB|TB|kB|x|×)\b', text):  # 147ms, 24GB, 3x
        toks.add(m.group(1))
    for m in re.finditer(r'(?<![\w.])(\d+\.\d+)(?!\.\d)', text):              # 0.984, 43.2 (not 1.1.0)
        toks.add(m.group(1))
    for m in re.finditer(r'\b(\d+)\s*(?:/|of)\s*(\d+)\b', text):              # 5/11, 5 of 11
        toks.add(m.group(1)); toks.add(m.group(2))
    return toks


def recent_output_numbers(path, window=40):
    if not path or not os.path.exists(path):
        return None  # no transcript -> can't verify
    texts = []
    try:
        with open(path) as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    e = json.loads(line)
                except Exception:
                    continue
                if e.get("type") != "user":
                    continue
                msg = e.get("message", {})
                content = msg.get("content") if isinstance(msg, dict) else None
                if not isinstance(content, list):
                    continue
                for b in content:
                    if isinstance(b, dict) and b.get("type") == "tool_result":
                        c = b.get("content")
                        if isinstance(c, str):
                            texts.append(c)
                        elif isinstance(c, list):
                            texts.append(" ".join(x.get("text", "") for x in c
                                                  if isinstance(x, dict)))
    except Exception:
        return None
    blob = "\n".join(texts[-window:])
    return set(re.findall(r'\d+(?:\.\d+)?', blob))


body = extract_body(cmd)
if not body.strip():
    sys.exit(0)

candidates = metric_tokens(body)
if not candidates:
    sys.exit(0)

backed = recent_output_numbers(transcript)
if backed is None:
    sys.exit(0)  # can't verify -> don't nag on missing data

unbacked = sorted(c for c in candidates if c not in backed)
if not unbacked:
    sys.exit(0)

reason = ("Numbers in this comment aren't in recent tool output — confirm they're "
          "measured, not fabricated (proceed if they're sourced elsewhere): "
          + ", ".join(unbacked))
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": reason,
}}))
sys.exit(0)
PY
