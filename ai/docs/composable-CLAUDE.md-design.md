<!--
Author: PB and cc-dots
Date: 2026-05-24
License: (c) HRDAG, 2026, GPL-2 or newer

---
ai/docs/composable-CLAUDE.md-design.md
-->

# Composable CLAUDE.md — design + implementation plan

Status: **Phases 0-3 implemented (2026-05-25). Phase 4 (self-review
verification) deferred.**

## Problem

Per-repo CLAUDE.md files across `~/projects/hrdag/{tfcs,ntx,filelister,
server-documentation,hrdag-ansible,hrdag-ansible-impl,hrdag-ansible-ops,
hrdag-monitor}` and `~/tmp` have drifted in shape and coverage:

- Global meta-CLAUDE.md prescribes session-start issue-triage; only 2 of 9
  repos implement it (server-documentation, hrdag-ansible-ops).
- The cross-repo workflow doc requires peer agents (tfcs/ntx/hmon/filelister)
  to triage hrdag-ansible issues filtered by their slice at session start — no
  peer CLAUDE.md currently prescribes this.
- Several repo CLAUDE.mds duplicate global content; some are too thin
  (filelister: 3 lines); some have repo-specific operational ritual that
  belongs in a module (server-doc's drift-check ritual).
- Only one repo (hrdag-ansible-ops) has any SessionStart automation, and it's
  bespoke.

The fix is a **modular CLAUDE.md library**: a single base module every repo
gets, plus opt-in modules each repo composes via a manifest.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Composition mechanism | Pre-built file via `claude-md render` | Visible artifact beats hidden hook output for debuggability |
| Module library location | `~/dotfiles/ai/modules/` | Co-located with the user-wide CLAUDE.md and existing global skills/hooks |
| Renderer location | `~/dotfiles/scripts/claude-md` | Single source of truth; on PATH already |
| Manifest syntax | HTML comment with single-line JSON | jq-greppable across repos; survives raw markdown rendering |
| Implicit modules (auto-prepended) | `[]` (none) | `IMPLICIT=()` after Phase 3. The user-wide CLAUDE.md is loaded into every session, so it IS the universal floor — no auto-prepend needed in project files. Manifest can override per-file via `"implicit": [...]`. |
| User-wide CLAUDE.md | Composed file with manifest, same machinery | `ai/CLAUDE.md` (renamed from `ai/docs/meta-CLAUDE.md` in Phase 3). Declares 8 universal modules (base, git-basics, python-uv, file-headers, shotgun-surgery, gh-signature, tri-home, qfix). |
| Renderer accepts file path | Yes (Phase 3) | Lets the same machinery manage `CLAUDE.local.md` and the user-wide `ai/CLAUDE.md`. PATH=dir resolves to PATH/CLAUDE.md; PATH=file is used directly. |
| Module IDs | Descriptive kebab-case (matches filename) | Self-documenting; list isn't long enough for short codes to pay off |
| Modules are prose | Yes (no templating in v1) | Per-repo specifics like slice paths live in repo-specific tail |
| XREPO content | 3-4 line summary + pointer to canonical doc | Avoid inlining 970-line workflow doc into every peer repo |
| ROLES-* content | Pointer-shaped; refer to §cc-ansible-* sections in workflow doc | Agents are agile enough to follow the pointer. Per-worktree role module loaded via `CLAUDE.local.md` manifest. |
| Staleness enforcement | Global SessionStart hook running `claude-md check` against both `CLAUDE.md` and `CLAUDE.local.md` | Warns only; auto-skips files without a manifest comment |
| Repo-specific layout | identity → generated block → repo-specific tail | Identity surfaces first; modules establish behavior; repo specifics last |

## Architecture

### File layout

```
~/dotfiles/
├── ai/
│   ├── CLAUDE.md                     # user-wide; symlinked from ~/.claude/CLAUDE.md
│   │                                 #   composed via manifest: base + 7 universals + qfix
│   ├── docs/
│   │   └── composable-CLAUDE.md-design.md  # this file
│   └── modules/
│       ├── README.md                 # module catalog + usage
│       ├── base.md                   # universal conduct
│       ├── git-basics.md             # git commit gate, git mv/rm, trailer convention
│       ├── python-uv.md              # uv-not-naked-python, Makefile-first
│       ├── file-headers.md           # Author/Date/License header convention
│       ├── shotgun-surgery.md        # parallel code paths audit
│       ├── gh-signature.md           # issue/PR footer + success condition
│       ├── tri-home.md               # own-repo issue triage at session start
│       ├── qfix.md                   # IaC drift queue + filing shorthand
│       │                             #   ↑ above 8 included in user-wide CLAUDE.md
│       ├── repo-pack.md              # repomix usage (project-level opt-in)
│       ├── tri-slice.md              # cross-repo slice triage (peer agents)
│       ├── cfg-from-disk.md          # always-read-config discipline
│       ├── xrepo.md                  # pointer to cross-repo workflow doc
│       ├── ansible-slice.md          # slice discipline for peer agents
│       ├── doc-drift.md              # server-documentation 5-step ritual
│       ├── roles-merger.md           # cc-ansible-merger role (per-worktree)
│       ├── roles-impl.md             # cc-ansible-impl role (per-worktree)
│       └── roles-ops.md              # cc-ansible-ops role (per-worktree)
└── scripts/
    └── claude-md                     # renderer (render | check); on PATH already
```

### Renderer

`claude-md` is a script (bash or python — TBD; bash if it stays small).

```
claude-md render [PATH]    # rewrites CLAUDE.md in PATH (default: cwd)
claude-md check  [PATH]    # exits non-zero if CLAUDE.md is stale
                           # auto-skips if no manifest comment present
```

**Render algorithm:**
1. Read `CLAUDE.md` from target dir
2. Parse manifest comment: `<!-- claude-md: {"modules": [...]} -->`
   - Absent → exit 0 (no-op; not a managed file)
3. Construct module list: `IMPLICIT + manifest.modules` (deduped, order preserved).
   `IMPLICIT = []` (empty) as of Phase 3 — the user-wide CLAUDE.md is now
   the universal floor (loaded into every session via the symlink), so the
   renderer no longer auto-prepends anything. Manifest can override via
   `"implicit": [...]` (used in CLAUDE.local.md to skip duplication).
4. For each module, read `~/dotfiles/ai/modules/{id}.md`
   - Missing → error, exit non-zero
5. Replace content between `<!-- BEGIN GENERATED -->` and `<!-- END GENERATED -->`
   with the concatenated module bodies (with two-blank-line separators)
6. Write back

**Check algorithm:** render to a temp file; diff against on-disk; exit non-zero
on diff. Print 1-line warning naming stale modules if possible.

### Per-repo CLAUDE.md shape

```markdown
# {repo-name} — {tagline}

<!-- claude-md: {"modules": ["git-basics", "python-uv", "file-headers", "gh-signature", "tri-home", "tri-slice", "xrepo", "ansible-slice"]} -->

## Agent identity
cc-{repo} {emoji}. GH footer: `---\n{emoji} cc-{repo}`.

<!-- BEGIN GENERATED -->
...module content concatenated here by `claude-md render`...
<!-- END GENERATED -->

## Repo-specific

### Slice paths in hrdag-ansible
- roles/{repo}/
- playbooks/deploy-{repo}.yml
- ...

### Local conventions
- ...
```

### Global SessionStart hook

Adds a third hook to `~/.claude/settings.json` alongside `mem-inject.sh` and
`session-env.sh`:

```json
{
  "type": "command",
  "command": "bash /Users/pball/.claude/hooks/claude-md-check.sh"
}
```

Hook script `~/dotfiles/ai/claude-code/hooks/claude-md-check.sh`:
- Runs `~/dotfiles/scripts/claude-md check` in cwd
- Auto-skips (exit 0) if no manifest comment
- On stale: emits one-line warning to stdout (becomes context for the agent)
- Never modifies any file; never emits content from modules

## Per-repo composition table

**Universal modules** (loaded via the user-wide `ai/CLAUDE.md` manifest, hence
available in every session): base, git-basics, python-uv, file-headers,
shotgun-surgery, gh-signature, tri-home, qfix.

**Project-level modules** (opt-in via per-repo manifest):

| Repo | repo-pack | tri-slice | cfg-from-disk | xrepo | ansible-slice | doc-drift | roles-* |
|------|-----------|-----------|---------------|-------|---------------|-----------|---------|
| ~/tmp (cc-logwood) |  |  |  |  |  |  |  |
| filelister | ✓ | ✓ |  | ✓ | ✓ |  |  |
| tfcs | ✓ | ✓ |  | ✓ | ✓ |  |  |
| ntx | ✓ | ✓ | ✓ | ✓ | ✓ |  |  |
| hmon | ✓ | ✓ | ✓ | ✓ | ✓ |  |  |
| hrdag-ansible | ✓ |  | ✓ |  |  |  |  |
| hrdag-ansible-impl `CLAUDE.local.md` |  |  |  |  |  |  | impl |
| hrdag-ansible-ops `CLAUDE.local.md` |  |  |  |  |  |  | ops |
| hrdag-ansible `CLAUDE.local.md` |  |  |  |  |  |  | merger |
| server-documentation | ✓ |  |  | ✓ |  | ✓ |  |

## Implementation plan

Steps are sequenced so each is independently verifiable. Don't skip ahead.

### Phase 0 — module + renderer foundation

- [x] **0.1** Create `~/dotfiles/ai/modules/` directory and `README.md` cataloging modules
- [x] **0.2** Author module files (factoring content from `meta-CLAUDE.md` and
      `hrdag-ansible/docs/cross-repo-agent-workflow.md`):
    - [x] `base.md` — universal floor (communication, epistemic, security,
          code discipline, task discipline, anti-reinvention, critical don'ts)
    - [x] `repo-pack.md` — repomix usage (every code repo opts in; not in
          non-repo dirs like ~/tmp): pack at session start, prefer packed
          output over ad-hoc grep/find for "where is X" questions, re-pack on
          substantial tree change
    - [x] `git-basics.md`
    - [x] `python-uv.md`
    - [x] `file-headers.md`
    - [x] `shotgun-surgery.md`
    - [x] `gh-signature.md`
    - [x] `tri-home.md`
    - [x] `tri-slice.md` (new — prescribes the workflow-doc-required slice triage)
    - [x] `cfg-from-disk.md`
    - [x] `xrepo.md` (summary + pointer)
    - [x] `ansible-slice.md`
    - [x] `doc-drift.md`
    - [x] `roles-merger.md` (pointer)
    - [x] `roles-impl.md` (pointer)
    - [x] `roles-ops.md` (pointer)
- [x] **0.3** Write `~/dotfiles/scripts/claude-md` (render + check)
- [x] **0.4** Smoke-test on a throwaway directory:
    - [x] `claude-md check` exits 0 when no manifest present
    - [x] `claude-md render` produces expected output for a manifest of `["git-basics"]`
    - [x] `claude-md check` exits non-zero when manifest modified after render
    - [x] `claude-md check` exits non-zero when generated content tampered
    - [x] `claude-md render` is idempotent (re-running produces no diff)
    - [x] Appending content after END marker (repo-specific tail) does NOT trigger drift
    - [x] Missing module surfaces a clear error
    - [x] Missing BEGIN/END markers (with manifest present) surfaces a clear error

**Success condition for Phase 0:** Renderer works end-to-end against a test
directory; all module files exist and render cleanly.

### Phase 1 — staleness hook

- [x] **1.1** Write `~/dotfiles/ai/claude-code/hooks/claude-md-check.sh`
- [x] **1.2** Add hook to `~/.claude/settings.json` SessionStart array
- [x] **1.3** Verify in a fresh session in a non-managed repo (no manifest):
      hook is silent (verified by direct hook invocation with
      CLAUDE_PROJECT_DIR; fresh-session confirmation will happen naturally)
- [x] **1.4** Verify in a fresh session in a (test) managed repo with stale
      CLAUDE.md: hook emits a single-line warning into context
      (verified by direct invocation; first fresh session in a managed repo
      will exercise it for real)

**Success condition for Phase 1:** Hook runs at every session start, warns
only on actual drift, never modifies files, never emits module content.

### Phase 2 — migration, one repo per step

Each migration step: write manifest + identity + repo-specific tail; render;
verify CLAUDE.md content; commit per repo's normal convention.

- [ ] **2.1** filelister (smallest, proves end-to-end)
    - [ ] Success: rendered CLAUDE.md covers what the old one did + adds tri-slice
    - [ ] Success: `claude-md check` clean immediately after render
- [ ] **2.2** tfcs
    - [ ] Success: slice paths (roles/tfcs/, playbooks/deploy-tfcs.yml, dropbox-ingest/, group_vars/tfcs_nodes/) preserved in repo-specific tail
    - [ ] Success: tri-slice prescribes `gh issue list --repo hrdag/hrdag-ansible --label tfcs`
- [ ] **2.3** hmon
    - [ ] Success: hmon's operational patterns (metric registration, smartctl, permissions, email encoding) preserved in repo-specific tail
- [ ] **2.4** ntx
    - [ ] Success: cfg-from-disk module appears in rendered output
    - [ ] Success: explicit "re-read tfcs.toml every time" reminder preserved
- [ ] **2.5** hrdag-ansible (merger worktree)
    - [ ] Success: roles-merger module pointer present
    - [ ] Success: workflow-doc stewardship + audit-drift session-start ritual preserved
- [ ] **2.6** hrdag-ansible-impl
    - [ ] Success: roles-impl module pointer present
    - [ ] Success: branch naming + lint+check pre-PR rule preserved
- [ ] **2.7** hrdag-ansible-ops
    - [ ] Success: roles-ops module pointer present
    - [ ] Success: existing SessionStart hook in `.claude/settings.local.json`
          reviewed for redundancy with the global check-hook; reconciled
          (likely keep the ops-specific automation since it does more than just
          checking staleness)
- [ ] **2.8** server-documentation
    - [ ] Success: doc-drift module covers the 5-step ritual (FIXME grep,
          WATCH.md, gh issue list, drift-check, recent cc-* commits)
- [ ] **2.9** ~/tmp (cc-logwood)
    - [ ] Decision: does ~/tmp warrant a manifest at all? It's a scratch
          directory. If yes, minimal (BASE + git-basics only; no repo-pack,
          no slice modules — ~/tmp is not a repo).

**Success condition for Phase 2:** Every targeted repo has a rendered
CLAUDE.md, manifest comment present, `claude-md check` clean across all.
Cross-repo composition is greppable via
`grep -h "claude-md:" ~/projects/hrdag/*/CLAUDE.md ~/tmp/CLAUDE.md`.

### Phase 3 — user-wide composition + manifest trim

Mid-implementation observation (Phase 2 → 3): Project CLAUDE.md files were
duplicating content already present in the user-wide `meta-CLAUDE.md`
(loaded into every session via the `~/.claude/CLAUDE.md` symlink). The
"base" module and several others (git-basics, python-uv, file-headers,
shotgun-surgery, gh-signature, tri-home) all repeated rules from the
user-wide file. Cost: ~1-3K duplicated tokens per managed session.

PB's resolution: make the user-wide file modular too. It becomes a composed
file with its own manifest, same machinery as project CLAUDE.md.

- [x] **3.1** Create `~/dotfiles/ai/modules/qfix.md` — extract qfix protocol
      (queue-fix-store/list/mark, filing shorthand, proactive offer rules)
      from the old meta-CLAUDE.md.
- [x] **3.2** `git mv ~/dotfiles/ai/docs/meta-CLAUDE.md ~/dotfiles/ai/CLAUDE.md`
      and refactor: preamble + manifest declaring 8 universal modules
      (base, git-basics, python-uv, file-headers, shotgun-surgery,
      gh-signature, tri-home, qfix) + BEGIN/END + small tail (pull-based
      deploy rule).
- [x] **3.3** `claude-md render` on the new user-wide CLAUDE.md; verify
      content matches what meta-CLAUDE.md provided.
- [x] **3.4** Update `~/.claude/CLAUDE.md` symlink to point to
      `~/dotfiles/ai/CLAUDE.md`.
- [x] **3.5** Update dotfiles references:
    - [x] `dotfiles/CLAUDE.md` — pointer text
    - [x] `ai/claude-code/install.sh` — symlink path + add
          `claude-md-check.sh` to the SessionStart array set up by installer
    - [x] `ai/claude-code/README.md` — multiple references
    - [x] `ai/claude-code/lib/meta-claude-mtime.sh` → renamed to
          `claude-md-mtime.sh`; label inside also updated
    - [x] `ai/claude-code/hooks/session-env.sh` — lib path
    - [x] `ai/claude-code/skills/refresh/SKILL.md` and
          `survey/SKILL.md` — wording
- [x] **3.6** Drop `IMPLICIT=()` in renderer — `base` no longer
      auto-prepended (the user-wide file is the universal floor; project
      CLAUDE.md doesn't need to repeat it).
- [x] **3.7** Re-render the 6 project CLAUDE.md files with trimmed
      manifests (drop universal modules). The 3 CLAUDE.local.md files
      already used `"implicit": []` so unaffected.
- [x] **3.8** Verify hook silent across all 9 dirs after re-render.

**Success condition for Phase 3:** User-wide CLAUDE.md is itself a managed
composed file. `claude-md check` clean on `ai/CLAUDE.md` and across all 9
project locations. Module content lives in exactly one place per module.
Project CLAUDE.md sizes roughly halved (filelister 316→146,
tfcs 473→260, hmon 447→256, ntx 388→197, hrdag-ansible 365→186,
server-documentation 294→107).

### Phase 4 — verify behavior change (DEFERRED)

Verification has two halves: (a) the rendered file is what we expect, and
(b) a fresh agent actually behaves the way the file prescribes. (b) is the
load-bearing check — file content can be correct while agent behavior drifts.

- [ ] **3.1** Write the self-review prompt to
      `~/dotfiles/ai/docs/startup-self-review-prompt.md` (canonical text in
      "Self-review prompt" section below)
- [ ] **3.2** For each migrated repo, launch a fresh Claude Code session,
      paste the self-review prompt, capture the response:
    - [ ] filelister
    - [ ] tfcs
    - [ ] ntx
    - [ ] hmon
    - [ ] server-documentation
    - [ ] hrdag-ansible (merger)
    - [ ] hrdag-ansible-impl
    - [ ] hrdag-ansible-ops
    - [ ] ~/tmp (if managed)
- [ ] **3.3** For each response, score:
    - [ ] Identity correctly stated (cc-{repo} + emoji)
    - [ ] Manifest modules correctly enumerated
    - [ ] Prescribed startup actions match what modules + tail say (no fabricated steps; no omitted steps)
    - [ ] Each prescribed action actually executed in step 4 of the response
    - [ ] Gaps surfaced in step 5 (or "none" if genuinely none)
- [ ] **3.4** For any failing repo: diagnose whether the issue is module
      content (the rule isn't there), module clarity (the rule is there but
      ambiguous), or rendering (the rule didn't make it into CLAUDE.md). Fix
      and re-test.
- [ ] **3.5** Module-change propagation test: edit a module in
      `~/dotfiles/ai/modules/`; run `claude-md check` across all managed
      repos; confirm drift is detected. Re-render all and confirm clean.

**Success condition for Phase 4:** Every migrated repo passes the self-review
prompt cleanly (identity, modules, actions enumerated, actions executed, no
unexplained gaps). Module-level edits propagate via re-render; drift is
visible, never silent.

### Self-review prompt (canonical)

To be saved at `~/dotfiles/ai/docs/startup-self-review-prompt.md`:

> Before responding to anything else, walk me through your session startup as
> if I were observing you. Specifically:
>
> 1. **Identity** — who are you in this repo? What's your `cc-{repo}` identity
>    and emoji?
> 2. **Composition** — read the `claude-md:` manifest comment in CLAUDE.md.
>    List the modules that apply to you (including the implicit ones).
> 3. **Prescribed actions** — what concrete steps does your effective
>    CLAUDE.md (modules + repo-specific tail) tell you to do at session start?
>    Enumerate as commands / tool invocations you would actually run, in
>    order.
> 4. **Execute** — run them now, in order. Report each result before moving
>    to the next.
> 5. **Gaps** — anything in your CLAUDE.md you don't know how to act on, or
>    that seems contradictory or ambiguous? Name it explicitly.
>
> Do not skip steps. Do not paraphrase rules — quote and act. If a step is
> impossible (missing tool, missing file), say so and continue to the next.

## Open / deferred

- **Pre-commit hook integration.** Considered, deferred: the SessionStart
  check-hook + manual `make claude-md` discipline should be sufficient.
  Revisit if drift becomes a practical problem.
- **Repo-pack timing — eager vs. lazy.** Module currently prescribes eager
  (at session start) packing. If the cost (a few seconds + a pack file in
  every session) proves annoying, revisit: switch to lazy ("pack before the
  first non-trivial task that needs orientation") or hybrid (stale-pack-OK
  for read-only sessions, re-pack before any change set).
- **Promoting the self-review prompt to a skill.** If we run it routinely,
  it could become `~/.claude/skills/verify-startup/` rather than a doc to
  paste. Defer until usage pattern is clear.
- **Module parameterization.** Not in v1. The one real use case (per-repo
  slice paths in ANSIBLE-SLICE) is handled by putting slice paths in the
  repo-specific tail rather than the module body.
- ~~**Migration to dotfiles symlink for the renderer.**~~ Resolved 2026-05-25:
  renderer lives at `~/dotfiles/scripts/claude-md` (already on PATH).
- **`cc-ansible-tfccc` and `cc-sysadmin` repos.** Not in current scope (per
  user-supplied repo list). The cross-repo workflow doc lists them as peer
  agents; should be added in a follow-up pass.
- **Workflow-doc edits.** If ROLES-* pointers prove to be too thin, the
  fallback is to extract those sections into modules (heavier surgery on the
  970-line doc). Don't do this preemptively.
