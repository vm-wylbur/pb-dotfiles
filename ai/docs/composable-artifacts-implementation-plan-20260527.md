<!--
Author: PB and cc-dots
Date: 2026-05-27
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/ai/docs/composable-artifacts-implementation-plan-20260527.md
-->

# Composable Artifacts — Implementation Plan

**Status (2026-05-28):** Phases 0, 1, 3, 4, 5, 6, 8, 9 shipped. Phase 2
deferred (prompt-hook transcript gap); Phase 7 hook-side deferred with it.
Phase 10 done 2026-05-28: **10a** (cross-machine parity), **10b**
(stale-repomix-ref re-renders, 4 repos), **10c** (drift-proof in-place
composable repos via `deploy-repos` MODE column — Option B, not template
adoption; 5 repos in `repos.txt`).
**Design doc:** [composable-artifacts-20260525.md](./composable-artifacts-20260525.md) (framework + cell taxonomy).
**This doc:** operational plan with success conditions per phase.

---

## Overview

### Goal

Refactor the agent environment against the eleven-cell taxonomy. For each
rule, place it in the cell(s) that make its failure visible to the most
relevant audiences (model, user, audit trail). Substrate follows from cell
choice.

### Scope

In:
- A-cell quick wins (settings.json permissions, denials with reasons)
- F-cell foundation (PreToolUse prompt hooks)
- B1 enhancement (session-start triage with issue bodies)
- claude-mem migration (MCP → lib/+skill; postgres backend retained)
- Runbook unification (RUNBOOK.md → SKILL.md with `disable-model-invocation`)
- repomix + tree-sitter migration (MCP → lib/+skill)
- B2 hook infrastructure (UserPromptSubmit periodic, Stop hooks)
- Per-repo composability (`<repo>/.claude/CLAUDE.md`, `<repo>/.claude/lib`)
- Rule placement content + CLAUDE.md / module updates
- Cross-repo + cross-machine deploy (porky + scott)

Deferred:
- **Phase 2 (F-cell prompt hook for gh-comment numerics)** — design gap
  surfaced 2026-05-27 while picking up the phase. A `type: "prompt"` hook
  only receives the proposed tool call as `$ARGUMENTS`; it does **not**
  have access to the session transcript or recent tool output. So it
  cannot perform the plan's stated check ("flag numeric values that
  don't appear in recent tool output") — the fast model has no source
  to compare against. A weaker version (detect quantitative claims and
  `ask` for verification) was considered but creates friction on every
  numeric gh comment without actually catching fabrication. Needs a
  redesign before re-entry: either move the check to a Stop-type
  `command` hook (which can scan transcript) or accept a friction-only
  prompt that asks the agent to source each number rather than catches
  fabrication directly.
- **Phase 7 partial — `stop-verify-numerics.sh`** — paired with Phase 2;
  deferred with it. The other two Phase 7 deliverables
  (`user-prompt-periodic.sh`, `stop-qfix-scan.sh`) use `type: "command"`
  hooks with transcript access and remain shippable independently.
- Other F-cell rules routed through prompt hooks (see Appendix A; e.g.
  Rule 4 "Never SSH to current host") — same redesign needed as
  Phase 2. Audit the F column in Appendix A when Phase 2's redesign
  lands and re-classify any rule that needed transcript visibility.
- Agent Teams integration (experimental, GA-gated)
- `/pr-drain`, `/deploy` per-repo skills (per-project design)
- TaskCompleted evidence hook (depends on Agent Teams)
- Plugin-system mechanism for our agents (currently install.sh renders)

### Dependency graph (text)

```
0 ──┬── 1 ──── 9 ──── 10
    ├── 2 ──── 7 ─────┘
    ├── 3 ────────────┘
    ├── 4 ────────────┘
    ├── 5 ──── 8 ─────┘
    └── 6 ────────────┘

0 gates all build phases (verifies assumptions).
1, 2, 3, 4, 6 are independent of each other (different substrates).
5 (runbook unification) and 8 (per-repo composability) are mostly
independent but 8's pilot benefits from 5's outcome.
7 (B2 hooks) builds on 2's prompt-hook pattern.
9 (rule placement content) lands after the substrate phases.
10 (deploy) generalizes 8's pilot to all repos + scott.
```

### Cross-machine policy

Each phase:
1. Build & verify on porky.
2. Commit; push to origin.
3. On scott: `git pull` → `install.sh` → `deploy-repos` (if per-repo work).
4. Verify on scott using the phase's documented success conditions.
5. Both green → phase done.

Roughly the cadence we exercised for the composable-artifacts deploy on
2026-05-26, formalized.

---

## Phase format

Each phase below carries:
- **Goal** — one sentence
- **Substrate touched** — cells + specific files
- **Deliverables** — concrete artifacts (files, scripts, doc edits)
- **Success conditions** — verifiable checks (command-line where possible)
- **Dependencies** — prior phases that must complete
- **Risk notes** — rollback path, verification flags
- **Scope** — S (<1 day), M (1–3 days), L (>3 days)

---

## Phase 0 — Verify framework assumptions

**Status:** ✅ COMPLETED 2026-05-27

**Goal:** Verify web-claude's implementation specifics before building on
them.

**Findings:**

