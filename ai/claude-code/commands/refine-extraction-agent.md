Analyze recent extraction decisions and propose refinements to the extract-insights agent.

This command implements the meta-learning loop: analyze patterns in user decisions
to iteratively improve the extract-insights agent's guidelines.

## Workflow:

**Step 1: Retrieve Recent Decisions**
Query extraction_decisions table for last N documents (default: 10, min: 5):
```sql
SELECT
  doc_filename,
  insight_number,
  insight_content,
  insight_tags,
  action,
  edited_content,
  skip_reason,
  timestamp
FROM extraction_decisions
ORDER BY timestamp DESC
LIMIT 100  -- Gets roughly 10-15 docs worth
```

**Step 2: Launch Meta-Analysis Agent**
Use Task tool with subagent_type='general-purpose' to launch agent with this prompt:

```
Analyze these extraction decisions to find patterns and propose agent refinements.

Decision Log:
[paste query results]

Your task:
1. Identify patterns:
   - Which types of insights get skipped? (look at skip_reason, content patterns)
   - Which insights get edited? (compare insight_content vs edited_content)
   - What strengthening language appears in edits? (e.g., "anti-pattern", "don't")
   - Are certain tags/topics consistently approved or skipped?

2. Propose guideline updates for extract-insights agent:
   - Add new guidelines if pattern is strong (>60% of similar cases)
   - Strengthen existing guidelines if user reinforces them
   - Flag potential conflicts (user approved X but later skipped similar Y)

3. Return JSON:
{
  "patterns_found": [
    {
      "pattern": "description",
      "evidence_count": N,
      "strength": "strong|moderate|weak",
      "proposed_action": "what to change in agent guidelines"
    }
  ],
  "proposed_guidelines": [
    {
      "guideline_text": "new or updated guideline",
      "rationale": "why this improves extraction"
    }
  ],
  "conflicts_detected": [
    {
      "description": "describe conflicting decisions",
      "recommendation": "ask user to clarify"
    }
  ]
}
```

**Step 3: Present Findings to User**
Show patterns found with evidence counts.
For each proposed guideline:
- Show current guideline (if updating)
- Show proposed new text
- Ask: Approve/Edit/Reject

**Step 4: Update Agent Guidelines**
If user approves changes:
- Read ~/.claude/agents/extract-insights.md
- Apply approved guideline updates
- Write updated file
- Show diff of changes
- Confirm with user before writing

**Step 5: Summary**
Report:
- Number of decisions analyzed
- Patterns found (approved count)
- Guidelines updated (count)
- Next analysis recommended after N more docs

## Parameters:

- `min_docs`: Minimum documents to analyze (default: 10)
- `force`: Skip "not enough data" check and analyze anyway

## Example:

```
Analyzing last 85 extraction decisions (from 12 documents)...

Patterns found:
1. [STRONG] Skipped 8 insights marked "superseded by newer approach"
   → Propose: Add recency check guideline

2. [MODERATE] Edited 5 insights to remove hedging ("may" → "don't")
   → Propose: Strengthen "strong opinions" guideline

3. [WEAK] Approved all insights with version numbers (15/15)
   → Note: Continue emphasizing version specificity

Conflicts detected:
None

Proposed guideline updates:
1. Add: "Check document date. Flag pre-2024 techniques as potentially superseded."
2. Update: "Use direct, unhedged language..." → "Use direct, imperative language. Write 'don't do X' not 'avoid X' or 'consider not doing X'."

Apply these updates? [y/e/n]
```

## Critical Rules:

1. Need at least 5 docs worth of decisions (35-50 decisions minimum)
2. Pattern strength based on evidence: strong >60%, moderate 40-60%, weak <40%
3. Show user the evidence (decision excerpts) for each pattern
4. Never auto-apply guidelines - always get user approval
5. Keep audit trail: log which patterns led to which guideline changes

Execute analysis now.
