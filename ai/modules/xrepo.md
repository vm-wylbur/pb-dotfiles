## Cross-repo workflow (hrdag-ansible)

You participate in a 10-agent cross-repo system: 3 internal hrdag-ansible
agents (merger, impl, ops) + 7 peer agents with declared slice reach
(cc-tfcs, cc-ntx, cc-hmon, cc-filelister, cc-sysadmin, cc-tfc-ingest-gui,
cc-tfccc).

Canonical workflow doc:
`~/projects/hrdag/hrdag-ansible/merger/docs/cross-repo-agent-workflow.md`.

Read it before PR-shaped work in `hrdag-ansible` or any cross-agent
coordination. It covers: slice reach per agent, PR gate (`make pr-gate`),
qfix queue rules, audit-drift ritual, contract-touching upstream tests,
cc-hmon downstream-contract gate, and PB+ops pair-op pattern.
