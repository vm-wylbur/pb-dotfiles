" Preamble {{{
"
" Last Modified:                          <Sun 29 Oct 2017 11:44:48 AM PDT>
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
" - clean up the autocmd stuff, esp for markdown. see _learning vimscript the hard way_
" - should think more about wildmode and tab completion
"
" }}}

" setup {{{
" set nocompatible

filetype plugin on
let g:vim_bootstrap_langs = 'python'
let g:vim_bootstrap_editor = 'nvim'				" nvim or vim
set runtimepath+=$HOME/dotfiles/vim-common
" }}}

" plugins {{{
call plug#begin(expand('~/.config/nvim/plugged'))

"" hack for plugins themselves
Plug 'tpope/vim-repeat'  " doesn't work? needs config for surround

" screen and window management
Plug 'mhinz/vim-startify'
" Plug 'spolu/dwm.vim'

"" editing and formatting
" Plug 'kbarrette/mediummode'
" Plug 'godlygeek/tabular'         " should align on regex :Tab /char
Plug 'tpope/vim-surround'        " adds surround action to create cmts
Plug 'kana/vim-textobj-function' " adds functions to create textobjs
Plug 'kana/vim-textobj-user'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'
Plug 'ntpeters/vim-better-whitespace'
Plug 'terryma/vim-expand-region'

" completion
Plug 'zchee/deoplete-jedi'
Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

" help
Plug 'rizzatti/dash.vim'
Plug 'lifepillar/vim-cheat40'  " cheat sheet: <leader>?

" navigation
Plug 'justinmk/vim-sneak'

"" files, buffers, and tags
Plug 'jlanzarotta/bufexplorer'
Plug 'ap/vim-buftabline'  " adds buffer tabs and numbers
Plug 'tpope/vim-vinegar'    " just hit - for the current path
Plug 'scrooloose/nerdtree'   " makes vinegar a little nicer
" Plug 'mtth/scratch.vim'  " this should be more useful than it is.
" Plug 'mileszs/ack.vim'    " :Ack to grep cwd; see options
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" colors and UI
Plug 'airblade/vim-gitgutter' " put chars in gutter
Plug 'yuttie/comfortable-motion.vim'  " smooths scrolling
Plug 'jeetsukumaran/vim-markology'    " look at all the marks!
Plug 'itchyny/lightline.vim'
Plug 'luochen1990/rainbow'
Plug 'icymind/NeoSolarized'

" languages
Plug 'sheerun/vim-polyglot'
Plug 'davidhalter/jedi-vim'
Plug 'lervag/vimtex'
" Plug 'donRaphaco/neotex', { 'for': 'tex' }
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
Plug 'bps/vim-textobj-python'
Plug 'reedes/vim-pencil'
" Plug 'vim-scripts/timestamp.vim'
Plug 'tpope/vim-fugitive'

" markdown stuff
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vim-pandoc/vim-rmarkdown'

" linting
Plug 'w0rp/ale'

" snippets
" Plug 'SirVer/ultisnips'
" Plug 'honza/vim-snippets'
call plug#end()
" }}}

" plugin configs {{{
" other solarized have bad colors in terminal
colorscheme NeoSolarized
let g:sneak#label = 1
let g:sneak#streak = 1
nmap s <Plug>SneakLabel_s
nmap S <Plug>SneakLabel_S

let g:comfortable_motion_scroll_down_key = "j"
let g:comfortable_motion_scroll_up_key = "k"

let g:livepreview_previewer = 'open -a Preview'
let g:timestamp_modelines = 10
" deoplete
" call deoplete#enable()
" autocmd FileType python nnoremap <leader>y :0,$!yapf<CR>
" autocmd CompleteDone * pclose " To close preview window of deoplete automagically

let g:deoplete#enable_at_startup = 1
let g:deoplete#auto_complete_start_length = 1
let g:deoplete#disable_auto_complete = 0
let g:deoplete#sources#jedi#statement_length = 30
let g:deoplete#sources#jedi#show_docstring = 1
let g:deoplete#sources#jedi#short_types = 1

" whitespace
autocmd BufEnter * EnableStripWhitespaceOnSave

" Insert mode completion
" imap <c-x><c-k> <plug>(fzf-complete-word)
" imap <c-x><c-f> <plug>(fzf-complete-path)
" imap <c-x><c-j> <plug>(fzf-complete-file-ag)
imap <c-x><c-l> <plug>(fzf-complete-line)

" cheat40.vim needs a hack to open the window at 42 chars
" this is a workaround for Markology but it doesn't look bad.
let g:cheat40_use_default = 0

let g:rainbow_active = 1

