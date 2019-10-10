"
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" git@github.com:vm-wylbur/pb-dotfiles.git
" (c) 2018 [HRDAG](https://hrdag.org), GPL-2 or later
"
" pb-dotfiles/vim-common/sets.vim

set hidden
set lazyredraw
set ttyfast

"" Copy/Paste/Cut
set clipboard=unnamed

set termguicolors
syntax on
set ruler
set relativenumber
set number
set mouse=a

" completions
set completeopt+=menuone,noselect
set shortmess+=c
set belloff+=ctrlg
set complete+=i
set complete+=kspell

" visual behavior
au VimLeave * set guicursor=a:block-blinkon0
set noerrorbells visualbell t_vb=
if has('autocmd')
  autocmd GUIEnter * set visualbell t_vb=
endif
set showcmd
set showmode                " Show the current mode.
set showcmd                 " show partial command on last line of screen.
set showmatch               " show matching parenthesis
set laststatus=2
set signcolumn=yes

" Tabs. May be overwritten by autocmd rules
set tabstop=4
set softtabstop=0
set shiftwidth=4
set expandtab
set smarttab autoindent

"" Searching
set hlsearch
set incsearch
set ignorecase smartcase
set smartcase
set showmatch
set gdefault

"" keys
set backspace=indent,eol,start
set nodigraph  " use c-k to start digraph: é

"" spelling
set spell
set spelllang=en_us spell

"" file types
set fileformats=unix,dos,mac
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set bomb
set binary

" stay consistent with disk
set autoread
autocmd TextChanged,InsertLeave,FocusLost * update

"" shells and directories for swp files
set noswapfile
if exists($SUDO_USER)
  set nobackup
  set nowritebackup
else
  " TODO: check for dir exist and create
  set backupdir=~/.vim/tmp/backup
  set backupdir+=.
endif

if has("persistent_undo")
    set undodir=~/.undodir/
    set undofile
endif

" for MacOS
if has('macunix')
  vmap <S-x> :!pbcopy<CR>
  vmap <S-c> :w !pbcopy<CR><CR>
endif

if exists('$SHELL')
    set shell=$SHELL
else
    set shell=/bin/bash
endif

" done.
