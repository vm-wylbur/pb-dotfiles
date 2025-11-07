# Context7 Skill: Before & After Examples

This file demonstrates concrete scenarios showing how the Context7 skill improves Claude Code's behavior.

---

## Example 1: PostgreSQL Connection Pooling

### User Request
```
"Set up PostgreSQL connection pooling with psycopg2 for a FastAPI app"
```

### WITHOUT Context7 Skill

**Claude's behavior:**
```python
# Might generate based on training data (potentially outdated)
import psycopg2
from psycopg2 import pool

# Basic pooling setup from training knowledge
connection_pool = psycopg2.pool.SimpleConnectionPool(
    1, 20,
    user="user",
    password="password",
    host="localhost",
    database="mydb"
)

def get_connection():
    return connection_pool.getconn()
```

**Issues:**
- May miss recent best practices
- Doesn't know about connection context managers
- Might use deprecated patterns
- No awareness of FastAPI-specific integration

### WITH Context7 Skill

**Claude's behavior:**
```
[Skill activates: detects "psycopg2" and "FastAPI"]
[Step 1: resolve-library-id("psycopg2")]
[Step 2: get-library-docs(id, query="connection pooling fastapi")]
[Step 3: Generate current code]

# Using current psycopg2 connection pooling with FastAPI
from contextlib import contextmanager
from psycopg2 import pool
from fastapi import Depends

# Thread-safe connection pool
db_pool = pool.ThreadedConnectionPool(
    minconn=1,
    maxconn=20,
    user="user",
    password="password",
    host="localhost",
    database="mydb"
)

@contextmanager
def get_db_connection():
    """Context manager for database connections"""
    conn = db_pool.getconn()
    try:
        yield conn
    finally:
        db_pool.putconn(conn)

def get_db():
    """FastAPI dependency for database access"""
    with get_db_connection() as conn:
        yield conn

# Usage in FastAPI endpoint
@app.get("/users/{user_id}")
def get_user(user_id: int, db=Depends(get_db)):
    cursor = db.cursor()
    cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    return cursor.fetchone()
```

**Benefits:**
- Current best practices (ThreadedConnectionPool)
- Proper context manager pattern
- FastAPI dependency injection
- Safe connection cleanup

---

## Example 2: Typer Multi-Command CLI with Config

### User Request
```
"Create a Typer CLI with multiple commands that loads config from YAML"
```

### WITHOUT Context7 Skill

**Claude's behavior:**
```python
# Might use basic argparse patterns or outdated Typer
import typer
import yaml

app = typer.Typer()

@app.command()
def process(file: str):
    # Basic command, no config handling
    print(f"Processing {file}")

@app.command()
def analyze(file: str):
    print(f"Analyzing {file}")

if __name__ == "__main__":
    app()
```

**Issues:**
- No config file integration
- Doesn't use Typer's command groups
- Missing modern patterns (callback, shared options)
- No type hints or validation

### WITH Context7 Skill

**Claude's behavior:**
```
[Skill activates: detects "Typer" + "multi-command" + "config"]
[Step 1: resolve-library-id("typer")]
[Step 2: get-library-docs(id, query="command groups configuration yaml")]
[Step 3: Generate current patterns]

# Modern Typer CLI with config and command groups
from pathlib import Path
from typing import Optional
import typer
from pydantic import BaseModel
import yaml

app = typer.Typer()

# Config model with pydantic validation
class Config(BaseModel):
    database_url: str
    log_level: str = "INFO"
    output_dir: Path = Path("output")

# Global state for config
config: Optional[Config] = None

@app.callback()
def main(
    config_file: Path = typer.Option(
        Path("config.yaml"),
        "--config",
        "-c",
        help="Path to YAML config file"
    )
):
    """
    Data processing CLI tool.
    
    Loads configuration from YAML and provides multiple commands.
    """
    global config
    
    if config_file.exists():
        with open(config_file) as f:
            config_data = yaml.safe_load(f)
        config = Config(**config_data)
        typer.echo(f"Loaded config from {config_file}")
    else:
        typer.secho(
            f"Config file not found: {config_file}",
            fg=typer.colors.RED
        )
        raise typer.Exit(1)

@app.command()
def process(
    input_file: Path = typer.Argument(..., help="Input CSV file"),
    dry_run: bool = typer.Option(False, "--dry-run", help="Preview without executing")
):
    """Process input data and store in database."""
    if config is None:
        typer.secho("No config loaded", fg=typer.colors.RED)
        raise typer.Exit(1)
    
    typer.echo(f"Processing: {input_file}")
    typer.echo(f"Database: {config.database_url}")
    typer.echo(f"Output: {config.output_dir}")
    
    if dry_run:
        typer.secho("DRY RUN - no changes made", fg=typer.colors.YELLOW)

@app.command()
def analyze(
    input_file: Path = typer.Argument(..., help="Input data file"),
    output: Optional[Path] = typer.Option(None, "--output", "-o")
):
    """Analyze processed data and generate reports."""
    if config is None:
        typer.secho("No config loaded", fg=typer.colors.RED)
        raise typer.Exit(1)
    
    output_path = output or config.output_dir / "analysis.csv"
    typer.echo(f"Analyzing: {input_file}")
    typer.echo(f"Output: {output_path}")

if __name__ == "__main__":
    app()
```

