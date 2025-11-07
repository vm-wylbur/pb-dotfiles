# Query Pattern Library

Common search patterns for tree-sitter and repomix code exploration.

---

## Repomix Grep Patterns

### Finding Definitions

**Python:**
```regex
^def                          # All function definitions
^class                        # All class definitions
^from .* import              # All imports
^import                      # All direct imports
```

**Bash:**
```regex
^function |^[a-z_]+\(\)     # Function definitions
^source |^\. /               # Source statements
```

**JavaScript/TypeScript:**
```regex
^function |^const .* =      # Function definitions
^class                       # Class definitions
^import .* from              # ES6 imports
^export                      # Exports
```

**SQL:**
```regex
^CREATE TABLE               # Table definitions
^CREATE INDEX               # Index definitions
^ALTER TABLE                # Schema changes
```

---

### Finding Usage Patterns

**Logging:**
```regex
log_info|log_warn|log_error|log_debug    # bash-logger calls
logger\.(info|warn|error|debug)           # Python logging
console\.(log|warn|error)                 # JavaScript console
```

**Error Handling:**
```regex
try:|except |catch \(|finally:            # Exception handling
raise |throw new                          # Error raising
```

**Database Operations:**
```regex
CREATE TABLE|ALTER TABLE|DROP TABLE       # DDL operations
INSERT INTO|UPDATE |DELETE FROM           # DML operations
PARTITION BY                              # Partitioning
```

**Configuration:**
```regex
TODO:|FIXME:|HACK:|NOTE:                  # Code comments
@deprecated|@override                     # Decorators/annotations
```

---

### Finding Patterns with Context

Use `contextLines` to see surrounding code:

```
repomix grep_repomix_output(
    outputId="...",
    pattern="pattern",
    contextLines=3              # Show 3 lines before/after
)
```

**Examples:**

```regex
# Find all database queries with context
pattern="SELECT .* FROM"
contextLines=2

# Find error handling blocks
pattern="try:|except "
contextLines=5

# Find function signatures with docstrings
pattern="^def "
contextLines=10
```

---

### Advanced Regex Patterns

**Lookahead/Lookbehind:**
```regex
# Functions that return None
^def .*\) -> None:

# Classes that inherit
^class \w+\(.*\):

# Variables with type hints
^\s+\w+:\s+\w+\s+=

# Multi-line matches (use multiline=true)
pattern="try:[\s\S]*?except"
multiline=true
```

**Character Classes:**
```regex
[A-Z][a-z]+                  # PascalCase identifiers
[a-z_]+                      # snake_case identifiers
[0-9a-f]{8}                  # Hash prefixes (8 chars)
```

---

## Tree-Sitter Query Templates

### Python Templates

**Find all function definitions:**
```python
tree-sitter get_symbols(
    project="ntt",
    file_path="bin/ntt-copier.py",
    symbol_types=["functions"]
)
```

**Find all class definitions:**
```python
tree-sitter get_symbols(
    project="ntt",
    file_path="bin/ntt-copier.py",
    symbol_types=["classes"]
)
```

**Find all imports:**
```python
tree-sitter get_symbols(
    project="ntt",
    file_path="bin/ntt-copier.py",
    symbol_types=["imports"]
)
```

**Get all symbols (functions + classes + imports):**
```python
tree-sitter get_symbols(
    project="ntt",
    file_path="bin/ntt-copier.py",
    symbol_types=["functions", "classes", "imports"]
)
```

---

### Finding Usage

**Find where symbol is used:**
```python
tree-sitter find_usage(
    project="ntt",
    symbol="CopyWorker",
    language="python"
)
```

**Find where symbol is used in specific file:**
```python
tree-sitter find_usage(
    project="ntt",
    symbol="log_info",
    file_path="bin/ntt-orchestrator",
    language="bash"
)
```

---

### Dependency Tracing

**Get dependencies for Python file:**
```python
tree-sitter get_dependencies(
    project="ntt",
    file_path="bin/ntt-copier.py"
)
```

