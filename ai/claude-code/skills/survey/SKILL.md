---
name: survey
description: Understand a project, find todos, assess doc staleness, prioritize work
---

# Project Survey

## Purpose

Understand what a project does, find outstanding work, assess documentation freshness, and return a prioritized todo list. Run this when starting work on a repo.

## When to Use

- User says "survey", "what needs doing", "catch me up"
- First time working in a project this session
- User wants to prioritize work

## Prerequisites

- Must be in a git repo (if not, say so and stop)
- **Run `git pull` before anything else.** Survey must reflect current remote state,
  not stale local state. If pull fails, note it and proceed but flag all findings as
  potentially stale.

## Workflow

### Phase 1: Understand the Project

1. Read project context files (in order, skip if missing):
   - `CLAUDE.md` (project-specific instructions)
   - `README.md`
   - `AGENTS.md`
   - `TODAY.md`, `FIXME.md`

2. Understand project structure:
   - Use tree-sitter `analyze_project` if available
   - Fallback: `ls` top-level, read key config files (package.json, pyproject.toml, Makefile, etc.)
   - Identify: language, build system, test framework, deployment method

3. Summarize in 3-5 sentences: what this project is, what it does, how it's built.

### Phase 2: Gather Outstanding Work

4. GitHub Issues (if `gh` CLI available):
   - `gh issue list --limit 20 --state open`
   - Note labels, assignees, staleness

5. Scan for TODO/task documents:
   - Project root: `TODO.md`, `FIXME.md`, `ROADMAP.md`, `CHANGELOG.md`
   - `docs/` directory: all `.md` files
   - In-code TODOs: `grep -r 'TODO\|FIXME\|HACK\|XXX' --include='*.py' --include='*.js' --include='*.ts' --include='*.sh' -c` (counts only)

6. Check claude-mem for project context:
   - Search claude-mem for this project name
   - Note any stored decisions or patterns

### Phase 3: Assess Staleness

7. For each TODO/doc found:
   - Is it still relevant? (grep for referenced files/functions — do they exist?)
   - Is it completed? (does the codebase already implement what's described?)
   - Is it superseded? (does a newer doc cover the same ground?)
   - Last modified date vs last commit date

8. **Git log check (mandatory for any item marked "pending" or "blocked"):**
   For each pending item that references a path, role, or dependency, run:
   ```
   git log --oneline -20 -- <relevant path>
   ```
   Examples:
   - Ansible role item → `git log --oneline -20 -- roles/tfcs/`
   - Source item → `git log --oneline -20 -- src/<module>/`
   - Config item → `git log --oneline -20 -- inventory/`

   Scan the output for: `closes #N`, `fixes #N`, `deploys`, `merged`, `enable`, `re-enable`.
   If found in the last 20 commits: reclassify as **Completed** or **Verify** — NOT Active.
   **Do not report a TODO as "pending" or "blocked" if git log shows it was recently closed.**

9. Categorize each item:
   - **Active**: still relevant, not done — confirmed by git log showing no close commit
   - **Completed**: git log or codebase shows this is done; doc should be archived/removed
   - **Superseded**: newer doc exists, this one is stale
   - **Unknown**: can't determine, flag for user

### Phase 4: Recommend Doc Cleanup

9. For completed/superseded docs:
   - Suggest: remove, archive to `docs/completed/`, or merge into another doc
   - Show evidence (what file/function proves completion)

### Phase 5: Prioritized Todo List

10. Return a single prioritized list:
    - **Doc cleanup first** (low-risk, high-value tidying)
    - Then active todos grouped by source (issues, docs, in-code)
    - Note dependencies between items if obvious
    - Format:

```
## Project: <name>
<3-5 sentence summary>

## Doc Cleanup (do first)
1. Remove TODO.md items 3,5,7 — implemented in src/foo.py
2. Archive docs/old-plan.md — superseded by docs/v2-plan.md

## Outstanding Work
### From GitHub Issues
- #42: <title> (P1, stale 30d)
- #38: <title> (P2)

### From Docs
- ROADMAP.md item 2: <description>

### In-Code
- 12 TODOs across 5 files (highest: src/core.py with 4)
```

## Guardrails

- Read-only: do NOT modify any files during survey
- If codebase is large (>500 files), use tree-sitter compression or sample key directories
- If `gh` fails (no remote, no auth), skip issues and note it
- If claude-mem unavailable, skip memory search and note it
- Time budget: aim for 30 seconds, not 5 minutes
