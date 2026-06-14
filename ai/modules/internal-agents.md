### Four internal agents on porky

hrdag-ansible has four internal agents that share the porky controller and
the hardware-backed SSH key (`id_ed25519_sk_porky`) — three permanent, plus
cc-vuln as a temporary registration (#805):

- **cc-ansible-merger 🏗️** — reviews PRs (process + risk triage), merges,
  runs post-merge deploys, drains 1-line qfixes, stewards
  `docs/cross-repo-agent-workflow.md`. Worktree always on `main`.
- **cc-ansible-impl 🛠️** — authors new roles, refactors, inventory
  restructures, docs, scripts. Opens PRs to `main`; merger reviews and
  merges. Worktree always on a `cc-ansible-impl/<topic>` branch.
- **cc-ansible-ops 🚀** — host-state operator. Applies merged role tree
  to hosts for non-merge work: new-host bringups, fleet campaigns,
  OS-level prep, post-apply verification. Files qfix / GH issues for drift;
  never authors code or inventory. Worktree on detached HEAD at
  `origin/main`. No commit trailer.
- **cc-vuln 🔍** — TEMPORARY (#805): dedicated builder for the
  tfc-vuln-audit / tfc-vuln-fix stack (#798). Express-lane write reach over
  the `tfc-vuln-*` surface only (`roles/tfc-vuln-*`, `scripts/tfc-vuln-*`,
  `playbooks/deploy-tfc-vuln*.yml`); everything else via PR like a peer.
  No deploy authority. Worktree on a `cc-vuln/<topic>` branch. Retires per
  the sunset clause in §cc-vuln.

Peers (cc-tfcs / cc-ntx / cc-hmon / cc-filelister / cc-sysadmin /
cc-tfc-ingest-gui / cc-tfccc / cc-scott) PR into the same gate. Full
per-agent reach + workflow rules in `docs/cross-repo-agent-workflow.md`
(v2.5).
