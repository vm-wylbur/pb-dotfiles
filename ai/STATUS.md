<!--
Author: PB and cc-dots 🧷
Date: 2026-05-23
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/ai/STATUS.md
-->

# Skills + Agents Audit — Session Handoff

**Last session:** 2026-05-23
**Active agent:** cc-dots 🧷 (this repo)
**Resume command:** "Continue the skills+agents audit. Read `ai/STATUS.md` first."

## What this is

Multi-session project to audit and restructure the AI agent setup:
skills, agents, hooks, scripts, runbooks, MCP config. Triggered by an
audit prompt from an Anthropic-engineer video (3-axis framework:
Visibility, Determinism, Composability) plus a scope axis we added
(where things live across user-wide dotfiles vs per-repo).

## Architecture decisions banked

| Decision | Lives at |
|---|---|
| Reactive, single-concern skills | `<repo>/.claude/skills/` (user-wide for generic; repo-local for domain) |
| Deliberate multi-step procedures | `<repo>/scripts/runbooks/<name>/RUNBOOK.md` + co-located scripts |
| Cross-repo shared script primitives | `dotfiles/ai/claude-code/lib/*.sh` → `~/.claude/lib/*.sh` |
| Repo-specific script primitives | `<repo>/scripts/*.sh` |
| Session-start state injection | hook (`session-env.sh`) — composes lib/ scripts |
| Mid-session reload | `refresh` skill — composition recipe for lib/ scripts |
| Reference docs (knowledge, contracts) | `<repo>/docs/*.md` (flat) |
| Skills are reactive, AI auto-fires | runbooks are deliberate, human-pulled |
| One consistent runbook path across all repos | yes — `scripts/runbooks/<name>/RUNBOOK.md` |
| ansible_* skills | repo-local in hrdag-ansible only (removed from user-wide) |

## Distinction: skill vs runbook

| | Skill | Runbook |
|---|---|---|
| Shape | Single factored concern | Sequence (may call skills + judgment + scripts) |
| Frequency | Many times across many contexts | Rare, for a specific operational event |
| Invocation | AI auto-fires from description match | Human-pulled deliberately |
| Risk | Reactive, narrow blast radius | Often multi-system, ordered |
| Output | A capability | A completed operation |

## What's done

- **Scope phase complete.** 4 ansible skills removed from dotfiles (`rm -rf`); now only in hrdag-ansible repo. PR #543 renames `investigate-first` → `ansible_inv-first` (awaiting cc-ansible-merger merge).
- **cc-dots identity established.** 🧷 "fastens the agent env." In `dotfiles/CLAUDE.md`. Commit trailer: `By PB & cc-dots 🧷`.
- **Trailer convention restored** to `{claude-id} {emoji}` (cbec5ad had inverted it; superseded by `d423392`).
- **OMC plugin removed**; stale `enabledPlugins."oh-my-claudecode@omc"` entry cleared from `~/.claude/settings.json` (2026-05-23).
- **`doc_drift-check` + `doc_sysadmin` converted to runbooks** in server-documentation (2026-05-23):
  - `server-documentation/scripts/runbooks/drift-check/RUNBOOK.md` (5da7dc5)
  - `server-documentation/scripts/runbooks/sysadmin-change/RUNBOOK.md` (0b24a7f)
  - `hrdag-ansible/scripts/coverage-search.sh` (3817b44) — extracted from sysadmin-change Step 3a
  - `server-documentation/CLAUDE.md` runbook pointer (17e7ce2)
  - Source dirs removed from dotfiles; minimal `name`/`description` frontmatter retained on RUNBOOK.md for indexing.
- **`ansible_inv-first` converted to runbook** in hrdag-ansible (2026-05-24, 3b1dd6a):
  - `hrdag-ansible/scripts/runbooks/inv-first/RUNBOOK.md` (git tracked as rename from `.claude/skills/ansible_inv-first/SKILL.md`, history preserved).
  - `hrdag-ansible/CLAUDE.md` runbook pointer added (mirrors server-doc pattern).
  - Reclassification: STATUS.md called this a "meta-rule for CLAUDE.md" but reading the content showed it's runbook-shaped (6 phases, connectivity map, classification rubric). Converted to runbook instead — preserves the procedural value.
  - Side fixes: stale `mcp__claude-mem__search` → `mcp__claude-mem__mem-search`; `.omc/plans/` annotated as read-only archive (OMC plugin removed).
