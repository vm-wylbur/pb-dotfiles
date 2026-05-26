<!--
Author: PB and cc-dots
Date: 2026-05-25
License: (c) HRDAG, 2026, GPL-2 or newer

---
ai/docs/composable-artifacts-20260525.md
-->

# Composable Artifacts — Plan

Status: **Plan committed. Track A in progress. Track B awaiting agent.**

## Context

The existing CLAUDE.md composition system (modules → renderer → BEGIN/END
markers, shipped 2026-05-25) works. We extend the same idiom to skills and
agents:

- One composition system. Three artifact kinds (CLAUDE.md, SKILL.md, agent
  files). Modules are the only includes.
- omc plugin (`oh-my-claudecode@omc`) deprecated; 13 keeper agents migrate
  into our dotfiles, 8 are dropped, omc is disabled.
- pb-voice (and similar cross-cutting concerns) become modules instead of
  passive references — render-time inclusion eliminates the "will the model
  read it" risk.
- Agent descriptions today are generic and overlap; a content-sharpening
  pass rewrites them for our actual use cases.

Reframe to keep in mind: **we are not building "skill composition" and then
"agent composition" as separate features.** We are building one
composable-artifacts system. CLAUDE.md, SKILL.md, and agent files are
artifact kinds it produces. Modules are leaves. The renderer is generic.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Source/output separation | Yes for all artifact kinds | Avoids mixing concerns. Source has manifest + markers; output is what Claude Code loads. |
| Source naming | `<NAME>.template.md` | Explicit; greppable; consistent across CLAUDE/SKILL/agent. |
| Manifest grammar | `<!-- compose: {"modules": [...], "output": "PATH"} -->` | Same syntax for all three artifact kinds. `output` field optional (default = sibling `.md`). |
| Marker grammar | `<!-- BEGIN module:NAME -->` / `<!-- END module:NAME -->` | Distinct from CLAUDE.md's `BEGIN GENERATED` so a single file could in principle host multiple module insertion points. |
| Module resolution | Project-local first, then user-wide | Project can override; explicit scoping `user:NAME` / `project:NAME` supported when needed. |
| Module file convention | Plain markdown, no frontmatter, top heading is the section it drops into | Same as existing modules. |
| Symlinks for hooks/lib | Keep | No composition needed; shell scripts; cheaper. |
| Symlinks for skills/agents/CLAUDE | Replace with render targets | Symlink conflates source-of-truth with output. |
| Renderer name | Keep `claude-md` | Renaming churns every install script in every repo. A future `chatgpt-md` could read the same modules. |
| Per-project scope | Supported | `<project>/ai/skill-templates/`, `<project>/ai/agent-templates/`, `<project>/ai/modules/` render to `<project>/.claude/skills/` and `<project>/.claude/agents/`. |
| Agent sharpening | Track B workstream | Big enough to warrant dedicated focus; can run parallel to Track A foundation. |
| omc plugin | Disabled in `settings.json` after Track A migration | Currently disabled flag already exists; just enforces the boundary. |

## Mental Model

```
                    modules/*.md   (leaves; never .template)
                          │
                          ▼
template (.template.md) ── render ──▶ output (.md, no template suffix)
        │                                  │
        │                                  └── what Claude Code loads
        │
        └── source-of-truth (manifest + markers)
```

A template's manifest declares which modules it composes. The renderer
splices each module's body into its `<!-- BEGIN module:NAME --><!-- END
module:NAME -->` region, then writes the result to the output path
(declared in `output` field, defaulting to the sibling `.md`).

## File Layout

### User-wide (dotfiles repo)

```
dotfiles/
  ai/
    CLAUDE.template.md                       # source for ~/.claude/CLAUDE.md
    modules/
      base.md, pb-voice.md, git-basics.md, ...
    docs/
      composable-artifacts-20260525.md       # this file
    claude-code/
      skill-templates/
        changelog/SKILL.template.md
        coordinate/SKILL.template.md
        facilitator/SKILL.template.md
        negotiate/SKILL.template.md
        refresh/SKILL.template.md
        survey/SKILL.template.md
        inventory/SKILL.template.md          # added in Track B
      agent-templates/
        critic.template.md, code-reviewer.template.md, ...  (13 keepers)
        lint-fixer.template.md               # added in Track B
      hooks/                                  # symlinked; no composition
      lib/                                    # symlinked; no composition
      install.sh
