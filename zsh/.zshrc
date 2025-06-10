#
#  Author: PB
#  Maintainer: PB
#  License: (c) HRDAG 2022, some rights reserved: GPL v2 or newer
#
# Executes commands at the start of an interactive session.
# TODO: mess with the MANPATH to check for gnu utils first
# maybe in ~/.machinespecific/

# Make sure the shell is interactive
case $- in
    *i*) ;;
    *) return ;;
esac
#
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
# FIXME: review how zsh does paths, there's a better way!
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
# # a plugin that doesn't play nice with antidote
if [[ ! -n "$NVIM_TUI_ENABLE_TRUE_COLOR" ]]; then
  source $HOME/src/zsh-vi-mode/zsh-vi-mode.plugin.zsh
  ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_NEX
fi


# ---PB additions below-----
SED='sed'

# colors
export TERM=xterm-256color
export ZSH_THEME="agnoster"
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
setopt appendhistory     #Append history to the history file (no overwriting)
setopt sharehistory      #Share history across terminals
setopt INC_APPEND_HISTORY
setopt incappendhistory  #Immediately append to the history file, not just when a term is killed

HISTSIZE=10000               #How many lines of history to keep in memory
HISTFILE=~/.zsh_history     #Where to save history to disk
SAVEHIST=100000               #Number of history entries to save to disk
HISTDUP=erase               #Erase duplicates in the history file

export MANPAGER="most"
# setting up fzf keybindings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ---aliases-----
alias gs="git status"
# alias gl="git log --graph --pretty=oneline --abbrev-commit"
alias gl='git log --pretty=format:"%h%x09%an%x09%ad%x09%s"'
alias gc='git commit'

alias '..'='cd ..'
alias '...'='cd ../..'
alias '....'='cd ../../..'
alias '.....'='cd ../../../..'
alias ccat="pygmentize $1"

alias ll="ls -ltrFG --color"
alias la="ls -laFG  --color"
# alias ll="colorls -ltrG"
# alias la="colorls -latrG"
# alias ll='exa -lh --git --group_ --sort mod'
# alias la='exa -lh --all --git --sort=mod'
# alias lt='exa -lh --git --tree'

# j command now handled by zoxide (z/zi)
alias h='print -z $(fc -l 1 | fzf +s --tac | $SED -re "s/^\s*[0-9]+\s*//")'

# maybe alacritty+tmux fixes here?
# alias tmux='TERM=screen-256color-bce tmux'

# ---env vars-----
export EDITOR='nvim'
export LANG='en_US.UTF-8';
export LC_ALL='en_US.UTF-8';
export PAGER="most"
export VI_MODE_SET_CURSOR=true

# ---for zsh-----
export KEYTIMEOUT=1
bindkey -e
bindkey '^?' backward-delete-char
bindkey '^P' up-history
bindkey '^N' down-history
bindkey '^?' backward-delete-char
bindkey '^h' backward-delete-char
bindkey '^w' backward-kill-word
bindkey '^r' history-incremental-search-backward
bindkey '^ ' autosuggest-accept
# bindkey -v

# autoload -U zmv   # the conventions are a bit opaque
autoload -U select-word-style  # makes backward-word-kill stop at non-alpha
select-word-style bash

# ---local-----
if [[ -f $HOME/.github-token ]]; then
	source ~/.github-token
fi
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=10'

# messing around with how to read manpages
# export MANPAGER="ov --section-delimiter '^[^\s]' --section-header"
export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man ts=8 nomod nolist nonu noma linebreak breakindent wrap' -\""

export LOCALGIT="$HOME/projects"
export HRDAGGIT="$LOCALGIT/hrdag"
export PERSONALGIT="$LOCALGIT/personal"
export STARSHIP_CONFIG="$HOME/dotfiles/starship/starship.toml"
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

# Python stuff
eval "$(uv generate-shell-completion zsh)"
# source "$HOME/.venv/bin/activate"
eval "$(zoxide init zsh)"

# done
# Note: server-specific configs (postgres, ghorg) only on Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export PAGER=/usr/bin/ov
  export MANPAGER=/usr/bin/ov
  alias pgpy='sudo -u postgres /usr/local/pgenv/bin/python'
  alias pgpip='sudo -u postgres /usr/local/pgenv/bin/pip'
  # for ghorg monitoring
  if [ -f ~/creds/ghorg-gh-personal-token.api ]; then
    export GHORG_GITHUB_TOKEN=$(cat ~/creds/ghorg-gh-personal-token.api)
  fi
  source ~/.venv/bin/activate
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

umask 027  #  (user=rwx, group=rx, others=)

# done.

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load p10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/pball/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