- **`negotiate` + `facilitator` + `coordinate` axis-2 pass** (2026-05-23, a47126b):
  - 2 new `lib/` primitives: `negotiate-mcp-setup.sh` (idempotent `claude mcp add`) and `negotiate-agent-id.sh` (resolves agent_id from CLAUDE.md). Total `lib/` count: 16.
  - Both skills' install blocks collapse from prose + duplicated `claude mcp add` to one-liners calling the scripts.
  - **OMC-removal repairs (side finding):** facilitator advisor panel referenced `Agent("oh-my-claudecode:critic")` etc. — those agent prefixes died with OMC. Bare names work (`critic`, `architect`, `security-reviewer`, `code-reviewer`); `tdd-guide` → `verifier`. coordinate's "Disable OMC" preamble removed.
  - **Frontmatter fix (side finding):** negotiate + facilitator had no YAML frontmatter, so the skills index surfaced "Author: PB and Claude" as the description. Replaced with proper `name`/`description` — both now show meaningful triggers in the available-skills list.
  - coordinate left mostly alone — single-session subagent architecture, no MCP overlap. Repomix-pack extraction deferred (one consumer; YAGNI).
- **Axis 2 (determinism) applied to `refresh` + `survey` + `changelog`.** 14 standalone scripts now in `ai/claude-code/lib/`:
  - From refresh (7): `env.sh`, `git-status.sh`, `gh-issues.sh`, `gh-prs.sh`, `skills-list.sh`, `mcp-status.sh`, `meta-claude-mtime.sh`
  - From survey (3): `git-pull-ff.sh`, `code-todos.sh`, `git-log-recent.sh`
  - From changelog (4): `gh-author-commits.sh`, `gh-author-issues.sh`, `repo-diff-since.sh`, `git-version-tags-since.sh`
  - `session-env.sh` hook composes mtime + MCP primitives (grounds every session start on guideline freshness + MCP gaps); `claude-negotiate` added to expected-MCP list.
  - All three SKILL.md files rewritten as composition recipes: deterministic data gathering delegated to lib/ scripts; AI focuses on judgment (refresh: 4 mid-session use cases; survey: staleness + categorization + prioritization; changelog: voice, theme selection, narrative synthesis).
  - `install.sh` adds `~/.claude/lib` symlink; symlink created on porky.

## Pending — pick up here

In rough priority:

1. **Convert hrdag-ansible procedural docs to `scripts/runbooks/<name>/`.** ~4-5 candidates: `adding-new-host.md`, `decommission-host.md`, `revoke-user-ssh-cert.md`, parts of `pikvm-hardening.md`. The `scripts/runbooks/` dir now exists (created by inv-first conversion).
2. **Axis 1 (visibility / risk gating).** Verify Claude Code's support for `disable-model-invocation` frontmatter. Apply to high-risk skills (e.g. `ansible_address`).
3. **Agents → dotfiles.** 21 stock OMC agents live in `~/.claude/agents/` un-version-controlled. Decide: vendor them into dotfiles, or leave to OMC plugin updates. (OMC plugin itself has been removed — see settings cleanup above; agents survived because they were dropped into `~/.claude/agents/` directly.)
4. **Stale README cleanup.** `claude-code/skills/README.md` still lists skills that no longer exist (code-explore, postgres-optimization, etc.). Either rewrite or delete.
5. **MCP → skill conversion (longer-term target).** PB flagged: some MCP behaviors should be skills backed by lib/ scripts for offline reliability + version control. Candidates: claude-mem (file-based store + grep search), possibly claude-negotiate.
6. **Branch cleanup (hrdag-ansible):** `cc-dots/rename-investigate-first` branch (PR #543, merged 2026-05-24) still exists locally + remote. Safe to delete.

## Open questions / things to verify

- Does Claude Code recognize `disable-model-invocation: true` and `user-invocable: false` in skill frontmatter? (From the audit-prompt video — needs verification against Claude Code docs.)
- For runbook discovery: confirmed approach is one-line CLAUDE.md pointer per repo to `scripts/runbooks/`. No session-start advertising (O(1) attention cost).
- claude-mem MCP came back online mid-session. If it goes down again, the MCP→skill conversion (item 8) becomes higher priority.

## Recent commits (dotfiles)

```
919709a changelog: decompose into lib/ scripts + voice-focused skill
4651c57 survey: decompose into lib/ scripts + judgment-focused skill
cca4300 session-env: emit mtime + MCP status; refresh skill simplified
f1aeec6 ai/STATUS.md: skills+agents audit handoff
bdb2bce refresh: decompose into lib/ scripts + thin orchestrator hook
d423392 meta-CLAUDE: trailer format is "claude-id then emoji"
e188026 CLAUDE.md: cc-dots agent identity + repo tagline
```

## Related PRs

- hrdag-ansible #543 — rename investigate-first → ansible_inv-first