**Trace import chain:**
```python
# Step 1: Get dependencies
deps = tree-sitter get_dependencies("ntt", "bin/ntt-copier.py")

# Step 2: For each dependency, get its dependencies
for dep in deps:
    sub_deps = tree-sitter get_dependencies("ntt", dep)
```

---

### Complexity Analysis

**Analyze file complexity:**
```python
tree-sitter analyze_complexity(
    project="ntt",
    file_path="bin/ntt-copier.py"
)
```

**Returns:**
- Cyclomatic complexity
- Nesting depth
- Function count
- Lines of code

---

### Finding Similar Code

**Find code similar to snippet:**
```python
tree-sitter find_similar_code(
    project="ntt",
    snippet="def log_event(...):\n    ...",
    threshold=0.8,              # 80% similarity
    max_results=10
)
```

**Use cases:**
- Detecting code duplication
- Finding similar patterns
- Identifying refactoring opportunities

---

## Language-Specific Patterns

### Python

**Common patterns:**
```python
# Class definitions with inheritance
^class \w+\([^)]+\):

# Async functions
^async def

# Type hints
def \w+\(.*\) -> \w+:

# Decorators
^@\w+

# Context managers
^with .* as .*:

# List comprehensions
\[.* for .* in .*\]
```

**Tree-sitter queries:**
- Functions: `symbol_types=["functions"]`
- Classes: `symbol_types=["classes"]`
- Imports: `symbol_types=["imports"]`

---

### Bash

**Common patterns:**
```bash
# Function definitions (two forms)
^function \w+|^[a-z_]+\(\)

# Variable assignments
^\w+=["\$]

# Command substitution
\$\(.*\)

# Conditional statements
^if \[|^elif \[|^else$

# Loops
^for \w+ in |^while \[

# Source/include
^source |^\. /
```

**Special cases:**
```bash
# Find all log calls (bash-logger)
log_info|log_warn|log_error

# Find all SQL execution
psql .* -c|sudo -u .* psql

# Find all fail/error exits
fail "|exit 1
```

---

### SQL

**Common patterns:**
```sql
# DDL operations
^CREATE TABLE|^ALTER TABLE|^DROP TABLE

# Index operations
^CREATE INDEX|^DROP INDEX

# Partitioning
PARTITION BY LIST|PARTITION BY RANGE

# Constraints
^ALTER TABLE .* ADD CONSTRAINT

# Queries
^SELECT .* FROM|^INSERT INTO|^UPDATE |^DELETE FROM
```

---

### JavaScript/TypeScript

**Common patterns:**
```javascript
# Function definitions
^function |^const .* = \(|^async function

# Class definitions
^class \w+|^export class

# Imports/exports
^import .* from|^export (default |const |function )

# React components
^const \w+ = \(\) =>|^function \w+\(\) \{

# Type definitions (TypeScript)
^interface |^type \w+ =
```

---

## Pattern Cookbook

### Scenario: Find All Error Handling

**Repomix approach:**
```regex
try:|except |catch \(|finally:|raise |throw new
```

**Result:** All error handling blocks across entire codebase

---

### Scenario: Find All Database Tables

**Repomix approach:**
```regex
^CREATE TABLE|PARTITION OF
```

**With context:**
```
contextLines=5   # See column definitions
```

---

### Scenario: Find Logging Migration Status

**Repomix approach:**
```regex
bash-logger: INTEGRATED|TODO.*bash-logger
```

**Result:** Scripts migrated vs pending migration

---

### Scenario: Find Functions with Specific Pattern

**Repomix approach:**
```regex
^def .*_worker\(
```

**Result:** All worker functions

---

### Scenario: Find Configuration Values

**Repomix approach:**
```regex
LOG_FILE=|DB_URL=|SOURCE=|TARGET=
```

**Result:** All configuration variables

---

## Combining Patterns

### Pattern 1: Find + Filter

