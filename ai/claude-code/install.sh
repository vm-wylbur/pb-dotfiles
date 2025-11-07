#!/usr/bin/env bash
# Author: PB and Claude
# Date: 2025-01-07
# License: (c) HRDAG, 2025, GPL-2 or newer
#
# ------
# dotfiles/ai/claude-code/install.sh
#
# Claude Code configuration installer
# Creates symlinks from system locations to dotfiles repository

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="$HOME/dotfiles/ai/claude-code/install.log"
BACKUP_LOG="backup.log"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}ERROR: $*${NC}" >&2
    log "ERROR: $*"
}

warn() {
    echo -e "${YELLOW}WARNING: $*${NC}" >&2
    log "WARNING: $*"
}

success() {
    echo -e "${GREEN}✓ $*${NC}"
    log "SUCCESS: $*"
}

info() {
    echo "$*"
    log "INFO: $*"
}

# Pre-flight checks
preflight_checks() {
    info ""
    info "=== Pre-flight Checks ==="

    # Check we're in the right location
    if [ ! -d "$HOME/dotfiles/ai/claude-code" ]; then
        error "Expected directory not found: $HOME/dotfiles/ai/claude-code"
        error "This script must be run after the directory structure is created"
        exit 1
    fi

    # Check if git repository
    if ! git -C "$HOME/dotfiles" rev-parse --git-dir &>/dev/null; then
        error "$HOME/dotfiles is not a git repository"
        exit 1
    fi

    # Check git status
    if [ -n "$(git -C "$HOME/dotfiles" status --porcelain --untracked-files=no)" ]; then
        warn "Git repository has uncommitted changes"
        warn "This is OK, but you may want to commit before proceeding"
    fi

    # Check for required tools
    for tool in python3 ln mkdir cp mv jq; do
        if ! command -v "$tool" &>/dev/null; then
            error "Required tool not found: $tool"
            exit 1
        fi
    done

    # Check Python has TOML support
    if ! python3 -c "import tomllib" 2>/dev/null; then
        error "Python tomllib module not available (requires Python 3.11+)"
        exit 1
    fi

    success "Pre-flight checks passed"
}

# Detect existing installation
detect_existing_installation() {
    local already_installed=false

    if [ -L "$HOME/.claude/skills" ] && [ "$(readlink -f "$HOME/.claude/skills")" = "$HOME/dotfiles/ai/claude-code/skills" ]; then
        info "✓ Skills symlink already exists and is correct"
        already_installed=true
    fi

    if [ -L "$HOME/.claude/command" ] && [ "$(readlink -f "$HOME/.claude/command")" = "$HOME/dotfiles/ai/claude-code/commands" ]; then
        info "✓ Commands symlink already exists and is correct"
        already_installed=true
    fi

    if [ -L "$HOME/.claude/CLAUDE.md" ] && [ "$(readlink -f "$HOME/.claude/CLAUDE.md")" = "$HOME/dotfiles/ai/docs/meta-CLAUDE.md" ]; then
        info "✓ CLAUDE.md symlink already exists and is correct"
        already_installed=true
    fi

    if [ "$already_installed" = true ]; then
        info ""
        info "Installation already exists. Options:"
        info "  1) Verify installation (check symlinks and config)"
        info "  2) Re-run migration (update from system locations)"
        info "  3) Skip and exit"
        read -p "Choice [1/2/3]: " choice
        case $choice in
            1) verify_installation; exit 0 ;;
            2) info "Proceeding with migration..." ;;
            3) info "Exiting."; exit 0 ;;
            *) error "Invalid choice"; exit 1 ;;
        esac
    fi
}

# Create backup
create_backup() {
    local backup_dir="$HOME/claude-code-backup-$(date +%Y%m%d-%H%M%S)"

    info ""
    info "=== Creating Backup ==="

    mkdir -p "$backup_dir"
    log "Created backup directory: $backup_dir"

    # Backup skills if they exist
    if [ -d "$HOME/.claude/skills" ] && [ ! -L "$HOME/.claude/skills" ]; then
        cp -r "$HOME/.claude/skills" "$backup_dir/"
        success "Backed up ~/.claude/skills/ to $backup_dir/"
        echo "skills: $HOME/.claude/skills -> $backup_dir/skills" >> "$backup_dir/$BACKUP_LOG"
    else
        info "No skills directory to backup (or already a symlink)"
    fi

    # Note: We don't backup config (stays in original location)

    echo "$backup_dir"
}

