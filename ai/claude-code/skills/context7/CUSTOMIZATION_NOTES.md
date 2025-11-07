# Context7 Skill - Customization Summary for Patrick

## Changes Made from Generic Version

This skill was customized specifically for your actual tech stack and workflows at HRDAG.

---

## Libraries Added

### CLI & Logging (NEW - Critical for your work)
- **Typer** - Multi-command CLI, config file integration
- **loguru** - Multi-sink logging, structured logs, rotation

### Data Science & ML (NEW)
- **scikit-learn** - ML library with version-specific APIs
- **xgboost** - Gradient boosting, parameter evolution
- **scipy** - Scientific computing

### Data Validation (EMPHASIZED)
- **pydantic** - v1 vs v2 breaking changes explicitly called out
  - This was mentioned as a specific pain point
  - Skill now checks version FIRST before generating pydantic code

### Development Tools (NEW)
- **mypy** - Type checking patterns
- **ruff** - Fast linting/formatting
- **python-magic** - File type detection

---

## Libraries Removed

### Web Frameworks (Not relevant to your work)
- ~~FastAPI~~ - You don't use this
- ~~Next.js~~ - Frontend framework
- ~~React~~ - Frontend library
- ~~Django~~ - Web framework

### DevOps/Infrastructure (Not your focus)
- ~~Docker~~ - Containerization
- ~~Terraform~~ - IaC
- ~~Ansible~~ - Configuration management

### Frontend Testing (Not relevant)
- ~~jest~~ - JavaScript testing
- ~~vitest~~ - Modern JS testing
- ~~playwright~~ - Browser automation

---

## Examples Updated

### Old Examples (Removed/Replaced)
1. ~~FastAPI authentication~~
2. ~~Async Redis with FastAPI~~
3. ~~FastAPI + PostgreSQL + Redis endpoint~~

### New Examples (Added)
1. **Typer multi-command CLI with YAML config**
   - Command groups
   - Config file integration with pydantic
   - Professional CLI UX

2. **loguru multi-sink logging**
   - Different files for errors vs general logs
   - Rotation and retention
   - Structured logging for pipelines
   - Context-specific logging

3. **pydantic version awareness**
   - Critical: v1 vs v2 breaking changes
   - Shows BOTH versions for comparison
   - Explains why this matters

### Kept Examples (Still relevant)
1. **PostgreSQL COPY command** - Your bulk loading work
2. **pandas version 2.x** - Nullable integers, API changes
3. **Algorithm skipping** - Shows when NOT to use Context7

---

## Decision Trees Updated

### Old Decision Trees
```
"FastAPI with async PostgreSQL and Redis caching"
```

### New Decision Trees
```
"Create a Typer CLI that loads config from YAML"
"Train an XGBoost model with cross-validation"
"Set up loguru with multiple log files"
```

---

## Workflow Sections Updated

### Old: "HRDAG-style Workflows"
Was too specific about HRDAG internal patterns

### New: "Data Analysis Workflows"
More general but still relevant:
- Statistical analysis and ML pipelines
- CLI applications with Typer
- Logging with loguru
- Database-heavy work (kept PostgreSQL COPY)
- Data validation with pydantic (v1 vs v2 emphasis)
- Development tooling (pytest, mypy, ruff)

---

## Key Emphasis Areas

### 1. Version Awareness (Critical)
**pydantic**: v1 → v2 is explicitly called out as "MASSIVE rewrite"
- Skill checks version BEFORE generating code
- Shows both v1 and v2 patterns in examples
- Prevents mixed syntax that breaks

**pandas**: 1.x → 2.x nullable integers
**scikit-learn**: API evolution across versions
**xgboost**: Parameter changes

### 2. CLI Patterns (New Focus)
Typer patterns:
- Multi-command structures
- Config file handling (YAML/TOML)
- NOT progress bars or rich output (as you specified)

### 3. Logging Patterns (New Focus)
loguru patterns:
- Multi-sink setup
- Structured logging
- Rotation policies
- Context-specific logging

### 4. PostgreSQL Bulk Operations (Kept)
COPY command for large datasets - critical for your work

### 5. Statistical/ML Libraries (New)
numpy, scipy, scikit-learn, xgboost
- Version-specific APIs
- Parameter evolution
- Current best practices

---

## Quick Reference Updates

### Common Library Shortcuts
Now includes:
- Typer multi-command → query for command groups
- loguru multi-sink → query for sink configuration
- pydantic v2 migration → version-specific docs
- scikit-learn pipeline → current patterns
- xgboost parameters → version-appropriate params

### Version Gotchas Table
Added:
- pydantic 1.x → 2.x (MASSIVE rewrite) - ✓ ALWAYS
- scikit-learn (API evolution) - ✓ For current patterns
- xgboost (Parameter changes) - ✓ For current params

---

## Integration Patterns

### New Section: Building CLI Tools
```
1. Context7 for Typer patterns (commands, config, arguments)
2. Context7 for loguru setup (sinks, formatting, rotation)
3. Your project structure and conventions
```

### New Section: Statistical Analysis
```
1. Context7 for scikit-learn/xgboost version-specific APIs
2. Context7 for pandas best practices
3. Your analytical patterns and domain knowledge
```

---

## Testing Suite Updates

Tests now check for:
- Typer CLI generation (not FastAPI)
- loguru logging setup
- pydantic version detection
- scikit-learn/xgboost patterns
- Your actual library stack

---

## What Stayed the Same

### Core Intelligence (Unchanged)
- When to invoke vs skip Context7
- Token efficiency strategies
- Error recovery patterns
- Lazy loading approach

### PostgreSQL Patterns (Kept & Enhanced)
- COPY command for bulk loading
- Connection pooling
- Version-specific psycopg2/3 patterns

### Redis Patterns (Kept)
- Caching patterns
- Queuing (relevant to your work)

### pandas (Kept & Enhanced)
- Version 2.x nullable integers
- Large dataset handling

### pytest (Kept)
- fixtures, parametrize, markers

---

## Installation Notes

The skill is ready to install with:
```bash
cd context7-skill
./install.sh
```

Or manually:
```bash
cp -r context7-skill ~/.claude/skills/context7
```

Test with your actual use cases:
```bash
claude "Create a Typer CLI with YAML config and loguru logging"
claude "Build a scikit-learn pipeline with cross-validation"
claude "Create a pydantic v2 model for data validation"
```

---

## Further Customization

You can still customize more by editing SKILL.md:

### Add Project-Specific Libraries
If you have internal tools or specific package versions:
```markdown
### Your Specific Tools
- your-internal-lib: Always check version, has breaking changes
- specific-analysis-package: Use Context7 for v3.x+
```

### Add Workflow Patterns
```markdown
### Your Common Patterns
- CSV → PostgreSQL: Always use COPY command
- Multi-project analysis: Load pandas, set up loguru early
- CLI tools: Typer + loguru + pydantic for config
```

### Adjust Token Budgets
```markdown
### Token Limits
- Max per library: 800 tokens (tighter)
- Max per session: 4000 tokens (more conservative)
```

---

## Summary

**Removed**: Web frameworks, frontend, DevOps tools you don't use  
**Added**: Typer, loguru, scikit-learn, xgboost, pydantic v2 focus  
**Emphasized**: Version awareness (especially pydantic!), CLI patterns, logging  
**Kept**: PostgreSQL COPY, Redis, pandas, pytest  
**Ready for**: Your actual data analysis, CLI, and statistical workflows

The skill is now tuned for command-line data processing tools, not web APIs!
