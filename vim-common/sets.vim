

 
set hidden
set lazyredraw
set ttyfast

"" Copy/Paste/Cut
set clipboard=unnamedplus

set termguicolors
syntax on
set ruler
set relativenumber
set number
set mouse=a
au VimLeave * set guicursor=a:block-blinkon0

" visual behavior
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
set tabstop=2
set softtabstop=0
set shiftwidth=2
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
