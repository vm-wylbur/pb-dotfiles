<!--
Author: PB and Claude
Date: 2025-12-29
License: (c) HRDAG, 2025, GPL-2 or newer

------
dotfiles/ai/claude-code/MCP-INSTALLATION.md
-->

# MCP Server Installation Guide

Instructions for installing and configuring Model Context Protocol (MCP) servers for Claude Code.

We maintain a minimal set of 3 MCPs that provide unique value not covered by Claude Code's native tools:

| MCP | Purpose | Why Keep |
|-----|---------|----------|
| **claude-mem** | Persistent memory with semantic search | Cross-session context, PostgreSQL-backed |
| **tree_sitter** | AST-based code analysis | Multi-language symbol extraction, precise queries |
| **repomix** | Codebase packaging for AI | Pack entire repos, grep search, token-aware |

**Removed** (redundant with Claude Code native tools):
- filesystem → Native Read/Write/Edit/Glob
- claude-todo → Native TodoWrite
- sequential-thinking → Native reasoning
- perplexity → Native WebSearch
- context7 → Native WebSearch (for library docs)
- zen → External model calls (adds cost/complexity)

---

## Prerequisites

- **Claude Code CLI**: Installed and working
- **Python 3.10+**: For tree-sitter MCP (via uv)
- **Node.js/npm**: For repomix
- **PostgreSQL with pgvector**: For claude-mem

```bash
python3 --version  # 3.10+
node --version     # Recent LTS
uv --version       # For tree-sitter
```

---

## Installation

### 1. Tree-sitter MCP

**Purpose**: AST-based code analysis for multi-language support

<<<<<<< HEAD
```bash
# Uses uv tool run (isolated, no global install)
claude mcp add --scope user tree_sitter uv -- tool run mcp-server-tree-sitter
```

=======
**Installation** (Recommended - uses isolated venv):
```bash
# Create isolated venv for MCP
python3 -m venv ~/.venv-mcp

# Install tree-sitter MCP in venv
~/.venv-mcp/bin/pip install mcp-server-tree-sitter

# Add to Claude Code
claude mcp add --scope user tree_sitter ~/.venv-mcp/bin/python -- -m mcp_server_tree_sitter.server

# Verify installation
claude mcp list
# Should show: tree_sitter: /home/pball/.venv-mcp/bin/python -m mcp_server_tree_sitter.server - ✓ Connected
```

**Why venv?**
- Creates isolated environment (no global pip install)
- Works consistently across all project directories
- Avoids conflicts with project-specific virtual environments
- Better practice than installing into system Python
- More reliable than uvx for Python 3.12+

>>>>>>> c17b49b (Update MCP installation docs: remove context7, add claude-mem)
**Key Features**:
- Multi-language AST analysis (Python, JS, TS, Go, Rust, etc.)
- Symbol extraction (functions, classes, imports)
- Pattern search with tree-sitter queries
<<<<<<< HEAD
- Parse tree caching for performance
=======

**Note on uvx**:
The documentation originally recommended `uvx` but it has compatibility issues with Python 3.14+. The venv approach above is more reliable.
>>>>>>> c17b49b (Update MCP installation docs: remove context7, add claude-mem)

---

### 2. Repomix MCP

**Purpose**: Codebase consolidation for AI-optimized analysis

```bash
claude mcp add --scope user repomix npx repomix -- --mcp
```

**Key Features**:
- Pack entire codebases into single AI-optimized files
- Multiple output formats (XML, Markdown, JSON)
- Security scanning for credentials
- Tree-sitter compression for token efficiency

---

<<<<<<< HEAD
### 3. Claude-mem MCP

**Purpose**: Persistent memory storage with semantic search

**Prerequisites**:
- PostgreSQL database with pgvector extension
- Config file at `~/.config/claude-mem/claude-mem.toml`

```bash
# Build from source (custom MCP)
cd ~/projects/personal/claude-mem
npm install && npm run build

# Add to Claude Code
claude mcp add --scope user claude-mem node -- ~/projects/personal/claude-mem/dist/index.js
```

**Configuration** (`~/.config/claude-mem/claude-mem.toml`):
```toml
[database]
type = "postgresql"

[database.postgresql]
hosts = ["localhost"]
port = 5432
database = "claude_mem"
user = "your_user"
password = "your_password"
sslmode = "prefer"

[ollama]
host = "http://localhost:11434"
model = "nomic-embed-text"

[server]
name = "claude-mem"
version = "1.0.0"

[logging]
level = "info"
file = "/tmp/claude-mem.log"

[features]
```

**Note**: This config file contains credentials and is NOT version controlled.
=======
### 3. Claude-mem (Memory MCP)

**Purpose**: Persistent memory storage across Claude sessions with PostgreSQL backend and semantic search

**Prerequisites**:
- PostgreSQL database with pgvector extension
- Configuration file at `~/.config/claude-mem/claude-mem.toml`

**Installation**:
```bash
# Clone/access the project
cd ~/projects/claude-mem

# Build the project
npm run build

# Add to Claude Code
claude mcp add --scope user claude-mem node /home/pball/projects/claude-mem/dist/index.js

# Verify installation
claude mcp list
# Should show: claude-mem: node /home/pball/projects/claude-mem/dist/index.js - ✓ Connected
```

**Configuration**:
- Create `~/.config/claude-mem/claude-mem.toml` based on `claude-mem.toml.example` in the project
- Configure PostgreSQL connection details
- See `~/projects/claude-mem/DATABASE_CONFIG.md` for database setup

**Key Features**:
- Persistent memory across sessions
- Semantic search using pgvector
- Long-term context storage for LLMs
- MCP protocol integration
>>>>>>> c17b49b (Update MCP installation docs: remove context7, add claude-mem)

---

## Verification

```bash
claude mcp list
```

Expected output:
```
<<<<<<< HEAD
repomix: npx repomix --mcp - ✓ Connected
tree_sitter: uv tool run mcp-server-tree-sitter - ✓ Connected
claude-mem: node ~/projects/personal/claude-mem/dist/index.js - ✓ Connected
=======
tree_sitter: /home/pball/.venv-mcp/bin/python -m mcp_server_tree_sitter.server - ✓ Connected
repomix: npx repomix --mcp - ✓ Connected
claude-mem: node /home/pball/projects/claude-mem/dist/index.js - ✓ Connected
>>>>>>> c17b49b (Update MCP installation docs: remove context7, add claude-mem)
```

---

## Troubleshooting

### MCP Not Showing as Connected

1. Check scope: `claude mcp list`
2. Remove and re-add: `claude mcp remove <name> -s user && claude mcp add --scope user ...`

<<<<<<< HEAD
### Claude-mem Database Connection

1. Verify PostgreSQL is running: `pg_isready`
2. Check config permissions: `chmod 600 ~/.config/claude-mem/claude-mem.toml`
3. Test connection manually with psql
=======
2. **Verify prerequisites installed**:
   - tree-sitter: `~/.venv-mcp/bin/python -c "import mcp_server_tree_sitter"`
   - claude-mem: Check `~/projects/claude-mem/dist/index.js` exists

3. **Remove and re-add**:
   ```bash
   claude mcp remove <server-name> -s user
   claude mcp add --scope user <server-name> <command>
   ```

### Local Settings Override Global

If MCPs work in some directories but not others:
- Local `.claude/settings.local.json` files may override user scope
- Solution: Use `--scope user` to ensure global availability
- Configuration hierarchy: local > project > user scope

### Python Module Not Found (tree-sitter)

```bash
# Verify pip installation
pip list | grep mcp-server-tree-sitter

# If missing, reinstall
pip install --upgrade mcp-server-tree-sitter
```

---

## Additional MCPs (Optional)

### Postgres-mcp
- **Status**: Available but not documented in this guide
- **Purpose**: PostgreSQL database analysis and optimization
- **Note**: Installation instructions to be added if needed

---

## Scope Explanation

**User Scope** (`--scope user`):
- Available globally across all projects
- Recommended for most MCPs
- Overrides local directory-specific settings

**Local Scope** (`--scope local`):
- Directory-specific
- Can override user scope
- Useful for project-specific configurations

**Project Scope** (`--scope project`):
- Project-level configuration
- Middle ground between user and local

**Recommendation**: Use `--scope user` for all general-purpose MCPs unless you have specific project-level needs.
>>>>>>> c17b49b (Update MCP installation docs: remove context7, add claude-mem)

---

## Related Documentation

- **Skills Installation**: `~/dotfiles/ai/claude-code/README.md`
- **Skills Overview**: `~/.claude/skills/README.md`
- **Meta Guidelines**: `~/dotfiles/ai/docs/meta-CLAUDE.md`
<<<<<<< HEAD
=======

---

## Contributing

If you discover installation steps for postgres-mcp or encounter issues with any MCP installation, please update this document and commit to the dotfiles repository.
>>>>>>> c17b49b (Update MCP installation docs: remove context7, add claude-mem)
