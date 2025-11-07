# Context7 Skill Testing & Validation Guide

This guide helps you verify the Context7 skill is working correctly and provides troubleshooting steps.

---

## Pre-flight Checks

Before testing the skill, verify prerequisites:

### 1. Context7 MCP Server Installed
```bash
# Check MCP installation
claude mcp list | grep context7

# Should show something like:
# context7 (user) - npx -y @upstash/context7-mcp
```

If not installed:
```bash
claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp
```

### 2. Skill Files Present
```bash
# Check skill structure
ls -la ~/.claude/skills/context7/

# Should show:
# SKILL.md (required)
# README.md (optional)
# QUICK_REFERENCE.md (optional)
# EXAMPLES.md (optional)
```

### 3. SKILL.md Frontmatter Valid
```bash
head -5 ~/.claude/skills/context7/SKILL.md

# Should show:
# ---
# name: context7
# description: Intelligent usage of Context7 MCP...
# ---
```

---

## Test Suite

### Test 1: Skill Recognition (Positive Case)

**Objective**: Verify skill activates when library is mentioned

**Test command**:
```bash
claude "Set up FastAPI authentication with JWT tokens"
```

**Expected behavior**:
1. Skill should activate (Claude recognizes "FastAPI")
2. Claude should call `resolve-library-id("fastapi")`
3. Claude should call `get-library-docs()` with auth-related query
4. Generated code uses current FastAPI auth patterns

**Validation checklist**:
- [ ] No manual prompt needed (skill auto-activates)
- [ ] Context7 tools invoked appropriately
- [ ] Code uses current patterns (not outdated training data)
- [ ] Brief mention of using Context7 docs

**If it fails**:
- Check skill is in correct location
- Verify SKILL.md frontmatter is valid
- Ensure Context7 MCP server is running
- Try explicit: "Use the context7 skill for this"

---

### Test 2: Skill Recognition (Negative Case)

**Objective**: Verify skill doesn't activate for non-library work

**Test command**:
```bash
claude "Explain the bubble sort algorithm"
```

**Expected behavior**:
1. Skill might load to evaluate request
2. Skill determines NO library involved
3. Claude does NOT invoke Context7 tools
4. Claude answers directly from training knowledge

**Validation checklist**:
- [ ] No Context7 tool calls made
- [ ] Fast response (no unnecessary delays)
- [ ] Correct algorithmic explanation
- [ ] Token-efficient (no wasted calls)

**If it fails**:
- Skill may be too aggressive
- Check SKILL.md "When NOT to Use" section
- May need to refine trigger conditions

---

### Test 3: Multiple Libraries (Token Efficiency)

**Objective**: Verify lazy, sequential fetching

**Test command**:
```bash
claude "Create a FastAPI endpoint with PostgreSQL and Redis caching"
```

**Expected behavior**:
1. Skill recognizes THREE libraries
2. Docs fetched ONE AT A TIME as needed (not bulk)
3. FastAPI → fetch when setting up endpoint structure
4. PostgreSQL → fetch when writing query code
5. Redis → fetch when implementing cache logic

**Validation checklist**:
- [ ] Three separate Context7 tool calls (not one bulk call)
- [ ] Calls happen sequentially as code develops
- [ ] Each call has specific query (not generic)
- [ ] Token-efficient progression

**If it fails**:
- May be bulk-fetching (wasteful)
- Check "Token Efficiency Strategies" in SKILL.md
- May need to emphasize lazy loading

---

### Test 4: Version Awareness

**Objective**: Verify version-specific behavior

**Setup**: Create test files
```bash
# Test with pandas 2.x feature
echo "pandas>=2.0.0" > /tmp/test-requirements.txt
```

**Test command**:
```bash
claude "Read this requirements.txt and show me how to use nullable integers in pandas"
```

**Expected behavior**:
1. Claude reads requirements.txt first
2. Sees pandas 2.x
3. Fetches pandas 2.x specific docs
4. Shows nullable integer types (Int64, pd.NA)