**Benefits:**
- Proper config file integration with pydantic validation
- Callback pattern for shared config loading
- Modern Typer patterns (Option, Argument, colors)
- Type-safe configuration
- Professional CLI UX (help text, colors, dry-run)

---

## Example 3: Loguru Multi-Sink Logging

### User Request
```
"Set up loguru with different log files for errors and general logs, with rotation"
```

### WITHOUT Context7 Skill

**Claude's behavior:**
```python
# Might use basic Python logging or outdated loguru patterns
from loguru import logger

# Basic single-file logging
logger.add("app.log")
logger.info("Application started")
```

**Issues:**
- No multi-sink configuration
- No rotation
- No level-specific routing
- Missing structured logging features

### WITH Context7 Skill

**Claude's behavior:**
```
[Skill activates: detects "loguru" + "different log files" + "rotation"]
[Step 1: resolve-library-id("loguru")]
[Step 2: get-library-docs(id, query="multiple sinks rotation")]
[Step 3: Generate current multi-sink patterns]

# Modern loguru multi-sink configuration
from loguru import logger
import sys

# Remove default handler
logger.remove()

# Console output (INFO and above)
logger.add(
    sys.stderr,
    format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>",
    level="INFO",
    colorize=True
)

# General log file with rotation
logger.add(
    "logs/app_{time:YYYY-MM-DD}.log",
    rotation="00:00",  # New file at midnight
    retention="30 days",  # Keep logs for 30 days
    compression="zip",  # Compress rotated logs
    level="DEBUG",
    format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} - {message}"
)

# Error log file (errors only)
logger.add(
    "logs/errors_{time:YYYY-MM-DD}.log",
    rotation="100 MB",  # Rotate when file reaches 100MB
    retention="90 days",
    compression="zip",
    level="ERROR",
    format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} - {message}\n{exception}",
    backtrace=True,  # Include full traceback
    diagnose=True    # Add diagnostic information
)

# Structured logging for data pipeline events
logger.add(
    "logs/pipeline_{time:YYYY-MM-DD}.log",
    rotation="500 MB",
    retention="180 days",
    serialize=True,  # JSON format for structured logs
    level="INFO"
)

# Usage
logger.info("Application started")
logger.error("Database connection failed", extra={"db": "postgres", "host": "localhost"})

# Context-specific logging
with logger.contextualize(task="data_import", project="analysis_2024"):
    logger.info("Starting data import")
    # This context will appear in all logs within this block
```

**Benefits:**
- Multiple sinks with different levels
- Automatic rotation and retention policies
- Compression for archived logs
- Structured logging option (JSON)
- Rich formatting with context
- Separate error tracking

---

### User Request
```
"Explain the bubble sort algorithm and implement it in Python"
```

### WITHOUT Context7 Skill

**Claude's behavior:**
```
[Might waste time trying to invoke Context7]
[No library involved - Context7 has nothing to offer]
[Eventually falls back to training knowledge]
```

### WITH Context7 Skill

**Claude's behavior:**
```
[Skill activates: evaluates request]
[Decision: NO library mentioned, algorithmic knowledge]
[Skip Context7 entirely]
[Use training knowledge directly]

# Bubble sort - algorithmic concept, no library needed
def bubble_sort(arr):
    """
    Sorts array using bubble sort algorithm.
    Time complexity: O(n²), Space complexity: O(1)
    """
    n = len(arr)
    for i in range(n):
        swapped = False
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
                swapped = True
        if not swapped:
            break
    return arr
```

