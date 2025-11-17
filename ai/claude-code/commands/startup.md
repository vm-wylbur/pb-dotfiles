# STARTUP 

Use the memory system to remember the memory overview and remember and run the startup protocol. If the memory system is not available, raise a warning to the user and stop. 

Start by understanding what I'm currently working on, ask if the project is not clear, then use repomix, treesitter, and perplexity (if available) to understand that project. Use the claude-todo MCP to understand what's going on. Ask questions! 

---

## ENHANCED STARTUP PROTOCOL (Target: ~3 minutes)

### 🛠️ MANDATORY MCP TOOL USAGE
**USE THESE MCP TOOLS (NOT BASIC COMMANDS):**
- **repomix**: `mcp__repomix__pack_codebase` - Superior to grep/find for codebase analysis
- **treesitter**: `mcp__tree_sitter__*` - Semantic code analysis (30+ languages)
- **perplexity**: `mcp__perplexity__perplexity_search_web` - Web search when available
- **claude-todo**: `mcp__claude-todo__*` - Task discovery and tracking
- **filesystem**: `mcp__filesystem__*` - File operations when needed

### 1. Foundation Setup (30s)
**🧠 MEMORY & META**
1. **Use memory system** for startup protocol (primary)
2. **Read meta-CLAUDE.md** via `mcp__filesystem__read_file`
3. **Warn and continue** if memory offline

**📁 PROJECT IDENTIFICATION**  
1. **Use `mcp__filesystem__directory_tree`** - analyze project structure
2. **If ambiguous**: Show detected projects list, ASK USER which one
3. **Read CLAUDE.md** via `mcp__filesystem__read_file` (project-specific)
4. **Use `mcp__repomix__pack_codebase`** to identify project type

### 2. Project Health & Context (90s)
**🔍 PROJECT HEALTH CHECK**
1. **Git status** - use bash for git commands
2. **Read last 3-5 commit messages** (+ diffs if Claude thinks useful)
3. **Use `mcp__repomix__pack_codebase`** - get comprehensive project overview
4. **Find build/test commands** from repomix analysis
5. **Add failing tests to todos** (don't gate on them)

**✅ TODO SYSTEM INTEGRATION**
1. **Use `mcp__claude-todo__analyze-codebase-todos`** (files + code TODOs)
2. **Review existing TodoRead** if any todos active
3. **Create TodoWrite** for this session's work

### 3. Code Understanding & Validation (60s)
**🎯 SEMANTIC CODE ANALYSIS**
1. **Use `mcp__tree_sitter__register_project_tool`** - register current project
2. **Use `mcp__tree_sitter__analyze_project`** - semantic understanding
3. **Use `mcp__perplexity__perplexity_search_web`** for external context (if needed)
4. **ASK QUESTIONS** when making assumptions about tools
5. **Verify understanding** with user before proceeding
6. **Confirm current goal** - what are we achieving today?

### ⚠️ CRITICAL CONSTRAINTS
- **Git commits**: ONLY use format "Brief title\n\nBy PB & Claude"
- **File creation**: NEVER create unless absolutely necessary
- **Documentation**: NEVER create .md/README unless explicitly requested
- **Search strategy**: Use MCP tools, NOT grep/find
- **Ask before assumptions**: When you start assuming what a tool should do

### 🎯 KEY MCP BEHAVIORS
- **NEVER use grep/find** → Use `mcp__repomix__*` tools
- **NEVER use basic file reads** → Use `mcp__filesystem__read_file`
- **NEVER use basic searches** → Use `mcp__tree_sitter__find_text`
- **Always use `mcp__claude-todo__*`** for task management
- **Use `mcp__perplexity__*`** for web searches 

### Last notes
- don't leave cruft. don't create temp files or pointless backups. and when you finish with a temporary test or a temporary file, remove it. 
- DO NOT DECLARE VICTORY until automated tests are passing and our actual use case is satisfied. Premature celebration forecloses curiousity about not just if you finished your task -- but if you ACCOMPLISHED your task. 

<!-- done --> 
