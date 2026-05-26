## Code review with /code-review

`/code-review` is a built-in Claude Code skill. It reviews the current
diff for correctness bugs at a configurable effort level. **Do not
reinvent it.** Do not write a "review the diff" skill or agent for
generic correctness review; use the built-in.

**Effort levels:**

| Level | Use for | Output character |
|---|---|---|
| `low` | Trivial fix, single-line change | Tight; only high-confidence findings |
| `medium` | Standard bugfix, small feature | Default; high-confidence findings, modest breadth |
| `high` | Contract-touching change, public API edit, security-adjacent diff | Broader coverage; may include uncertain findings worth a human glance |
| `max` | Major refactor, structural change, anything you want a thorough pass on | Widest coverage; most likely to surface uncertain findings |

**`--comment` flag:** when reviewing a GitHub PR and you want findings
posted as inline review comments (instead of summarized in the session),
add `--comment`. Reserve this for `high`/`max` runs on contract-touching
PRs — comment noise on `low`/`medium` reviews wastes reviewer time.

**Routing rule:** the built-in `/code-review` covers generic
correctness. For specialized lenses, spawn the dedicated agents
instead:

- threat model / OWASP read → `security-reviewer`
- logic / SOLID / anti-patterns → `quality-reviewer`
- pre-implementation plan review → `critic`

`/code-review` and these agents are complementary, not redundant —
they answer different questions on different objects.
