## Built-in skills vs agents — routing

Claude Code ships a growing roster of built-in slash commands; PB
also runs a set of specialized agents. The two are NOT
interchangeable — they answer different questions on different
objects. Don't spawn an agent when a built-in covers the case, and
don't reach for a built-in when you need a specialized lens.

| Question | Built-in | Specialized agent |
|---|---|---|
| Is this diff correct? | `/code-review` (effort: low/med/high/max) | `code-reviewer` for thorough spec-compliance review |
| Is this branch a security risk? | `/security-review` (whole branch) | `security-reviewer` (OWASP threat-modeling lens) |
| Review THIS pull request | `/review <PR#>` | — |
| Does this code work end-to-end? | `/verify` / `/run` (launch + observe) | — |
| Maintainability / SOLID / anti-patterns | — | `quality-reviewer` |
| Hostile read of a plan before exec | — | `critic` |
| Build a recurring loop | `/loop` (in-session) or `/schedule` (cron) | — |
| Configure the harness itself | `/update-config`, `/fewer-permission-prompts` | — |

**Rules of thumb.**

- Built-in first when the question matches its shape. Built-ins are
  cheaper, faster, and PB-audited.
- Agent when the question needs a specific lens that no built-in
  provides (threat model, SOLID, plan review). Spawning an agent for
  a generic question wastes context and time.
- `/code-review` covers generic correctness. The `code-reviewer`
  agent is for deeper spec-compliance work — overlap is fine, but
  pick one per task.
- `/security-review` and `security-reviewer` are complementary: the
  built-in is fast and surfaces the obvious; the agent is for a real
  threat-modeling read on auth / user-input / crypto paths.