# Create symlinks
create_symlinks() {
    info ""
    info "=== Creating Symlinks ==="

    # Ensure ~/.claude directory exists
    mkdir -p "$HOME/.claude"

    # Skills symlink
    if [ -e "$HOME/.claude/skills" ] && [ ! -L "$HOME/.claude/skills" ]; then
        info "Removing existing ~/.claude/skills/ directory (backed up)"
        rm -rf "$HOME/.claude/skills"
    fi

    if [ ! -L "$HOME/.claude/skills" ]; then
        ln -sf "$HOME/dotfiles/ai/claude-code/skills" "$HOME/.claude/skills"
        success "Created symlink: ~/.claude/skills -> ~/dotfiles/ai/claude-code/skills"
    else
        info "Skills symlink already exists"
    fi

    # Commands symlink
    if [ -e "$HOME/.claude/command" ] && [ ! -L "$HOME/.claude/command" ]; then
        info "Removing existing ~/.claude/command/ directory (backed up)"
        rm -rf "$HOME/.claude/command"
    fi

    if [ ! -L "$HOME/.claude/command" ]; then
        ln -sf "$HOME/dotfiles/ai/claude-code/commands" "$HOME/.claude/command"
        success "Created symlink: ~/.claude/command -> ~/dotfiles/ai/claude-code/commands"
    else
        info "Commands symlink already exists"
    fi

    # Global CLAUDE.md symlink
    if [ -e "$HOME/.claude/CLAUDE.md" ] && [ ! -L "$HOME/.claude/CLAUDE.md" ]; then
        info "Backing up existing ~/.claude/CLAUDE.md"
        mv "$HOME/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md.backup-$(date +%Y%m%d-%H%M%S)"
    fi

    if [ ! -L "$HOME/.claude/CLAUDE.md" ]; then
        ln -sf "$HOME/dotfiles/ai/docs/meta-CLAUDE.md" "$HOME/.claude/CLAUDE.md"
        success "Created symlink: ~/.claude/CLAUDE.md -> ~/dotfiles/ai/docs/meta-CLAUDE.md"
    else
        info "CLAUDE.md symlink already exists"
    fi
}

