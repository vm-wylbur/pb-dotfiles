#
#  Author: PB
#  Maintainer: PB
#  License: (c) HRDAG 2022, some rights reserved: GPL v2 or newer
#
# Executes commands at the start of an interactive session.

# Make sure the shell is interactive
case $- in
    *i*) ;;
    *) return ;;
esac

# Show backup status on terminal open
[[ -x /etc/update-motd.d/50-backup-status ]] && /etc/update-motd.d/50-backup-status

autoload -Uz compinit
compinit

# ---functions -----
function chpwd() {
  emulate -L zsh
  printf "\033]7;file://$(hostname -s)\033\\"
  echo -ne "\x1b]0;$(hostname -s)\x1b\\"
  ls -ltrFG --color
}

# ---paths-----
if [[ -f $HOME/.machinespecific/paths ]] ; then
	source $HOME/.machinespecific/paths
else
	echo "no paths found! add ~/.machinespecific/paths"
fi
export PATH="$HOME/bin:$HOME/dotfiles/scripts:$HOME/.local/bin:$PATH"
typeset -U path

# --- plugin manager: antidote-----
[[ -e ~/.antidote ]] || git clone https://github.com/mattmc3/antidote.git ~/.antidote
if [[ ! -f ~/.zsh_plugins.txt ]] ; then
	echo "missing zsh plugins file! trying to symlink"
	ln -sf ~/dotfiles/zsh/zsh_plugins.txt ~/.zsh_plugins.txt
fi

source ~/.antidote/antidote.zsh
antidote load

# a plugin that doesn't play nice with antidote
if [[ ! -n "$NVIM_TUI_ENABLE_TRUE_COLOR" ]]; then
  source $HOME/src/zsh-vi-mode/zsh-vi-mode.plugin.zsh
  ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_NEX
fi


# ---PB additions below-----
SED='sed'

# colors
export TERM=xterm-256color
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=black,bold'
export PGDATABASE=pball

# ---shell options-----
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CHASE_LINKS
setopt ALWAYS_TO_END
setopt rm_star_silent
setopt HIST_IGNORE_DUPS
setopt BANG_HIST
setopt EXTENDED_HISTORY
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=100000
HISTDUP=erase

# setting up fzf keybindings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ---aliases-----
alias gs="git status"
alias gl='git log --pretty=format:"%h%x09%an%x09%ad%x09%s"'
alias gc='git commit'

alias '..'='cd ..'
alias '...'='cd ../..'
alias '....'='cd ../../..'
alias '.....'='cd ../../../..'
alias ccat="pygmentize $1"

alias ll="ls -ltrFG --color"
alias la="ls -laFG  --color"

# j command now handled by zoxide (z/zi)
alias h='print -z $(fc -l 1 | fzf +s --tac | $SED -re "s/^\s*[0-9]+\s*//")'

# ---env vars-----
export EDITOR='nvim'
export LANG='en_US.UTF-8';
export LC_ALL='en_US.UTF-8';
export VI_MODE_SET_CURSOR=true

# ---for zsh-----
export KEYTIMEOUT=1
bindkey -e
bindkey '^?' backward-delete-char
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward
bindkey '^ ' autosuggest-accept

autoload -U select-word-style
select-word-style bash

# ---local-----
if [[ -f $HOME/.github-token ]]; then
	source ~/.github-token
fi
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=10'

export LOCALGIT="$HOME/projects"
export HRDAGGIT="$LOCALGIT/hrdag"
export PERSONALGIT="$LOCALGIT/personal"

# starship prompt (with fallback)
# starship finds ~/.config/starship/starship.toml automatically
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
else
  # Simple fallback prompt when starship not installed
  PROMPT='%n@%m:%~ %# '
fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# Python stuff
command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"
eval "$(zoxide init zsh)"

# Platform-specific configs
case "$OSTYPE" in
  linux-gnu*)
    export PAGER=/usr/bin/ov
    export MANPAGER=/usr/bin/ov
    alias pgpy='sudo -u postgres /usr/local/pgenv/bin/python'
    alias pgpip='sudo -u postgres /usr/local/pgenv/bin/pip'
    # for ghorg monitoring
    if [ -f ~/creds/ghorg-gh-personal-token.api ]; then
      export GHORG_GITHUB_TOKEN=$(cat ~/creds/ghorg-gh-personal-token.api)
    fi
    [[ -f ~/.venv/bin/activate ]] && source ~/.venv/bin/activate
    ;;
  darwin*)
    export PAGER="most"
    export MANPAGER="most"
    ;;
esac

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

umask 027

# done.
