Extract insights from lessons-learned markdown documents interactively.

Launch the extract-insights agent to analyze a document and propose insights for approval.

## Workflow:

**Step 1: Select Document**
Ask user which document to extract from:
- Show recent docs from lessons_learned_docs (last 10)
- Or let user specify filename/topic
- Retrieve full document content from database

**Step 2: Launch Agent**
Use Task tool with subagent_type='general-purpose' to launch extract-insights agent.
Pass document content, filename, filepath, and metadata.

**Step 3: Review Insights**
Agent returns 3-7 proposed insights in JSON format.
For each insight:
- Show content, type, tags
- Show rationale (why this is valuable)
- Ask: Approve/Edit/Skip/Stop
  - Approve: Store with mcp__claude-mem__store-dev-memory, log decision
  - Edit: Let user modify content/tags/type, then store, log decision with edited_content
  - Skip: Move to next insight, log decision (optionally ask for skip reason if unclear from context)
  - Stop: End extraction session

**Step 4: Store Approved Insights**
For each approved insight:
- Store using store-dev-memory with source_doc_id linking to document
- Show stored memory ID
- Track count of approved vs skipped

**Step 5: Summary**
- Show total insights: approved/edited/skipped
- Offer to extract from another document

## Example Interaction:

```
Which document to extract insights from?

Recent documents:
1. zfs-performance.md (2025-11-15, 1523 words)
2. backup-strategy.md (2025-11-10, 892 words)
3. disk-failure-saga.md (2025-11-08, 2341 words)

Enter number or search term: 1

Launching agent to analyze zfs-performance.md...

[Agent returns 5 insights]

Insight 1/5:
Content: "ZFS recordsize tuning for backup workloads: Use recordsize=1M
         for large sequential writes..."
Type: code
Tags: zfs, performance, backup, tuning
Rationale: Anyone tuning ZFS for backup performance would want this specific setting

Approve this insight? [y/e/n/s=stop] y
✓ Stored as memory a4f8c2d1 (linked to zfs-performance.md)

Insight 2/5:
[...]
```

## Critical Rules:

1. Always link insights to source doc via source_doc_id
2. Show rationale so user understands why agent extracted this
3. Allow editing before storage (fix tags, refine content)
4. Track and report approval rate (helps tune agent prompts)
5. **LOG EVERY DECISION**: After each y/e/n action, use mcp__postgres-mcp__execute_sql to INSERT into extraction_decisions table with:
   - doc_id, doc_filename from current document
   - insight_number (1-7 position in batch)
   - insight_title, insight_content, insight_tags from agent output
   - action: 'approved', 'edited', or 'skipped'
   - edited_content: if edited, the new version
   - skip_reason: infer from context (e.g., "superseded", "duplicative") or NULL
   - stored_memory_id: the memory ID returned from store-dev-memory (if approved/edited)

Launch the workflow now - ask which document to extract from.
