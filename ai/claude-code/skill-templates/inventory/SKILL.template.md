---
name: inventory
description: List installed skills, agents, modules, hooks, MCP servers, and built-in slash commands. Two-column cheat sheet of the live AI environment. Trigger when the user asks "what skills/agents do I have", "what's installed", "show inventory", or wants to discover available capabilities.
---

# Inventory

## Purpose

A scannable cheat sheet of what's available in this Claude Code
environment — every user-facing surface in one ~70-line view. Reads
live state on each invocation; no caching.

## When to use

- User asks "what skills/agents do I have?", "what's installed?",
  "show inventory", "what can I run?"
- Session start, when re-orienting after a long break
- Before recommending a tool, to confirm it's actually installed

## Recipe

```
bash ~/.claude/lib/inventory.sh
```

That's it. The lib script reads:

- `~/.claude/skills/*/SKILL.md` — user-installed skills (frontmatter `description`)
- `~/.claude/agents/*.md` — subagents (frontmatter `description`)
- `~/dotfiles/ai/modules/README.md` — module catalog table
- `~/.claude/settings.json` — hook registrations
- `claude mcp list` — live MCP server status
- A curated list of built-in slash commands (hard-coded in the script)

## Output shape

Six sections, each with a section count in brackets:

```
== Claude Code inventory ==                    YYYY-MM-DD

SKILLS (~/.claude/skills) [N]
  <name>           <description>

AGENTS (~/.claude/agents) [N]
  <name>           <description>

BUILT-IN SLASH COMMANDS (curated)
  /<cmd>           <description>

HOOKS (~/.claude/settings.json) [N]
  <event>:<matcher>  <hook names>

MCP SERVERS (claude mcp list) [N]
  ✓ <name>         <transport>
  ! <name>         needs authentication

CLAUDE.md MODULES (~/dotfiles/ai/modules) [N]
  <id>             <use-when phrase>
```

## Notes

- A blank description for a module means it's missing from
  `ai/modules/README.md` — surface that to the user as a small gap.
- The built-in slash command list is curated and may go stale when
  Claude Code adds/removes commands. Refresh when noticed.
- The script is idempotent and silent on no-data per section
  (e.g., if `~/.claude/agents/` is empty, the AGENTS block is empty
  but the header still prints with `[0]`).
