<!--
Author: PB and Claude
Date: 2025-11-16
License: (c) HRDAG, 2025, GPL-2 or newer

------
.claude/commands/cleanup.md
-->

# Repository Cleanup Analysis

Perform comprehensive analysis of unstaged and untracked files to determine their fate.

## Your Task

Analyze all unstaged changes and untracked files in the repository, then categorize each file with specific recommendations for action.

## Analysis Process

### Step 1: Inventory Files
- Run `git status --short` to find all unstaged/untracked files
- List modified unstaged files with `git diff --name-only`
- List untracked files with `git ls-files --others --exclude-standard`

### Step 2: Deep Analysis Per File

For EACH file, investigate:

#### A. Git History (MANDATORY - check this first)
```bash
# Was this file ever committed?
git log --all -- <file>

# When last modified in repo?
git log -1 --format="%ai %h %s" -- <file>

# Find renames/moves
git log --follow --all -- <file>

# Find similar files (same basename)
git log --all --full-history -- "*$(basename <file>)"
```

**Decision factors:**
- Never committed → experimental, evaluate need
- Not updated in months → possibly superseded
- Has rename history → understand evolution
- Recently active → probably should stage

#### B. Content Analysis (use code-explore skill)

**For code files (.py, .sh, .js, etc.):**
1. Extract function/class signatures
2. Use code-explore to search for:
   - Same function names elsewhere
   - Similar implementations
   - Duplicate logic patterns
3. Determine: refactor? duplicate? replacement? new?

**For documentation (.md files):**
1. Extract key topics/headers
2. Search docs/ for same topics
3. Check overlap with README, existing docs
4. Determine: merge? supersedes? new content?

#### C. Reference Analysis (is it used?)

```bash
# For code - is it imported/sourced?
grep -r "import.*$(basename <file> .py)" . 2>/dev/null
grep -r "source.*<file>" . 2>/dev/null

# For docs - is it linked?
grep -r "$(basename <file>)" docs/ README.md 2>/dev/null
```

**Decision factors:**
- Referenced → likely should commit
- Not referenced but complete → orphaned, evaluate
- Not referenced and partial → experimental WIP

#### D. Completion Analysis

**For planning/proposal docs:**
1. Extract goals/tasks from document
2. Search commits for implementation: `git log --all --grep="<topic>"`
3. Use code-explore to verify features exist
4. Classify:
   - Implemented → archive to docs/completed/ with commit refs
   - Partial → move to docs/partial/ with status
   - Not started → keep or delete if obsolete

**For code:**
1. Check for TODOs/FIXMEs
2. Check git history for related commits
3. Basic syntax validation if possible
4. Classify:
   - Complete and working → should commit
   - Partial → document WIP status
   - Broken/abandoned → rm or archive

### Step 3: Pattern-Based Heuristics

**Filename patterns:**
- `*-old.*, *-backup.*, *-tmp.*` → probably rm
- `*-new.*, *-v2.*` → check if supersedes previous version
- `draft-*, wip-*, experimental-*` → move to docs/partial/
- `test-*, debug-*, benchmark-*` → evaluate if still needed

**Age check:**
```bash
# Files not modified in >90 days (exclude .git)
find . -type f -mtime +90 -not -path './.git/*'
```

### Step 4: Cross-Reference Recent Commits

```bash
# What was committed recently?
git log --since="1 month ago" --name-only --pretty=format: | sort -u
```
Check if unstaged file has committed counterpart.

## Output Format

Generate a detailed markdown report with these sections:

```markdown
# Repository Cleanup Analysis
Generated: YYYY-MM-DD HH:MM

## Summary
- X unstaged files analyzed
- Y untracked files analyzed
- Z total recommendations

---

## SUPERSEDED (recommend: rm)

### filename.ext
- **Replaced by:** path/to/new/file (commit: abc123)
- **Last commit:** 2025-09-10 (2 months ago)
- **Git history:** 5 commits, not touched since Sep
- **References:** Not found in codebase
- **Evidence:** [show relevant git log output]
- **Action:** `rm filename.ext`

---

## DUPLICATIVE CODE (recommend: merge or dedupe)

### file1.py vs file2.py
- **Overlap:** 80% identical functionality
- **Differences:** file2 has better error handling
- **Functions duplicated:** parse_input(), validate_data()
- **Evidence:** [show function signatures from both]
- **Recommendation:** Merge improvements from file2 into file1
- **Action:**
  ```bash
  # Review diff first
  diff -u file1.py file2.py
  # Then merge manually and rm file2.py
  ```

---

## DUPLICATIVE DOCS (recommend: consolidate)

### doc1.md + doc2.md
- **Overlap:** 60% similar content
- **doc1 unique:** Section on X
- **doc2 unique:** Section on Y
- **More complete:** doc2.md
- **Action:** Merge doc1 unique sections into doc2, then `rm doc1.md`

---

## COMPLETED (recommend: archive to docs/completed/)

### proposal-feature-x.md
- **Implemented in commits:** abc123, def456, ghi789
- **Code location:** bin/feature-x.py matches proposal
- **Evidence:** [show relevant commits]
- **Action:**
  ```bash
  # Add implementation references to file first
  echo "## Implementation\n- Commit abc123: Initial\n- Commit def456: Core\n- Commit ghi789: Tests" >> proposal-feature-x.md
  git mv proposal-feature-x.md docs/completed/
  git commit -m "Archive completed proposal: feature-x"
  ```

---

## WORK IN PROGRESS (recommend: document or move to docs/partial/)

### draft-new-feature.md
- **Status:** No implementation found
- **Relevance:** Mentioned in recent commit messages
- **Recommendation:** Move to docs/partial/ with WIP status
- **Action:** `git mv draft-new-feature.md docs/partial/`

---

## SHOULD COMMIT (recommend: git add)

### useful-script.sh
- **Status:** Complete implementation
- **References:** Called by bin/main-workflow.sh (line 42)
- **Duplicates:** None found
- **Git history:** Never committed (new file)
- **Action:** `git add useful-script.sh`

---

## EXPERIMENTAL (ask user - evaluate need)

### test-performance.py
- **Created:** 3 days ago
- **References:** None found
- **Status:** Has TODOs, incomplete
- **Question:** Still needed for testing? One-off analysis?

---

## Recommended Actions (prioritized)

1. **Remove superseded files** (safe - not referenced)
   - `rm file1 file2 file3`

2. **Archive completed docs** (preserves history)
   - `git mv docs/proposal-x.md docs/completed/`

3. **Merge duplicates** (requires review)
   - Review each diff, merge manually

4. **Stage ready files** (should commit)
   - `git add file1 file2`

5. **Organize WIP** (cleanup workspace)
   - `git mv draft-*.md docs/partial/`

6. **Evaluate experiments** (ask user)
   - Present list, ask per file

---

Which category would you like to act on first?
```

## CRITICAL RULES

1. **ALWAYS check git history** before recommending deletion
2. **ALWAYS use code-explore** to find duplicate functionality
3. **NEVER delete files** without showing git history evidence
4. **For each recommendation**, explain WHY with concrete evidence
5. **Show actual commands** user should run
6. **Prioritize by safety**: superseded → archive → merge → commit → experimental

## After Analysis

Ask the user which category they want to act on first, or if they want to proceed with all safe actions (rm superseded, archive completed).
