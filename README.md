# pb-dotfiles

<!-- date -j -f "%Y-%m-%dT%H:%M:%SZ" "2025-06-10T17:07:03Z" "+%a %d %b %Y %H:%M %Z" -->
< Last update: Tue 10 Jun 2025 10:04 PDT >

## Structure

Dotfiles are organized into packages for easy management:

```
dotfiles/
├── zsh/              # ZSH configuration (.zshrc, .zsh_plugins.txt)
├── vim/              # Vim configuration (.gvimrc)
├── p10k/             # Powerlevel10k theme (.p10k.zsh)
├── wezterm/          # WezTerm terminal configuration (.wezterm.lua)
├── scripts/          # Utility scripts
├── starship/         # Starship prompt configuration
├── deprecated/       # Old configs (bash, old vim/nvim setups)
└── manage.sh         # Management script
```

## Quick Start

1. **Install all packages:**
   ```bash
   ./manage.sh install
   ```

2. **Install specific package:**
   ```bash
   ./manage.sh install zsh
   ```

3. **List available packages:**
   ```bash
   ./manage.sh list
   ```

## Dependencies

* [`GNU Stow`](https://www.gnu.org/software/stow/) - for symlink management
* [`Antidote`](https://github.com/mattmc3/antidote) - ZSH plugin manager (replaces antibody)
* [`Starship`](https://starship.rs/) - cross-shell prompt
* [`Powerlevel10k`](https://github.com/romkatv/powerlevel10k) - ZSH theme
* [`WezTerm`](https://wezfurlong.org/wezterm/) - terminal emulator

## Manual Stow Usage

If you prefer to use stow directly:

```bash
# Install all packages
stow zsh vim p10k wezterm

# Install single package
stow zsh

# Uninstall package
stow -D zsh

# Restow (useful after changes)
stow -R zsh
```