**Benefits:**
- Faster response (no unnecessary tool calls)
- Token efficiency
- Direct answer from training knowledge

---

## Example 4: Pydantic Version Awareness (Critical!)

### User Request
```
"Create a pydantic model for validating user data"
```

### WITHOUT Context7 Skill

**Claude's behavior:**
```python
# Might mix v1 and v2 patterns (broken code!)
from pydantic import BaseModel, validator

class User(BaseModel):
    name: str
    email: str
    age: int
    
    # v1 pattern - won't work in v2!
    @validator('email')
    def validate_email(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email')
        return v
    
    class Config:  # v1 pattern
        validate_assignment = True
```

**Issues:**
- Mixes v1 and v2 syntax
- @validator decorator doesn't exist in pydantic v2
- Config class moved to model_config in v2
- Code will break depending on version

### WITH Context7 Skill

**Claude's behavior:**
```
[Skill activates: detects "pydantic"]
[CRITICAL: Check requirements.txt or environment for version]
[Version detected: pydantic 2.x]
[Fetch v2-specific documentation]

# Pydantic v2 patterns (current)
from pydantic import BaseModel, EmailStr, field_validator, ConfigDict
from typing import Annotated

class User(BaseModel):
    # v2: Use ConfigDict instead of Config class
    model_config = ConfigDict(validate_assignment=True)
    
    name: str
    email: EmailStr  # Built-in email validation
    age: Annotated[int, Field(ge=0, le=150)]
    
    # v2: Use @field_validator instead of @validator
    @field_validator('name')
    @classmethod
    def name_must_not_be_empty(cls, v: str) -> str:
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v.strip()

# Usage
user = User(
    name="Alice",
    email="alice@example.com",
    age=30
)
```

**Benefits:**
- Correct v2 syntax (@field_validator, not @validator)
- Uses ConfigDict instead of Config class
- Modern type hints with Annotated
- Code actually works!

**If pydantic v1 detected:**
```python
# Pydantic v1 patterns (legacy)
from pydantic import BaseModel, EmailStr, validator

class User(BaseModel):
    name: str
    email: EmailStr
    age: int
    
    # v1: @validator decorator
    @validator('name')
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Name cannot be empty')
        return v.strip()
    
    # v1: Config class
    class Config:
        validate_assignment = True
```

**Why this matters:**
- pydantic v1 → v2 is one of the biggest breaking changes in Python ecosystem
- Claude Code often generates mixed patterns without Context7
- Context7 skill ensures version-appropriate code

---

## Example 5: Knowing When NOT to Use Context7

### User Request
```
"Process this CSV with pandas, handling the new nullable integer types"
```

### WITHOUT Context7 Skill

**Claude's behavior:**
```python
# Might use pandas 1.x patterns (outdated)
import pandas as pd

df = pd.read_csv('data.csv')

# Old approach: convert to float (loses type info)
df['age'] = df['age'].astype(float)  # NaN for missing
```

**Issues:**
- Doesn't know about pandas 2.x nullable integers
- Uses deprecated patterns
- Loses type information

### WITH Context7 Skill

**Claude's behavior:**
```
[Skill activates: detects "pandas" + version-specific feature]
[Check: pandas version in requirements.txt or environment]
[Fetch: pandas 2.x nullable integer documentation]

# Using pandas 2.x nullable integer types
import pandas as pd

# Modern approach with nullable integers
df = pd.read_csv('data.csv', dtype_backend='numpy_nullable')

# Or explicit nullable integer dtype
df = pd.read_csv(
    'data.csv',
    dtype={'age': 'Int64'}  # Capital I = nullable integer
)

# Benefits:
# - Preserves integer type even with missing values
# - pd.NA (not NaN) for missing integers
# - Better type safety and performance
```

**Benefits:**
- Uses current pandas 2.x features
- Proper nullable integer handling
- Type-safe approach

---

## Example 6: Error Recovery

### User Request
```
"Use Tanstack Query (React Query) for data fetching in Next.js"
```

### WITHOUT Context7 Skill

**Claude's behavior:**
```
[Tries: resolve-library-id("React Query")]
[Result: Not found (old name)]
[Gives up: "Documentation not available"]
```

### WITH Context7 Skill