source $HOME/dotfiles/vim-common/line.vimrc   " for the lightline config
set laststatus=2

let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
  augroup pencil
    autocmd!
    autocmd FileType markdown,mkd  call pencil#init()
    autocmd FileType text          call pencil#init()
    autocmd FileType tex           call pencil#init()
  augroup END
autocmd FileType markdown,mkd,tex setlocal spell
autocmd FileType markdown,mkd,tex setlocal wrap

autocmd FileType tex setlocal spell
autocmd FileType tex setlocal wrap

" stop spellcheck in terminal
autocmd FileType terminal setlocal nospell


let g:buftabline_numbers=1
let g:buftabline_indicators='on' " this is helpful.
let g:buftabline_separators='on'

" let g:MRU_Exclude_Files = '.*/.git/COMMIT_EDITMSG$'

" keep in mind that C-v TAB will insert a literal tab
" currently commented out bc I don't understand it.
" let g:SuperTabCompletionContexts = ['s:ContextText', 's:ContextDiscover']
" let g:SuperTabContextTextOmniPrecedence = ['&omnifunc', '&completefunc']
" let g:SuperTabContextDiscoverDiscovery =
"     \ ["&completefunc:<c-x><c-u>", "&omnifunc:<c-x><c-o>"]

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
" none of the colors seem to work.
" highlight! nCursor guifg=black guibg=magenta gui=reverse
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
execute 'set colorcolumn=' . join(range(81,335), ',')
" }}}}

" }}}

" editing {{{