```

### Rendered (Claude Code's view)

```
~/.claude/
  CLAUDE.md                                  # rendered
  skills/changelog/SKILL.md, ...             # rendered (real files)
  agents/critic.md, ...                      # rendered (real files)
  hooks/   →  symlink to dotfiles/.../hooks/
  lib/     →  symlink to dotfiles/.../lib/
```

### Per-project

```
<project>/
  CLAUDE.md                                  # rendered
  ai/
    CLAUDE.template.md
    modules/                                 # project-local modules
    skill-templates/<name>/SKILL.template.md
    agent-templates/<name>.template.md
  .claude/
    skills/<name>/SKILL.md                   # rendered
    agents/<name>.md                         # rendered
```

## Renderer Contract

`claude-md` gains two modes:

```
claude-md render <source-file>
    Resolves output via the source's manifest `output` field; falls back
    to sibling .md (strip .template). Source must have a manifest comment.

claude-md render-tree <source-root> --to <output-root>
    Walks source-root for *.template.md files, mirrors structure under
    output-root, strips .template from filenames. install.sh uses this
    for skills and agents bulk rendering.

claude-md render <dir>
    Backward-compat: legacy in-place mode for an existing CLAUDE.md
    that has a manifest + markers but no .template.md sibling.
    Deprecated; emit warning on stderr.

claude-md check <source-file>
    Re-render to tmp, diff against output. Exit non-zero on drift.

claude-md check-tree <source-root> --to <output-root>
    Same idea, walks all templates in source-root.
