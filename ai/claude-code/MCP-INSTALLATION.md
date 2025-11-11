<!--
Author: PB and Claude
Date: Thu 07 Nov 2025
License: (c) HRDAG, 2025, GPL-2 or newer

------
dotfiles/ai/claude-code/MCP-INSTALLATION.md
-->

# MCP Server Installation Guide

Instructions for installing and configuring Model Context Protocol (MCP) servers for Claude Code.

**Note**: This documentation is based on successful installations from memory system. Some sections may need verification on new machines.

---

## Prerequisites

- **Claude Code CLI**: Installed and working
- **Python 3.10+**: For tree-sitter MCP
- **Node.js/npm**: For context7 and other npm-based MCPs
- **npx**: Comes with npm, used for repomix

Verify prerequisites:
```bash
python3 --version  # Should be 3.10 or higher
node --version     # Should be recent LTS
npm --version
npx --version
```

---

## Installation Instructions

### 1. Tree-sitter MCP

**Purpose**: AST-based code analysis for multi-language support (Python, JS, TS, Go, Rust, C, C++, etc.)

**Installation**:
```bash
# Install globally via pip
pip install mcp-server-tree-sitter

# Add to Claude Code with user scope (available globally)
claude mcp add --scope user tree_sitter python -- -m mcp_server_tree_sitter.server

# Verify installation
claude mcp list
# Should show: tree_sitter: python -m mcp_server_tree_sitter.server - ✓ Connected
```

**Key Features**:
- Multi-language AST analysis
- Parse tree caching for performance
- Context-aware code exploration
- Pattern search with tree-sitter queries

**Alternative installation** (development version):
```bash
pip install -e "git+https://github.com/wrale/mcp-server-tree-sitter.git#egg=mcp-server-tree-sitter[dev,languages]"
```

---

### 2. Repomix MCP

**Purpose**: Codebase analysis and consolidation for AI-optimized code understanding

**Installation**:
```bash
# Add to Claude Code (npx will handle installation automatically)
claude mcp add --scope user repomix npx repomix -- --mcp

# Verify installation
claude mcp list
# Should show: repomix: npx repomix --mcp - ✓ Connected
```

**Important Notes**:
- The `--` separator is crucial: it passes `--mcp` to repomix, not to claude command
- Use `--scope user` for global availability across all projects
- No separate `npm install` needed - npx handles it

**Key Features**:
- Pack entire codebases into single AI-optimized files
- Support for multiple output formats (XML, Markdown, JSON, Plain)
- Security scanning for credentials
- Tree-sitter compression for token efficiency
- GitHub repository analysis

---

### 3. Context7 MCP

**Purpose**: Documentation search for current framework/library docs

**Installation** (needs verification):
```bash
# Install globally via npm
npm install -g @modelcontextprotocol/server-context7

# Add to Claude Code
claude mcp add --scope user context7 npx -- @modelcontextprotocol/server-context7

# Verify installation
claude mcp list
# Should show: context7: npx @modelcontextprotocol/server-context7 - ✓ Connected
```

**Note**: This approach is based on older documentation and may need adjustment. If it fails, check:
- Latest context7 installation instructions
- Whether package name or command has changed
- Alternative installation methods

**Key Features**:
- Resolve library IDs for documentation lookup
- Fetch up-to-date library documentation
- Version-specific documentation support

---

## Verification

After installing all MCPs, verify they're connected:

```bash
claude mcp list
```

Expected output should show all servers with ✓ Connected status:
```
tree_sitter: python -m mcp_server_tree_sitter.server - ✓ Connected
repomix: npx repomix --mcp - ✓ Connected
context7: npx @modelcontextprotocol/server-context7 - ✓ Connected
```

---

## Troubleshooting

### MCP Not Showing as Connected

1. **Check installation scope**:
   ```bash
   claude mcp list
   ```
   If not listed, reinstall with `--scope user`

2. **Verify prerequisites installed**:
   - tree-sitter: `python3 -c "import mcp_server_tree_sitter"`
   - context7: `npm list -g @modelcontextprotocol/server-context7`

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

## Additional MCPs (Documentation Needed)

The following MCPs are configured on the current machine but installation instructions need to be documented:

### Postgres-mcp
- **Status**: Connected and working
- **Purpose**: PostgreSQL database analysis and optimization
- **Documentation needed**: Installation steps, configuration requirements

### Claude-mem (Memory MCP)
- **Status**: Connected and working
- **Purpose**: Persistent memory storage across Claude sessions
- **Location**: Custom MCP from `~/projects/claude-mem`
- **Configuration**: `~/.config/claude-mem/claude-mem.toml` (not version controlled)
- **Backend**: PostgreSQL with pgvector for semantic search
- **Documentation needed**:
  - Installation steps
  - Configuration file setup
  - Database requirements (PostgreSQL with pgvector)

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

---

## Related Documentation

- **Skills Installation**: `~/dotfiles/ai/claude-code/README.md`
- **Skills Overview**: `~/.claude/skills/README.md`
- **Meta Guidelines**: `~/dotfiles/ai/docs/meta-CLAUDE.md`

---

## Contributing

If you discover installation steps for postgres-mcp or claude-mem, or if you find issues with the context7 installation, please update this document and commit to the dotfiles repository.
