---
name: context7
description: Intelligent usage of Context7 MCP for fetching current, version-specific library documentation. Automatically invoked when working with external libraries, frameworks, or APIs where up-to-date documentation improves code quality.
---

# Context7 Documentation Assistant

This skill teaches Claude when and how to effectively use the Context7 MCP server to fetch current library documentation.

## Core Principle

Context7 bridges the gap between Claude's training data (cutoff: January 2025) and the current state of fast-moving libraries. Use it proactively when library-specific knowledge matters.

## Automatic Invocation Triggers

ALWAYS use Context7 when:

1. **Library mentioned by name** in user's request
   - "implement FastAPI authentication"
   - "use psycopg2 connection pooling"
   - "Redis pub/sub with redis-py"

2. **Code involves library-specific APIs**
   - Importing third-party packages
   - Using framework-specific patterns
   - Configuring library-specific options

3. **Fast-moving ecosystems** (docs change monthly/quarterly)
   - Next.js, React, Tailwind CSS
   - FastAPI, Pydantic v2
   - Modern testing frameworks (pytest, vitest)
   - ORMs and database libraries

4. **Version-sensitive scenarios**
   - Breaking changes between major versions
   - Deprecated APIs
   - New features in recent releases

## When NOT to Use Context7

Skip Context7 for:

- **Standard library functions** (Python builtins, Node.js core modules)
- **Stable, well-known patterns** (basic SQL, HTTP concepts, Unix commands)
- **General programming concepts** (algorithms, data structures, design patterns)
- **Historical/legacy code** where training data is sufficient
- **Non-library work** (pure business logic, mathematical computations)

## Invocation Workflow

### Step 1: Detect library reference
```
User mentions: "PostgreSQL connection pooling with psycopg2"
→ Library detected: psycopg2
```

### Step 2: Resolve library ID
```
Call resolve-library-id with query: "psycopg2"
→ Receive Context7 ID: "psycopg/psycopg2" (or similar)
```

### Step 3: Fetch targeted documentation
```
Call get-library-docs with:
- library_id: "psycopg/psycopg2"
- query: "connection pooling" (specific to user's need)
```

### Step 4: Apply documentation
Use the fetched docs to:
- Generate current, correct code
- Cite version-specific patterns
- Avoid deprecated approaches

## Token Efficiency Strategies

1. **One library at a time** - Don't bulk-fetch multiple libraries
2. **Specific queries** - "FastAPI dependency injection" not just "FastAPI"
3. **Read carefully** - Context7 docs are pre-filtered and relevant
4. **Session memory** - Remember library IDs within a conversation
5. **Lazy loading** - Only fetch when about to generate library-specific code

## Error Recovery Patterns

### Library not found
```
Try variations:
- "react-query" → "tanstack-query"
- "nextjs/middleware" → "nextjs"
- "python-redis" → "redis-py"

Fallback: Training knowledge + note to user about docs availability
```

### Docs seem incomplete
```
Strategies:
1. Refine query to be more specific
2. Try related library in ecosystem
3. Combine Context7 docs with web_search for very new features
```

### Rate limiting
```
Without API key: Conservative usage, batch-related queries
With API key: Normal operation
```

## Common Library Patterns

### CLI & Logging
- `typer` - CLI applications (multi-command, config files)
- `loguru` - Advanced logging (multi-sink, structured, rotation)

### Data & Statistical Analysis
- `pandas` - Data analysis (version 2.x nullable integers!)
- `numpy` - Numerical computing
- `scipy` - Scientific computing
- `scikit-learn` - Machine learning (API changes across versions)
- `xgboost` - Gradient boosting (version-specific parameters)

### Data Validation & Serialization
- `pydantic` - Data validation (1.x vs 2.x MAJOR breaking changes)

### Database & Caching
- `psycopg/psycopg2` or `psycopg/psycopg3` - PostgreSQL
- `redis/redis-py` - Redis (queuing, caching)

### Development Tools
- `pytest` - Testing framework
- `mypy` - Type checking
- `ruff` - Fast linting/formatting

### Utilities
- `python-magic` - File type detection (trivial but useful)

## Integration with Other Skills

### When creating documents (docx/xlsx/pptx)
```
1. Load document skill for file format expertise
2. Use Context7 for library-specific approaches (python-docx, openpyxl)
3. Combine both for optimal results
```