| Claim | Status | Implication |
|---|---|---|
| CC 2.1.0+ SessionStart no user-visible terminal text | ✓ Confirmed | v2.1.139+: no controlling terminal; stdout routes to additionalContext; use `terminalSequence` JSON field for terminal effects. (Explains A1 revert.) |
| CC #37210: Edit/Write deny doesn't undo writes | ✗ **Web-claude wrong** | The bug was wrong response format. **Exit 0 + `hookSpecificOutput` wrapper enforces deny across all tools.** No `chmod 444` defense-in-depth needed. |
| CC #14281: additionalContext duplication | ✓ Fixed in v2.1 (we're on 2.1.152) | Non-issue. |
| CC #36900: Bash patterns literal-string with `*` wildcards | ✓ Confirmed | `Bash(git status:*)` breaks when claude adds `-C` flag. Use PreToolUse hooks with `if`-field for non-trivial Bash matching. |
| `if` field syntax | ✓ Confirmed | Permission-rule syntax: `if: "Tool(pattern *)"`. For Bash: strips leading `VAR=value`, matches any subcommand. Runs unconditionally when too complex to parse. |
| WebFetch URL pattern syntax | ✓ **Corrected** | `WebFetch(domain:example.com)` with `domain:` prefix — not `WebFetch(URL-pattern)`. |
| UserPromptSubmit 30s timeout | ✓ Confirmed | Command/HTTP/MCP=30s on UPS (vs 600s on other events); prompt hooks=30s default; agent hooks=60s. |
| `disable-model-invocation: true` semantics | ✓ Confirmed empirically | Suppresses system prompt indexing entirely. Fresh `claude --print` session cannot see skill description. **Runbook unification is token-positive.** |
| Hook ordering | ✓ Confirmed | Within matcher group: parallel + auto-dedupe. Across matcher groups: sequential in config order. |

**Correct PreToolUse deny format (load-bearing):**

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked by policy: <reason>"
  }
}
```

Exit code **0** (not 2). Exit 2 = blocking error (stderr to Claude,
stdout JSON ignored, tool may proceed). `permissionDecision` is a
4-state enum: `deny` / `allow` / `ask` / `defer`. `defer` falls back to
default permission flow.

**Bonus findings — skill frontmatter (from `code.claude.com/docs/en/skills`):**

| Frontmatter | Effect | Maps to cell |
|---|---|---|
| `disable-model-invocation: true` | Suppresses system prompt indexing; explicit-pull only via `/name` | D'' substrate inside cell C |
| `user-invocable: false` | Hides from `/` menu (background-only) | Hidden-substrate variant |
| `paths: <glob>` | Auto-load only when working with matching files | **Implements cell 9 (E2 lazy-loaded) via skill substrate** |
| `context: fork` + `agent: <type>` | Skill runs in forked subagent context | D' substrate from C frontmatter |
| `allowed-tools` / `disallowed-tools` | Per-skill tool allowlist | Per-skill cell A scoping |
| `hooks:` | Hooks scoped to skill's lifecycle | Per-skill cell 2–5 scoping |
| `description + when_to_use` cap at 1,536 chars | Skill listing token budget | Discoverability constraint |

**Bonus findings — bundled CC skills present in our session:**

`/code-review`, `/run`, `/verify`, `/loop`, `/schedule`, `/update-config`,
`/fewer-permission-prompts`, `/security-review`, `/review`, `/init`,
`/keybindings-help`, `/claude-api`. Five worth facade modules (see
Phase 9 deliverables): `/update-config`, `/verify`, `/run`, `/loop`,
`/fewer-permission-prompts`.

---

## Phase 1 — A-cell quick wins

**Goal:** Translate the prose "Never WebSearch" rule into hard enforcement;
allowlist Anthropic-owned docs; deny `Bash(watch *)`.

**Substrate touched:**
- Cell A: `settings.json` `permissions.deny` and `permissions.allow`
- Cell E1: new module `modules/web-access.md` composed into CLAUDE.template.md

**Deliverables:**
- `dotfiles/ai/claude-code/install.sh` updated to write the new permissions
  structure
- `dotfiles/ai/modules/web-access.md` (new module, prose explaining policy
  + alternative routing to web-claude + threat model)
- `dotfiles/ai/CLAUDE.template.md` updated to compose `web-access` module
- Old `## Security` section in user-wide CLAUDE.md prose removed/replaced

**Success conditions:**
```bash
# Settings reflect the rule
jq -e '.permissions.deny | index("AskUserQuestion") and index("WebSearch")' ~/.claude/settings.json
jq -e '.permissions.deny | index("Bash(watch *)")' ~/.claude/settings.json
jq -e '.permissions.allow | index("WebFetch(domain:code.claude.com)")' ~/.claude/settings.json
jq -e '.permissions.allow | index("WebFetch(domain:docs.anthropic.com)")' ~/.claude/settings.json
# Github broad allow NOT present (gh CLI used instead)
jq -e '.permissions.allow | map(test("github.com")) | any' ~/.claude/settings.json | grep -q false

# Module composed
grep -q "BEGIN module:web-access" ~/.claude/CLAUDE.md
grep -q "WebSearch is denied" ~/.claude/CLAUDE.md

# Render clean
~/dotfiles/scripts/claude-md check-tree ~/dotfiles/ai/claude-code/skill-templates --to ~/.claude/skills
~/dotfiles/scripts/claude-md check ~/dotfiles/ai/CLAUDE.template.md
```

