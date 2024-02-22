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
#

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
export PATH="$PATH:$HOME/bin:$HOME/dotfiles/scripts:$HOME/.local/bin"
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
# TODO: switch to zoxide
# init fasd on eleanor; fasd is part of pretzo on petunia
case $HOST in
  (porky)
    # eval "$(fasd --init auto)"
    # $HOME/dotfiles/scripts/wezterm-macos.sh &
    ;;
  (henwen)
    eval "$(fasd --init auto)"
    SED="sed"
    ;;
  (eleanor)
    eval "$(fasd --init auto)"
    SED="sed"
    ;;
  (*) eval "$(fasd --init auto)"
    SED="sed"
    ;;
esac

# colors
export TERM=xterm-256color
export ZSH_THEME="agnoster"
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=black,bold'


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

alias j='xdir=$(fasd -ld | fzf --tac) && cd "$xdir"'
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

export LOCALGIT="$HOME/projects"
export HRDAGGIT="$LOCALGIT/hrdag"
export PERSONALGIT="$LOCALGIT/personal"

export STARSHIP_CONFIG="$HOME/dotfiles/starship/starship.toml"
eval "$(starship init zsh)"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh" || true

if [[ -f $HOME/dotfiles/scripts/wezterm-record.py ]]; then
  $HOME/dotfiles/scripts/wezterm-record.py running &!
  $HOME/dotfiles/scripts/wezterm-escapes.sh running &!
fi

# for tmux to set window name.
# printf '\033]0;%s\007' "$USER@$HOSTNAME" # just the local part


# done.

