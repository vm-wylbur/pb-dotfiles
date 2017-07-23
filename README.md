# pb-dotfiles
PB's dotfiles for bash and emacs

## vim

vim is complicated: there are various config files:

* ~/.config/nvim/init.vim should be $dot/neovim/init.vim
* ~/.gvimrc for MacVim in $dot/macvim/gvimrc
* ~/.vimrc for most vims in $dot/vim/vimrc 

And each of the files has a plugged directory which keeps the plugins. maybe a `$dot/vimX/plugged/` to which the others symlink? 

### refactoring plan

* rename plugged dirs and symlink to common

## emacs

of course deprecated. 

## bash 

These startup files are called by ~/.bash_profile in OSX and ~/.bashrc in linux. Note that I source .bashrc as the first step in bash_profile

<!-- done -->
