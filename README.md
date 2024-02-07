# pb-dotfiles

< Last update: Tue Feb  6 19:14:10 PST 2024 >


## install
* `neovim` + python deps
* [`starship`](https://starship.rs/) for prompts
* [`antibody`](https://getantibody.github.io/) for zsh plugins
* [`vim-plug`](https://github.com/junegunn/vim-plug) for neovim plugins


## [`stow`](https://www.gnu.org/software/stow/)
Install the files in this directory as symlinks in `$HOME` with this:
```bash
 $ stow --target=$HOME $HOME/dotfiles/
```

## MailMate

MailMate knows how to launch an editor for the body of an email. (See the MailMate issues thread or hidden prefs to find it).

### MacVim

Works _ok_ but not super for MailMate email. The key challenge is that enough of the config is different from NeoVim that I have to debug the heck out of `~/.gvimrc`.


## deprecated/bash, deprecated/

I keep these because I still use bash on some machines, eg, at AWS

<!-- done -->
