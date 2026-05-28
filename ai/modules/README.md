<!--
Author: PB and cc-dots
Date: 2026-05-25
License: (c) HRDAG, 2026, GPL-2 or newer

---
ai/modules/README.md
-->

# CLAUDE.md modules

Composable prompt fragments. Each repo's `CLAUDE.md` declares a manifest;
`~/dotfiles/scripts/claude-md render` concatenates the selected modules into
the generated section of that file.

Design + implementation plan: `~/dotfiles/ai/docs/composable-CLAUDE.md-design.md`.

## Implicit (always rendered, regardless of manifest)

| ID | File | Purpose |
|---|---|---|
| base | `base.md` | Universal conduct: communication style, epistemic discipline, security, code-change protocol, task discipline, anti-reinvention, critical don'ts. No opt-out. |

## Opt-in modules

| ID | File | Use when |
|---|---|---|
| web-access | `web-access.md` | Any session with web tools. Backs the settings-level WebSearch / `watch` denies and `WebFetch` allowlist (Anthropic docs); routes research to web-claude. |
| repo-pack | `repo-pack.md` | Working in a code repository (excluded from non-repo dirs like `~/tmp`). Prescribes repomix usage for orientation. |
| git-basics | `git-basics.md` | Any git-tracked dir. Commit gate, `git mv`/`git rm`, commit trailer. |
| python-uv | `python-uv.md` | Python repos. `uv` over naked python; Makefile-first. |
| file-headers | `file-headers.md` | Repos where new files are authored. Author/Date/License convention. |
| shotgun-surgery | `shotgun-surgery.md` | Repos with parallel code paths (e.g. process.py + pgdump.py). Audit-all-callers rule. |
| gh-signature | `gh-signature.md` | Issue/PR-filing repos. Signature footer + success-condition convention. |
| tri-home | `tri-home.md` | Repos with their own GH issue queue. Session-start triage of own-signature issues. |
| tri-slice | `tri-slice.md` | Peer agents with write-reach into another repo's slice (per cross-repo workflow). Session-start slice-filtered triage. |
| cfg-from-disk | `cfg-from-disk.md` | Repos with rotating config (e.g. ntx tfcs.toml keys). Re-read config every time; memory is not truth. |
| xrepo | `xrepo.md` | Anyone participating in the hrdag-ansible cross-repo workflow. 3-4 line summary + pointer to canonical doc. |
| ansible-slice | `ansible-slice.md` | Peer agents with declared slice ownership in hrdag-ansible. PR-only, route through merger. |
| doc-drift | `doc-drift.md` | server-documentation only. 5-step drift-check ritual. |
| roles-merger | `roles-merger.md` | hrdag-ansible (cc-ansible-merger worktree). Pointer to §cc-ansible-merger of workflow doc. |
| roles-impl | `roles-impl.md` | hrdag-ansible-impl. Pointer to §cc-ansible-impl. |
| roles-ops | `roles-ops.md` | hrdag-ansible-ops. Pointer to §cc-ansible-ops. |
| pb-voice | `pb-voice.md` | Skills/agents that produce prose for humans (changelog, README writers, issue/PR composers). Operational subset of `~/docs/pb-voice-guide.md`. |
| code-review | `code-review.md` | When to invoke the built-in `/code-review` skill and at which effort level. Routing rule for specialized reviewers. |
| goal-lock | `goal-lock.md` | When to invoke `/goal` (session anchor) and how it composes with `TaskCreate` (in-session ledger). Goal-condition format. |
| multi-agent | `multi-agent.md` | Decision tree for picking among `Task`, `/coordinate`, `/negotiate`, `/facilitator`, Agent Teams. |
| qfix | `qfix.md` | Sysadmin-flavored sessions likely to touch host state needing IaC encoding (sudo on `/etc/`, `/usr/local/`, systemd units). Ansible-targeted drift queue protocol + proactive offer. |

## How to use

In a managed `CLAUDE.md`, declare the manifest near the top:

```markdown
<!-- claude-md: {"modules": ["repo-pack", "git-basics", "python-uv", "file-headers", "gh-signature", "tri-home", "tri-slice", "xrepo", "ansible-slice"]} -->
```

Then bracket the generated section:

```markdown
<!-- BEGIN GENERATED -->
<!-- END GENERATED -->
```

Run `claude-md render` from the repo root to populate. `claude-md check`
reports drift without modifying anything; the global SessionStart hook runs
this check and warns if the file is stale.

## Adding a new module

1. Author `~/dotfiles/ai/modules/<id>.md` (plain markdown, no frontmatter).
2. Add a row to the table above.
3. Add the ID to the manifest of any repo that needs it; `claude-md render`.

## Adding a new implicit module

The list lives in the renderer as `IMPLICIT = ["base"]`. Edit there.
Discipline reminder: "implicit" means *literally always* — one exception
breaks the rule. Most universals should be opt-in modules listed in every
manifest instead.
