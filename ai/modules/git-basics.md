## Git workflow

- **Never commit without asking** "Should we commit this?"
- Use `git mv`, NOT bash `mv` — preserves history.
- Use `git rm`, NOT bash `rm` — tracks deletions.
- Commit format: brief title, then `By PB & {claude-id} {emoji}` trailer
  (e.g. `By PB & cc-sysadmin 🔧`). Single trailer line, no `Co-authored-by`.
- **No emojis in commit title or body.** The emoji belongs only in the
  agent-id trailer line — it is part of the agent's identity mark.
- Multi-agent attribution (cross-repo author + reviewer) lives in the PR
  body, not the commit trailer.