```

Manifest examples:

```html
<!-- compose: {"modules": ["base", "pb-voice"], "output": "~/.claude/CLAUDE.md"} -->
<!-- compose: {"modules": ["pb-voice"]} -->                    # default: sibling .md
<!-- compose: {"modules": ["user:base", "project:deploy-gates"]} -->
```

The implicit-modules feature from CLAUDE.md ports unchanged: a template
can declare `"implicit": []` to suppress any defaults, or `"implicit":
["base"]` to override the renderer's default IMPLICIT list. The script
default remains `IMPLICIT=()`.

## Staleness Hook

`claude-md-check.sh` (existing) extends from checking just CLAUDE.md and
CLAUDE.local.md to walking the template trees:

- `~/dotfiles/ai/CLAUDE.template.md`
- `~/dotfiles/ai/claude-code/skill-templates/**/*.template.md`
- `~/dotfiles/ai/claude-code/agent-templates/*.template.md`
- `<project>/CLAUDE.template.md`, `<project>/ai/skill-templates/**/*.template.md`,
  `<project>/ai/agent-templates/*.template.md` (if project is composable)

For each: call `claude-md check <source>`, accumulate warnings, surface
once with a single "stale files; run `claude-md render-tree`" hint.

Refactor into multiple hooks later if any single check becomes slow.
For now, one hook walking all targets.

---

## Track A — Composable Artifacts Foundation

**Owner:** current session (cc-dots).
**Goal:** infrastructure + identity migration. After Track A merges,
Track B has the layout, renderer, hook, and unsharpened-but-relocated
agents/skills to work against.

### Steps

1. **Directory restructure** in dotfiles
   - Create `ai/claude-code/skill-templates/` and `ai/claude-code/agent-templates/`.
   - `git mv ai/CLAUDE.md ai/CLAUDE.template.md`.
   - For each existing skill: `git mv ai/claude-code/skills/<name> ai/claude-code/skill-templates/<name>` then `git mv .../SKILL.md .../SKILL.template.md`. Add no manifest yet (the rendered output is identity-equivalent to the source).
   - Old `ai/claude-code/skills/` directory removed.

2. **Migrate 13 keeper agents**
   - From `~/.claude/agents/`, copy these 13 into `dotfiles/ai/claude-code/agent-templates/<name>.template.md`:
     analyst, architect, code-reviewer, code-simplifier, critic, debugger, deep-executor, git-master, quality-reviewer, scientist, security-reviewer, test-engineer, verifier.
   - Drop (do not copy) these 8: designer, qa-tester, writer, document-specialist, build-fixer, explore, executor, planner.
   - The 8 dropped get archived (not deleted): `mv ~/.claude/agents/<name>.md ~/.claude/agents.archive/`.

3. **Extend `dotfiles/scripts/claude-md`**
   - Recognize `<NAME>.template.md` sources.
   - Add `render-tree` and `check-tree` verbs.
   - Parse `output` field from manifest; resolve `~` and relative paths.
   - Add `BEGIN module:NAME` / `END module:NAME` marker support (in addition to legacy `BEGIN GENERATED` / `END GENERATED` for backward compat).
   - Keep `MANIFEST_PREFIX` flexible: accept both `<!-- claude-md: ` (legacy) and `<!-- compose: ` (new). Prefer `compose` for new files.

4. **Extend `dotfiles/ai/claude-code/hooks/claude-md-check.sh`**
   - Walk the user-wide template trees on every SessionStart.
   - One consolidated warning block if any template's output is stale.

5. **Update `install.sh`**
   - Remove `link_file` calls for `skills` and `CLAUDE.md`.
   - Add `claude-md render-tree ~/dotfiles/ai/claude-code/skill-templates --to ~/.claude/skills`.
   - Add `claude-md render-tree ~/dotfiles/ai/claude-code/agent-templates --to ~/.claude/agents`.
   - Add `claude-md render ~/dotfiles/ai/CLAUDE.template.md` (its manifest specifies output `~/.claude/CLAUDE.md`).
   - Keep `link_file` for `hooks` and `lib`.
   - omc-disable already in install.sh (`enabledPlugins."oh-my-claudecode@omc" = false`); confirmed in place.

6. **A1 — `terminalSequence` in `session-env.sh`**
   - Switch hook output from text to JSON.
   - Emit `{additionalContext: <current text>, terminalSequence: "\033]2;${host}:${dir}@${branch}\007"}`.
   - Schema confirmed via hooks docs (top-level string field, OSC 2 for window title).

### Track A Acceptance

- `claude-md render` and `claude-md render-tree` both work end-to-end.
- `claude-md check-tree` reports clean on fresh render, dirty on hand-edit.
- `install.sh` runs idempotently and produces `~/.claude/CLAUDE.md`, `~/.claude/skills/<6 skills>/SKILL.md`, `~/.claude/agents/<13 agents>.md` — all real files, all byte-identical to their sources (because no template has a manifest yet, render is identity).
- A new session shows the window title set via `terminalSequence`.
- SessionStart staleness hook walks all templates, stays silent when clean.

Track A does **not** include:
- Any module content changes
- Any manifest additions to templates
- Any agent description rewrites
- Any new modules
- New skills (inventory, lint-fixer, etc.)
- /goal-lock module
- pb-voice composition proof

Those are Track B.

---

## Track B — Content

**Owner:** separate agent (typically `deep-executor` or `architect`, Opus,
in a fresh session). This section is the agent's playbook.

### Prerequisites

- Track A has merged. The repo state matches the file-layout section above.
- Read `ai/docs/composable-artifacts-20260525.md` (this file) first.
- Read `ai/docs/composable-CLAUDE.md-design.md` for prior context on the
  composition system.
- Identify yourself as `cc-dots` if working from the dotfiles repo, or the
  appropriate per-project identity for project-local work.

### Goal

Populate the composable-artifacts foundation with content. Bring the
collection from "mechanically migrated" to "actively useful."

### Sequence

Steps are intentionally ordered: each builds on prior. Do **not**
parallelize within Track B unless explicitly safe (noted below).

#### Step B1 — pb-voice composition (first proof)

Write `ai/modules/pb-voice.md` by extracting voice rules already inlined in
`ai/claude-code/skill-templates/changelog/SKILL.template.md`. The voice
traits should be concrete and use-case-grounded — terse, citation-driven,
no hype, lowercase casual where appropriate, no emojis except in the
agent-id trailer. Read 2-3 of PB's existing READMEs to triangulate (the
dotfiles README, the hrdag-ansible README, and one HRDAG repo README).

Then:
1. Add a `<!-- compose: {"modules": ["pb-voice"]} -->` manifest at the top of `changelog/SKILL.template.md`.
2. Add `<!-- BEGIN module:pb-voice -->` / `<!-- END module:pb-voice -->` markers in the Voice section.
3. Move the voice content out of the template body into the new module.
4. Run `claude-md render-tree` and verify the rendered `~/.claude/skills/changelog/SKILL.md` content has the voice rules in the right place.
5. Hand-modify the rendered file, run `claude-md check-tree`, verify it warns. Re-render, verify clean.

Acceptance: the round-trip works and the rendered skill content is
semantically equivalent to pre-composition state.

#### Step B2 — Agent description sharpening

Rewrite the 13 keeper agents. For each:

- **Description**: use-case-oriented, not capability-blurb. Format:
  `"Use this agent when X. Strong at Y. Returns Z."` (one sentence).
  Replace generic phrases like "expert at" with concrete triggers.

- **Body**: add an explicit `## Do NOT use when` section. Crisp boundaries
  with sibling agents.

- **Identify merge candidates**: explicitly compare and decide:
  - `critic` vs `code-reviewer` vs `quality-reviewer` — three reviewers.
    Likely keep all three but make distinctions sharp (critic = work-plan
    pre-review; code-reviewer = inline correctness; quality-reviewer =
    SOLID/anti-patterns post-implementation). If any two collapse into the
    same trigger after sharpening, merge.
  - `architect` vs `analyst` — pre-work planning. Likely keep one, possibly
    rename. `analyst` looks like the duplicate.
  - `deep-executor` vs the built-in `general-purpose` agent — these are
    near-duplicates from the harness side. `deep-executor` should either
    be sharpened to claim a non-overlapping niche (long autonomous loops?
    state-saving workflows?) or dropped. PB chose to keep it; sharpen
    rather than drop, but propose drop in your final summary if no niche
    survives the sharpening.

- **Composition**: if multiple agents share content (e.g., role-prompts that
  cite evidence requirements, or the facilitator-style panel personas),
  factor common content into a new module under `ai/modules/role-*.md` or
  similar. Add manifests to the consuming agent templates. Same pattern as
  pb-voice.

Acceptance: each surviving agent has a one-line description a new user can
read and understand when to spawn it. The full agent set has no two
agents whose triggers overlap by more than 20%.

#### Step B3 — New modules

Author the following modules under `ai/modules/`:

1. **`code-review.md`** — content drafted in earlier discussion:
   - When to use `/code-review` (built-in slash) at which effort level
   - `low` / `medium` for bugfixes and small features; `high` / `max` with
     `--comment` for contract-touching PRs
   - Specific reminder: `/code-review` is built-in; do not reinvent.

2. **`goal-lock.md`** — guidance on `/goal`:
   - When to invoke (any non-trivial multi-step task or session expected to
     run > 30 minutes)
   - Condition format: verifiable, atomic, single-line
   - Composition with `TaskCreate` (use both: `/goal` is the session
     anchor, TaskCreate is the in-session checkpoint ledger)
   - Anti-pattern: don't `/goal` trivial single-edit tasks
   - Note: `/goal` is a session-scoped Stop hook; does not persist across
     sessions (ultragoal in omc would have, but omc is deprecated)

3. **`multi-agent.md`** — decision tree for which multi-agent mechanism
   to reach for:
   - Single host, cross-repo decision → `/coordinate` skill
   - Cross-host, peer-to-peer → `/negotiate` skill (MCP-backed)
   - Single-session adversarial review of a negotiation → `/facilitator`
   - Local parallel exploration with direct teammate↔teammate messaging
     → consider Agent Teams (experimental; env-gated; not yet integrated)
   - Subagent spawning within one session → Task tool
   - Brief explanation of when to reach for each, with the failure mode
     each addresses

Acceptance: each module is opt-in (declared in template manifests where
relevant). At least one template composes each. `claude-md check-tree`
clean.

#### Step B4 — lint-fixer (hook + agent)

Two coupled pieces:

1. **Hook extension** — extend `dotfiles/ai/claude-code/hooks/yaml-validate.sh`
   to also run `ansible-lint` on `.yml`/`.yaml` files when the current
   working dir is inside an ansible repo (detect by presence of
   `ansible.cfg` or `playbooks/` at any ancestor up to home). Output first
   ~20 lines on findings; don't block.

2. **New agent** — author `ai/claude-code/agent-templates/lint-fixer.template.md`:
   - Scope: ansible-lint, ruff, yamllint
   - Discipline: minimal diffs, no architectural changes
   - Description: "Use this agent when you have multiple lint findings to
     drain in one pass. Knows ansible-lint, ruff, yamllint dialects."
   - Tools: Read, Edit, Bash, Grep
   - Model: sonnet (cheap, fast)
   - Do NOT use when: errors are runtime (not lint), or when the fix
     requires architectural judgment.

Acceptance: hook surfaces lint output on YAML edits in ansible repos.
Agent spawnable via `Agent(subagent_type="lint-fixer", ...)`. Rendered.

#### Step B5 — 5-advisor panel as modules + composable agents

**Deferred 2026-05-26 (cc-dots).** Reading the actual code revealed
that facilitator has zero co-consumers of the panel pattern: coordinate
uses a different agent topology (Repo Perspective + Integrator +
Adversary), and no other skill calls the panel. The "duplication" B5
would factor is ~75 words of one-liner role appendices in a single
file. Additionally, post-B2 the named agents (`critic`, `architect`,
…) now carry sharpened personas that *differ* from the panel's
transcript-review context — composing the panel one-liners into the
agent templates would overload them. Revisit when (a) a second skill
adopts the same 5-agent panel structure, or (b) B6's `/inventory`
output surfaces real multi-file duplication worth modularizing.

The facilitator skill currently uses an inline 5-advisor panel: `critic`,
`architect`, `security-reviewer`, `code-reviewer` (as DRY-guardian),
`verifier`. With the new system:

- Author `ai/modules/role-critic.md`, `role-architect.md`, etc. containing
  the role prompts (extracted from facilitator/SKILL.template.md).
- The corresponding `agent-templates/<role>.template.md` files compose the
  role module via manifest.
- Update `facilitator/SKILL.template.md` to reference the agents by name
  (`Agent(subagent_type="critic", ...)`) — no inline role prompts needed
  anymore since the agents themselves carry the role.

This factors content out of the facilitator skill into reusable agents.
Other skills (notably `coordinate`) can use the same agents.

Acceptance: facilitator skill still works (its panel-spawn behavior is
unchanged in effect). The role content is owned by modules, consumed by
both the facilitator skill (via Agent calls) and any future skill that
wants the same review structure.

#### Step B6 — `/inventory` skill (gate: B2 done, B3 partial OK)

Build the `/inventory` skill that enumerates the current collection. See
the user-prior discussion for the output shape. Key implementation notes:

- `ai/claude-code/skill-templates/inventory/SKILL.template.md` is the
  source.
- Backed by `ai/claude-code/lib/inventory.sh` which reads:
  - `~/.claude/skills/*/SKILL.md` (frontmatter `name` + `description`)
  - `~/.claude/agents/*.md` (frontmatter)
  - `dotfiles/ai/modules/README.md`
  - `~/.claude/settings.json` hooks block
  - Built-in slash commands (hard-coded curated list, may need periodic
    refresh)
  - MCP servers from `~/.claude.json`
- Output: ~70 lines, two-column scannable cheat sheet.
- Surface in session-env: a one-line note "run `/inventory` to list 30+
  capabilities" (only if running interactively).

Acceptance: `/inventory` produces the cheat sheet. lib script is idempotent
and reads live state (not cached).

### Track B Acceptance Criteria (overall)

1. `claude-md check-tree` clean across all templates after Track B
   completes.
2. Every consumer of pb-voice (and any other multi-consumer module) goes
   through the renderer; no skill or agent has inline duplicate voice
   content.
3. Every keeper agent's description starts with "Use this agent when".
4. No two agents have overlapping trigger conditions.
5. `/inventory` invocation produces a one-screen cheat sheet enumerating
   everything in the collection.
6. The 8 dropped agents are gone from `~/.claude/agents/` (archived
   elsewhere, not in install path).
7. `~/.claude/agents/lint-fixer.md` exists and is spawnable.

### Out of Scope for Track B

- A2 (`background_tasks` / `session_crons` in Stop hook input) — blocked on
  Anthropic schema documentation; defer.
- Pre-flight verification hook (block GH comments with unverified metrics)
  — PB explicitly excluded from parking lot.
- `/pr-drain` skill — per-repo skill; needs the per-project mechanism plus
  per-repo design work; defer.
- `/deploy` skill — per-repo skill; same.
- coordinate v2 with Agent Teams under the hood — experimental feature
  exploration; defer until Agent Teams is GA.
- `TaskCompleted` evidence hook — depends on Agent Teams; defer.
- per-project rendering integration in install.sh — projects own their own
  render invocation; defer until first project actually wants it.

---

## Deferred

| Item | Reason |
|---|---|
| `background_tasks` / `session_crons` capture in Stop hook | Schema not yet documented by Anthropic |
| Per-project rendering integration | Will land when a project needs it (likely `/pr-drain` or `/deploy` in tfcs / hrdag-ansible) |
| Agent Teams integration (coordinate v2, TaskCompleted hook) | Experimental feature; revisit when GA |
| `/pr-drain`, `/deploy` skills | Per-project work; design separately when each repo needs it |

## Not in Scope (explicitly excluded)

| Item | Reason |
|---|---|
| `ultragoal` plugin enable | Inherits omc lineage which we're deprecating; `/goal` alone suffices |
| Pre-flight verification PreToolUse hook | Excluded by PB during scope discussion |
| `chatgpt-md` sibling renderer | Aspirational; not designed; not built |
| Renaming `claude-md` to `compose` | Would churn every install script |
| Splitting CLAUDE.md source/output in projects with no manifest | Files without manifest are passed through verbatim; no `.template` rename forced |

---

## Provenance

This plan emerged from a session on 2026-05-25 that started with a hooks
docs audit and expanded to a full roster review. Source inputs:

- `https://code.claude.com/docs/en/changelog` (2.1.140 → 2.1.150)
- `https://code.claude.com/docs/en/hooks` (terminalSequence schema)
- `https://code.claude.com/docs/llms.txt` (background_tasks blocker)
- `file:///Users/pball/docs/porky-insights-20260525.html` (workflow patterns)
- `~/.claude/plugins/marketplaces/omc/` (ultragoal/`/goal` lineage)
- claude-mem entries 2026-05-22 to 2026-05-25 (composable CLAUDE.md context)
- Existing skills + agents + modules (inventory + DRY analysis)