Manual checks (in a fresh `claude` session):
- WebSearch attempt → denied with permission-rule reason
- WebFetch on `code.claude.com` → succeeds
- WebFetch on `github.com` → denied (use gh CLI alternative)
- `watch ls` via Bash → denied
- `gh issue view N --repo X` via Bash → succeeds

**Dependencies:** Phase 0 (WebFetch syntax + permissionDecision format
verified).

**Risk notes:** Reversible via settings.json edit. Low risk. If
WebSearch deny breaks anything we use (it shouldn't — we use gh CLI for
github + web-claude forwarding for research), narrow the deny to specific
patterns instead.

**Scope:** S

---

## Phase 2 — F-cell foundation via Rule 6 prompt hook

**Status:** ⏸ DEFERRED 2026-05-27. See top-level Deferred list for the
design gap (prompt hooks lack transcript visibility). Re-entry requires
redesign — likely as a Stop-type command hook, not a PreToolUse prompt
hook. The section below is preserved as the original intent; do not
implement as-written.

**Goal:** Establish the prompt-hook substrate pattern by implementing the
highest-leverage F-cell rule: verification-discipline check on
`gh issue comment | gh pr comment` invocations to catch fabricated metrics
before posting.

**Substrate touched:**
- Cell 5 (F — Trigger-fired judgment): new PreToolUse hook with
  `type: "prompt"`
- Cell 4 (B3 — Event-context): wiring in `settings.json` with `if`-field
  narrowing to `Bash(gh issue comment *)|Bash(gh pr comment *)`
- `lib/` if helper scripts needed

**Deliverables:**
- `dotfiles/ai/claude-code/hooks/verify-gh-numerics.md` — prompt template
  for the fast model: "review the proposed gh comment for numeric values
  that don't appear in recent tool output; flag them"
- `dotfiles/ai/claude-code/install.sh` registers the PreToolUse hook
- A test transcript demonstrating the hook firing on a synthetic fabricated
  metric and *not* firing on a verifiable metric

**Success conditions:**
```bash
# Hook registered in settings.json
jq -e '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[] | select(.type == "prompt")' ~/.claude/settings.json

# if-field narrows correctly (load test)
jq -e '.hooks.PreToolUse[] | .hooks[] | select(.if != null and (.if | test("gh.+comment")))' ~/.claude/settings.json
```

Synthetic tests (manual):
1. `gh issue comment N --body "scrape took 0.0623s"` where 0.0623 is NOT
   in recent tool output → hook flags
2. Same with a number that IS in tool output (verified value) → hook
   allows / defers

**Dependencies:** Phase 0 (verified prompt-hook substrate exists and
deny-format).

**Risk notes:** Prompt-hook adds latency to gh comment posting; the `if`
narrow keeps cost off non-gh Bash calls. 30s default timeout for prompt
hooks; if the fast model takes longer, the hook times out and tool
proceeds (failure mode is permissive, not blocking — acceptable).

**Scope:** M

---

## Phase 3 — B1 enhancement for session-start triage

**Goal:** Move the prose "session-start: triage your own-repo issues" rule
out of cell E (where it gets skipped under pressure) and into cell 2
(B1 — Session-context) by injecting issue bodies into the SessionStart
hook output.

**Substrate touched:**
- Cell 2: new `lib/triage-issues.sh` composed into `hooks/session-env.sh`
- Cell E1: prose in CLAUDE.md "Session-start triage" reduced to the
  judgment part (data gather now lives in B1)

**Deliverables:**
- `dotfiles/ai/claude-code/lib/triage-issues.sh` — JSON-in/JSONL-out lib
  script that runs `gh issue list --author <user>` filtered for `cc-{repo}`
  signature, includes body, recent comments
- `dotfiles/ai/claude-code/hooks/session-env.sh` composes
  `triage-issues.sh` after `gh-issues.sh`
