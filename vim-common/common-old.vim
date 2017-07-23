" these are settings to be used in both vim and nvim
" 2017-07-21T21:33
" todo:
"  - add plugin section, w dash.vim to dash search for word under cursor
"       <leader>d 
"
" setup {{{
" testing bad spelling one two there
set nocompatible
filetype plugin on
set directory^=$HOME/.backups//
set shell=/bin/bash\ -l
set shellcmdflag=-ic
set incsearch
set hlsearch
set spelllang=en_us spell
set wildmenu
set wildmode=longest:list,full

" }}}
" General {{{

" Softtabs, 4 spaces
set tabstop=4
set shiftwidth=4
set shiftround
set expandtab

" Share the clipboard outside of vim
set clipboard=unnamed

" Reload files if changed outside vim
set autoread

" In markdown files, Control + a surrounds highlighted text with square
" brackets, then dumps system clipboard contents into parenthesis
autocmd FileType markdown vnoremap <c-a> <Esc>`<i[<Esc>`>la](<Esc>"*]pa)<Esc>


" don't use swap files
set noswapfile

" Turn on spell checking
set spell
" }}}
" key maps {{{
inoremap <C-a> <Home>
inoremap <C-e> <End>
" }}}
