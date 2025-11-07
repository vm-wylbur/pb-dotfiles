Execute the 'refresh' skill in light mode:

- Check ~/.claude/CLAUDE.md last modified date using: `stat -c '%y' ~/.claude/CLAUDE.md | cut -d' ' -f1`
- List ALL skills available in this Claude instance (introspection - check what skills you actually have)
- List ALL MCP servers accessible to this instance (introspection - check ListMcpResourcesTool or similar to get complete list of ALL connected servers, don't miss any)
- Report current working directory: `pwd`

Output in structured format:
```
Context loaded
├─ Guidelines (YYYY-MM-DD)
├─ Skills: N - name, name, name
├─ MCPs: N - server, server, server (list ALL)
└─ Working in: /path
```

Execute these steps now. Be thorough - report EVERY skill and EVERY MCP server you have access to.
