Scan filesystem for markdown documentation files and ingest them into the lessons_learned_docs database table.

Use the `mcp__claude-mem__sync-docs` tool with default parameters to:
- Find all *.md files in ~/docs and current-project/docs directories
- Detect new files and updated files (via content hash comparison)
- Ingest only new/changed documents (efficient)
- Report summary of what was ingested

Execute the tool now.
