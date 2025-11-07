# Context7 Skill for Claude Code

An intelligent skill that teaches Claude Code when and how to effectively use the Context7 MCP server for fetching current library documentation.

## What This Skill Does

This skill makes Claude Code smarter about:
- **When** to invoke Context7 (library-specific work) vs when not to (general concepts)
- **How** to use Context7 efficiently (specific queries, token management)
- **Error recovery** when library docs aren't available
- **Integration** with other workflows (testing, document creation, debugging)

## Prerequisites

You must have the Context7 MCP server installed. If you haven't yet:

```bash
# Install Context7 MCP user-wide
claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp

# Optional: with API key for higher rate limits
claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
```

Verify installation:
```bash
claude mcp list
```

## Installation

### Option 1: Manual installation (recommended)

```bash
# Copy the skill directory to your Claude skills folder
cp -r context7-skill ~/.claude/skills/context7

# Or for project-specific:
cp -r context7-skill /path/to/your/project/.claude/skills/context7
```

### Option 2: Via Claude Code

In Claude Code, you can reference the skill directory directly in your project.

## Usage

Once installed, the skill activates automatically when Claude detects library-specific work. You can also explicitly reference it:

```bash
# Claude Code will automatically use Context7 when appropriate
claude "create a Typer CLI with multi-commands and YAML config"

# The skill guides Claude to:
# 1. Detect "Typer" library
# 2. Resolve Context7 ID
# 3. Fetch current Typer config patterns
# 4. Generate up-to-date code
```

## Configuration

### Global auto-invocation (optional)

Add to `~/.claude/CLAUDE.md` to make Context7 always available:

```markdown
Always use Context7 when working with external libraries, frameworks, or APIs.
Automatically invoke Context7 tools to resolve library IDs and fetch documentation
without waiting for explicit requests.
```

### Project-specific rules

Add to `/path/to/project/.claude/CLAUDE.md`:

```markdown
For this project, prioritize Context7 for:
- PostgreSQL/psycopg operations
- Redis/redis-py patterns  
- pandas/numpy data processing
```

## Examples

### Example 1: PostgreSQL connection pooling
```
User: "Set up PostgreSQL connection pooling with psycopg2"

Claude (with skill):
1. Detects library: psycopg2
2. Calls resolve-library-id
3. Fetches pooling docs from Context7
4. Generates current best-practice code with connection pooling

Without skill: Might use outdated patterns or miss version-specific features
```

### Example 2: FastAPI async patterns
```
User: "Create a FastAPI endpoint with async database access"

Claude (with skill):
1. Recognizes FastAPI + async database (likely asyncpg or psycopg3)
2. Fetches docs for both libraries
3. Generates code using current async patterns
4. Avoids deprecated approaches

Without skill: May not know when to invoke Context7, miss opportunities
```

### Example 3: Knowing when NOT to use Context7
```
User: "Explain quicksort algorithm"

Claude (with skill):
- Recognizes this is algorithmic knowledge, not library-specific
- Skips Context7 invocation
- Uses training knowledge directly
- Saves tokens and time

Without skill: Might waste time trying to fetch irrelevant docs
```

## Benefits

### Token efficiency
- Only fetches docs when needed
- Specific queries, not bulk fetching
- Progressive disclosure (skill loads on-demand)

### Better code quality
- Current, version-specific patterns
- Avoids deprecated APIs
- Catches breaking changes

### Faster development
- No manual doc switching
- Proactive documentation fetching
- Smart error recovery

## Customization

The skill can be customized for your workflows. Edit `SKILL.md` to:

1. **Add your common libraries** to the patterns section
2. **Adjust trigger conditions** for your tech stack
3. **Define project-specific rules** for team workflows
4. **Set token budgets** based on your usage patterns

Example customization for HRDAG-style workflows:

```markdown
## HRDAG-Specific Patterns

When working with statistical analysis:
- Always use Context7 for: pandas, psycopg, redis-py
- Check versions especially for: pandas 1.x → 2.x migrations
- Prioritize PostgreSQL-specific features (COPY, JSON, arrays)
```

## Troubleshooting

### Skill not loading
```bash
# Check skill location
ls -la ~/.claude/skills/context7/SKILL.md

# Verify SKILL.md has proper frontmatter
head -5 ~/.claude/skills/context7/SKILL.md
```

### Context7 MCP not responding
```bash
# Check MCP installation
claude mcp list | grep context7

# Reinstall if needed
claude mcp remove context7
claude mcp add context7 --scope user -- npx -y @upstash/context7-mcp
```

### Skill too verbose/quiet
Edit the skill's decision thresholds in SKILL.md to tune behavior.

## License

MIT License - feel free to modify and share.

## Contributing

Suggestions for improvement:
- Additional library patterns
- Better error recovery strategies
- More decision tree examples
- Integration patterns with other skills

## Related Resources

- [Context7 MCP Documentation](https://github.com/upstash/context7)
- [Claude Skills Documentation](https://docs.claude.com/en/docs/agents-and-tools/agent-skills)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
