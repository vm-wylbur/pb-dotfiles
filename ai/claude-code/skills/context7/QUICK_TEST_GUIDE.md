# Quick Test Guide - Your Actual Use Cases

After installing the skill, test it with these real scenarios from your workflow:

---

## Test 1: Typer CLI (Should Use Context7)

```bash
claude "Create a Typer CLI with three commands: import, analyze, and export. Load settings from config.yaml"
```

**Expected**: 
- ✓ Skill detects "Typer" + "commands" + "config"
- ✓ Calls resolve-library-id("typer")
- ✓ Fetches docs for command groups and config
- ✓ Generates proper multi-command structure with pydantic config

---

## Test 2: loguru Logging (Should Use Context7)

```bash
claude "Set up loguru with separate log files for INFO and ERROR levels, with daily rotation"
```

**Expected**:
- ✓ Skill detects "loguru" + "separate files" + "rotation"
- ✓ Fetches multi-sink configuration docs
- ✓ Generates proper sink setup with rotation and retention

---

## Test 3: pydantic Version Check (Critical!)

```bash
claude "Create a pydantic model for validating user data with email and age"
```

**Expected**:
- ✓ Skill checks for pydantic version (v1 vs v2)
- ✓ If v2: Uses @field_validator and ConfigDict
- ✓ If v1: Uses @validator and Config class
- ✓ NO mixed v1/v2 syntax!

---

## Test 4: PostgreSQL Bulk Load (Should Use Context7)

```bash
claude "Load a large CSV file into PostgreSQL efficiently using the COPY command"
```

**Expected**:
- ✓ Skill detects "PostgreSQL" + "large" + "COPY"
- ✓ Fetches psycopg COPY documentation
- ✓ Generates COPY-based approach (not INSERT loops)
- ✓ Mentions efficiency benefits

---

## Test 5: scikit-learn (Should Use Context7)

```bash
claude "Create a scikit-learn pipeline with StandardScaler and RandomForestClassifier"
```

**Expected**:
- ✓ Skill detects "scikit-learn" + "pipeline"
- ✓ Fetches current pipeline API docs
- ✓ Uses current estimator patterns
- ✓ Proper fit/transform patterns

---

## Test 6: Algorithm (Should SKIP Context7)

```bash
claude "Implement quicksort in Python"
```

**Expected**:
- ✓ Skill evaluates: No library, just algorithm
- ✓ Does NOT call Context7
- ✓ Fast response from training knowledge
- ✓ Token-efficient

---

## Test 7: Multi-Library Workflow (Should Be Smart)

```bash
claude "Create a Python script that:
1. Loads a CSV with pandas
2. Processes it with numpy
3. Saves to PostgreSQL with psycopg2 COPY
4. Logs everything with loguru
Make it a Typer CLI"
```

**Expected**:
- ✓ Skill detects: Typer, pandas, numpy, psycopg2, loguru
- ✓ Fetches docs ONE AT A TIME as code develops
- ✓ Typer → pandas → numpy → psycopg2 → loguru (sequential)
- ✓ NOT bulk-fetching all five upfront
- ✓ Token-efficient progression

---

## Test 8: pytest (Should Use Context7)

```bash
claude "Write pytest tests with fixtures for database connection"
```

**Expected**:
- ✓ Skill detects "pytest" + "fixtures"
- ✓ Fetches pytest fixture docs
- ✓ Current fixture patterns (not outdated)
- ✓ Proper scope and autouse patterns

---

## Test 9: xgboost (Should Use Context7)

```bash
claude "Train an XGBoost classifier with early stopping"
```

**Expected**:
- ✓ Skill detects "xgboost"
- ✓ Fetches current parameter documentation
- ✓ Version-appropriate early stopping syntax
- ✓ Current best practices

---

## Test 10: Standard Library (Should SKIP Context7)

```bash
claude "How do I read a JSON file in Python?"
```

**Expected**:
- ✓ Skill recognizes: standard library (json module)
- ✓ Does NOT invoke Context7
- ✓ Direct answer from training knowledge
- ✓ Fast and efficient

---

## Red Flags (Things to Watch For)

### ❌ Bad Behavior
1. **Bulk fetching**: Calls Context7 for all libraries upfront (wasteful)
2. **False positives**: Uses Context7 for algorithms or standard library
3. **Version mixing**: Generates pydantic v1 + v2 mixed syntax
4. **Missing opportunities**: Doesn't invoke for Typer/loguru when mentioned
5. **Giving up**: Fails to try alternate names when library not found

### ✓ Good Behavior
1. **Lazy loading**: Fetches docs right before generating related code
2. **Smart skipping**: Recognizes when Context7 not needed
3. **Version-aware**: Checks pydantic version before generating
4. **Proactive**: Invokes when it sees library names, doesn't wait to be asked
5. **Error recovery**: Tries alternate names, falls back gracefully

---

## Quick Verification Commands

After each test, check:

```bash
# Did Context7 get invoked appropriately?
# Look for these in Claude's response:
# - resolve-library-id calls
# - get-library-docs calls
# - Brief mention of "using Context7 docs" or similar

# Token efficiency check:
# - Single library: ~1000 tokens is reasonable
# - Multiple libraries: Should scale linearly (2 libs ≈ 2000 tokens)
# - NOT: 3000+ tokens for simple query
```

---

## Performance Benchmarks

Track these over time:

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Invocation accuracy | 90%+ | True positives / (TP + FP + FN) |
| Token efficiency | <1500/task | Avg tokens for multi-lib tasks |
| Code quality | 95%+ | Current patterns, no deprecated |
| False positives | <10% | Context7 used when not needed |
| False negatives | <5% | Missed library opportunities |

---

## If Things Go Wrong

### Skill Not Loading
```bash
# Check it's in the right place
ls ~/.claude/skills/context7/SKILL.md

# Verify frontmatter
head -5 ~/.claude/skills/context7/SKILL.md
```

### Too Aggressive (Using Context7 Too Much)
Edit SKILL.md:
- Strengthen "When NOT to Use" section
- Add more explicit standard library exclusions
- Raise invocation threshold

### Too Conservative (Missing Opportunities)
Edit SKILL.md:
- Add more library name patterns
- Lower invocation threshold
- Add implicit library detection patterns

### Wrong Version Generated (esp. pydantic)
Check SKILL.md has strong version-checking language:
```markdown
### Data validation with pydantic
- CRITICAL: pydantic 1.x vs 2.x has massive breaking changes
- Always check version before generating pydantic code
```

---

## Success Indicators

You'll know the skill is working well when:

1. **Typer code** uses current command groups and config patterns
2. **loguru setup** has proper multi-sink configuration
3. **pydantic models** use correct v1 OR v2 syntax (never mixed!)
4. **PostgreSQL loads** use COPY command for bulk operations
5. **scikit-learn/xgboost** use current API patterns
6. **Algorithm questions** answered fast without Context7
7. **Multi-library tasks** fetch docs sequentially, not all at once
8. **Token usage** is reasonable (~1000/library, not 3000+)

---

## Ready to Test?

```bash
# Install first
cd context7-skill
./install.sh

# Then run tests above
claude "Create a Typer CLI with YAML config and loguru logging"
claude "Build a pydantic v2 model for data validation"
claude "Load CSV into PostgreSQL with COPY command"

# Watch for Context7 invocations and quality of generated code
```

Good luck! The skill should make Claude Code much smarter about when and how to use Context7 for your actual workflow.