**Validation checklist**:
- [ ] Checks version BEFORE fetching docs
- [ ] Uses version-appropriate patterns
- [ ] Mentions nullable integers (pandas 2.x feature)
- [ ] Doesn't suggest float workaround (pandas 1.x approach)

**If it fails**:
- Skill may not be checking versions first
- Review "Version awareness" in SKILL.md
- May need more emphasis on version checking

---

### Test 5: Error Recovery

**Objective**: Verify intelligent retry with alternate names

**Test command**:
```bash
claude "Use React Query for data fetching in Next.js"
```

**Expected behavior**:
1. Try: resolve-library-id("React Query")
2. Fails (old name)
3. Skill guides retry with "Tanstack Query"
4. Try: resolve-library-id("tanstack-query")
5. Success! Generate current code

**Validation checklist**:
- [ ] Doesn't give up after first failure
- [ ] Tries alternate/current name
- [ ] Eventually finds correct library
- [ ] Generates current Tanstack Query v5 code

**If it fails**:
- Error recovery patterns may be weak
- Check "Error Recovery Patterns" in SKILL.md
- May need more alternate name examples

---

### Test 6: Integration with Other Skills

**Objective**: Verify skill plays nicely with document skills

**Test command**:
```bash
claude "Create a Python script that generates an Excel report with pandas, then explain the code in a .docx file"
```

**Expected behavior**:
1. Context7 skill for pandas patterns
2. xlsx skill for Excel generation
3. docx skill for documentation
4. All three coordinate smoothly

**Validation checklist**:
- [ ] Multiple skills load as needed
- [ ] No conflicts between skills
- [ ] Context7 used for pandas specifics
- [ ] Document skills used for file formats
- [ ] Complete solution with all parts

**If it fails**:
- Skills may be conflicting
- Check "Integration with Other Skills" in SKILL.md
- May need clearer boundaries

---

### Test 7: HRDAG-Specific Workflow

**Objective**: Verify skill handles HRDAG-scale patterns

**Test command**:
```bash
claude "Load a 10GB CSV into PostgreSQL efficiently using psycopg2 COPY command"
```

**Expected behavior**:
1. Recognizes "large file" + "efficiently"
2. Fetches psycopg2 COPY documentation
3. Generates COPY-based approach (not INSERT loops)
4. Mentions bulk loading benefits

**Validation checklist**:
- [ ] Uses COPY command (not row-by-row INSERT)
- [ ] Mentions efficiency/scale considerations
- [ ] Appropriate for large data volumes
- [ ] HRDAG-relevant approach

**If it fails**:
- May default to naive approaches
- Check "HRDAG-Specific Patterns" in SKILL.md
- May need more emphasis on bulk operations

---

## Debugging & Troubleshooting

### Skill Not Loading

**Symptoms**: Context7 not being used even when appropriate

**Diagnosis**:
```bash
# 1. Verify skill file exists
ls ~/.claude/skills/context7/SKILL.md

# 2. Check frontmatter
head -10 ~/.claude/skills/context7/SKILL.md

# 3. Validate YAML frontmatter
python3 << 'EOF'
import yaml
with open('/Users/your-username/.claude/skills/context7/SKILL.md') as f:
    content = f.read()
    # Extract frontmatter
    if content.startswith('---'):
        parts = content.split('---', 2)
        frontmatter = yaml.safe_load(parts[1])
        print("Frontmatter valid:", frontmatter)
EOF
```

**Solutions**:
1. Ensure proper YAML frontmatter format
2. Check file permissions (should be readable)
3. Restart Claude Code if recently installed

---

### Skill Too Aggressive

**Symptoms**: Context7 invoked when not needed

**Diagnosis**: Check logs, see if Context7 called for general questions

**Solutions**:
1. Strengthen "When NOT to Use" section
2. Add more specific trigger conditions
3. Emphasize checking for library presence first

**Edit SKILL.md**:
```markdown
## When NOT to Use Context7

Before invoking, ask: "Is there a specific library/framework involved?"
If NO → Skip Context7, use training knowledge

DO NOT use for:
- Pure algorithmic questions
- Language syntax questions  
- General programming concepts
[Add more specific examples]
```

---

### Skill Too Conservative

**Symptoms**: Missing opportunities to use Context7

**Diagnosis**: Library mentioned but Context7 not invoked

**Solutions**:
1. Lower activation threshold
2. Add more library name patterns
3. Make triggers more sensitive

**Edit SKILL.md**:
```markdown
## Automatic Invocation Triggers

Expand to catch more patterns:
- Implicit library references ("JWT tokens" → might be FastAPI/Flask)
- Common abbreviations ("pg" → PostgreSQL)
- Framework features ("middleware" → Next.js/FastAPI)
```

---

### Token Inefficiency

**Symptoms**: Too many Context7 calls, high token usage

**Diagnosis**: Check if bulk-fetching multiple libraries upfront

**Solutions**:
1. Emphasize lazy loading in SKILL.md
2. Add more explicit "one at a time" guidance
3. Set token budgets

**Edit SKILL.md**:
```markdown
## Token Efficiency Strategies

CRITICAL: Fetch docs ONE AT A TIME, right before generating code

Example progression:
1. User mentions: "FastAPI + PostgreSQL + Redis"
2. Start with FastAPI endpoint structure → fetch FastAPI docs
3. When writing DB query → fetch PostgreSQL docs  
4. When implementing cache → fetch Redis docs

NOT: Bulk-fetch all three at the start
```

---

## Performance Benchmarks

Track these metrics to evaluate skill effectiveness:

### Invocation Accuracy
```
Target: 90%+ correct decisions
- True positives: Context7 used when needed
- True negatives: Context7 skipped when not needed
- False positives: Wasted Context7 calls
- False negatives: Missed opportunities
```

### Token Efficiency
```
Target: <1500 tokens per multi-library task
- Without skill baseline: 3000+ tokens
- With skill target: 1500 tokens
- Skill overhead: 1200 tokens (one-time)
```

### Code Quality
```
Target: 95%+ current patterns
- Uses current library versions
- Avoids deprecated APIs
- Follows best practices
- Version-aware implementations
```

---

## Continuous Improvement

### Logging Pattern
After each session, note:
```markdown
## Session Log - YYYY-MM-DD

### What worked well
- Context7 invoked for pandas 2.x nullable integers ✓
- Proper lazy loading for multi-library task ✓
- Error recovery found "tanstack-query" after "react-query" failed ✓

### What needs improvement
- Missed opportunity to use Context7 for asyncpg
- False positive: invoked for standard library question
- Could be more aggressive for FastAPI patterns

### Action items
- Add asyncpg to common library patterns
- Strengthen standard library exclusion
- Lower threshold for web framework detection
```

### Skill Refinement Cycle
```
1. Use skill for 1 week
2. Review logs and collect issues
3. Update SKILL.md with improvements
4. Test changes with validation suite
5. Deploy updated skill
6. Repeat monthly
```

---

## Success Criteria

The skill is working well when:

✅ **High accuracy**: Correct Context7 usage 90%+ of the time  
✅ **Token efficient**: 30-50% fewer tokens vs. no skill  
✅ **Better code**: Current patterns, version-aware, best practices  
✅ **Fast**: No noticeable delay from skill overhead  
✅ **Transparent**: Users barely notice skill working in background  
✅ **Maintainable**: Easy to update patterns as libraries evolve  
✅ **Composable**: Works well alongside other skills  

---

## Support & Community

**Report issues**: Document unexpected behavior with:
- Full prompt that triggered issue
- Expected behavior
- Actual behavior
- Context7 tool calls made (or not made)

**Share improvements**: If you refine patterns, consider sharing:
- New library detection patterns
- Better error recovery strategies
- HRDAG-specific optimizations
- Token efficiency techniques

**Stay updated**: 
- Monitor Context7 updates (new libraries added)
- Track library version changes (pandas 3.x?)
- Update skill as your stack evolves
