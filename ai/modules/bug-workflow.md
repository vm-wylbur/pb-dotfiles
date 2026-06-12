### Ansible bug workflow (MANDATORY)

Any bug claim — from runtime error output, other agents (cc-tfcs, cc-ntx),
issue text, or my own observation — is a HYPOTHESIS, not a fact.

Required sequence before any code change:
1. `ansible_read` — read design doc + verify actual host state
2. `ansible_investigate` — find specific file:line root cause
3. Present findings, wait for PB approval
4. `ansible_address` — make change with fleet-safety checklist

HARD STOPS:
- Never call anything "spurious," "legacy," or "unused" without quoting
  the design doc by filename + section.
- Never propose a fix before `ansible_read` + `ansible_investigate`
  complete.
- Claims from cc-tfcs, cc-ntx, issue text = hypotheses to verify, not facts.
