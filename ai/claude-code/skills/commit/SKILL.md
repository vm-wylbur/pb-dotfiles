---
name: commit
description: Git commit workflow with message format enforcement and change review
---

# Commit Workflow Skill

## Purpose
Ensures every git commit follows project standards with proper message format, comprehensive change review, and consistency checks.

## When This Activates
- User says "commit", "let's commit", "should we commit"
- User requests to commit changes
- Keywords: "commit", "git commit", "check in"

## Instructions

### Phase 1: Pre-Commit Review

1. **Check Git Status**
   Run `git status` to see:
   - What files are staged
   - What files are modified but unstaged
   - What files are untracked

2. **Review Staged Changes**
   Run `git diff --cached` to see what will be committed

3. **Verify Scope**
   - Are the right files staged?
   - Should any unstaged files be included?
   - Should any staged files be removed?
   - Are there build artifacts or generated files staged? (usually should not commit)

4. **Common Issues Check**
   Look for:
   - Debug code (console.log, print statements)
   - Commented-out code blocks
   - TODO comments added
   - Hardcoded secrets or API keys
   - Files that should be in .gitignore
   - Unintended whitespace changes

### Phase 2: Commit Message Generation

5. **Analyze Changes**
   Based on git diff, identify:
   - What feature/fix is being added?
   - What problem is being solved?
   - What files/modules are affected?
   - Is this a new feature, bugfix, refactor, or documentation?

6. **Draft Commit Message**

   **Format (MANDATORY):**
   ```
   Brief descriptive title (imperative mood, <50 chars)

   Optional body explaining why/what changed:
   - Use bullet points for multiple changes
   - Explain context and reasoning
   - Reference related issues/docs if relevant
   - Keep lines <72 characters

   By PB & Claude
   ```

   **Title Guidelines:**
   - Start with verb: "Add", "Fix", "Update", "Remove", "Refactor"
   - Be specific but concise
   - Example: "Add JWT authentication to API endpoints"
   - Example: "Fix data recovery error handling for bad sectors"

   **Body Guidelines (optional but recommended for complex changes):**
   - Why: What problem does this solve?
   - What: What are the key changes?
   - How: Any important implementation details?

   **Attribution:**
   - ALWAYS end with "By PB & Claude"
   - NEVER include "Co-authored-by:" lines
   - NEVER include tool attribution or "Generated with Claude Code"

7. **Present Message to User**
   Show the suggested commit message and ask for approval:
   - "Here's the suggested commit message: [message]"
   - "Should I proceed with this commit?"

### Phase 3: Commit Execution

8. **Execute Commit**
   If approved, run:
   ```bash
   git commit -m "$(cat <<'EOF'
   <commit message here>
   EOF
   )"
   ```

9. **Confirm Success**
   Show the commit hash and message

## Commit Message Examples

### Example 1: Feature Addition
```
Add lessons-learned extraction workflow

- Created extract-lessons-learned subproject with slash commands
- Added process-doc and batch-process commands for memory extraction
- Implemented in-file tagging with JSON comment blocks
- Extracted 31 memories from ~/docs markdown files

By PB & Claude
```

### Example 2: Bug Fix
```
Fix USB adapter detection for Sabrent DS12

Changed SCSI translation layer to use dd instead of ddrescue
for buggy Innostor IS611 chips. Prevents device resets and
D-state hangs during recovery operations.

By PB & Claude
```

### Example 3: Refactoring
```
Refactor memory quality analysis into modular agents

Split monolithic analyzer into specialized agents (general-curator,
security-specialist) with consensus-based decision making. Maintains
backward compatibility via feature flag.

By PB & Claude
```

### Example 4: Documentation
```
Add ZFS recordsize decision guide to docs

Documented data-driven approach for choosing recordsize based on
file size distribution and workload characteristics. Includes
decision matrix and real-world examples.

By PB & Claude
```

### Example 5: Simple Fix
```
Fix typo in extraction log

By PB & Claude
```

## Rules

### ✅ Always Do
- Review all staged changes before committing
- Check for debug code and uncommitted secrets
- Use imperative mood in title ("Add" not "Added" or "Adding")
- Keep title under 50 characters
- End with "By PB & Claude"
- Ask user for approval before committing

### ❌ Never Do
- Commit without reviewing git diff --cached
- Include "Co-authored-by:" lines
- Include tool attribution like "Generated with Claude Code"
- Use past tense in title ("Added", "Fixed")
- Commit generated files (unless explicitly requested)
- Skip the user approval step

### ⚠️ Watch For
- src/buildInfo.ts or similar auto-generated files (usually should not commit)
- node_modules/ or vendor/ directories
- .env files with secrets
- Personal configuration files
- Large binary files
- Merge conflict markers

## Common Patterns

### Multi-Part Changes
When changes span multiple areas, use bullet points:
```
Update memory system and add extraction tools

- Reorganize TODO into focused next-steps
- Move curation plan to docs/TODO-curation.md
- Add extract-lessons-learned subproject
- Create commit skill for message enforcement

By PB & Claude
```

### Related to Issue/Ticket
```
Fix cluster chain corruption in FAT recovery (closes #123)

Implemented fatcat merge before fsck.fat to preserve data
during FAT metadata repair. Updated recovery guide with
safety protocols.

By PB & Claude
```

### Breaking Changes
```
BREAKING: Change memory API response format

Changed from flat array to paginated response with metadata.
Clients must update to handle new format.

Migration guide: docs/migration-v2.md

By PB & Claude
```

## Workflow Summary

1. User says "commit" or "let's commit"
2. Run `git status` to see staged files
3. Run `git diff --cached` to review changes
4. Check for common issues (debug code, secrets, etc.)
5. Analyze changes and draft commit message
6. Present message to user and ask for approval
7. If approved, execute commit with proper format
8. Confirm success with commit hash

## Success Criteria

- Every commit has a clear, descriptive title
- Complex changes have explanatory body text
- All commits end with "By PB & Claude"
- No commits contain debug code or secrets
- User approves message before execution
- Commit follows imperative mood convention
