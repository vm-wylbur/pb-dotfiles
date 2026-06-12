### Cross-repo workflow

Canonical doc: `docs/cross-repo-agent-workflow.md` (v2.1). Converged via
claude-negotiate session `neg-c4f214ec` 2026-04-30; see that doc's
header for full version history.

Key rules:
- **PR gate**: `ansible-lint` + `--check --diff --limit <one-host>` must
  pass clean. Contract-touching changes need upstream test reference in PR
  body.
- **Deploy authority**: cc-ansible-merger (post-merge applies) +
  cc-ansible-ops (all other applies). Peers and cc-ansible-impl never
  apply.
- **Commit trailer**: `By PB & {claude-id} {emoji}` (see your
  `CLAUDE.local.md` for the per-agent value). No `Co-authored-by`.
- **Cross-cutting / new-role / inventory restructure** → GH issue first;
  PRs implement.
- **qfix drain**: 1-line in 1 file → cc-ansible-merger handles. Bigger →
  file as issue, route to cc-ansible-impl.
- **Express lane vs. qfix queue**: per-role write reach is the express
  lane. Cross-role observations from peers still go through qfix.
