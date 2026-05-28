#!/usr/bin/env bash
# Author: PB and cc-dots 🧷
# Date: 2026-05-26
# License: (c) HRDAG, 2026, GPL-2 or newer
#
# dotfiles/ai/claude-code/lib/inventory.sh
#
# Two-column cheat sheet enumerating the AI-environment collection:
# skills, agents, modules, hooks, MCP servers, built-in slash commands.
# Reads live state — no caching.

set -u

CLAUDE_DIR=${CLAUDE_DIR:-$HOME/.claude}
DOTFILES=${DOTFILES:-$HOME/dotfiles}
MODULES_DIR=${CLAUDE_MD_MODULES_DIR:-$DOTFILES/ai/modules}

# Extract the description from a SKILL.md / agent .md frontmatter block.
# Handles single-line and YAML block-scalar (>, |) forms.
# Args: file path. Strip "Use this agent when " boilerplate; truncate to 58.
get_description() {
    awk '
        /^---$/ { if (fm) { exit } else { fm = 1; next } }
        !fm     { next }
        /^description: *[>|]/ { block = 1; next }
        block && /^[a-zA-Z_-]+:/ { exit }
        block {
            sub(/^ +/, "")
            out = out (out ? " " : "") $0
            next
        }
        /^description:/ {
            sub(/^description: */, "")
            sub(/^"/, ""); sub(/"$/, "")
            out = $0
            exit
        }
        END { print out }
    ' "$1" | sed 's/^Use this agent when //' | cut -c1-58
}

# Pull the "use when" cell (col 4) from the modules README table for a given id.
get_module_use() {
    local id=$1
    awk -F'|' -v id=" $id " '
        $2 == id {
            gsub(/^ +| +$/, "", $4)
            print substr($4, 1, 58)
            exit
        }
    ' "$MODULES_DIR/README.md"
}

# --------- header ---------
printf '== Claude Code inventory ==                                    %s\n\n' "$(date +%Y-%m-%d)"

# --------- skills (user-installed, rendered from dotfiles) ---------
SKILLS=()
if [[ -d "$CLAUDE_DIR/skills" ]]; then
    while IFS= read -r d; do
        [[ -f "$d/SKILL.md" ]] && SKILLS+=("$(basename "$d")")
    done < <(find -L "$CLAUDE_DIR/skills" -maxdepth 1 -mindepth 1 -type d | sort)
fi
printf 'SKILLS (~/.claude/skills) [%d]\n' "${#SKILLS[@]}"
for s in "${SKILLS[@]}"; do
    printf '  %-16s %s\n' "$s" "$(get_description "$CLAUDE_DIR/skills/$s/SKILL.md")"
done
echo

# --------- runbooks (per-repo skills tagged runbook: true) ---------
# Walk up from PWD to find the nearest .claude/skills/ dir (repo-local).
runbook_root=""
d=$PWD
while [[ "$d" != "/" && "$d" != "$HOME" ]]; do
    if [[ -d "$d/.claude/skills" ]]; then
        runbook_root="$d/.claude/skills"
        break
    fi
    d=$(dirname "$d")
done
if [[ -n "$runbook_root" ]]; then
    RUNBOOKS=()
    while IFS= read -r f; do
        # Frontmatter-scan: include only if runbook: true is set in the YAML block.
        if awk '
            /^---$/ { fm++; if (fm == 2) exit }
            fm == 1 && /^runbook: *true *$/ { found = 1 }
            END { exit !found }
        ' "$f"; then
            RUNBOOKS+=("$f")
        fi
    done < <(find -L "$runbook_root" -maxdepth 2 -name SKILL.md | sort)
    if (( ${#RUNBOOKS[@]} > 0 )); then
        printf 'RUNBOOKS (%s) [%d]\n' "${runbook_root/#$HOME/~}" "${#RUNBOOKS[@]}"
        for f in "${RUNBOOKS[@]}"; do
            name=$(basename "$(dirname "$f")")
            printf '  %-18s %s\n' "$name" "$(get_description "$f")"
        done
        echo
    fi
fi

# --------- agents ---------
AGENTS=()
if [[ -d "$CLAUDE_DIR/agents" ]]; then
    while IFS= read -r f; do
        AGENTS+=("$(basename "$f" .md)")
    done < <(find -L "$CLAUDE_DIR/agents" -maxdepth 1 -name '*.md' -not -name 'README.md' | sort)
fi
printf 'AGENTS (~/.claude/agents) [%d]\n' "${#AGENTS[@]}"
for a in "${AGENTS[@]}"; do
    printf '  %-16s %s\n' "$a" "$(get_description "$CLAUDE_DIR/agents/$a.md")"
done
echo

# --------- built-in slash commands (curated; refresh periodically) ---------
printf 'BUILT-IN SLASH COMMANDS (curated)\n'
cat <<'EOF'
  /help            Help with using Claude Code
  /clear           Clear the conversation
  /config          Adjust harness settings
  /agents          Manage agent definitions
  /goal            Set session anchor (Stop-hook reminder)
  /code-review     Review current diff at chosen effort level
  /loop            Run a prompt on a recurring interval
  /schedule        Create/list/run scheduled remote agents
  /init            Initialize CLAUDE.md for a new codebase
  /review          Review a pull request
  /security-review Security review of pending changes
  /ultrareview     Multi-agent cloud review (user-triggered, billed)
  /verify          Run the app to confirm a change works
EOF
echo

# --------- hooks (settings.json) ---------
HOOK_LINES=$(python3 - <<'PY' 2>/dev/null
import json, os
p = os.path.expanduser('~/.claude/settings.json')
try:
    d = json.load(open(p))
except Exception:
    raise SystemExit
events = d.get('hooks', {})
total = 0
rows = []
for event, entries in events.items():
    for e in entries:
        matcher = e.get('matcher', '*')
        names = []
        for h in e.get('hooks', []):
            cmd = h.get('command', '')
            # Pull last path component before any args.
            name = os.path.basename(cmd.split()[-1]) if cmd else ''
            name = name.replace('.sh','')
            names.append(name)
            total += 1
        if names:
            rows.append(f'  {event}:{matcher:14s} {", ".join(names)}')
print(f'HOOKS (~/.claude/settings.json) [{total}]')
for r in rows:
    print(r)
PY
)
[[ -n "$HOOK_LINES" ]] && printf '%s\n\n' "$HOOK_LINES"

# --------- MCP servers ---------
if command -v claude &>/dev/null; then
    MCP_OUTPUT=$(claude mcp list 2>&1)
    TOTAL=$(echo "$MCP_OUTPUT" | grep -cE '✓ Connected|✗ Failed|! Needs')
    printf 'MCP SERVERS (claude mcp list) [%d]\n' "$TOTAL"
    # Two passes so connected servers list first, then failures/auth.
    for pass in connected failed; do
        echo "$MCP_OUTPUT" | awk -v pass="$pass" '
            pass == "connected" && /✓ Connected/ {
                split($0, a, " - ")
                split(a[1], b, ": ")
                printf "  ✓ %-18s %s\n", b[1], substr(b[2], 1, 56)
            }
            pass == "failed" && /✗ Failed/ {
                split($0, a, ":")
                printf "  ✗ %-18s failed\n", a[1]
            }
            pass == "failed" && /! Needs/ {
                split($0, a, ":")
                printf "  ! %-18s needs authentication\n", a[1]
            }
        '
    done
    echo
fi

# --------- modules (compose into CLAUDE.md / skills / agents) ---------
if [[ -d "$MODULES_DIR" ]]; then
    MODULES=()
    while IFS= read -r f; do
        MODULES+=("$(basename "$f" .md)")
    done < <(find -L "$MODULES_DIR" -maxdepth 1 -name '*.md' -not -name 'README.md' | sort)
    printf 'CLAUDE.md MODULES (%s) [%d]\n' "${MODULES_DIR/#$HOME/~}" "${#MODULES[@]}"
    for m in "${MODULES[@]}"; do
        printf '  %-18s %s\n' "$m" "$(get_module_use "$m")"
    done
    echo
fi
