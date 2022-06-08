# pb-dotfiles

< Last update: 2022-06-08 12:54 >


## install this
* `neovim` + python deps
* [`starship`](https://starship.rs/)
* [`vim-plug`](https://github.com/junegunn/vim-plug)


## vim

vim is complicated: there are various config files:

* `~/.config/nvim/init.vim` should be `$dot/neovim/init.vim`
* `~/.gvimrc` for MacVim in `$dot/macvim/gvimrc`
* `~/.vimrc` for most vims in `$dot/vim/vimrc`

And each of the files has a plugged directory which keeps the plugins. maybe a `$dot/vimX/plugged/` to which the others symlink?

## zsh 


## bash 

These startup files are called by `~/.bashrc` in linux. Note that I source .bashrc as the first step in bash_profile

<!-- done -->