# Validate configuration
validate_config() {
    local config_path="$HOME/.config/claude-mem/claude-mem.toml"
    local errors=()

    info ""
    info "=== Validating Configuration ==="

    # 1. Existence check
    if [ ! -f "$config_path" ]; then
        errors+=("ERROR: Config file missing at $config_path")
        errors+=("  → You must manually copy this file from another machine")
        errors+=("  → Expected location: ~/.config/claude-mem/claude-mem.toml")
    else
        success "Config file exists: $config_path"

        # 2. Permissions check
        local perms=$(stat -c %a "$config_path" 2>/dev/null || echo "unknown")
        if [ "$perms" != "unknown" ] && [ "$perms" -gt 600 ]; then
            errors+=("WARNING: Config file too permissive ($perms), should be 600 or less")
            errors+=("  → Run: chmod 600 $config_path")
        else
            success "Config permissions OK ($perms)"
        fi

        # 3. Valid TOML syntax check
        if ! python3 -c "import tomllib; tomllib.load(open('$config_path', 'rb'))" 2>/dev/null; then
            errors+=("ERROR: Invalid TOML syntax in $config_path")
            errors+=("  → Check for syntax errors with a TOML validator")
        else
            success "TOML syntax valid"

            # 4. Required sections and keys check
            local validation_output
            validation_output=$(CONFIG_PATH="$config_path" python3 <<'PYEOF' 2>&1
import tomllib, sys, os

required = {
    'database': ['type'],
    'database.postgresql': ['hosts', 'port', 'database', 'user', 'password', 'sslmode'],
    'ollama': ['host', 'model'],
    'server': ['name', 'version'],
    'logging': ['level', 'file'],
    'features': []
}

try:
    config_path = os.environ['CONFIG_PATH']
    with open(config_path, 'rb') as f:
        config = tomllib.load(f)

    for section, keys in required.items():
        parts = section.split('.')
        val = config
        for part in parts:
            if part not in val:
                print(f"Missing section: [{section}]", file=sys.stderr)
                sys.exit(1)
            val = val[part]
        for key in keys:
            if key not in val:
                print(f"Missing key: {key} in [{section}]", file=sys.stderr)
                sys.exit(1)

    print("All required sections and keys present")
    sys.exit(0)
except Exception as e:
    print(f"Validation error: {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
)
            local validation_status=$?

            if [ $validation_status -eq 0 ]; then
                success "All required sections and keys present"
            else
                errors+=("ERROR: $validation_output")
            fi
        fi
    fi

    # Report all errors, then fail if any exist
    if [ ${#errors[@]} -gt 0 ]; then
        echo ""
        error "=== Configuration Validation Failed ==="
        for err in "${errors[@]}"; do
            echo "$err"
        done
        echo "======================================="
        echo ""
        error "INSTALLATION FAILED: Fix config issues above and re-run"
        return 1
    else
        success "Configuration validation passed"
        return 0
    fi
}

# Verify installation
verify_installation() {
    info ""
    info "=== Verifying Installation ==="

    local all_good=true

    # Check skills symlink
    if [ -L "$HOME/.claude/skills" ]; then
        local target=$(readlink -f "$HOME/.claude/skills")
        if [ "$target" = "$HOME/dotfiles/ai/claude-code/skills" ]; then
            success "Skills symlink correct: ~/.claude/skills -> ~/dotfiles/ai/claude-code/skills"
        else
            error "Skills symlink points to wrong location: $target"
            all_good=false
        fi
    else
        error "Skills symlink missing"
        all_good=false
    fi

    # Check commands symlink
    if [ -L "$HOME/.claude/command" ]; then
        local target=$(readlink -f "$HOME/.claude/command")
        if [ "$target" = "$HOME/dotfiles/ai/claude-code/commands" ]; then
            success "Commands symlink correct: ~/.claude/command -> ~/dotfiles/ai/claude-code/commands"
        else
            error "Commands symlink points to wrong location: $target"
            all_good=false
        fi
    else
        error "Commands symlink missing"
        all_good=false
    fi

    # Check CLAUDE.md symlink
    if [ -L "$HOME/.claude/CLAUDE.md" ]; then
        local target=$(readlink -f "$HOME/.claude/CLAUDE.md")
        if [ "$target" = "$HOME/dotfiles/ai/docs/meta-CLAUDE.md" ]; then
            success "CLAUDE.md symlink correct: ~/.claude/CLAUDE.md -> ~/dotfiles/ai/docs/meta-CLAUDE.md"
        else
            error "CLAUDE.md symlink points to wrong location: $target"
            all_good=false
        fi
    else
        error "CLAUDE.md symlink missing"
        all_good=false
    fi

    # Validate config
    if ! validate_config; then
        all_good=false
    fi

    if [ "$all_good" = true ]; then
        success "All verification checks passed"
    else
        error "Some verification checks failed"
        return 1
    fi
}

# Print final report
print_report() {
    local backup_dir=$1

    info ""
    info "======================================="
    info "=== Installation Complete ==="
    info "======================================="
    info ""
    info "What was done:"
    info "  • Created directory structure in ~/dotfiles/ai/claude-code/"
    info "  • Migrated skills to ~/dotfiles/ai/claude-code/skills/"
    info "  • Created symlinks:"
    info "      ~/.claude/skills -> ~/dotfiles/ai/claude-code/skills"
    info "      ~/.claude/command -> ~/dotfiles/ai/claude-code/commands"
    info "      ~/.claude/CLAUDE.md -> ~/dotfiles/ai/docs/meta-CLAUDE.md"
    info "  • Global CLAUDE.md will be auto-loaded on every session"

    if [ -n "$backup_dir" ]; then
        info "  • Backup created at: $backup_dir"
    fi

    info ""
    info "Configuration:"
    info "  • Location: ~/.config/claude-mem/claude-mem.toml"
    info "  • Status: Validated ✓"
    info "  • Note: This file stays in original location (not version controlled)"
    info ""
    info "Next steps:"
    info "  1. Review changes:"
    info "       cd ~/dotfiles && git status"
    info "  2. Test Claude Code can find skills and config"
    info "  3. Commit to git (when ready):"
    info "       cd ~/dotfiles && git add ai/claude-code"
    info ""
    info "For new machines:"
    info "  1. Clone dotfiles repository"
    info "  2. Run: ~/dotfiles/ai/claude-code/install.sh"
    info "  3. Manually copy ~/.config/claude-mem/claude-mem.toml from this machine"
    info ""
    info "Installation log: $LOG_FILE"
    info "======================================="
}

# Main installation flow
main() {
    info "Claude Code Configuration Installer"
    info "===================================="

    preflight_checks
    detect_existing_installation

    local backup_dir=""
    backup_dir=$(create_backup)

    create_symlinks

    # Validate config (fail if invalid)
    if ! validate_config; then
        exit 1
    fi

    verify_installation

    print_report "$backup_dir"

    success "Installation successful!"
}

# Run main
main "$@"