"" Autocomplete {{{{
set omnifunc=syntaxcomplete#Complete
set complete+=i
set complete+=kspell
set completeopt+=menuone,noselect
set completeopt+=preview
" }}}}

" Wildmenu {{{{
set wildignore+=.DS_Store,Icon\?,*.dmg,*.git,*.pyc,*.o,*.obj,*.so,*.swp,*.zip
set wildmenu " Show possible matches when autocompleting
set wildignorecase " Ignore case when completing file names and directories
" }}}}

"" Auto commands at save {{{{
" function! <SID>StripTrailingWhitespaces()
"     let l = line(".")
"     let c = col(".")
"     %s/\s\+$//e
"     call cursor(l, c)
"   endfun
set autoread
augroup autoSaveAndRead
  autocmd!
  autocmd TextChanged,InsertLeave,FocusLost * silent! wall
  autocmd CursorHold * silent! checktime
augroup END
" autocmd BufWritePre * :%s/\s\+$//e  " removes training whitespace
" autocmd BufWritePre python,sh,r,makefile :call <SID>StripTrailingWhitespaces()
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
set smarttab autoindent
" }}}}

"" Enable hidden buffers {{{{
set hidden
" }}}}

"" for MacOS {{{{
if has('macunix')
  vmap <S-x> :!pbcopy<CR>
  vmap <S-c> :w !pbcopy<CR><CR>
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
" set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
set gdefault
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
" unclear why, but this doesn't work
" iab xsdate <c-r>=strftime("%Y-%m-%dT%H:%M%Z")<CR>
" iab xldate <c-r>=strftime("%a %d %b %Y %H:%M:%S%Z")<CR>
" }}}

" mappings {{{
"" the big picture here is:
"" * remapping std vim keys should be enhancements, not overrides
"" * leader keys are in groups
"" * try to stay off remapping C- keys. There's already lots there.
"" * A-x keys move among windows and do not-vimmy stuff

"" mapleader {{{{
let g:mapleader='\'
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
tnoremap <a-1> <c-\><c-n>1<c-w><c-w>
tnoremap <a-2> <c-\><c-n>2<c-w><c-w>
tnoremap <a-3> <c-\><c-n>3<c-w><c-w>
tnoremap <a-4> <c-\><c-n>4<c-w><c-w>
tnoremap <a-5> <c-\><c-n>5<c-w><c-w>
tnoremap <a-6> <c-\><c-n>6<c-w><c-w>
nnoremap <A-1> 1<c-w><c-w>
nnoremap <A-2> 2<c-w><c-w>
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

" let g:dwm_map_keys = 0
nnoremap <c-k> <c-w>W
nnoremap <c-j> <c-w><c-p>
tnoremap <c-j> <c-\><c-n><c-w><c-p>

tnoremap jj <c-\><c-n>
" nnoremap <c-k> <c-w>k<c-w>
" nnoremap <leader>j <c-w>w
" nnoremap <leader>k <c-w>w
" if !hasmapto('<Plug>DWMRotateCounterclockwise')
"     nmap <leader>, <Plug>DWMRotateCounterclockwise
" endif
" nnoremap <c-,> <Plug>DWMRotateCounterClockwise
" if !hasmapto('<Plug>DWMRotateClockwise')
"     nmap <leader>. <Plug>DWMRotateClockwise
" endif
" nnoremap <c-.> <Plug>DWMRotateClockwise
" if !hasmapto('<Plug>DWMNew')
"     nmap <leader>N <Plug>DWMNew
" endif
" if !hasmapto('<Plug>DWMClose')
"     nmap <leader>C <Plug>DWMClose
" endif
" if !hasmapto('<Plug>DWMFocus')
"     nmap <C-Space> <Plug>DWMFocus
" endif
" }}}}

" }}}

" leader {{{
"" the big picture here is:
"" * a small number of important keys get single-char leader
"" * most keys are in groups of 2-char leaders

"" PB specifics {{{{
nnoremap <leader>x :so %<CR>
nnoremap <leader>m :History<CR>
" BufExplorer is pretty much emacs
nnoremap <leader>b :BufExplorer<CR>

nnoremap <leader>\ :BLines<space><CR>
" needs better mapping; note jedi has some leader keys.
nnoremap <leader>G :Lines<space>
nnoremap <leader>f :Files<space>
nnoremap <leader>a :Ag<space>
nnoremap <leader>` :Marks<CR>
inoremap <c-x><c-l> <plug>(fzf-complete-line)

" Dash for word under point
nmap <silent> <leader>d <Plug>DashSearch

" spelling hack
nnoremap <leader>l mt[s1z=`t
inoremap <C-s> <ESC>mt[s1z=`ta

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
nnoremap <leader>0 :b10 <CR>

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
"

" snippets {{{{
" let g:UltiSnipsExpandTrigger='<tab>'
" let g:UltiSnipsJumpForwardTrigger='<tab>'
" let g:UltiSnipsJumpBackwardTrigger='<c-b>'
" let g:UltiSnipsEditSplit='vertical'
" }}}}

" w0rp/ale {{{{
let g:ale_linters = {
\   'python': ['flake8'],
\   'r': ['lintr'],
\   'sh': ['shell'],
\   'yaml': ['yamllint'],
\   'tex': ['chktex'],
\   'vim': ['vint'],
\}
let g:ale_sign_warning = '▲'
let g:ale_sign_error = '✗'
highlight link ALEWarningSign String
highlight link ALEErrorSign Title
let g:ale_sign_column_always = 1
let g:ale_change_sign_column_color = 1
let g:ale_enabled = 1
let g:ale_lint_on_insert_leave = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_vim_vint_show_style_issues = 1
" }}}}

"" python {{{{
augroup vimrc-python
  autocmd!
  autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=8 colorcolumn=79
      \ formatoptions+=croq softtabstop=4
      \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
augroup END

" jedi-vim
let g:jedi#popup_on_dot = 0
let g:jedi#goto_assignments_command = '<leader>g'
let g:jedi#goto_definitions_command = '<leader>d'
let g:jedi#documentation_command = 'K'
let g:jedi#usages_command = '<leader>n'
let g:jedi#rename_command = '<leader>r'
let g:jedi#show_call_signatures = '0'
let g:jedi#completions_command = '<C-Space>'
let g:jedi#smart_auto_mappings = 0

let g:polyglot_disabled = ['python', 'tex']
let g:python_highlight_all = 1
" }}}}

" }}}
" timestamp {{{
" https://gist.github.com/jelera/783801
" auto-update the timestamp right before saving a file

autocmd! BufWritePre * :call s:timestamp()
" to update timestamp when saving if its in the first 20 lines of a file
function! s:timestamp()
    let pat = '\(\(Last\)\?\s*\([Cc]hanged\?\|[Mm]odified\|[Uu]pdated\?\)\s*:\s*\).*'
    let rep = '\1' . ' <' . strftime("%a %d %b %Y %I:%M:%S %p %Z") . '>'
    call s:subst(1, 20, pat, rep)
endfunction
" subst taken from timestamp.vim
" {{{ subst( start, end, pat, rep): substitute on range start - end.
function! s:subst(start, end, pat, rep)
    let lineno = a:start
    while lineno <= a:end
	let curline = getline(lineno)
	if match(curline, a:pat) != -1
	    let newline = substitute( curline, a:pat, a:rep, '' )
	    if( newline != curline )
		" Only substitute if we made a change
		"silent! undojoin
		keepjumps call setline(lineno, newline)
	    endif
	endif
	let lineno = lineno + 1
    endwhile
endfunction
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

" }}}

set modeline
set modelines=5
setlocal foldmethod=marker
" vim: set foldmethod=marker foldlevel=1:
