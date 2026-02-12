<!--
Author: PB and Claude
Date: 2026-02-12
License: (c) HRDAG, 2025, GPL-2 or newer

------
dotfiles/ai/claude-code/MCP-INSTALLATION.md
-->

# MCP Server Installation Guide

3 MCPs that provide unique value not covered by Claude Code's native tools:

| MCP | Purpose | Why Keep |
|-----|---------|----------|
| **claude-mem** | Persistent memory with semantic search | Cross-session context, PostgreSQL+pgvector on snowball |
| **tree_sitter** | AST-based code analysis | Multi-language symbol extraction, precise queries |
| **repomix** | Codebase packaging for AI | Pack entire repos, grep search, token-aware |

**Removed** (redundant with Claude Code native tools):
- filesystem → Native Read/Write/Edit/Glob
- context7 → Low value for infra/Python work
- claude-todo → Native TodoWrite
- sequential-thinking → Native reasoning
- perplexity → Prohibited (prompt injection risk)
- zen → External model calls (adds cost/complexity)

---

## Prerequisites

- **Claude Code CLI**: Installed and working
- **Python 3.10+**: For tree-sitter MCP (via uv)
- **Node.js/npm**: For repomix and claude-mem
- **PostgreSQL with pgvector**: For claude-mem (on snowball via Tailscale)

---

## Installation

### 1. Tree-sitter MCP

```bash
claude mcp add --scope user tree_sitter uv -- tool run mcp-server-tree-sitter
```

### 2. Repomix MCP

```bash
claude mcp add --scope user repomix npx repomix -- --mcp
```

### 3. Claude-mem MCP

```bash
cd ~/projects/personal/claude-mem
npm install && npm run build
claude mcp add --scope user claude-mem node -- ~/projects/personal/claude-mem/dist/index.js
```

**Config** at `~/.config/claude-mem/claude-mem.toml` (not version controlled, contains credentials).

---

## Verification

```bash
claude mcp list
```

Expected:
```
tree_sitter: uv tool run mcp-server-tree-sitter - ✓ Connected
repomix: npx repomix --mcp - ✓ Connected
claude-mem: node ~/projects/personal/claude-mem/dist/index.js - ✓ Connected
```

Also present: `plugin:oh-my-claudecode:t` (OMC plugin, auto-managed).

---

## Troubleshooting

- **MCP not connected**: `claude mcp remove <name> -s user && claude mcp add --scope user ...`
- **claude-mem DB**: `psql -h snowball.hrdag.net -U pball -d claude_mem -c 'SELECT count(*) FROM memories'`
- **claude-mem config**: `chmod 600 ~/.config/claude-mem/claude-mem.toml`
