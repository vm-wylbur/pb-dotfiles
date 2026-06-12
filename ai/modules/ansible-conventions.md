### Ansible conventions

- Always run `ansible-playbook` from the hrdag-ansible directory — never
  from other repos.
- Never hardcode node-specific values in templates. Use variables and
  Jinja2 (`ansible_hostname`, group_vars, host_vars). Hardcoded
  hostnames/paths in templates = immediate stop.
- NEVER use `copy:` for files that contain ANY path, hostname, IP, or
  port that could differ per host. Use `template:` with variables.
- Jinja2 templates that contain shell curly braces: always wrap with
  `{% raw %}...{% endraw %}`.
- `ansible-playbook apply` (without `--check`) requires explicit user
  permission. `--check` and `--diff` modes are free. Propose first,
  apply after go-ahead.
- After PB approves a change: deploy directly (not `--check`). `--check`
  is noisy and often misleading for multi-step roles. Verify AFTER deploy
  with host checks.
- Default deploy order: scott first, then fleet. Never skip the reference
  node.
- Detect target host architecture (ARM64 vs AMD64) before deploying
  binaries: `ansible -m setup -a 'filter=ansible_architecture' <host>`.
- Before closing ANY issue: SSH to affected host(s) and verify on-disk
  state. Issue text, other agents' claims, and "ansible ran clean" are
  NOT verification.