### When building CLI tools
```
1. Context7 for Typer patterns (commands, config, arguments)
2. Context7 for loguru setup (sinks, formatting, rotation)
3. Your project structure and conventions
```

### When writing tests
```
1. Context7 for pytest features (fixtures, parametrize, markers)
2. Context7 for mypy type checking patterns
3. Your testing patterns for organization
```

### When debugging
```
1. Examine error messages for library clues
2. Context7 for library-specific debugging techniques
3. Stack traces often reveal version-specific issues
```

### When doing statistical analysis
```
1. Context7 for scikit-learn/xgboost version-specific APIs
2. Context7 for pandas best practices
3. Your analytical patterns and domain knowledge
```

## Best Practices

1. **Be proactive** - Don't wait to be asked; invoke when you see library names
2. **Version awareness** - Check package.json/requirements.txt first
3. **Cite sources** - Mention you're using Context7 docs briefly
4. **Verify assumptions** - Training data may be outdated for fast-moving libs
5. **Combine approaches** - Context7 + training knowledge + web search as needed

## Example Decision Trees

### User: "Set up PostgreSQL connection pooling"
```
Decision: Use Context7
Reason: PostgreSQL drivers have version-specific pooling APIs
Steps:
1. Detect library: psycopg2 or psycopg3 (check user's environment)
2. Resolve ID
3. Fetch pooling docs
4. Generate current best-practice code
```

### User: "Explain bubble sort algorithm"
```
Decision: Skip Context7
Reason: Algorithmic concept, no library involved
Action: Use training knowledge directly
```

### User: "Create a Typer CLI that loads config from YAML and has multiple commands"
```
Decision: Use Context7
Reason: Typer has specific patterns for multi-command + config
Steps:
1. Resolve typer library ID
2. Fetch docs on command groups and configuration
3. Generate current Typer patterns
```

### User: "Train an XGBoost model with cross-validation"
```
Decision: Use Context7
Reason: XGBoost parameters and APIs change across versions
Steps:
1. Check if requirements.txt exists (version awareness)
2. Resolve xgboost library ID
3. Fetch current cross-validation patterns
4. Generate version-appropriate code
```

### User: "Set up loguru with multiple log files for different modules"
```
Decision: Use Context7
Reason: loguru has specific multi-sink configuration patterns
Steps:
1. Resolve loguru library ID
2. Fetch multi-sink setup docs
3. Generate proper sink configuration
```

## Monitoring Your Usage

After using Context7, briefly note:
- ✓ Library ID resolved successfully
- ✓ Docs were relevant and current
- ⚠ Fell back to training knowledge (docs unavailable)
- ⚠ Combined Context7 + web search (very new features)

This helps users understand your information sources.

## Special Considerations for Data Analysis Workflows

### Statistical analysis and ML pipelines
- Use Context7 for: pandas, numpy, scipy, scikit-learn, xgboost specifics
- Use training for: statistical concepts, mathematical theory
- Check versions especially for breaking changes (pandas 1.x → 2.x, pydantic 1.x → 2.x)
- Version-specific APIs matter for scikit-learn estimators and xgboost parameters

### CLI applications with Typer
- Multi-command structures: Command groups, shared options
- Configuration handling: YAML/TOML loading patterns
- Use Context7 for: Typer-specific patterns, not generic argparse

### Logging with loguru
- Multi-sink setups for different modules/projects
- Structured logging for data pipelines
- Rotation and retention policies
- Use Context7 for: loguru-specific configuration, not generic logging

### Database-heavy work
- PostgreSQL extensions and features change frequently
- Use Context7 for: psycopg versions, connection patterns, COPY operations
- Critical for: JSON operations, array handling, performance features
- Bulk loading patterns (COPY command) for large datasets

### Data validation with pydantic
- CRITICAL: pydantic 1.x vs 2.x has massive breaking changes
- Always check version before generating pydantic code
- Use Context7 for: version-specific validation patterns, field definitions
- Migration patterns if upgrading from v1 to v2

### Development tooling
- pytest: fixtures, parametrize, markers change over versions
- mypy: type checking patterns evolve
- ruff: configuration and rule sets update frequently
- Use Context7 for: current best practices, not outdated patterns

## Meta: When to Load This Skill

This skill loads automatically when:
- User mentions library/framework names
- Code generation involves third-party packages
- Documentation quality affects success

Token cost: ~50 tokens until loaded, ~1200 tokens when active
