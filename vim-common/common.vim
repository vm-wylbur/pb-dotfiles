" Preamble {{{
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" (c) 2017 [HRDAG](https://hrdag.org), GPL-2 or later
"
" moved to github
"    git@github.com:vm-wylbur/pb-dotfiles.git
"
" this file contains
" sourced in the various init files
"
" }}}

" setup {{{
set nocompatible               " Be iMproved

filetype plugin on
let g:vim_bootstrap_langs = "python"
let g:vim_bootstrap_editor = "nvim"				" nvim or vim

" }}}

" plugins setup and bootstrap {{{
" if !filereadable(vimplug_exists)
"   if !executable("curl")
"     echoerr "You have to install curl or first install vim-plug yourself!"
"     execute "q!"
"   endif
"   echo "Installing Vim-Plug..."
"   echo ""
"   silent !\curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"   let g:not_finish_vimplug = "yes"

"   autocmd VimEnter * PlugInstall
" endif
" }}} 

" plugins {{{
call plug#begin(expand('~/.config/nvim/plugged'))

" hack for plugins themselves
Plug 'tpope/vim-repeat'  " doesn't work? needs config for surround

" editing and formatting
Plug 'godlygeek/tabular'      " should align on regex :Tab /char
Plug 'tpope/vim-surround'
Plug 'ervandew/supertab'
Plug 'kana/vim-textobj-function'
Plug 'kana/vim-textobj-user'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'

" files, buffers, and tags
Plug 'yegappan/mru'
Plug 'qpkorr/vim-bufkill'
" Plug 'majutsushi/tagbar'
Plug 'ap/vim-buftabline'

" fzf is its own thing
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" colors and UI
Plug 'frankier/neovim-colors-solarized-truecolor-only'
Plug 'airblade/vim-gitgutter' " put chars in gutter
" Plug 'inside/vim-search-pulse'
Plug 'itchyny/lightline.vim'
Plug 'luochen1990/rainbow'

" languages
Plug 'sheerun/vim-polyglot'
" Plug 'davidhalter/jedi-vim'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
Plug 'bps/vim-textobj-python'
Plug 'reedes/vim-pencil'
Plug 'vim-syntastic/syntastic'
Plug 'tpope/vim-fugitive'

" snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

call plug#end()
" }}}

" plugin configs {{{
set rtp+=$HOME/src/solarized/vim-colors-solarized
" let $NVIM_TUI_ENABLE_TRUE_COLOR=1
colorscheme solarized

source $HOME/dotfiles/vim-common/line.vimrc   " for the lightline config
set laststatus=2

let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
  augroup pencil
    autocmd!
    autocmd FileType markdown,mkd  call pencil#init()
    autocmd FileType text          call pencil#init()
  augroup END
autocmd FileType markdown,mkd setlocal spell
autocmd FileType markdown setlocal wrap

let g:buftabline_numbers=1
let g:buftabline_indicators='on' " this is helpful.
let g:buftabline_separators='on'

let MRU_Exclude_Files = '.*/.git/COMMIT_EDITMSG$'
" }}}

" cursor+gui+colors {{{

