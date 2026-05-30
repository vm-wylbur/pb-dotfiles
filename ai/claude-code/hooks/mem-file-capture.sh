#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-30
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/hooks/mem-file-capture.sh
#
# PostToolUse hook (Edit|Write): mirror file-based memory into claude-mem.
#
# When a write lands on a memory file under
#   ~/.claude/projects/*/memory/*.md
# (the per-project file-based memory store), strip its YAML frontmatter and
# POST the body to claude-mem via lib/mem-store.sh, keyed for upsert so that
# re-editing a memory updates the stored copy instead of duplicating it.
#
#   key   source_key = "<project>:<frontmatter.name>"   (namespaced to avoid
#                       cross-project collisions under ON CONFLICT)
#   tags  [<project>, <frontmatter.metadata.type>, "memory-file"]
#
# The MEMORY.md index file is SKIPPED — it is a table of contents, not a
# memory; its one-line pointers would pollute the store.
#
# source_key is a no-op against the current /store endpoint (it destructures
# only {content, tags}); it becomes load-bearing once /store gains UPSERT
# support (claude-mem Track 2b). Until then, edits insert-always.
#
# Install in ~/.claude/settings.json (registered by install.sh):
#   "PostToolUse": [{"matcher": "Edit|Write", "hooks": [{"type": "command",
#     "command": "bash ~/.claude/hooks/mem-file-capture.sh"}]}]
#
# Never blocks: exits 0 on any path that isn't a capturable memory file, and
# a failed store is reported to stderr but does not fail the hook.

set -uo pipefail

INPUT=$(cat)

FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    pass
" 2>/dev/null)

[[ -z "$FILE_PATH" ]] && exit 0

# Only act on memory files: ~/.claude/projects/<slug>/memory/<file>.md
case "$FILE_PATH" in
    */.claude/projects/*/memory/*.md) ;;
    *) exit 0 ;;
esac

# The index is a TOC, not a memory.
[[ "$(basename "$FILE_PATH")" == "MEMORY.md" ]] && exit 0
[[ -f "$FILE_PATH" ]] || exit 0

PROJECT=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")

# Parse frontmatter; emit the store payload as JSON, or nothing if the body
# is empty. name/type are best-effort: a body with no frontmatter still gets
# stored (without a source_key) so a capture is never silently lost.
PAYLOAD=$(FILE_PATH="$FILE_PATH" PROJECT="$PROJECT" python3 <<'PYEOF'
import os, sys, json

path = os.environ["FILE_PATH"]
project = os.environ["PROJECT"]

with open(path, encoding="utf-8") as f:
    raw = f.read()

name = None
mtype = None
body = raw

# Split a leading "---\n ... \n---" frontmatter block off the front.
if raw.startswith("---"):
    parts = raw.split("\n---", 1)
    # parts[0] is "---\n<frontmatter>"; parts[1] is "\n<body>"
    if len(parts) == 2:
        fm_text = parts[0][3:]           # drop the opening "---"
        body = parts[1].lstrip("\n")
        try:
            import yaml
            fm = yaml.safe_load(fm_text) or {}
            if isinstance(fm, dict):
                name = fm.get("name")
                meta = fm.get("metadata")
                if isinstance(meta, dict):
                    mtype = meta.get("type")
        except Exception:
            pass

body = body.strip()
if not body:
    sys.exit(0)   # nothing to store

tags = [project]
if mtype:
    tags.append(str(mtype).strip())
tags.append("memory-file")

payload = {"content": body, "tags": tags}
if name:
    payload["source_key"] = f"{project}:{str(name).strip()}"

print(json.dumps(payload))
PYEOF
)

[[ -z "$PAYLOAD" ]] && exit 0

# Store target resolves to lib/mem-store.sh; MEM_FILE_CAPTURE_STORE overrides
# it for testing (point at a script that records stdin instead of POSTing).
STORE="${MEM_FILE_CAPTURE_STORE:-}"
if [[ -z "$STORE" ]]; then
    LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" 2>/dev/null && pwd)"
    STORE="$LIB_DIR/mem-store.sh"
    [[ -x "$STORE" ]] || STORE="$HOME/.claude/lib/mem-store.sh"
fi

if printf '%s' "$PAYLOAD" | bash "$STORE" >/dev/null 2>&1; then
    echo "[mem-file-capture] mirrored $(basename "$FILE_PATH") -> claude-mem" >&2
else
    echo "[mem-file-capture] store failed for $(basename "$FILE_PATH")" >&2
fi

exit 0