```
Step 1: Find all functions
  repomix grep "^def "

Step 2: Filter for async functions
  repomix grep "^async def "
```

---

### Pattern 2: Find + Trace

```
Step 1: Find class definition
  repomix grep "^class CopyWorker"

Step 2: Find usage
  tree-sitter find_usage(symbol="CopyWorker")
```

---

### Pattern 3: Find + Analyze

```
Step 1: Find all files with pattern
  repomix grep "pattern"

Step 2: Analyze complexity
  tree-sitter analyze_complexity(file)
```

---

## Performance Tips

### Tip 1: Use Anchors

❌ Slow: `def ` (matches anywhere in line)
✅ Fast: `^def ` (only matches start of line)

**Why:** Reduces false positives, faster search

---

### Tip 2: Use Specific Patterns

❌ Slow: `class` (matches "class", "subclass", "classroom")
✅ Fast: `^class \w+` (only class definitions)

**Why:** More precise, fewer matches to filter

---

### Tip 3: Limit Context When Possible

❌ Slow: `contextLines=20` (large output)
✅ Fast: `contextLines=2` (minimal context)

**Why:** Less data to process and display

---

### Tip 4: Use Tree-Sitter for Symbols

❌ Slow: Repomix grep for every symbol
✅ Fast: Tree-sitter get_symbols once

**Why:** Single operation vs multiple greps

---

## Common Mistakes

### Mistake 1: Forgetting Anchors

```regex
# Bad: Matches "function", "malfunction", etc.
function

# Good: Only matches function definitions
^function
```

---

### Mistake 2: Greedy Matching

```regex
# Bad: Matches everything between first and last quote
".*"

# Good: Matches minimal content
"[^"]*"
```

---

### Mistake 3: Not Escaping Special Characters

```regex
# Bad: . matches any character
log.info

# Good: Escaped dot
log\.info
```

---

### Mistake 4: Using Filesystem Tools for Patterns

```
# Bad
Glob("**/*.py")
Read each file
Search manually

# Good
repomix grep "pattern"
```

---

## Quick Reference

### Most Common Patterns

```
TASK                     PATTERN                      TOOL
─────────────────────────────────────────────────────────────
Find functions           ^def |^function             Repomix
Find classes             ^class                      Repomix
Find imports             ^import |^from              Repomix
Find logging             log_info|log_warn           Repomix
Find errors              try:|except |catch          Repomix
Find TODOs               TODO:|FIXME:                Repomix
Trace usage              N/A                         Tree-Sitter
Get dependencies         N/A                         Tree-Sitter
Analyze complexity       N/A                         Tree-Sitter
```

---

## Examples by Language

### Python Examples

```python
# Find all class methods
repomix grep "    def \w+"

# Find all async functions
repomix grep "^async def "

# Find all type hints
repomix grep "def \w+\(.*\) -> "

# Find all decorators
repomix grep "^@\w+"
```

---

### Bash Examples

```bash
# Find all function definitions
repomix grep "^function |^\w+\(\)"

# Find all log calls
repomix grep "log_info|log_warn|log_error"

# Find all fail statements
repomix grep 'fail "'

# Find all psql executions
repomix grep "psql .* -c"
```

---

### SQL Examples

```sql
# Find all table creations
repomix grep "^CREATE TABLE"

# Find all partitioned tables
repomix grep "PARTITION BY"

# Find all indexes
repomix grep "^CREATE INDEX"

# Find all foreign keys
repomix grep "FOREIGN KEY"
```

---

## Summary

**Key Principles:**

1. **Use anchors** (`^`, `$`) for precision
2. **Be specific** - narrow patterns = faster search
3. **Choose right tool** - Tree-sitter for symbols, Repomix for patterns
4. **Use context wisely** - more context = more data
5. **Test patterns** - verify matches before bulk operations

**Remember:** Good patterns make code exploration fast and accurate. Bad patterns waste time filtering false positives.