"" basics {{{{
set termguicolors
set background=dark
syntax on
set ruler
set relativenumber
set number
" }}}}

" cursor stuff {{{{
highlight! nCursor guifg=black guibg=magenta gui=reverse

" set guicursor=n:block-nCursor/lCursor-blinkon0,
"   \v:block-Cursor/lCursor-blinkon0,
"   \c:hor40-Cursor/lCursor-blinkon0,
"   \o:hor40-Cursor/lCursor-blinkon0,
"   \i-ci:ver25-Cursor/lCursor,
"   \r-cr:hor20-Cursor/lCursor

au VimLeave * set guicursor=a:block-blinkon0

augroup CursorLine
    au!
    au VimEnter * setlocal cursorcolumn
    au WinEnter * setlocal cursorcolumn
    au BufWinEnter * setlocal cursorcolumn
    au WinLeave * setlocal nocursorcolumn

    au VimEnter * setlocal cursorline
    au WinEnter * setlocal cursorline
    au BufWinEnter * setlocal cursorline
    au WinLeave * setlocal nocursorline
  augroup END
" }}}}

"" setting up right margin highlighting {{{{
augroup BgHighlight
autocmd!
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END
" makes right margin diff color
execute "set colorcolumn=" . join(range(81,335), ',')
" }}}}

" }}}

" editing {{{
"" Autocomplete {{{{
set omnifunc=syntaxcomplete#Complete
" }}}}

"" Auto commands at save {{{{
set omnifunc=syntaxcomplete#Complete
set autoread
augroup autoSaveAndRead
  autocmd!
  autocmd TextChanged,InsertLeave,FocusLost * silent! wall
  autocmd CursorHold * silent! checktime
augroup END
autocmd BufWritePre * :%s/\s\+$//e  " removes training whitespace
" }}}}

"" Encoding {{{{
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set bomb
set binary
" }}}}

"" Fix backspace indent {{{{
set backspace=indent,eol,start
" }}}}

"" Tabs. May be overriten by autocmd rules {{{{
set tabstop=2
set softtabstop=0
set shiftwidth=2
set expandtab
" }}}}

"" Enable hidden buffers {{{{
set hidden
" }}}}

"" for MacOS {{{{
if has('macunix')
  vmap <C-x> :!pbcopy<CR>
  vmap <C-c> :w !pbcopy<CR><CR>
endif
" }}}}

"" Copy/Paste/Cut {{{{
set clipboard=unnamed
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif
" }}}}

"" Disable visualbell {{{{
set noerrorbells visualbell t_vb=
if has('autocmd')
  autocmd GUIEnter * set visualbell t_vb=
endif
set showcmd
" }}}}

"" Searching {{{{
set hlsearch
set incsearch
set ignorecase
set smartcase
" }}}}

"" Turn on spell checking {{{{
set spell
"" }}}}

"" shells and directories for swp files {{{{
set nobackup
set noswapfile

set fileformats=unix,dos,mac
set showcmd

if exists('$SHELL')
    set shell=$SHELL
else
    set shell=/bin/bash
endif
" }}}}
" }}}

" Abbreviations {{{

"" abbreviations for quick datestamping in Insert mode
iab xsdate <c-r>=strftime("%Y-%m-%dT%H:%M%Z")<CR>
iab xldate <c-r>=strftime("%a %d %b %Y %H:%M:%S%Z")<CR>
" }}}

" mappings {{{
let mapleader=','

nnoremap D Da
nnoremap U d^i
" this is a better line 

"" insert mode like emacs {{{{
inoremap <C-a> <Home>
inoremap <C-e> <End>
" }}}}

"" bubbling text with vim-impaired and Drew Neil's mappings {{{{
" Bubble multiple lines; note that the *noremap's don't work here. 
nmap <C-Up> [e
nmap <C-Down> ]e
vmap <C-Up> [egv
vmap <C-Down> ]egv
" }}}}


"" terminal config {{{{
" only really relevant to neovim, maybe should move there
tnoremap <ESC> <C-\><C-n>
tnoremap <A-h> <C-\><C-N><C-w>h
tnoremap <A-j> <C-\><C-N><C-w>j
tnoremap <A-k> <C-\><C-N><C-w>k
tnoremap <A-l> <C-\><C-N><C-w>l
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l

command! Cquit
    \  if exists('b:nvr')
    \|   for chanid in b:nvr
    \|     silent! call rpcnotify(chanid, 'Exit', 1)
    \|   endfor
    \| endif

autocmd BufWinEnter,WinEnter term://* startinsert
autocmd BufLeave term://* stopinsert
au BufEnter * if &buftype == 'terminal' | :startinsert | endif
" }}}}

" }}}

" leader {{{
nnoremap <leader>x :so %<CR>
"" terminal emulation {{{{
if g:vim_bootstrap_editor == 'nvim'
  nnoremap <silent> <leader>sh :terminal<CR>
else
  nnoremap <silent> <leader>sh :VimShellCreate<CR>
endif


" }}}}

"" fugitive mappings {{{{
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader>gc :Gcommit -a<CR>
nnoremap <leader>gp :Gpush<CR>
nnoremap <leader>gl :Gpull<CR>
" }}}}

" }}}

" language {{{

" In markdown files, Control + a surrounds highlighted text with square
" brackets, then dumps system clipboard contents into parenthesis
autocmd FileType markdown vnoremap <c-a> <Esc>`<i[<Esc>`>la](<Esc>"*]pa)<Esc>

" }}}

" Autocmd Rules {{{

"" Remember cursor position {{{{
augroup vimrc-remember-cursor-position
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END
" }}}}

" }}}

" misc {{{
" }}}


setlocal foldmethod=marker
setlocal foldlevel=1
" vim: set foldmethod=marker foldlevel=0:
