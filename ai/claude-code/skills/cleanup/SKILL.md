---
name: cleanup
description: "Repository cleanup with evidence-based decisions (user)"
version: 1.0.0
metadata:
  priority: medium
  requires: ["claude-mem"]
  changelog: "1.0.0 - Initial skill from command conversion"
---

# Repository Cleanup

Perform comprehensive repository cleanup with evidence-based decisions.

## When to Activate

- User says "cleanup", "clean up repo", "tidy files"
- Working directory has accumulated unstaged/untracked files

## Workflow

Launch the cleanup-analyzer agent to scan unstaged and untracked files, then process categories interactively.

### Phase 1: Analysis (Agent)

Launch cleanup-analyzer agent using the Task tool with subagent_type='general-purpose'.
The agent will return JSON with categorized files and evidence.

### Phase 2: Quick Wins (Interactive)

Present obvious_deletions and markdown files:
- Show evidence for each deletion candidate
- Execute approved deletions immediately
- For .md files not in lessons_learned_docs, offer to run /ingest-docs

### Phase 3: Deduplication (Interactive)

For each duplicate pair:
- Show similarity score and evidence
- Show memory context if available
- Present options: merge/keep both/delete one/skip
- Execute approved action immediately

### Phase 4: Completed Work (Interactive)

For each completed proposal:
- Show implementation evidence
- Present draft memory (content, tags, files)
- Get approval to store memory + archive file
- Execute: store memory, then git mv to docs/completed/

### Phase 5: Should Commit (Interactive)

- Show files ready to commit with evidence
- Get approval and execute git add

### Phase 6: Ambiguous (Interactive)

For each ambiguous file:
- Show evidence and questions
- Ask user: keep/delete/commit/defer
- Execute decision

### Phase 7: Summary

- Show actions taken (counts by type)
- Draft cleanup session memory
- Store memory if approved

## Guardrails

1. Execute actions immediately after approval (don't batch)
2. Show evidence before each decision
3. For .md files, integrate with /ingest-docs workflow
4. Capture completed work and cleanup decisions to memory
5. Use the agent's evidence, don't re-analyze
6. Never delete without explicit approval
