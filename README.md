# pb-dotfiles

< Last update: 2022-06-20 17:35 >


## install
* `neovim` + python deps
* [`starship`](https://starship.rs/) for prompts
* [`antibody`](https://getantibody.github.io/) for zsh plugins
* [`vim-plug`](https://github.com/junegunn/vim-plug) for neovim plugins


## vim

vim is complicated: there are various config files (where `dot=$HOME/dotfiles`):

* `~/.config/nvim/init.vim` should be `$dot/neovim/init.vim`
* `~/.gvimrc` for MacVim in `$dot/macvim/gvimrc`
* `~/.vimrc` for most vims in `$dot/vim/vimrc`

And each of the files has a plugged directory which keeps the plugins. maybe a `$dot/vimX/plugged/` to which the others symlink?

### MailMate

MailMate knows how to launch an editor for the body of an email. (See the MailMate issues thread or hidden prefs to find it). 

### MacVim 

Works _ok_ but not super for MailMate email. The key challenge is that enough of the config is different from NeoVim that I have to debug the heck out of `.gvimrc`.

### VimR

Could VimR replace MacVim? Big advantage is that it uses the same config as NeoVim, so it inherits the same settings. Much easier to maintain.

The key app is to edit email from MailMate, which requires some kind of Apple ID hash. Quite possibly could work. Also, **amazing** markdown previewing. This is itself worth the price of admission. 

## zsh 

This should mostly be automagical, once the installations are done.

## bash 

I keep these because I still use bash on some machines, eg, at AWS

<!-- done -->
