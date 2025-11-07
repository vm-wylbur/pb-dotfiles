# Context7 Skill Quick Reference

## Decision Tree: Should I Use Context7?

```
Is there a library/framework mentioned?
├─ YES → Is it fast-moving? (changes monthly/quarterly)
│  ├─ YES → USE CONTEXT7 ✓
│  └─ NO → Is there version-specific behavior?
│     ├─ YES → USE CONTEXT7 ✓
│     └─ NO → Skip Context7, use training knowledge
└─ NO → Is this general programming knowledge?
   ├─ YES → Skip Context7, use training knowledge
   └─ NO → Clarify with user
```

## Fast Invocation Patterns

### Pattern 1: Direct library mention
```
User: "FastAPI dependency injection"
→ resolve-library-id("fastapi")
→ get-library-docs(id, query="dependency injection")
```

### Pattern 2: Multiple libraries
```
User: "FastAPI with PostgreSQL and Redis"
→ Fetch docs ONE AT A TIME as needed
→ Don't bulk-fetch all three upfront
```

### Pattern 3: Version check first
```
User shares package.json or requirements.txt
→ Check versions BEFORE fetching docs
→ Fetch version-specific documentation
```

## Common Library Shortcuts

| User Says | Resolve To | Query With |
|-----------|------------|------------|
| "psycopg2 pooling" | psycopg/psycopg2 | connection pooling |
| "Typer multi-command" | typer | command groups |
| "loguru multi-sink" | loguru | multiple sinks configuration |
| "Redis pub/sub" | redis/redis-py | publish subscribe |
| "pandas 2.0" | pandas | version 2.0 [specific feature] |
| "pydantic v2 migration" | pydantic | version 2 migration |
| "scikit-learn pipeline" | scikit-learn | pipeline |
| "xgboost parameters" | xgboost | parameters |
| "pytest fixtures" | pytest | fixtures |
| "mypy type hints" | mypy | [specific typing scenario] |

## Token Budget Guidelines

| Scenario | Token Cost | Worth It? |
|----------|------------|-----------|
| Simple library query | ~500-1000 | ✓ YES |
| Multiple related libs | ~1500-2500 | ✓ YES |
| Bulk fetching (4+ libs) | ~3000+ | ✗ NO - fetch lazily |
| Standard library | 0 (skip) | ✓ YES - skip Context7 |

## Error Recovery Cheat Sheet

### "Library not found"
```
Try: Alternative names
- "react-query" → "tanstack-query"
- "python-redis" → "redis-py"

Try: Parent library
- "nextjs/middleware" → "nextjs"

Fallback: Training knowledge + note to user
```

### "Docs incomplete"
```
1. Refine query (more specific)
2. Try related library in ecosystem
3. Combine with web_search for very new features
```

### "Rate limited"
```
Without API key: Batch queries, be conservative
With API key: Normal operation
```

## When NOT to Use Context7

❌ **Skip for:**
- Python builtins (`len`, `map`, `filter`)
- Node.js core modules (`fs`, `http`, `path`)
- SQL fundamentals (SELECT, JOIN, WHERE)
- Algorithms (sorting, searching, trees)
- Design patterns (singleton, factory, observer)
- Math/statistics concepts (mean, variance, regression)
- Unix commands (`grep`, `awk`, `sed`)
- HTML/CSS basics

✓ **Use for:**
- Typer, loguru (CLI and logging)
- psycopg2/3 (PostgreSQL drivers)
- redis-py (Redis client)
- pandas, numpy, scipy (data science)
- scikit-learn, xgboost (ML frameworks)
- pydantic (data validation - versions matter!)
- pytest, mypy, ruff (dev tools)
- python-magic (file detection)

## Integration Shortcuts

### With document skills (docx/xlsx/pptx)
```
1. Load document skill first (structure)
2. Use Context7 for library specifics (python-docx patterns)
3. Combine for complete solution
```

### With testing workflows
```
1. Context7 for framework APIs (pytest fixtures)
2. Your patterns for organization
3. Recent approaches from web_search if needed
```

### With debugging
```
1. Parse error message for library clues
2. Context7 for library-specific debugging
3. Check for version-specific issues
```

## Monitoring Template

After Context7 usage, note:
```
✓ FastAPI docs fetched - current async patterns applied
✓ psycopg2 pooling - version 2.9.x approach used
⚠ pandas docs partial - combined with training knowledge
⚠ Very new feature - supplemented with web_search
```

## Common Workflows

### Workflow 1: API endpoint creation
```
User mentions framework → detect library
└─ Resolve ID → fetch auth/routing/validation docs
   └─ Generate code → cite Context7 source briefly
```

### Workflow 2: Database operations
```
Check requirements.txt → identify driver & version
└─ Fetch version-specific docs → use current patterns
   └─ Apply to connection/query/transaction code
```

### Workflow 3: Testing setup
```
Identify test framework → resolve ID
└─ Fetch fixture/mock/assertion docs → set up test structure
   └─ Generate tests with current best practices
```

## Customization Hooks

Add to `~/.claude/CLAUDE.md` for auto-behavior:

```markdown
# Always use Context7 for:
- External libraries and frameworks
- Version-sensitive APIs
- Fast-moving ecosystems

# Prioritize for my projects:
- PostgreSQL operations (psycopg2/3, asyncpg)
- Redis patterns (redis-py)
- Data processing (pandas, numpy)
```

## Performance Tips

1. **Lazy loading**: Fetch docs right before generating code, not at start
2. **Specific queries**: "FastAPI dependency injection" not just "FastAPI"
3. **Session memory**: Remember library IDs within conversation
4. **One at a time**: Serial fetching, not parallel bulk
5. **Read carefully**: Context7 results are pre-filtered and relevant

## Quick Syntax

```python
# Resolve library ID
resolve-library-id(query: str) → library_id: str

# Get documentation
get-library-docs(
    library_id: str,
    query: str  # specific to user's need
) → docs: str
```

## Version-Specific Gotchas

| Library | Breaking Change | Use Context7? |
|---------|----------------|---------------|
| pandas 1.x → 2.x | API changes | ✓ ALWAYS |
| pydantic 1.x → 2.x | MASSIVE rewrite | ✓ ALWAYS |
| psycopg2 → psycopg3 | Complete rewrite | ✓ ALWAYS |
| scikit-learn | API evolution | ✓ For current patterns |
| xgboost | Parameter changes | ✓ For current params |
| Redis-py | Mostly stable | ✓ For async patterns |

## Remember

- **Proactive, not reactive**: Invoke when you see library names
- **Token-conscious**: Don't fetch what you already know well
- **User-transparent**: Brief mention of doc source
- **Error-graceful**: Fall back smoothly when docs unavailable
- **Combine approaches**: Context7 + training + web search as needed
