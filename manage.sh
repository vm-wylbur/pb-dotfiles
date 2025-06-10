#!/usr/bin/env bash
#
# dotfiles management script using GNU Stow
# Usage: ./manage.sh [install|uninstall|restow|list]
#

set -e

# Available packages
PACKAGES=("zsh" "vim" "p10k" "wezterm")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 [install|uninstall|restow|list] [package_name]"
    echo ""
    echo "Commands:"
    echo "  install     - Install all packages or specific package"
    echo "  uninstall   - Uninstall all packages or specific package"
    echo "  restow      - Restow (uninstall + install) all packages or specific package"
    echo "  list        - List available packages"
    echo ""
    echo "Available packages: ${PACKAGES[*]}"
    echo ""
    echo "Examples:"
    echo "  $0 install          # Install all packages"
    echo "  $0 install zsh      # Install only zsh package"
    echo "  $0 uninstall vim    # Uninstall only vim package"
    echo "  $0 restow           # Restow all packages"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_package() {
    local package="$1"
    for p in "${PACKAGES[@]}"; do
        if [[ "$p" == "$package" ]]; then
            return 0
        fi
    done
    return 1
}

stow_package() {
    local package="$1"
    if [[ ! -d "$package" ]]; then
        log_error "Package directory '$package' not found"
        return 1
    fi
    
    log_info "Installing package: $package"
    stow "$package"
}

unstow_package() {
    local package="$1"
    if [[ ! -d "$package" ]]; then
        log_warn "Package directory '$package' not found, skipping"
        return 0
    fi
    
    log_info "Uninstalling package: $package"
    stow -D "$package"
}

restow_package() {
    local package="$1"
    if [[ ! -d "$package" ]]; then
        log_error "Package directory '$package' not found"
        return 1
    fi
    
    log_info "Restowing package: $package"
    stow -R "$package"
}

list_packages() {
    echo "Available packages:"
    for package in "${PACKAGES[@]}"; do
        if [[ -d "$package" ]]; then
            echo "  ✓ $package"
        else
            echo "  ✗ $package (directory not found)"
        fi
    done
}

# Main script
if [[ $# -eq 0 ]]; then
    usage
    exit 1
fi

command="$1"
specific_package="$2"

# Change to dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

case "$command" in
    "install")
        if [[ -n "$specific_package" ]]; then
            if check_package "$specific_package"; then
                stow_package "$specific_package"
            else
                log_error "Unknown package: $specific_package"
                echo "Available packages: ${PACKAGES[*]}"
                exit 1
            fi
        else
            log_info "Installing all packages..."
            for package in "${PACKAGES[@]}"; do
                stow_package "$package"
            done
        fi
        ;;
    "uninstall")
        if [[ -n "$specific_package" ]]; then
            if check_package "$specific_package"; then
                unstow_package "$specific_package"
            else
                log_error "Unknown package: $specific_package"
                echo "Available packages: ${PACKAGES[*]}"
                exit 1
            fi
        else
            log_info "Uninstalling all packages..."
            for package in "${PACKAGES[@]}"; do
                unstow_package "$package"
            done
        fi
        ;;
    "restow")
        if [[ -n "$specific_package" ]]; then
            if check_package "$specific_package"; then
                restow_package "$specific_package"
            else
                log_error "Unknown package: $specific_package"
                echo "Available packages: ${PACKAGES[*]}"
                exit 1
            fi
        else
            log_info "Restowing all packages..."
            for package in "${PACKAGES[@]}"; do
                restow_package "$package"
            done
        fi
        ;;
    "list")
        list_packages
        ;;
    *)
        log_error "Unknown command: $command"
        usage
        exit 1
        ;;
esac

log_info "Done!"

