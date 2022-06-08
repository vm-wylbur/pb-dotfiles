# -*- shell-script -*-
# 2016-02-07 adapted from git@github.com:mathiasbynens/dotfiles.git
# 2016-12-15 ported to petunia
# 2017-10-14 hacking with vim, set expandtab

# stop unless interactive
[[ $- == *i* ]] || return

# Add `~/bin` to the `$PATH`
export PATH="$HOME/bin:$PATH";

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
# NB: prompt removed, added starship
for file in ~/dotfiles/bash/{path,exports,aliases,functions,extra}; do
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

shopt -s nocaseglob;   # Case-insensitive globbing (used in pathname expansion)
shopt -s histappend;   # Append to the Bash history file, rather than overwriting it
shopt -s cdspell;      # Autocorrect typos in path names when using `cd`

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
  shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for many Bash commands
if which brew > /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
  source "$(brew --prefix)/share/bash-completion/bash_completion";
elif [ -f /etc/bash_completion ]; then
  source /etc/bash_completion;
fi;

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &> /dev/null && [ -f /usr/local/etc/bash_completion.d/git-completion.bash ]; then
  complete -o default -o nospace -F _git g;
fi;

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh;

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

# eval `gdircolors $HOME/src/dircolors-solarized/dircolors.ansi-dark`

eval `ssh-agent`
ssh-add -K "${HOME}/.ssh/id_rsa"

eval "$(fasd --init auto)"

# [ -f ~/.gpg-agent-info ] && source ~/.gpg-agent-info
# if [ -S "${GPG_AGENT_INFO%%:*}" ]; then
#   export GPG_AGENT_INFO
# else
#   eval $( gpg-agent --daemon --write-env-file ~/.gpg-agent-info )
# fi
# GPG_TTY=$(tty)
# export GPG_TTY

# this sets up the pyenv virtual environment manager
eval "$(pyenv init -)"

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash


# done.

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba init' !!
export MAMBA_EXE="/home/pball/bin/micromamba";
export MAMBA_ROOT_PREFIX="/opt/micromamba/";
__mamba_setup="$('/home/pball/bin/micromamba' shell hook --shell bash --prefix '/opt/micromamba/' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    if [ -f "/opt/micromamba/etc/profile.d/mamba.sh" ]; then
        . "/opt/micromamba/etc/profile.d/mamba.sh"
    else
        export PATH="/opt/micromamba/bin:$PATH"
    fi
fi
unset __mamba_setup

export STARSHIP_CONFIG="$HOME/dotfiles/starship/starship.toml"
eval "$(starship init bash)"
#
# <<< mamba initialize <<<
