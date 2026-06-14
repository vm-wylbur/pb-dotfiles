---
name: fleet-brief
description: Daily cross-agent fleet brief — what the fleet did, decisions made, and what's blocked on you. Aggregates commits/issues/PRs/memory/qfix/negotiations across all repos into one morning screen so PB stops being the only place fleet state lives. Use when PB types /fleet-brief, asks "what's the fleet doing / what's blocked on me / fleet status", or when the scheduled morning run invokes it.
---

# Fleet brief

## Purpose

PB attends many Claude agents across many repos. He is the only place cross-agent state is aggregated, and that is his scaling limit. This skill produces one scannable morning artifact so he reads a single screen instead of polling N sessions. It is layer 2 of the capture-architecture direction (see the `capture-architecture-direction` memory).

This is a personal ops dashboard, NOT a colleague-facing changelog — terse, scannable, action-oriented. No blog voice, no narrative padding. The `/changelog` skill is the weekly fleet-wide story; this is the daily what-needs-PB cut. They are different artifacts on different cadences.

## When to use

- PB types `/fleet-brief` (optionally `/fleet-brief YYYY-MM-DD` to set the window start).
- PB asks "what's the fleet doing", "what's blocked on me", "fleet status", "morning brief".
- The scheduled local launchd job invokes it headlessly each morning (macOS/porky only — on Linux hosts there is no scheduled run; invoke `/fleet-brief` manually).

Note on the scheduled cadence: the headless run is **negotiation-blind** — print mode does not inherit the claude-negotiate MCP, so scheduled briefs report "negotiations: not checked" with a ⚠ marker. Run `/fleet-brief` interactively (where the MCP is live) to fold in negotiation gates.

## Arguments

Optional single argument: window start date `YYYY-MM-DD`. Default is the last 24h (the gather script's default).

## Workflow

### Phase 0: Gather (deterministic, read-only)

```
bash ~/.claude/lib/fleet-brief-gather.sh ${DATE:+--since $DATE}
```

Returns ONE JSON object: `{since, generated_at, host, commits[], issues[], merged_prs[], recent_memories[], qfix_open[], negotiations, sources{gh, claude_mem}}`. Check `.sources` first — if `gh` is `missing` or `claude_mem` is `unreachable`, say so explicitly in the brief; a dark source is a gap, not a quiet day, and the "blocked on you" section is only as trustworthy as its inputs.

### Phase 1: Add the gate sources the gather can't see

The gather script is GitHub + claude-mem REST only. Two gate sources need adding here:

- **Open PRs across the fleet** (awaiting PB's review/merge): `gh search prs --state=open --author=@me --json repository,number,title,updatedAt --limit 50`. These are the strongest "blocked on you" signal.
- **Negotiations awaiting PB's turn** (MCP-only — invisible to any shell script): call `mcp__claude-negotiate__list_negotiations`, then for any open one `mcp__claude-negotiate__get_status` to see whose turn it is. Surface any awaiting PB or awaiting a cc-dots/peer action that PB gates.

If the negotiate MCP is not connected this session, note "negotiations: not checked (MCP offline)" rather than implying there are none.

### Phase 2: Derive "blocked on you"

This is the load-bearing section. A gate is anything that cannot advance without PB's judgment. From the gathered + Phase-1 data, identify:

- Open PRs awaiting review/merge (Phase 1).
- Open `qfix_open` entries (the IaC drift queue waiting to be drained).
- Negotiations where it is PB's turn (Phase 1).
- Open issues authored by an agent whose body states a success condition that the recent commits/memories suggest is now MET (the agent is waiting on PB to close) — judgment call; mark these "verify + close?" not "done".

For each gate, name three things: **agent / artifact / the single action PB takes**. Example: "cc-dots — PR #14 (fleet-brief 2c) — review & merge". Be honest about scope: in-session commit gates and anything ephemeral are NOT visible to a scheduled run, so this section covers persistent gates only. If nothing is blocked, say "Nothing blocked on you" — do not manufacture gates.

### Phase 3: Compose the three sections

Terse. Bullets over prose. Group, don't recite.

```markdown
# Fleet brief — {TODAY}  (window: {since} → now)

## Blocked on you
- {agent} — {artifact} — {action}
  (or: "Nothing blocked on you.")

## Decisions made ({window})
- {one line each, with repo#N / sha / memory id as a trailing ref}

## What the fleet did
- {theme-grouped one-liners — by agent or by repo cluster, whichever reads cleaner}

{If any source was dark: "⚠ Gaps: {gh missing | claude-mem unreachable | negotiations not checked}"}
```

Ordering is deliberate: **blocked on you first** — it is why PB opens this. Decisions and activity are context below it.

Rules:
- Scale length to what actually happened. A quiet day is three lines, not a forced full template.
- Credit agents by their cc-* identity (from commit trailers, branch names, issue signatures).
- No emojis except the ⚠ gap marker (agent glyphs belong in commit trailers, not here).
- Recent memories are evidence of decisions/lessons — fold them into "Decisions made" where they explain a why; don't list raw memory dumps.

### Phase 4: Output

1. Write to `~/docs/fleet-brief-{TODAY}.md` (TODAY = `date +%Y-%m-%d`).
2. If running interactively, render: `glow ~/docs/fleet-brief-{TODAY}.md`.
3. Report the path. The scheduled run relies on the file; the SessionStart surfacing (if wired) points at it.

## Guardrails

- Read-only everywhere: the gather scripts `fetch origin` but never modify a working tree; this skill does NOT pull, commit, push, or close anything. It REPORTS gates; PB acts on them.
- Scratch and output under `~/docs` and `~/tmp`, never `/tmp` (mac rule).
- A dark source (gh missing / claude-mem unreachable / MCP offline) must be surfaced, never silently treated as "no activity" — the whole value is trustworthy gate detection.
- If the gather returns empty across all sources AND all sources are healthy, say "quiet window, nothing to report" and stop.
