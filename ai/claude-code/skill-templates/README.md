# Claude Code Skills

User-level skills that enhance Claude Code workflows with specialized capabilities.

## Installed Skills

### code-change-approval
**Version:** 1.0.0
**Purpose:** Request approval before modifying files and verify changes are necessary
**Source:** Project-level skill

### code-explore
**Version:** 1.1.0
**Purpose:** Systematic codebase exploration using tree-sitter AST analysis and repomix semantic search
**Updates:** v1.1.0 - Added security validation, token awareness, and configuration best practices

**Activation:**
- "Explore codebase", "find all functions", "where is X used", "analyze structure"

**Key Features:**
- Security scanning for credentials in packed outputs
- Token awareness with compression suggestions
- Configuration guidance (.repomixignore, includePatterns)
- Prevents wasteful Glob/Grep/Read iterations

**Core Principle:** NEVER use filesystem tools when tree-sitter or repomix tools are available

### commit
**Version:** 1.0.0
**Purpose:** Git commit workflow with message format enforcement and change review
**Source:** Project-level skill

**Enforces:**
- Commit message format: "By PB & Claude" (no Co-authored-by lines)
- Always ask before committing
- No tool attribution in commits

### memory-augmented-dev
**Version:** 1.0.0
**Purpose:** Development with persistent memory checks and automatic logging
**Source:** claude-mem project

**Activation:**
- "Implement", "build", "fix", "refactor", "add feature"

**Workflow:**
1. **Research**: Search memory for relevant patterns before implementing
2. **Implementation**: Apply established patterns from past work
3. **Documentation**: Store learnings with rich metadata

### new-file
**Version:** 1.0.0
**Purpose:** Create new files with proper headers and verify necessity
**Source:** Project-level skill

### postgres-optimization
**Version:** 1.0.0
**Purpose:** PostgreSQL database optimization combining institutional knowledge with live analysis
**Source:** claude-mem project
**Requires:** postgres-mcp MCP server

**Activation:**
- "Optimize database", "slow query", "performance tuning", "analyze query", "database health"

**Workflow:**
1. **Research**: Search memory for similar optimizations
2. **Analysis**: Use postgres-mcp for live database analysis
3. **Synthesis**: Combine past learnings with current state
4. **Implementation**: Execute with confirmation, verify results
5. **Documentation**: Store optimization learnings

**Key Features:**
- Database health checks (buffer cache, bloat, vacuum)
- Slow query identification (pg_stat_statements)
- Query execution plan analysis
- Automated index recommendations
- Read-only by default, confirmation required for DDL

## Skills Management

### Installation
Skills are installed at user level from various sources:
- Project-specific: From project `.claude/skills/` directories
- claude-mem repository: `~/projects/claude-mem/skills/`
- Custom development: Created locally

### Updates
When a skill is updated:
1. Edit the skill SKILL.md in its source location
2. Copy to `~/.claude/skills/` to activate
3. Update version number and changelog in frontmatter
4. Update this README with changes

### Version History

**2025-11-05**
- code-explore v1.1.0: Added security validation, token awareness, configuration best practices

**2025-11-04**
- postgres-optimization v1.0.0: Initial release with 5-phase optimization workflow

**2025-11-03**
- Initial skill system setup
- commit, code-change-approval, new-file skills added

## Skill Development Guidelines

### Skill Structure
```
skills/skill-name/
├── SKILL.md          # Main skill definition
├── README.md         # Optional: Usage examples
└── references/       # Optional: Supporting docs
```

### SKILL.md Format
```yaml
---
name: skill-name
description: "Brief description with activation keywords"
version: 1.0.0
metadata:
  priority: high|medium|low
  requires: ["optional dependencies"]
  changelog: "Version history"
---

# Skill Title

## Mission
What this skill does and why it exists

## When to Activate
Trigger phrases and conditions

## Workflow
Step-by-step process

## Guardrails
Safety constraints and prohibited actions

## Integration
How this skill works with other tools/skills
```

## Related Documentation

- **MCP Servers:** Configured in `~/.claude.json`
- **Project Skills:** Some projects have `.claude/skills/` directories
- **Memory System:** claude-mem at `~/projects/claude-mem`
- **Skills Source:** claude-mem repo skills at `~/projects/claude-mem/skills/`

## Notes

- Skills are user-wide and available in all Claude Code sessions
- Some skills require specific MCP servers to be installed
- Skills automatically activate based on user requests and keywords
- Skills can integrate with memory system for learning over time
