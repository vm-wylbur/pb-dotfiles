---
name: changelog
description: Generate narrative changelog organized by themes, not repos
---

<!-- compose: {"modules": ["pb-voice"]} -->

# Changelog

## Purpose

Generate a narrative summary of work since a given date, organized by themes
(challenges overcome, security hardened, capabilities added), written in the
blog voice from `~/docs/pb-voice-guide.md`. Weekly report for colleagues who
care about what problems were solved and what new things the system can do —
not which files changed.

Deterministic data gathering is delegated to `~/.claude/lib/` scripts. The
AI's job is voice, theme selection, and synthesis.

## When to Use

- User invokes `/changelog YYYY-MM-DD`
- User says "write my changelog", "weekly summary", "what did I do this week"

## Arguments

Single argument: start date in `YYYY-MM-DD` format. End date is always today.

## Workflow

### Phase 1: Discover repos

```
bash ~/.claude/lib/gh-author-commits.sh ${DATE}
```

Output: TSV `repo\tsha\tdate\tmessage`. Extract the unique list of repos —
those are the working set.

### Phase 2: Gather per-repo evidence

For each repo, check if a local clone exists at `~/projects/hrdag/{repo_name}`.

**If local clone exists** — collect diffs and version tags:

```
bash ~/.claude/lib/repo-diff-since.sh ~/projects/hrdag/{repo} ${DATE} \
    > /tmp/changelog-diff-{repo}.txt 2>&1

bash ~/.claude/lib/git-version-tags-since.sh ~/projects/hrdag/{repo} ${DATE}
```

`repo-diff-since.sh` is large output (full commits + diffs + stats) — always
redirect to a per-repo file. Read these via the Read tool when synthesizing.
The script ff-pulls if clean, warns and skips pull if dirty (your WIP).

**If no local clone** — skip diffs; use the commit messages from Phase 1.

### Phase 3: Read voice guide (REQUIRED)

Read `~/docs/pb-voice-guide.md` with the Read tool. Not optional — the
changelog's voice comes from this file.

### Phase 4: Gather additional context

```
bash ~/.claude/lib/gh-author-issues.sh ${DATE}
```

Output: TSV `repo#N\tstate\ttitle`. Use to enrich the narrative with
decisions, discussions, and review findings beyond raw commits.

Beyond that, scan the per-repo diff files for:
- Post-mortems / design docs: `docs/*postmortem*`, `*adr*`, `*design*`, `*plan*`
- Performance numbers, error counts, before/after metrics in commit messages
- README / deployment / architecture docs added or rewritten

### Phase 5: Synthesize

**Organize by theme, not by repo.** Repos are evidence; readers care about
stories — problems identified and overcome, what's more secure, what new
capabilities exist, what's ready for the next failure.

```markdown
# Changelog: {DATE} to {TODAY}

{Opening paragraph: one-paragraph thesis naming the overarching arc.
What state were things in at the start? Now? How did it get there?}

## {Theme: e.g., "Scaling the coordination layer"}

{Narrative prose telling the story across whichever repos are involved.
Cite repos and version tags as evidence ("shipped as tfcs v0.12.0").}

## {Theme: e.g., "Closing the unsigned-revoke hole"}
...
```

**Choosing themes:** read all the evidence, identify natural narrative arcs.
Common themes: challenges overcome, security holes closed, failure prep,
new capabilities, documentation brought up to date, infrastructure improvements.
Let the evidence determine the themes — don't force categories that aren't there.

**Changelog-specific rules** (general voice rules live in the pb-voice
module, rendered into the Voice section below):

- Tell stories, not diffs. Commits are evidence for the story.
- Version tags are navigation aids — readers use them to find the work in git history.
- Cross-reference freely when work in one repo enabled or depended on another.
- Scale length to significance, not to commit count.
- Do NOT recite commits. Synthesize.
- Spelling: "DataCívica" (not "Data Civica" or "Datacivica").

### Phase 6: Output

1. Write to `~/docs/changelog-{DATE}-to-{TODAY}.md`
2. Render: `glow ~/docs/changelog-{DATE}-to-{TODAY}.md`
3. Report: "Changelog written to ~/docs/changelog-{DATE}-to-{TODAY}.md"

## Guardrails

- Read-only on repos beyond `git pull --ff-only` (and that's skipped on dirty tree).
- Do NOT push or commit anything.
- If `gh-author-commits.sh` returns nothing, say so and stop.
- The diff files in `/tmp/changelog-diff-*.txt` can be large — read selectively
  with the Read tool's `limit` and `offset`, not all at once.

<!-- BEGIN module:pb-voice -->
<!-- END module:pb-voice -->