**Claude's behavior:**
```
[Skill activates: detects library name]
[Try 1: resolve-library-id("React Query")]
[Result: Not found]
[Skill guidance: Try alternative name "Tanstack Query"]
[Try 2: resolve-library-id("tanstack-query")]
[Result: Found! ID = "tanstack/query"]
[Fetch docs and generate current code]

// Using Tanstack Query v5 with Next.js App Router
'use client';

import { useQuery } from '@tanstack/react-query';

export default function UserProfile({ userId }) {
  const { data, isLoading, error } = useQuery({
    queryKey: ['user', userId],
    queryFn: async () => {
      const response = await fetch(`/api/users/${userId}`);
      if (!response.ok) throw new Error('Failed to fetch');
      return response.json();
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  
  return <div>{data.name}</div>;
}
```

**Benefits:**
- Intelligent retry with alternate names
- Finds renamed libraries
- Graceful fallback when needed
- Uses current v5 API patterns

---

## Example 7: HRDAG-Specific Workflow

### User Request
```
"Load a large CSV into PostgreSQL efficiently with psycopg2"
```

### WITHOUT Context7 Skill

**Claude's behavior:**
```python
# Might use row-by-row insertion (slow)
import psycopg2
import csv

conn = psycopg2.connect("postgresql://...")
cursor = conn.cursor()

with open('data.csv', 'r') as f:
    reader = csv.reader(f)
    next(reader)  # Skip header
    for row in reader:
        cursor.execute(
            "INSERT INTO data VALUES (%s, %s, %s)",
            row
        )
conn.commit()
```

**Issues:**
- Extremely slow for large files
- No use of COPY command
- Inefficient for HRDAG-scale data

### WITH Context7 Skill

**Claude's behavior:**
```
[Skill activates: detects "PostgreSQL" + "large CSV" + "efficiently"]
[Context: HRDAG workflows often involve bulk loading]
[Fetch: psycopg2 COPY command documentation]

# Efficient bulk loading with COPY command
import psycopg2
import io
import csv

conn = psycopg2.connect("postgresql://...")
cursor = conn.cursor()

# Read CSV into memory buffer
with open('data.csv', 'r') as f:
    # Skip header, keep for column mapping
    reader = csv.reader(f)
    header = next(reader)
    
    # Create StringIO buffer
    buffer = io.StringIO()
    writer = csv.writer(buffer)
    
    # Write remaining rows
    for row in reader:
        writer.writerow(row)
    
    # Reset buffer position
    buffer.seek(0)
    
    # Use COPY for bulk insert (100x faster than INSERT)
    cursor.copy_expert(
        f"""
        COPY data ({','.join(header)})
        FROM STDIN WITH CSV
        """,
        buffer
    )

conn.commit()
conn.close()

# For truly large files (> memory), use copy_from with file object directly
```

**Benefits:**
- 100x+ faster than row-by-row
- Proper use of PostgreSQL COPY
- Memory-efficient approach
- HRDAG-appropriate scale handling

---

## Summary: What the Skill Provides

### Intelligence Layer
- **When**: Knows when Context7 is needed vs. training knowledge
- **How**: Efficient fetching strategies (lazy, specific queries)
- **Why**: Clear reasoning about tool invocation

### Token Efficiency
- **Before**: Might bulk-fetch or waste tokens on irrelevant calls
- **After**: Targeted, just-in-time documentation fetching

### Code Quality
- **Before**: Mix of current and outdated patterns
- **After**: Consistently current, version-aware code

### Error Recovery
- **Before**: Gives up when library not found
- **After**: Intelligent retry with alternatives, graceful fallbacks

### Workflow Integration
- **Before**: Context7 as isolated tool
- **After**: Context7 integrated with testing, docs, debugging workflows

---

## Token Cost Comparison

| Scenario | Without Skill | With Skill | Savings |
|----------|--------------|------------|---------|
| Algorithm question | 500 (wasted call) | 0 (skipped) | 500 tokens |
| Single library | 1000 (works) | 1000 (works) | 0 tokens |
| Multiple libs (bulk) | 3000 (all upfront) | 1500 (lazy) | 1500 tokens |
| Error/retry | 2000 (gives up) | 1500 (smart retry) | Better outcome |

**Skill overhead**: ~50 tokens until loaded, ~1200 when active
**Break-even**: After 1-2 smart invocations per session
