### Runbooks

Deliberate multi-step procedures live in
`.claude/skills/<name>/SKILL.md` with `disable-model-invocation: true`
and `runbook: true` in the frontmatter (human-pulled, not auto-fired).
Discover via `/inventory` (RUNBOOKS section). Current:

- `add-host` — add a new machine to HRDAG infrastructure (3 phases +
  per-class notes)
- `decommission-host` — permanently remove a host from the fleet
- `harden-pikvm` — manual PiKVM bringup (service user, restricted-shell
  wrapper)
- `inv-first` — verify host state before implementing an issue fix
- `recover-pikvm` — recover an unreachable PiKVM device
- `revoke-user-cert` — revoke a user's CA-signed SSH cert (KRL update +
  deploy)
