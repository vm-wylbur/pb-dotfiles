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

```bash
# Uses uv tool run (isolated, no global install)
claude mcp add --scope user tree_sitter uv -- tool run mcp-server-tree-sitter
```

**Key Features**:
- Multi-language AST analysis (Python, JS, TS, Go, Rust, etc.)
- Symbol extraction (functions, classes, imports)
- Pattern search with tree-sitter queries
- Parse tree caching for performance

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

---

## Verification

```bash
claude mcp list
```

Expected output:
```
repomix: npx repomix --mcp - ✓ Connected
tree_sitter: uv tool run mcp-server-tree-sitter - ✓ Connected
claude-mem: node ~/projects/personal/claude-mem/dist/index.js - ✓ Connected
```

---

## Troubleshooting

### MCP Not Showing as Connected

1. Check scope: `claude mcp list`
2. Remove and re-add: `claude mcp remove <name> -s user && claude mcp add --scope user ...`

### Claude-mem Database Connection

1. Verify PostgreSQL is running: `pg_isready`
2. Check config permissions: `chmod 600 ~/.config/claude-mem/claude-mem.toml`
3. Test connection manually with psql

---

## Related Documentation

- **Skills Installation**: `~/dotfiles/ai/claude-code/README.md`
- **Skills Overview**: `~/.claude/skills/README.md`
- **Meta Guidelines**: `~/dotfiles/ai/docs/meta-CLAUDE.md`
