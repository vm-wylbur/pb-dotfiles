" mappings
"" the big picture here is:
"" * remapping std vim keys should be enhancements, not overrides
"" * leader keys are in groups
"" * try to stay off remapping C- keys. There's already lots there.
"" * A-x keys move among windows and do not-vimmy stuff

let g:mapleader='\'

"" PB specific remaps
""" because scrolling is *the* main thing we do
nnoremap <space> <C-d>
nnoremap <C-space> <C-u>
""" repeat the last macro w CR
nnoremap <return> @@

"" tweaks adding functionality to existing keys {{{{
nnoremap D Da
nnoremap U d^i
" Keep the cursor in place while joining lines
nnoremap J mzJ`z
"" Vmap for maintain Visual Mode after shifting > and <
vmap < <gv
vmap > >gv
nnoremap <C-l> :nohlsearch<CR><C-l>zz
inoremap <C-l> <ESC>:nohlsearch<CR><C-l>zz
"" }}}}

"" insert/command mode like emacs {{{{
inoremap <C-a> <Home>
inoremap <C-e> <End>
inoremap <A-bs> <c-w>
cnoremap <C-a> <Home>
cnoremap <C-e> <End>
cnoremap <A-bs> <c-w>
" }}}}

"" bubbling text {{{{
""" Bubble multiple lines; note that the *noremap's don't work here.
""" with vim-impaired and Drew Neil's mappings
nmap <C-Up> [e
nmap <C-Down> ]e
""" Move visual block
vnoremap J [egv
vnoremap K ]egv
vmap <C-Up> [egv
vmap <C-Down> ]egv

" window nav in normal mode via control
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" this is neovim specific
tnoremap <Esc> <C-\><C-n>

"" to normal mode with jj or jk {{{{
inoremap jj <ESC>
inoremap jk <ESC>
tnoremap jj <c-\><c-n>
" this is esp good for getting out of fzf searches
tnoremap jk <c-\><c-n>:q<cr>
" }}}}
" }}}
"
" leader {{{
"" the big picture hire is:
"" * a small number of important keys get single-char leader

"" PB specifics {{{{
nnoremap <leader>x :so %<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>m :History<CR>
" BufExplorer is pretty much emacs
nnoremap <leader>b :BufExplorer<CR>
nnoremap <leader>u :UndotreeToggle<cr>

vnoremap <leader>v c[<C-r>"](<Esc>"*pli)<Esc>

" this is a demo, wraps viw in double-q
" :nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel


" direct editing
nnoremap <leader>ev :e ~/dotfiles/vim-common/common.vim<cr>
nnoremap <leader>en :e ~/Documents/notes/vim-notes.md<cr>
nnoremap <leader>em :call EditMacro()<cr> <Plug>em

" spelling hack. NB the cursor moves bc the mark is relative to the byte
" position in the line. how to make the cursor stick?
nnoremap <leader>l mt[s1z=`t
nnoremap <c-s> mt[s1z=`t
inoremap <C-s> <ESC>mt[s1z=`ta

"" buffer navigation {{{{
nnoremap <leader>1 :b1<CR>
nnoremap <leader>2 :b2 <CR>
nnoremap <leader>3 :b3 <CR>
nnoremap <leader>4 :b4 <CR>
nnoremap <leader>5 :b5 <CR>
nnoremap <leader>6 :b6 <CR>
nnoremap <leader>7 :b7 <CR>
nnoremap <leader>8 :b8 <CR>
nnoremap <leader>9 :b9 <CR>
nnoremap <leader>0 :b10 <CR>

"" }}}}
