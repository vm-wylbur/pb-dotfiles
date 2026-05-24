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
- **Axis 2 (determinism) applied to `refresh`.** 7 standalone scripts in `ai/claude-code/lib/`:
  - `env.sh`, `git-status.sh`, `gh-issues.sh`, `gh-prs.sh`, `skills-list.sh`, `mcp-status.sh`, `meta-claude-mtime.sh`
  - `session-env.sh` hook refactored to compose them (behavior-preserving)
  - `refresh/SKILL.md` is now a composition recipe documenting 4 mid-session use cases
  - `install.sh` adds `~/.claude/lib` symlink for new-machine setup
  - `~/.claude/lib` symlink created on porky

## Pending — pick up here

In rough priority:

1. **Apply axis 2 + 3 to remaining skills.** Same pattern: identify scriptable steps, push to `lib/`, spot duplicates, extract shared.
   - `survey` — likely wants `lib/git-log.sh`, reuses `lib/gh-issues.sh`
   - `changelog` — reuses `lib/git-log.sh`, `lib/gh-prs.sh`
   - `coordinate` — mostly judgment; minimal scripting
   - `negotiate` + `facilitator` — share MCP-setup primitive (extract to lib/?)
2. **Convert `doc_drift-check` + `doc_sysadmin` from skills to runbooks.** Both flagged as runbook-shaped (multi-step, deliberate, high blast radius). Move to `scripts/runbooks/<name>/` in their home repos (server-documentation or hrdag-ansible — TBD which).
3. **Reclassify `ansible_inv-first`.** It's a meta-rule ("investigate before implementing"), not a capability. Probably belongs in hrdag-ansible/CLAUDE.md, not as a skill.
4. **Convert hrdag-ansible procedural docs to `scripts/runbooks/<name>/`.** ~4-5 candidates: `adding-new-host.md`, `decommission-host.md`, `revoke-user-ssh-cert.md`, parts of `pikvm-hardening.md`.
5. **Axis 1 (visibility / risk gating).** Verify Claude Code's support for `disable-model-invocation` frontmatter. Apply to high-risk skills (`ansible_address`, `doc_sysadmin` if it stays a skill).
6. **Agents → dotfiles.** 21 stock OMC agents live in `~/.claude/agents/` un-version-controlled. Decide: vendor them into dotfiles, or leave to OMC plugin updates.
7. **Stale README cleanup.** `claude-code/skills/README.md` still lists skills that no longer exist (code-explore, postgres-optimization, etc.). Either rewrite or delete.
8. **MCP → skill conversion (longer-term target).** PB flagged: some MCP behaviors should be skills backed by lib/ scripts for offline reliability + version control. Candidates: claude-mem (file-based store + grep search), possibly claude-negotiate.

## Open questions / things to verify

- Does Claude Code recognize `disable-model-invocation: true` and `user-invocable: false` in skill frontmatter? (From the audit-prompt video — needs verification against Claude Code docs.)
- For runbook discovery: confirmed approach is one-line CLAUDE.md pointer per repo to `scripts/runbooks/`. No session-start advertising (O(1) attention cost).
- claude-mem MCP came back online mid-session. If it goes down again, the MCP→skill conversion (item 8) becomes higher priority.

## Recent commits (dotfiles)

```
d423392 meta-CLAUDE: trailer format is "claude-id then emoji"
e188026 CLAUDE.md: cc-dots agent identity + repo tagline
b165582 ai/claude-code/hooks: pre-bash-guard.sh from kill-cascade incident
```

## Related PRs

- hrdag-ansible #543 — rename investigate-first → ansible_inv-first
