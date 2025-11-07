<!--
Author: PB and Claude
Date: 2025-11-07
License: (c) HRDAG, 2025, GPL-2 or newer

------
dotfiles/ai/claude-code/README.md
-->

# Claude Code Configuration

Consolidated, version-controlled Claude Code setup with symlink-based deployment.

## Purpose

This directory contains all Claude Code configuration for easy replication across multiple development machines. The configuration is tracked in git, and system locations point to this directory via symlinks.

## Structure

```
~/dotfiles/ai/claude-code/
├── README.md                   # This file
├── install.sh                  # Bootstrap/installation script
├── skills/                     # Custom skills (version controlled)
│   ├── README.md
│   ├── memory-augmented-dev/
│   ├── context7/
│   ├── code-change-approval/
│   ├── code-explore/
│   ├── commit/
│   ├── postgres-optimization/
│   └── new-file/
└── commands/                   # Custom commands (for future use)
    └── .gitkeep

# Symlinks to expected system locations:
~/.claude/skills/ -> ~/dotfiles/ai/claude-code/skills/
~/.claude/command/ -> ~/dotfiles/ai/claude-code/commands/

# NOT symlinked (manual per-machine):
~/.config/claude-mem/claude-mem.toml
```

## Shared Documentation

Meta development guidelines are shared across all AI tools:
- **Location**: `~/dotfiles/ai/docs/meta-CLAUDE.md`
- **Purpose**: Common behavioral instructions for all AI agents

## Installation

### First Machine (Initial Setup)

This has already been done on the current machine:

```bash
cd ~/dotfiles/ai/claude-code
./install.sh
```

The script will:
1. Verify prerequisites (git, Python 3.11+, required tools)
2. Create timestamped backup of existing configuration
3. Create symlinks from system locations to dotfiles
4. Validate configuration file
5. Report installation status

After installation, commit to git:
```bash
cd ~/dotfiles
git add ai/claude-code
git commit -m "Add consolidated Claude Code configuration

By PB & Claude"
```

### New Machines

To replicate the setup on a new machine:

1. **Clone dotfiles repository** (if not already done):
   ```bash
   git clone git@github.com:vm-wylbur/pb-dotfiles.git ~/dotfiles
   ```

2. **Run installation script**:
   ```bash
   cd ~/dotfiles/ai/claude-code
   ./install.sh
   ```

3. **Copy configuration file** from the original machine:
   ```bash
   # On original machine:
   scp ~/.config/claude-mem/claude-mem.toml newmachine:~/.config/claude-mem/

   # Or manually copy the file
   ```

   **IMPORTANT**: The `claude-mem.toml` file contains credentials and is NOT version controlled. You must manually copy this file to each new machine.

4. **Verify installation**:
   ```bash
   cd ~/dotfiles/ai/claude-code
   ./install.sh
   # Choose option 1: Verify installation
   ```

## Configuration File (claude-mem.toml)

### Location
`~/.config/claude-mem/claude-mem.toml`

### Why Not Version Controlled?

This file contains sensitive credentials:
- PostgreSQL database password
- Connection strings
- API endpoints

**Never commit this file to git.**

### Required Structure

The configuration file must contain these sections:

```toml
[database]
type = "postgresql"

[database.postgresql]
hosts = ["..."]
port = 24030
database = "..."
user = "..."
password = "..."  # ← Credentials!
sslmode = "require"

[ollama]
host = "http://localhost:11434"
model = "nomic-embed-text"

[server]
name = "memory-server-pg"
version = "0.1.0"

[logging]
level = "info"
file = "~/.local/share/mcp-memory/logs/memory-server.log"

[features]
vector_search = true
metadata_indexing = true
relationship_tracking = true
auto_embedding = true
```

The `install.sh` script validates this structure and will report any missing sections or keys.

### Permissions

For security, the config file should have restricted permissions:

```bash
chmod 600 ~/.config/claude-mem/claude-mem.toml
```

The installation script will warn if permissions are too permissive.

## Updating Configuration

### Updating Skills

Skills are version controlled. To update:

```bash
cd ~/dotfiles/ai/claude-code/skills
# Edit skill files as needed
git add skills/
git commit -m "Update Claude Code skills"
git push
```

On other machines:
```bash
cd ~/dotfiles
git pull
# Changes immediately available via symlinks
```

### Updating Commands

Same process as skills. Add new commands to `commands/` directory.

## Troubleshooting

### Symlinks Not Working

Verify symlinks are correct:
```bash
ls -la ~/.claude/skills
ls -la ~/.claude/command
```

Should show:
```
~/.claude/skills -> /home/pball/dotfiles/ai/claude-code/skills
~/.claude/command -> /home/pball/dotfiles/ai/claude-code/commands
```

Re-run installation if needed:
```bash
cd ~/dotfiles/ai/claude-code
./install.sh
```

### Config Validation Errors

Run validation:
```bash
cd ~/dotfiles/ai/claude-code
./install.sh
# Choose option 1: Verify installation
```

Common issues:
- **File missing**: Copy from another machine
- **Invalid TOML**: Check syntax with a TOML validator
- **Missing keys**: Compare with structure above
- **Bad permissions**: Run `chmod 600 ~/.config/claude-mem/claude-mem.toml`

### Claude Code Can't Find Skills

Check that symlinks exist and point to correct location:
```bash
readlink -f ~/.claude/skills
# Should output: /home/pball/dotfiles/ai/claude-code/skills
```

If wrong or missing, re-run `install.sh`.

### Installation Script Fails

Check the log file:
```bash
cat ~/dotfiles/ai/claude-code/install.log
```

Common issues:
- Python < 3.11 (tomllib not available)
- Not in git repository
- Missing required tools

## Backup and Recovery

### Backups

The installation script creates timestamped backups:
```
~/claude-code-backup-YYYYMMDD-HHMMSS/
├── skills/         # Original skills directory
└── backup.log      # Backup manifest
```

Backups are created before any destructive operations.

### Recovery

To restore from backup:
```bash
# Remove symlinks
rm ~/.claude/skills
rm ~/.claude/command

# Restore from backup
cp -r ~/claude-code-backup-YYYYMMDD-HHMMSS/skills ~/.claude/
```

## Related Documentation

- **Meta Guidelines**: `~/dotfiles/ai/docs/meta-CLAUDE.md` - Shared AI agent guidelines
- **Multi-AI Workflow**: `~/dotfiles/ai/docs/multi-ai-workflow.md`
- **Installation Log**: `~/dotfiles/ai/claude-code/install.log`

## Support

For issues or questions:
- Check troubleshooting section above
- Review installation log: `~/dotfiles/ai/claude-code/install.log`
- Check git repository status: `cd ~/dotfiles && git status`
