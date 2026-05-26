## /goal — session anchor

`/goal` is a Claude Code built-in. It captures a one-line goal for the
current session and reminds you of it on Stop. **Session-scoped only**
— it does not persist across sessions. (The `ultragoal` plugin from
`oh-my-claudecode` would have persisted goals, but omc is deprecated in
this setup.)

**When to invoke:**

- Any non-trivial multi-step task.
- Any session expected to run longer than ~30 minutes.
- Any task where it would be embarrassing to finish having done
  something adjacent to what was asked.

**When NOT to invoke:**

- Single edits, obvious fixes, one-shot questions. Overhead without
  benefit.
- Exploratory sessions with no fixed target.

**Goal condition format** — verifiable, atomic, single line:

> [feature/fix] is done when [observable check] passes.

Examples:
- "B3 is done when `claude-md check-tree` is clean and `~/.claude/CLAUDE.md`
  contains the three new modules."
- "auth-rewrite is done when `pytest tests/auth/` is green and the legacy
  session-token code is deleted."

Anti-pattern: vague goals ("clean up auth"), multi-clause goals
("refactor X AND add Y AND document Z" — that's three goals), or
goals without a check ("make it better").

**Composition with `TaskCreate`:**

- `/goal` = session anchor. What "done" means. Set once, referenced at
  Stop.
- `TaskCreate` = in-session checkpoint ledger. Where you are right now.
  Updated continuously.

Use both for a non-trivial task. The goal tells you when to stop; the
task list tells you what to do next.
