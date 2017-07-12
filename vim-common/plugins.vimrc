" Preamble {{{
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" (c) 2017 [HRDAG](https://hrdag.org), GPL-2 or later
"
" plugins and their configs 
" }}}

" setup and bootstrap {{{
if !filereadable(vimplug_exists)
  if !executable("curl")
    echoerr "You have to install curl or first install vim-plug yourself!"
    execute "q!"
  endif
  echo "Installing Vim-Plug..."
  echo ""
  silent !\curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  let g:not_finish_vimplug = "yes"

  autocmd VimEnter * PlugInstall
endif
" }}}
"
"

" plug packages {{{
call plug#begin(expand('~/.config/nvim/plugged'))
" editing 

Plug 'godlygeek/tabular'      " should align on regex :Tab /char
Plug 'Yggdroot/indentLine'    " ??
Plug 'airblade/vim-gitgutter' " put chars in gutter
" Plug 'altercation/vim-colors-solarized'
" Plug 'frankier/neovim-colors-solarized-truecolor-only'
Plug 'morhetz/gruvbox'
Plug 'ap/vim-buftabline'
Plug 'avelino/vim-bootstrap-updater'
Plug 'bps/vim-textobj-python'
" Plug 'craigemery/vim-autotag'
Plug 'ervandew/supertab'
Plug 'inside/vim-search-pulse'
Plug 'itchyny/lightline.vim'
Plug 'jistr/vim-nerdtree-tabs'
Plug 'justinmk/vim-sneak'
Plug 'kana/vim-textobj-function'
Plug 'kana/vim-textobj-user'
Plug 'luochen1990/rainbow'
Plug 'majutsushi/tagbar'
Plug 'qpkorr/vim-bufkill'
Plug 'reedes/vim-pencil'
Plug 'scrooloose/nerdtree'
Plug 'scrooloose/syntastic'
Plug 'tpope/vim-commentary'
" Plug 'tpope/vim-sensible'
Plug 'tpope/vim-surround'
Plug 'vim-syntastic/syntastic'

" languages
Plug 'sheerun/vim-polyglot'
Plug 'davidhalter/jedi-vim'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}

"" Vim-Session
" Plug 'xolox/vim-misc'
" Plug 'xolox/vim-session'

Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
" }}} 

" Plug configs {{{

source $HOME/dotfiles/vim-common/line.vimrc

let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
  augroup pencil
    autocmd!
    autocmd FileType markdown,mkd  call pencil#init()
    autocmd FileType text          call pencil#init()
  augroup END
autocmd FileType markdown,mkd setlocal spell

let g:buftabline_numbers=1
let g:buftabline_indicators='on' " this is helpful.
let g:buftabline_separators='on'

let g:sneak#label = 1
" }}} 

call plug#end()

set modeline
set modelines=5
" vim: set foldmethod=marker foldlevel=0:


