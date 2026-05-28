## settings.json hygiene

When the task is about Claude Code harness configuration —
permissions, env vars, hooks, allow/deny lists — use the bundled
skills, don't hand-edit `~/.claude/settings.json` from memory.

- **`/update-config`** — for any change to `settings.json` /
  `settings.local.json`: permissions ("allow X", "move permission
  to user settings"), env vars, hooks, model selection. Also for
  automated behaviors ("from now on when X, do Y") that need a hook
  rather than memory or preferences — the harness executes hooks,
  not Claude.
- **`/fewer-permission-prompts`** — scans your recent transcripts
  for read-only Bash / MCP calls that keep prompting for permission,
  and proposes a prioritized allowlist to add to project
  `.claude/settings.json`. Run when permission prompts become
  noticeable friction in a session.

Anti-pattern: drafting a settings.json snippet from scratch when one
of these skills already encodes the schema. Settings drift comes
from hand-edits that miss the surrounding structure.
