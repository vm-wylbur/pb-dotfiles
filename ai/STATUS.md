<!--
Author: PB and cc-dots 🧷
Date: 2026-05-23
Updated: 2026-05-26
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/ai/STATUS.md
-->

# Skills + Agents Audit — Status

**Last session:** 2026-05-26
**Active agent:** cc-dots 🧷 (this repo)
**Audit arc:** composable-artifacts plan executed (Track A + Track B
B1–B4, B6; B5 deferred). See `ai/docs/composable-artifacts-20260525.md`
for plan + rationale.

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
| Composable artifacts (CLAUDE.md / SKILL.md / agents) | `.template.md` sources + `claude-md render-tree` → rendered outputs |
| Source-of-truth separation | templates live in `ai/`; rendered outputs in `~/.claude/` |
| Cross-cutting prose (voice, code-review, goal, multi-agent) | `ai/modules/<id>.md`, composed via per-template manifest |

## Distinction: skill vs runbook

| | Skill | Runbook |
|---|---|---|
| Shape | Single factored concern | Sequence (may call skills + judgment + scripts) |
| Frequency | Many times across many contexts | Rare, for a specific operational event |
| Invocation | AI auto-fires from description match | Human-pulled deliberately |
| Risk | Reactive, narrow blast radius | Often multi-system, ordered |
| Output | A capability | A completed operation |

## What's done

### Phase 1 — Scope + identity (2026-05-23)

- 4 ansible skills moved from dotfiles to hrdag-ansible (repo-local only).
- `cc-dots` 🧷 identity established; commit trailer convention restored
  (`{claude-id} {emoji}`).
- OMC plugin removed; `enabledPlugins` entry cleared from settings.json.

### Phase 2 — Docs to runbooks (2026-05-23 → 2026-05-24)

- `doc_drift-check` + `doc_sysadmin` → runbooks in server-documentation.
- `ansible_inv-first` + `decommission-host`, `revoke-user-cert`,
  `add-host`, `harden-pikvm`, `recover-pikvm` → runbooks in hrdag-ansible.
- Reference docs (e.g. `ssh-ca-overview.md`, `pikvm-reference.md`)
  separated from procedural runbooks where co-mingled.

### Phase 3 — Determinism (lib/ extraction, 2026-05-23)

- 14 standalone scripts extracted into `ai/claude-code/lib/` from
  `refresh`, `survey`, `changelog`, `negotiate`, `facilitator`.
- `session-env.sh` composes mtime + MCP primitives at every session start.
- `~/.claude/lib` symlink in install.sh.

### Phase 4 — Composable artifacts (Track A + B, 2026-05-25 → 2026-05-26)

Per `ai/docs/composable-artifacts-20260525.md`:

- **Track A**: directory restructure, 13 keeper agents migrated,
  `claude-md` extended with `render-tree`/`check-tree`, staleness hook
  walks template trees, install.sh updated to render rather than symlink.
  (A1 terminalSequence reverted.)
- **B1**: `pb-voice` module extracted from `changelog` skill; composition
  proven end-to-end.
- **B2**: 12 keeper agents sharpened with use-case-oriented descriptions
  and Do-NOT-use boundaries; `deep-executor` dropped.
- **B3**: `code-review`, `goal-lock`, `multi-agent` modules added and
  composed into the user-wide CLAUDE.md.
- **B4**: `yaml-validate.sh` extended with advisory ansible-lint pass
  (ancestor detection, non-blocking); `lint-fixer` agent (sonnet,
  Read/Edit/Bash/Grep) for draining multi-finding lint passes.
- **B5**: **deferred** — premise (extract panel role prompts into shared
  modules) doesn't match reality (zero co-consumers; post-B2 agent
  personas differ from panel role). Revisit if a second consumer
  emerges. Rationale in plan doc.
- **B6**: `/inventory` skill + `lib/inventory.sh` (two-column cheat
  sheet of skills/agents/modules/hooks/MCPs/built-in slashes);
  session-env emits a one-line hint pointing at it.

Total user-wide collection after Track B: 7 skills, 13 agents,
22 modules (21 opt-in + 1 implicit), 4 hooks.

## Pending — pick up here

In rough priority:

1. **Axis 1 (visibility / risk gating).** Still unverified: does Claude
   Code recognize `disable-model-invocation` / `user-invocable: false`
   in skill frontmatter? Apply to high-risk skills if supported.
2. **B5 revisit conditions.** Watch for (a) a second skill adopting the
   5-agent panel structure, or (b) `/inventory` output surfacing real
   multi-file duplication worth modularizing. If neither emerges, B5
   stays deferred indefinitely — that is fine.
3. **`ai/docs/to-deprecate-meta-CLAUDE.md`.** Still in the docs dir;
   marked for deletion. Either delete or repurpose.
4. **MCP → skill conversion (longer-term target).** Some MCP behaviors
   should be skills backed by lib/ scripts for offline reliability +
   version control. Candidates: claude-mem (file-based store + grep),
   possibly claude-negotiate.
5. **Branch cleanup (hrdag-ansible):** `cc-dots/rename-investigate-first`
   branch (PR #543, merged 2026-05-24) still exists locally + remote.
   Safe to delete if not already done.

## Open questions / things to verify

- Does Claude Code recognize `disable-model-invocation: true` and
  `user-invocable: false` in skill frontmatter? (From the audit-prompt
  video — needs verification against Claude Code docs.)
- Module composition for *agent* templates is unproven end-to-end:
  every keeper agent renders as passthrough (no manifest), and B5's
  deferral postponed the first marker-based agent render. First agent
  to grow a manifest is the bug-discovery moment for the renderer's
  agent-frontmatter path.

## Related artifacts

- `ai/docs/composable-artifacts-20260525.md` — Track A/B plan (source
  of truth for Phase 4).
- `ai/docs/composable-CLAUDE.md-design.md` — pre-Track A design notes.
- `ai/modules/README.md` — module catalog (used by `/inventory`).
