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
" todo:
" - need to put the augroup cmds together
" - clean up the autocmd stuff, esp for markdown. see "learning vimscript the hard way"
" - should think more about wildmode and tab completion
" }}}

" setup {{{
set nocompatible

filetype plugin on
let g:vim_bootstrap_langs = "python"
let g:vim_bootstrap_editor = "nvim"				" nvim or vim

" }}}

" plugins {{{
call plug#begin(expand('~/.config/nvim/plugged'))

"" hack for plugins themselves
Plug 'tpope/vim-repeat'  " doesn't work? needs config for surround

"" editing and formatting
""" fixme: replace tabular with junegunn/vim-easy-align
Plug 'godlygeek/tabular'         " should align on regex :Tab /char
Plug 'tpope/vim-surround'        " adds surround action to create cmts
Plug 'ervandew/supertab'
Plug 'kana/vim-textobj-function' " adds functions to create textobjs
Plug 'kana/vim-textobj-user'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'

"" files, buffers, and tags
Plug 'yegappan/mru'
Plug 'qpkorr/vim-bufkill' " adds BufDelete, etc, keeping windows
                          " Plug 'majutsushi/tagbar'
Plug 'ap/vim-buftabline'  " adds buffer tabs and numbers
Plug 'mtth/scratch.vim'
Plug 'mileszs/ack.vim'    " :Ack to grep cwd; see options

" fzf is its own thing
" Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
" Plug 'junegunn/fzf.vim'

" colors and UI
" todo: maybe a color that's a little sharper?
Plug 'frankier/neovim-colors-solarized-truecolor-only'
Plug 'airblade/vim-gitgutter' " put chars in gutter
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

" keep in mind that C-v TAB will insert a literal tab
let g:SuperTabCompletionContexts = ['s:ContextText', 's:ContextDiscover']
let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']
let g:SuperTabContextDiscoverDiscovery =
    \ ["&completefunc:<c-x><c-u>", "&omnifunc:<c-x><c-o>"]

let g:scratch_persistence_file = '~/tmp/scratch.md'
let g:scratch_insert_autohide = 0
let g:scratch_filetype = 'markdown'
let g:scratch_autohide = 1
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

"" switch cwd to buffer's path {{{{
autocmd BufEnter * lcd %:p:h
" }}}}
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
set spelllang=en_us spell
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
"" the big picture here is:
"" * remapping std vim keys should be enhancements, not overrides
"" * leader keys are in groups
"" * try to stay off remapping C- keys. There's already lots there.
"" * A-x keys move among windows and do not-vimmy stuff

"" mapleader {{{{
let mapleader='\'
"" }}}}

"" PB specific remaps {{{{
nnoremap <space> <C-d>
" these keep the x cmds from cluttering the delete register
nmap X "_d
nmap XX "_dd
vmap X "_d
vmap x "_d"
nnoremap x "_x
" increment a number; C-a is overloaded everywhere.
nnoremap <A-a> <C-a>
" }}}}

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
" }}}}

"" to normal mode with jj or jk {{{{
inoremap jj <ESC>
inoremap jk <ESC>
" }}}}

"" window navigation via Meta {{{{
nnoremap <A-1> 1<c-w><c-w>
nnoremap <A-2> 2<c-w><c-w>
nnoremap <A-3> 3<c-w><c-w>
nnoremap <A-4> 4<c-w><c-w>
nnoremap <A-5> 5<c-w><c-w>
nnoremap <A-6> 6<c-w><c-w>
nnoremap <A-7> 7<c-w><c-w>
nnoremap <A-8> 8<c-w><c-w>
nnoremap <A-9> 9<c-w><c-w>
inoremap <A-h> <C-\><C-N><C-w>h
inoremap <A-j> <C-\><C-N><C-w>j
inoremap <A-k> <C-\><C-N><C-w>k
inoremap <A-l> <C-\><C-N><C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k
nnoremap <A-l> <C-w>l
"" }}}}

" }}}

" leader {{{
"" the big picture here is:
"" * a small number of important keys get single-char leader
"" * most keys are in groups of 2-char leaders

"" PB specifics {{{{
nnoremap <leader>x :so %<CR>
nnoremap <leader>w :w <CR>
" kill buffer, window stays; think cmd-w; also just :BD
nnoremap <leader>W :BD<CR>
" most-freq files are a simple list, no fzf
nnoremap <leader>m :MRU<CR>
" spelling hack
nnoremap <leader>l mt[s1z=`t

" }}}}

"" direct edits {{{{
nnoremap <Leader>ei :e ~/dotfiles/nvim/init.vim<CR>
nnoremap <Leader>ec :e ~/dotfiles/vim-common/common.vim<CR>
nnoremap <Leader>et :e ~/Documents/notes/tech-todo.md<CR>
nnoremap <Leader>en :e ~/Documents/notes/vim-notes.md<CR>
" [H]=here
nnoremap <Leader>eh :e <C-R>=expand("%:p:h") . "/"<CR>
"" }}}}

"" viewing internal stuff {{{{
nnoremap <Leader>vr :registers<CR>
nnoremap <Leader>v" :registers<CR>
nnoremap <Leader>vm :marks<CR>
nnoremap <Leader>v' :marks<CR>
nnoremap <Leader>vc :changes<CR>
nnoremap <Leader>vj :jumps<CR>
nnoremap <Leader>v; :jumps<CR>
"" }}}}

" fugitive mappings {{{{
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader>gc :Gcommit -a<CR>
nnoremap <leader>gp :Gpush<CR>
nnoremap <leader>gl :Gpull<CR>
" }}}}

"" buffer+window navigation {{{{
nnoremap <leader>1 :b1<CR>
nnoremap <leader>2 :b2 <CR>
nnoremap <leader>3 :b3 <CR>
nnoremap <leader>4 :b4 <CR>
nnoremap <leader>5 :b5 <CR>
nnoremap <leader>6 :b6 <CR>
nnoremap <leader>7 :b7 <CR>
nnoremap <leader>8 :b8 <CR>
nnoremap <leader>9 :b9 <CR>

"" }}}}

"" getting to the scratch buffer {{{{
" these should be on <leader>cX
" :ScratchInsert
" :ScratchSelection
" see scratch help on this stuff
  " let g:scratch_no_mappings = 1

" And set your favorite keys like below: >

  " nmap <leader>gs <plug>(scratch-insert-reuse)
  " nmap <leader>gS <plug>(scratch-insert-clear)
  " xmap <leader>gs <plug>(scratch-selection-reuse)
  " xmap <leader>gS <plug>(scratch-selection-clear)
" }}}}

" }}}

" language {{{

"" markdown {{{{
" In markdown files, Control + a surrounds highlighted text with square
" brackets, then dumps system clipboard contents into parenthesis
autocmd FileType markdown vnoremap <c-a> <Esc>`<i[<Esc>`>la](<Esc>"*]pa)<Esc>
autocmd FileType markdown setlocal nocursorline
autocmd FileType markdown setlocal nocursorcolumn
" }}}}

" snippets {{{{
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"
let g:UltiSnipsEditSplit="vertical"
" }}}}

"" syntastic {{{{
let g:loaded_syntastic_r_lintr_checker = 1
let g:syntastic_aggregate_errors = 1
let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_error_symbol='✗'
let g:syntastic_style_error_symbol = '✗'
let g:syntastic_style_warning_symbol = '⚠'
let g:syntastic_warning_symbol='⚠'
" let g:syntastic_python_checkers=['pep8']
let g:syntastic_python_checkers=['python', 'flake8']
let g:syntastic_r_checkers = ['lintr']
" }}}}

"" python {{{{
augroup vimrc-python
  autocmd!
  autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=8 colorcolumn=79
      \ formatoptions+=croq softtabstop=4
      \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
augroup END

" jedi-vim
" let g:jedi#popup_on_dot = 0
" let g:jedi#goto_assignments_command = "<leader>g"
" let g:jedi#goto_definitions_command = "<leader>d"
" let g:jedi#documentation_command = "K"
" let g:jedi#usages_command = "<leader>n"
" let g:jedi#rename_command = "<leader>r"
" let g:jedi#show_call_signatures = "0"
" let g:jedi#completions_command = "<C-Space>"
" let g:jedi#smart_auto_mappings = 0

let g:polyglot_disabled = ['python']
let python_highlight_all = 1
" }}}}

" }}}

" Autocmd Rules {{{

"" Remember cursor position {{{{
augroup vimrc-remember-cursor-position
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END
" }}}}

" }}}

" misc functions {{{

"" SEARCH ACROSS BUFFERS {{{{
" Looks for a pattern in all the open buffers.
" :Bvimgrep 'pattern' puts results into the quickfix list
" :Blvimgrep 'pattern' puts results into the location list
function! BuffersVimgrep(pattern,cl)
  let str = ''
  if (a:cl == 'l')
    let str = 'l'
  endif
  let str = str.'vimgrep /'.a:pattern.'/'
  for i in range(1, bufnr('$'))
    let str = str.' '.bufname(i)
  endfor
  execute str
  execute a:cl.'w'
endfunction

command! -nargs=1 Bvimgrep  call BuffersVimgrep(<args>,'c')
command! -nargs=1 Blvimgrep call BuffersVimgrep(<args>,'l')

" function! BuffersList()
"   let all = range(0, bufnr('$'))
"   let res = []
"   for b in all
"     if buflisted(b)
"       call add(res, bufname(b))
"     endif
"   endfor
"   return res
" endfunction

" function! GrepBuffers (expression)
"   exec 'vimgrep/'.a:expression.'/ '.join(BuffersList())
" endfunction

" command! -nargs=+ GrepBufs call GrepBuffers(<q-args>)


" }}}}
" }}}

setlocal foldmethod=marker
" vim: set foldmethod=marker foldlevel=1:
