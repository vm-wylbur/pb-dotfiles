# pb-dotfiles

< Last update: 2022-06-08 14:44 >


## install
* `neovim` + python deps
* [`starship`](https://starship.rs/) for prompts
* [`antibody`](https://getantibody.github.io/) for zsh plugins
* [`vim-plug`](https://github.com/junegunn/vim-plug) for neovim plugins


## vim

vim is complicated: there are various config files:

* `~/.config/nvim/init.vim` should be `$dot/neovim/init.vim`
* `~/.gvimrc` for MacVim in `$dot/macvim/gvimrc`
* `~/.vimrc` for most vims in `$dot/vim/vimrc`

And each of the files has a plugged directory which keeps the plugins. maybe a `$dot/vimX/plugged/` to which the others symlink?

## zsh 

This should mostly be automagical, once the installations are done.

## bash 

deprecate??

<!-- done -->