- `dotfiles/ai/modules/session-start-triage.md` (or update the existing
  one) reduced to judgment-only guidance ("for each triaged issue, verify
  success condition; reopen if unmet; acknowledge owner comments")

**Success conditions:**
```bash
# Lib script exists and runs
echo '{}' | ~/.claude/lib/triage-issues.sh | jq -e '.' >/dev/null

# Composed into session-env
grep -q "triage-issues.sh" ~/dotfiles/ai/claude-code/hooks/session-env.sh

# New session shows triage block with issue bodies (not just counts)
# Manual: start a fresh `claude` session in a repo with open issues
# authored by cc-{repo}; SessionStart shows "Open issues w/ bodies"
```

In-session verification (the hrdag-monitor reproduction):
- New session in hrdag-ansible
- First user message: a generic question (not "do triage")
- Model's first response acknowledges the open-issue state in
  context — does not require the user to prompt "run triage"

**Dependencies:** Phase 0 (additionalContext routing verified).

**Risk notes:** Latency cost per session start (one `gh issue list` call
per known repo). If repos grow large, may need pagination or a
deny-list of repos to skip. Reversible by removing the composed line
from session-env.sh.

**Scope:** S–M

---

## Phase 4 — claude-mem migration (MCP → lib/+skill)

**Goal:** Replace the claude-mem MCP server with lib/ scripts wrapping
direct postgres access. Keep the postgres+pgvector backend. Reduce
system prompt token cost; increase discoverability via a reactive skill.

**Substrate touched:**
- `lib/`: new `mem-search.sh`, `mem-store.sh`, `mem-recent.sh`,
  `qfix-store.sh`, `qfix-list.sh`, `qfix-mark.sh` (JSON-in / JSONL-out)
- Cell C: new `/mem` (or `/recall`) skill — auto-fire on description match
- Cell 1: remove `mcp__claude-mem__*` from `permissions.allow`
- `.claude.json`: remove `claude-mem` MCP server entry
- `dotfiles/ai/claude-code/hooks/mem-inject.sh`: rewrite to read from
  postgres via `lib/mem-recent.sh` instead of MCP

**Deliverables:**
- Six `lib/mem-*.sh` and `lib/qfix-*.sh` scripts with consistent JSON I/O
  specs (documented in a `lib/mem-IO.md`)
- `dotfiles/ai/claude-code/skill-templates/mem/SKILL.template.md` — the
  /mem (or /recall) skill with reactive description
- Updated `mem-inject.sh` (SessionStart hook composing
  `lib/mem-recent.sh`)
- `install.sh` updates: remove MCP server entry; remove allow; keep
  postgres host config visible somewhere (e.g., `~/.config/claude-mem/`)
- Migration verification: same content visible via lib/ as via prior MCP

**Success conditions:**
```bash
# Lib scripts work
echo '{"query":"tailscale derp","limit":3}' | ~/.claude/lib/mem-search.sh | jq -e '.[0].id' >/dev/null
echo '{"limit":5}' | ~/.claude/lib/mem-recent.sh | jq -e 'length >= 1'

# MCP entry removed
jq -e '.mcpServers."claude-mem"' ~/.claude.json | grep -q null

# Permission allow removed
jq -e '.permissions.allow | index("mcp__claude-mem__*")' ~/.claude/settings.json | grep -q null

# Skill rendered + discoverable
ls ~/.claude/skills/mem/SKILL.md
~/dotfiles/scripts/claude-md check-tree ~/dotfiles/ai/claude-code/skill-templates --to ~/.claude/skills

# Session start still injects recent memories (via lib, not MCP)
# Manual: start fresh session, observe mem-inject hook output is non-empty
```

**Dependencies:** Phase 0 (verified disable-model-invocation; verified
permission-rule syntax for removal of MCP-pattern allows).

**Risk notes:** Postgres dependency unchanged — snowball must remain
reachable. Rollback: re-add MCP server entry + allow; lib/ scripts can
remain unused. Token-cost win is permanent regardless of rollback decision
(MCP tool descriptions stop consuming system prompt once entry is removed).

**Scope:** M–L

---

## Phase 5 — Runbook unification (RUNBOOK.md → SKILL.md)

**Goal:** Collapse the separate RUNBOOK substrate into the skill substrate
via `disable-model-invocation: true` + `runbook: true` tag. Reduce
maintenance overhead; gain `/inventory` native discoverability; preserve
human-pull semantics.

**Substrate touched:**
- Per-repo skill substrate: `<repo>/.claude/skills/<runbook-name>/SKILL.md`
- Co-located scripts: stay in skill directory, OR lift to
  `<repo>/scripts/lib/` (case-by-case based on reuse)
- Deprecate: `<repo>/scripts/runbooks/` directory tree
- Repo CLAUDE.md "Runbooks" pointer sections updated

**Deliverables (per repo, ~6 in hrdag-ansible + 2 in server-documentation):**
- Each `<repo>/scripts/runbooks/<name>/RUNBOOK.md` migrated via `git mv`
  to `<repo>/.claude/skills/<name>/SKILL.md`
- Frontmatter added: `disable-model-invocation: true`, `runbook: true`
  tag (or similar)
- Co-located scripts in the same skill directory; cross-repo-useful ones
  identified for lift to user-wide `lib/`
- Repo CLAUDE.md "Runbooks" sections updated to point at
  `.claude/skills/` rather than `scripts/runbooks/`
- `/inventory` `lib/inventory.sh` updated to surface runbook-tagged
  skills as a distinct section

**Success conditions:**
```bash
# All runbooks migrated (per repo)
for repo in hrdag-ansible server-documentation; do
  for runbook in <list>; do
    ls ~/projects/hrdag/$repo/.claude/skills/$runbook/SKILL.md
    grep -q "disable-model-invocation: true" ~/projects/hrdag/$repo/.claude/skills/$runbook/SKILL.md
  done
done

# Old runbook directories gone or marked deprecated
! ls ~/projects/hrdag/hrdag-ansible/scripts/runbooks/ 2>/dev/null

# /inventory shows them
bash ~/.claude/lib/inventory.sh | grep -q "RUNBOOKS"

# System prompt token impact verified: each fresh session's available-
# skills listing should NOT include runbook bodies. Spot-check by
# running `claude --print 'what is the description of runbook X'` —
# it should not be able to answer without reading the file.
```

**Dependencies:** Phase 0 (`disable-model-invocation` confirmed to suppress
system prompt indexing — verified empirically 2026-05-27).

**Risk notes:** Operational discoverability changes — humans who used to
`ls scripts/runbooks/` must learn to `/inventory` or `ls .claude/skills/`.
CLAUDE.md pointers help. Co-located scripts may break if hardcoded paths
exist anywhere; audit before move. Rollback: git revert the moves.

**Scope:** M

---

## Phase 6 — repomix + tree-sitter migration (MCP → lib/+skill)

**Goal:** Same pattern as Phase 4 but for two computation-bridge MCPs.
Wrap each CLI via `lib/`, expose via skill with reactive description,
remove MCP server entries.

**Substrate touched:**
- `lib/`: `repomix-pack.sh`, `tree-sitter-parse.sh`, etc. (JSON I/O specs)
- Cell C: `/pack` (or `/repomix`) and `/parse` (or `/ast`) skills
- Cell 1: remove `mcp__repomix__*` and `mcp__tree_sitter__*` allows
- `.claude.json`: remove both MCP server entries

**Deliverables:**
- `lib/repomix-*.sh` wrapping `repomix` CLI binary
- `lib/tree-sitter-*.sh` wrapping `tree-sitter` CLI (or maintained
  Python via uv-managed env)
- Skills with reactive descriptions ("Use when broad codebase context
  needed", "Use for AST-level code queries")
- `install.sh` cleanup of MCP entries

**Success conditions:**
```bash
# Lib scripts work
echo '{"path":"/Users/pball/dotfiles","output":"/tmp/test.xml"}' | ~/.claude/lib/repomix-pack.sh
test -f /tmp/test.xml

# MCP entries removed
jq -e '.mcpServers.repomix' ~/.claude.json | grep -q null
jq -e '.mcpServers.tree_sitter' ~/.claude.json | grep -q null

# Permission allows removed
jq -e '.permissions.allow | index("mcp__repomix__*")' ~/.claude/settings.json | grep -q null
jq -e '.permissions.allow | index("mcp__tree_sitter__*")' ~/.claude/settings.json | grep -q null

# Skills discoverable
ls ~/.claude/skills/repomix/SKILL.md
ls ~/.claude/skills/tree-sitter/SKILL.md
```

**Dependencies:** Phase 0 (allow-removal syntax verified).

**Risk notes:** repomix and tree-sitter CLIs must be on PATH on every
machine; verify during deploy. Same rollback path as Phase 4.

**Scope:** M

---

## Phase 7 — B2 hook infrastructure

**Status:** ⏸ PARTIALLY DEFERRED 2026-05-27. `stop-verify-numerics.sh`
is paired with Phase 2 and inherits the defer. The other two
deliverables (`user-prompt-periodic.sh`, `stop-qfix-scan.sh`) use
`type: "command"` hooks and remain shippable independently — re-scope
this phase to those two if picked up before Phase 2's redesign.

**Goal:** Build out the second-cell hooks (UserPromptSubmit periodic
injection + Stop hook for qfix proactive offer + verification-scan).

**Substrate touched:**
- Cell 3 (B2 — Turn-context): new `dotfiles/ai/claude-code/hooks/`
  - `user-prompt-periodic.sh` — UserPromptSubmit, fires every Nth turn
  - `stop-qfix-scan.sh` — Stop, scans conversation for sudo + system
    paths, injects "qfix that?" reminder if matched
  - `stop-verify-numerics.sh` — Stop, scans for numeric values lacking
    tool-output backing (paired with Phase 2's PreToolUse for full
    coverage)
- `lib/`: helpers for prompt-count tracking (e.g., `~/.claude/state/`
  per-session counter)

**Deliverables:**
- Three new hooks (above)
- `lib/prompt-counter.sh` — increments and reads a per-session counter
  in `~/.claude/state/<session_id>/prompt-count`
- `lib/sudo-system-path-scan.sh` — checks conversation transcript for
  sudo on /etc/, /usr/local/, /var/lib/, systemd unit files
- `install.sh` registers all three hooks in settings.json
- New module `modules/output-budget.md` referenced at install time
  + injected by `user-prompt-periodic.sh` (every Nth turn)

**Success conditions:**
```bash
# Hooks registered
jq -e '.hooks.UserPromptSubmit' ~/.claude/settings.json
jq -e '.hooks.Stop' ~/.claude/settings.json

# Periodic counter works
echo '' | ~/.claude/lib/prompt-counter.sh  # should increment

# Stop-scan finds sudo+system paths
echo "sudo vi /etc/foo" | ~/.claude/lib/sudo-system-path-scan.sh | jq -e '.matched'
```

Manual test: a session that runs `sudo vi /etc/something` should produce
a "qfix that?" injection at end of turn.

**Dependencies:** Phase 2 (prompt-hook pattern established;
verify-numerics in cell F + Stop hook share idiom).

**Risk notes:** Stop hook with `exit 2` would force more model work
(loops, fatigue). Use **plain stdout injection only**, never block.
UserPromptSubmit has 30s timeout — keep periodic-injection logic fast.

**Scope:** M

---

## Phase 8 — Per-repo composability pattern (pilot)

**Goal:** Establish the `<repo>/.claude/CLAUDE.md` composed + `<repo>/.claude/lib`
symlink + per-worktree `CLAUDE.local.md` pattern. Pilot in hrdag-ansible.

**Substrate touched:**
- `<repo>/ai/CLAUDE.template.md` — source, composes from `<repo>/ai/modules/`
  + user-wide modules
- `<repo>/.claude/CLAUDE.md` — rendered output (gitignored or committed?
  open question — see below)
- `<repo>/.claude/lib` — symlink to `~/.claude/lib`
- `<repo-worktree>/.claude/CLAUDE.local.md` — per-worktree identity,
  machine-local (gitignored)
- A `dotfiles/scripts/deploy-repos` script (proto of Phase 10's version)

**Deliverables:**
- Pilot in hrdag-ansible:
  - `hrdag-ansible/ai/CLAUDE.template.md` (template)
  - `hrdag-ansible/ai/modules/` populated with the repo-specific modules
    (roles-merger, roles-impl, roles-ops references)
  - `hrdag-ansible/.claude/CLAUDE.md` (rendered)
  - `hrdag-ansible/.claude/lib` → `~/.claude/lib` (symlink)
  - `hrdag-ansible-merger/.claude/CLAUDE.local.md` (rendered per-worktree)
  - Same for `hrdag-ansible-impl` and `hrdag-ansible-ops` worktrees
- Open decision documented: commit rendered `.claude/CLAUDE.md` to repo
  (preserves git history; visible to teammates) vs gitignore (treat as
  build artifact)
- Proto `deploy-repos --pilot hrdag-ansible` script

**Success conditions:**
```bash
# Pilot rendered cleanly
ls ~/projects/hrdag/hrdag-ansible/.claude/CLAUDE.md
ls ~/projects/hrdag/hrdag-ansible/.claude/lib/inventory.sh  # via symlink
ls ~/projects/hrdag/hrdag-ansible-merger/.claude/CLAUDE.local.md

# check-tree clean
~/dotfiles/scripts/claude-md check-tree ~/projects/hrdag/hrdag-ansible/ai/modules

# Symlink resolves
readlink ~/projects/hrdag/hrdag-ansible/.claude/lib | grep -q "/.claude/lib"

# In-repo session loads composed CLAUDE.md
# Manual: start `claude` from within hrdag-ansible; verify session shows
# the repo-specific identity + role modules
```

**Dependencies:** Phase 5 (runbook unification — composed CLAUDE.md
references skills now, not RUNBOOK paths).

**Risk notes:** Decision needed on commit-vs-gitignore for rendered
`<repo>/.claude/CLAUDE.md`. Per-worktree CLAUDE.local.md must remain
gitignored (machine-local identity).

**Scope:** M–L

---

## Phase 9 — Rule placement content & CLAUDE.md updates

**Goal:** Place each inventory rule (12 from our framework discussion + 3
from the porky-insights doc) against the framework. Update CLAUDE.md
modules to reflect placements. Add facade modules for bundled CC skills.

**Substrate touched:**
- `dotfiles/ai/modules/` — split-by-concern modules (per the (ii) decision)
  - Edit existing modules; add new where rules' homes change
  - Add facade modules: `verify-discipline.md`, `settings-hygiene.md`,
    `app-verification.md` (referencing /run, /verify), `built-in-loop.md`
    (vs custom hooks)
- `dotfiles/ai/CLAUDE.template.md` — composed manifest updated
- Rendered `~/.claude/CLAUDE.md` reflects all changes

**Deliverables:**
- Rule placement table appended to this implementation plan (Appendix A)
  with each rule's final cell(s) and substrate
- Updated existing modules:
  - `web-access.md` (from Phase 1)
  - `goal-lock.md`, `multi-agent.md`, `code-review.md` — review for fit
- New modules (the (ii) split-per-concern approach):
  - `verify-discipline.md` — Rule 6 + porky-insights "verify-before-claim"
    + references `/verify`, `/run` bundled skills + Phase 2's F-cell hook
  - `settings-hygiene.md` — references `/update-config`,
    `/fewer-permission-prompts`
  - `output-budget.md` — Rule 11 + periodic-injection pattern (Phase 7)
  - `triage-discipline.md` — Rule 3 + the B1 enhancement (Phase 3)
  - `built-ins-routing.md` (or split further) — when to use built-in
    `/security-review` vs our `security-reviewer` agent; `/review` vs
    `/code-review`; etc.
- Updated CLAUDE.md composing all new modules

**Success conditions:**
```bash
# All rules placed
grep -c '^| [0-9]\+ |' <this-doc-appendix-A>  # 15 rules

# Modules composed
for module in web-access verify-discipline settings-hygiene output-budget \
              triage-discipline built-ins-routing; do
  grep -q "BEGIN module:$module" ~/.claude/CLAUDE.md
done

# check-tree clean
~/dotfiles/scripts/claude-md check ~/dotfiles/ai/CLAUDE.template.md
```

**Dependencies:** All prior phases (rules' homes depend on substrate
existing).

**Risk notes:** Module sprawl risk — keep each single-concern; reject
"misc-rules" modules.

**Scope:** L

---

## Phase 10 — Cross-repo + cross-machine deploy

**Status (2026-05-28):** split into 10a/10b/10c.
- **10a — cross-machine parity. ✅ DONE.** `deploy-repos --verify-only`
  exit 0 on porky and scott; scott at `17cb8a8`, clean working tree.
  hrdag-ansible targets correctly absent on scott (no checkout there).
  Nothing to deploy — `main` unchanged since scott's 05-26 sync.
- **10b — stale `mcp__repomix__pack_codebase` ref fixes. ✅ DONE.** Fixed
  in filelister, hrdag-monitor, ntx, server-documentation via
  `claude-md render` (NOT hand-edit). Commits: filelister `646803a`,
  hrdag-monitor `700adad`, ntx `22b318f`, server-documentation `665de3c`
  (closed issue #28).
- **10c — drift-proof the in-place composable repos. ✅ SHIPPED (Option B), 2026-05-28.**

  **Decision: B, not template adoption.** The legacy repos compose *only*
  user-wide modules (no repo-local modules), so the Phase-8b template
  pattern buys nothing for them. Instead of converting, we made the
  existing in-place render *automatic*: extended `deploy-repos` with a
  per-entry `MODE` column (`template` / `inplace` / `symlink`). `inplace`
  runs `claude-md render <repo>/CLAUDE.md` against the embedded manifest and
  **skips** the `.claude/lib` symlink (these repos use absolute
  `~/.claude/lib`, so 10c touched zero files inside them). Added filelister,
  hrdag-monitor, ntx, server-documentation, **tfcs** to `repos.txt` as
  `inplace`. Since `install.sh` runs `deploy-repos`, these `CLAUDE.md` files
  can no longer silently drift — closes the #28 class structurally. All five
  idempotent on porky verify.

  **Trade-off accepted:** two manifest formats now coexist (`claude-md:`
  in-place vs `compose:`+template). Operational standardization (one deploy
  mechanism for every composable repo) was the load-bearing goal; format
  unification is deferred until a repo actually needs repo-local modules —
  *that* is the trigger to convert it to the Phase-8b template pattern.
  `claude-md:` is the older verb; if it's ever deprecated, the in-place
  repos need conversion then.

  Caveat banked: never hand-edit a `BEGIN GENERATED` region — `claude-md
  render` only (the 10b mistake; initial hand-edits were superseded by
  re-render commits).

**Goal:** Generalize Phase 8's pilot to all repos that need per-repo
composability. Build the deploy script. Verify on porky; replicate to
scott.

**Substrate touched:**
- New: `dotfiles/scripts/deploy-repos` (idempotent, reads repo manifest)
- New: `dotfiles/ai/repos.txt` (or similar manifest of repos in scope)
- Each in-scope `<repo>/.claude/CLAUDE.md`, `<repo>/.claude/lib`,
  per-worktree `CLAUDE.local.md`

**Deliverables:**
- `dotfiles/ai/repos.txt` — manifest of repos with composition templates
- `dotfiles/scripts/deploy-repos` — walks manifest, renders per-repo
  artifacts, creates lib/ symlinks; `--verify-only` flag for dry-runs
- `dotfiles/ai/claude-code/install.sh` invokes `deploy-repos` after
  user-wide render
- Documentation at top of planning doc: cross-machine rollout sequence
  (push from porky → pull on scott → install.sh → deploy-repos → verify)

**Success conditions:**
```bash
# Manifest exists and lists expected repos
test -f ~/dotfiles/ai/repos.txt
wc -l ~/dotfiles/ai/repos.txt  # >= number of in-scope repos

# Deploy verifies cleanly on porky
~/dotfiles/scripts/deploy-repos --verify-only  # exit 0, no diffs

# Same on scott after git pull
ssh scott "cd ~/dotfiles && git pull --ff-only && bash ai/claude-code/install.sh"
ssh scott "bash ~/dotfiles/scripts/deploy-repos --verify-only"  # exit 0
```

End-to-end cross-machine check: pick a repo with `<repo>/.claude/CLAUDE.md`
that was rendered on porky. On scott, after pull + install.sh +
deploy-repos, the same file should exist with byte-identical content.

**Dependencies:** Phases 1–9 complete.

**Risk notes:** scott's repo checkouts must match porky's structure
(same paths, same worktree topology where relevant). Document any
divergences in the manifest. Worktree-specific CLAUDE.local.md files
remain machine-local; deploy-repos creates them from a template if
absent, doesn't overwrite if present.

**Scope:** M

---

## Verification policy

- Each phase's success conditions must pass on **porky first**, then
  **scott** after rollout, before the phase is marked done.
- A failing success condition is an INCOMPLETE phase, not a partial
  success. Either fix or document the gap as deferred.
- "Manual checks" in success conditions are acceptable but should produce
  a transcript or screenshot recorded in this doc (or a linked
  per-phase notes file).
- Rollback path is mandatory for every phase. If rollback is "revert the
  commit," say so explicitly.

## Cross-machine rollout policy

Per phase:
1. Build & verify on porky.
2. Commit on a worktree branch; PR review (if shape merits) or direct
   to main if low-risk.
3. Push to origin.
4. On scott: `cd ~/dotfiles && git pull --ff-only origin main`.
5. Run `install.sh` if user-wide substrate changed.
6. Run `deploy-repos` if per-repo substrate changed (from Phase 10
   onward).
7. Re-run the phase's success conditions on scott.
8. Phase done when both machines pass.

## Open questions

Resolved by PB 2026-05-27:

1. **Commit-vs-gitignore for rendered `<repo>/.claude/CLAUDE.md`** (Phase 8)
   — **Resolved: gitignore.** It's a build artifact; never let it drift from
   the template.
2. **Facade for `/security-review` vs `security-reviewer` agent** (Phase 9)
   — **Resolved: skip.** Neither is in active use; don't spend module
   real estate differentiating tools we don't reach for.
3. **claude-mem postgres backend portability** (Phase 4) — **Resolved:
   accept the snowball dependency.** If snowball is down, mem-* fails. No
   local fallback.
4. **GitHub allowlist tightening** (Phase 1) — **Resolved: defer.** Likely
   direction is to move all WebSearch-style research to web-claude
   (cleaner, simpler) rather than carve allowlist exceptions in Claude
   Code itself.
5. **`commands` symlink deleted on scott** — **Resolved: accept the break.**
   If something later relies on `~/.claude/commands`, we'll fix it then.

## Appendix A — Rule placement table

Updated 2026-05-28 as part of Phase 9d (validation). Cells reflect the
post-9 state — Phase 7 hook-side substrate is deferred, so rules 4–8
and 11 still rely on prose-only enforcement until Phase 7 ships.

| # | Rule | Cell(s) | Substrate (current) | Status |
|---|---|---|---|---|
| 1 | Anti-reinvention (check skills before code) | E1 + 11 (claude-mem) | `modules/base.md` "## Anti-reinvention" + `~/.claude/lib/mem-search.sh` | shipped (4 + 9a fix to base.md) |
| 2 | Never WebSearch | A | `settings.json` `permissions.deny: ["WebSearch"]` | shipped (1) |
| 3 | Session-start own-repo triage | 2 (B1) + E1 | `lib/triage-issues.sh` + `modules/tri-home.md` (judgment-only) | shipped (3) |
| 4 | Never SSH to current host | 5 (F) | `modules/base.md` "## Task discipline" prose | hook deferred (Phase 7) |
| 5 | git mv / git rm (not bash mv/rm) | 5 (F) | `modules/git-basics.md` prose | hook deferred (Phase 7) |
| 6 | Verify before claiming | E1 + 5 (F) + 3 (B2 Stop) | `modules/verify-discipline.md` (new in 9b) | module shipped; hook + Stop scan deferred (Phase 2, 7) |
| 7 | qfix proactive offer | 3 (B2 Stop) | `modules/qfix.md` prose | Stop hook deferred (Phase 7) |
| 8 | GitHub PR/issue signature | 4 (B3) | `modules/gh-signature.md` prose | PostToolUse hook deferred (Phase 7) |
| 9 | Never watch | A | `settings.json` `Bash(watch *)` deny | shipped (1) |
| 10 | Plan-to-file means STOP | E1 | `modules/base.md` "## Task discipline" | shipped (prose-only by design) |
| 11 | Output budget | E1 + 3 (B2 periodic) | `modules/output-budget.md` (new in 9b) | module shipped; periodic hook deferred (Phase 7) |
| 12 | Pull /facilitator for hard design | E1 + 11 (claude-mem) | `modules/multi-agent.md` (decision tree) + facilitator skill | shipped (no dedicated module needed — covered by multi-agent.md) |
| **+3** | Verification Discipline (insights doc) | folded into Rule 6 | `modules/verify-discipline.md` | shipped (9b) |
| **+3** | Autonomy Defaults (insights doc) | E1 | new module | **deferred** — source content in PB's porky-insights HTML; first-draft skipped in 9b |
| **+3** | Output Budget (insights doc) | folded into Rule 11 | `modules/output-budget.md` | shipped (9b) |

Substrate-facing modules added in 9b that don't map to a numbered rule
above:
- `modules/settings-hygiene.md` — routing for `~/.claude/settings.json`
  edits via `/update-config` and `/fewer-permission-prompts` skills.
- `modules/built-ins-routing.md` — built-in slash commands vs
  specialized agents (table form).

## Appendix B — Bundled CC skills audit

| Skill | Purpose | Facade module candidate |
|---|---|---|
| `/code-review` | Review diff for correctness | ✅ already in `modules/code-review.md` |
| `/run` | Launch and drive app | ✅ Phase 9 `verify-discipline.md` |
| `/verify` | Build + run to confirm change | ✅ Phase 9 `verify-discipline.md` |
| `/loop` | Recurring interval skill runner | ✅ Phase 9 `output-budget.md` (vs custom B2 hooks) |
| `/schedule` | Cron-style remote agent scheduling | Optional |
| `/update-config` | settings.json configuration | ✅ Phase 9 `settings-hygiene.md` |
| `/fewer-permission-prompts` | Allowlist scanning | ✅ Phase 9 `settings-hygiene.md` |
| `/security-review` | Security review of branch | ⚠ Differentiate from `security-reviewer` agent |
| `/review` | Review a PR | ⚠ Differentiate from `/code-review` |
| `/init` | Initialize CLAUDE.md | None (one-time) |
| `/keybindings-help` | Keyboard shortcuts | None (niche) |
| `/claude-api` | Anthropic SDK work | None (out of scope) |
