---
name: handoff
description: Save durable session state for the next session — where things stand, decisions made, open threads, gotchas. Use when the user types /handoff or asks to "save state", "hand off", "save where we are for next time", or to record session progress before wrapping up. Writes to the project's file-based memory, not a chat summary.
---

# Handoff — save session state for the next session

Record what the *next* session needs to resume cleanly. This writes to the
file-based project memory (the directory `MEMORY.md` lives in for this
project), which the harness recalls at session start. It is not a
conversational summary.

## What to capture (judgment, not a dump)

Persist only what won't be obvious from the code, git history, or CLAUDE.md:

- **Where things stand** — the current state of the work in flight.
- **Decisions made this session** — and the *why*, especially ones that
  closed off alternatives.
- **Open threads / next steps** — what you'd pick up first next time.
- **Gotchas** — non-obvious constraints, dead ends, or harness/tool
  behavior learned the hard way.

Skip anything re-derivable from the repo, transient chatter, or details
that only mattered inside this conversation.

## How to write it

1. Find the project memory dir — where this project's `MEMORY.md` lives
   (e.g. `~/.claude/projects/<slug>/memory/`). Do NOT guess the slug; it
   is the same dir the session-start recalled memories came from.
2. **Update an existing memory file** if one already covers this work
   (check the `MEMORY.md` index first) — don't create a near-duplicate.
   Otherwise create one file per fact with the standard frontmatter
   (`name`, `description`, `metadata.type` = project / feedback /
   reference). Follow feedback/project bodies with **Why:** / **How to
   apply:** per the memory convention.
3. Convert relative dates to absolute. Link related memories with
   `[[name]]`.
4. Add or refresh the one-line pointer in `MEMORY.md`
   (`- [Title](file.md) — hook`).
5. Report back: which files you wrote or updated, and a one-line gist of
   each.

## Relationship to the Stop-hook offer

`hooks/stop-session-offers.sh` nudges this once per substantive session.
That nudge is a backstop and fires mid-session (the harness has no true
"session end" signal); running `/handoff` deliberately at the real end of
your work gives the cleanest state. If there is nothing material to save,
say so and skip — an empty handoff is worse than none.
