<!--
Author: PB and cc-dots 🧷
Date: 2026-06-13
License: (c) HRDAG, 2026, GPL-2 or newer

---
dotfiles/docs/versioning.md
-->

# Versioning the agent environment

This repo is the agent environment — skills, hooks, lib scripts, MCP config, CLAUDE.md modules, the conformance suite — deployed pull-based onto each host via `ai/claude-code/install.sh`. As of `1.0.0` (2026-06-13) it carries a single declared version, tagged in git, marking the point at which versioning became a discipline rather than an afterthought. The cut coincides with the start of the cross-agent capture-architecture direction; `1.0.0` is "the environment as it stood before that work began."

## The number lives in two places, kept in sync

- `VERSION` at the repo root holds the declared version (e.g. `1.0.0`) — runtime-readable, the source of truth for "what version is this tree."
- An annotated git tag with the same value marks the exact commit. The tag is immutable history; the file is what tooling reads.

A version cut updates the file and tags the commit that contains the update, so the tag always points at a tree that declares its own version.

## Format: bare semver, no `v` prefix

Versions are `MAJOR.MINOR.PATCH` with no prefix — `1.0.0`, not `v1.0.0`. This matches the repo's existing component versions (`ai/harvest-conformance/VERSION` is `1.4.0`, bare) and deliberately distinguishes the new scheme from the two fossil tags (`v0.1`, `v.0.9.0`) left over from the repo's earlier life as literal shell/vim dotfiles. Those fossils are kept as honest history; the absence of the `v` is the signal that a tag belongs to the disciplined era.

## Bump rules

The unit of change is the **deploy contract** — what `git pull && install.sh` does to a host.

- **MAJOR** — the deploy contract breaks. An `install.sh` layout change, a `settings.json` or hook schema migration, a removed/renamed surface other tools depend on — anything where re-running the installer is *not* seamless and a host needs manual attention.
- **MINOR** — a new backward-compatible capability: a new skill, hook, lib script, agent template, or a capture layer. Re-running the installer picks it up with no manual step.
- **PATCH** — fixes or docs to existing surface, no new capability and no contract change.

The cross-agent capture work (incremental harvester, daily fleet brief, verdict-moment capture hooks, peer-signal relay) is additive, so each layer lands as a MINOR — `1.1.0`, `1.2.0`, and so on. `2.0.0` is reserved for the first change that breaks the deploy contract.

## Relationship to the changelog and to component versions

This version is orthogonal to the `/changelog` skill. The changelog is date-windowed and fleet-wide — it answers "what happened across all repos between these dates." The environment version answers "what state is *this* environment in, and what is deployed where." A version cut may reference the changelog window that produced it, but neither generates the other.

Component versions stay independent. `ai/harvest-conformance/VERSION` tracks the conformance suite's own contract and bumps on its own cadence; the repo-level `VERSION` tracks the environment as a whole. Two scopes, two numbers, no coupling.

## Cutting a version

1. Decide the bump (major/minor/patch) per the rules above.
2. Edit `VERSION` to the new number.
3. Commit it (`env: cut X.Y.Z` with the standard trailer).
4. Annotated tag on that commit: `git tag -a X.Y.Z -m "<what this version is>"`.

Keep tag messages substantive — the annotation is where a future reader learns *why* the cut happened, since the changelog lives on a different axis.

## What makes the version load-bearing: the deploy stamp

`install.sh` writes `~/.claude/.env-version` (JSON) on every deploy, recording the declared `VERSION`, `git describe --tags`, the short commit, the deploy timestamp, the host, and a `deploy_repos` status (`ok` / `degraded` / `skipped`) so the stamp doesn't overstate success when the per-repo deploy step had issues. This is what keeps the scheme from decaying into ceremony the way `v0.1` did: it makes "porky is on 1.2.0, scott is on 1.1.0" a directly answerable question, which is the host-drift problem the managed-settings sync work keeps surfacing. `git describe` also exposes intra-tag drift (`1.1.0-3-gabc123` = three commits past the tag), so a host that pulled but skipped a tagged cut is visible.
