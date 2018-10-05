" Preamble {{{
"
" Last Modified: <Wed 03 Oct 2018 09:18:07 PM PDT>
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" (c) 2018 [HRDAG](https://hrdag.org), GPL-2 or later
"
" on github at
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
set nocompatible

" I think both of these are unnecessary. filetype loads 2x without this line.
" filetype plugin on
" let g:vim_bootstrap_langs = 'python'
let g:python_host_skip_check = 1
let g:python3_host_skip_check = 1

let g:vim_bootstrap_editor = 'nvim'				" nvim or vim
set runtimepath+=$HOME/dotfiles/vim-common
" }}}

" plugins {{{
call plug#begin(expand('~/.config/nvim/plugged'))

"" hack for plugins themselves
Plug 'tpope/vim-repeat'               " doesn't work? config for surround

" screen and window management
Plug 'mhinz/vim-startify'             " cute!

" editing and formatting
Plug 'tpope/vim-surround'             " adds surround action to create cmts
" Plug 'tpope/vim-abolish'
Plug 'tpope/vim-commentary'           " wow, all the time.
Plug 'tpope/vim-unimpaired'           " many additional movements with [ and ]
Plug 'ntpeters/vim-better-whitespace' " to remove trailing whitespace on save
" Plug 'terryma/vim-expand-region'      " + to increase visual selection
Plug 'tommcdo/vim-exchange'           " cx{motion} to exhange text objs
" Plug 'mbbill/undotree'                " UndotreeToggle to bring it up
Plug 'machakann/vim-highlightedyank'  " blink

" completion
" note: YCM never worked
"       nvim-completion-manager works on eleanor but not petunia
"       deoplete works on petunia but not eleanor
if hostname() == 'eleanor'
  Plug 'roxma/nvim-completion-manager'
else
  Plug 'zchee/deoplete-jedi'
  Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
endif

" help
Plug 'rizzatti/dash.vim'       " c-d to lookup at point
Plug 'lifepillar/vim-cheat40'  " cheat sheet: <leader>?

" navigation
Plug 'justinmk/vim-sneak'        " I should use this more.

"" files, buffers, and tags
Plug 'jlanzarotta/bufexplorer'   " helpful but SLOW
Plug 'ap/vim-buftabline'         " adds buffer tabs and numbers
Plug 'dhruvasagar/vim-vinegar'   " - for curdir and adds some netrw behaviors
Plug 'tpope/vim-eunuch'          " u-nick(s), get it? *nix bits: Find, Rename
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" colors and UI
Plug 'airblade/vim-gitgutter'          " put chars in gutter
" Plug 'jeetsukumaran/vim-markology'   " kills syntax hilighting on cur line
Plug 'kshenoy/vim-signature'           " less cluttered, marks more visible
Plug 'itchyny/lightline.vim'           " workable. Prob could be done by hand.
Plug 'luochen1990/rainbow'             " I really like these!
Plug 'itchyny/vim-cursorword'          " this works w * operator
" Plug 't9md/vim-choosewin'              " cool idea: on <leader>w
Plug 'icymind/NeoSolarized'
Plug 'joshdick/onedark.vim'
Plug 'mhartington/oceanic-next'

" languages
Plug 'sheerun/vim-polyglot'
Plug 'davidhalter/jedi-vim'
Plug 'lervag/vimtex'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
Plug 'reedes/vim-pencil'
Plug 'tpope/vim-fugitive'
Plug 'tmhedberg/SimpylFold'            " folding for python, za/zc

" markdown stuff
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vim-pandoc/vim-rmarkdown'
Plug 'tpope/vim-markdown'

" linting
Plug 'w0rp/ale'

call plug#end()
" }}}

" plugin configs {{{

" other solarized have bad colors in terminal
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
colorscheme NeoSolarized
" colorscheme onedark

let g:oceanic_next_terminal_bold = 1
let g:oceanic_next_terminal_italic = 1
" colorscheme OceanicNext

let g:neosolarized_bold = 1
let g:neosolarized_underline = 1
let g:neosolarized_italic = 1
let g:neosolarized_vertSplitBgTrans = 0
let g:neosolarized_contrast = "high"
set background=dark

let g:jedi#force_py_version = 3

highlight Comment cterm=italic
highlight Comment gui=italic
" change cursor shape with mode
" let &t_ZH="\e[3m"
" let &t_ZR="\e[23m"

let g:gitgutter_eager = 0
let g:gitgutter_async = 1
let g:gitgutter_realtime = 1

if has("persistent_undo")
    set undodir=~/.undodir/
    set undofile
endif

" FIXME
" nnoremap <c--> <Plug>choosewin
let g:choosewin_overlay_enable = 1

set signcolumn=yes

let g:sneak#label = 1
let g:sneak#streak = 1
nmap s <Plug>SneakLabel_s
nmap S <Plug>SneakLabel_S

let g:comfortable_motion_scroll_down_key = "j"
let g:comfortable_motion_scroll_up_key = "k"

let g:timestamp_modelines = 1

" deoplete
if hostname() != 'eleanor'
  call deoplete#enable()
  autocmd CompleteDone * pclose
  let g:deoplete#enable_at_startup = 1
  let g:deoplete#auto_complete_start_length = 1
  let g:deoplete#disable_auto_complete = 0
  let g:deoplete#sources#jedi#statement_length = 30
  let g:deoplete#sources#jedi#show_docstring = 1
  let g:deoplete#sources#jedi#short_types = 1
  let g:deoplete#file#enable_buffer_path = 1
endif

let g:cm_smart_enable = 1
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"

" whitespace
autocmd BufEnter * EnableStripWhitespaceOnSave
" autocmd BufEnter * lcd %:p:h



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
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
autocmd BufRead,BufNew *.md set filetype=markdown

autocmd FileType tex setlocal spell
autocmd FileType tex setlocal wrap

" stop spellcheck in terminal
autocmd FileType terminal setlocal nospell


let g:buftabline_numbers=1
let g:buftabline_indicators='on' " this is helpful.
let g:buftabline_separators='on'
" let g:MRU_Exclude_Files = '.*/.git/COMMIT_EDITMSG$'

let g:scratch_persistence_file = '~/tmp/scratch.md'
let g:scratch_insert_autohide = 0
let g:scratch_filetype = 'markdown'
let g:scratch_autohide = 1
" }}}

" cursor+gui+colors {{{

"" basics {{{{
set termguicolors
" set background=dark
syntax on
set ruler
set relativenumber
set number
" }}}}

" cursor stuff {{{{
set mouse=a
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
set nodigraph  " use c-k to start digraph: é
" }}}}

" Wildmenu {{{{
set wildignore+=.DS_Store,Icon\?,*.dmg,*.git,*.pyc,*.o,*.obj,*.so,*.swp,*.zip
set wildmenu " Show possible matches when autocompleting
set wildignorecase " Ignore case when completing file names and directories
" }}}}

" set inccommand=split

"" Auto commands at save {{{{
set autoread
augroup autoSaveAndRead
  autocmd!
  autocmd TextChanged,InsertLeave,FocusLost * silent! wall
  autocmd CursorHold * silent! checktime
augroup END
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

"" Tabs. May be overwritten by autocmd rules {{{{
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
" set nobackup
if exists($SUDO_USER)
  set nobackup
  set nowritebackup
else
  set backupdir=~/.vim/tmp/backup
  set backupdir+=.
endif

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
" because scrolling is *the* main thing we do
nnoremap <space> <C-d>
nnoremap <C-space> <C-u>
" repeat the last macro.
nnoremap <return> @@
" increment a number; C-a is overloaded everywhere.
nnoremap <A-a> <C-a>

" some notes here:

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

" }}}}

"" window navigation via Meta {{{{
tnoremap <a-1> <c-\><c-n>1<c-w><c-w>
tnoremap <a-2> <c-\><c-n>2<c-w><c-w>
tnoremap <a-3> <c-\><c-n>3<c-w><c-w>
tnoremap <a-4> <c-\><c-n>4<c-w><c-w>
tnoremap <a-5> <c-\><c-n>5<c-w><c-w>
tnoremap <a-6> <c-\><c-n>6<c-w><c-w>
nnoremap <a-1> 1<c-w><c-w>
nnoremap <a-2> 2<c-w><c-w>
nnoremap <a-1> 1<c-w><c-w>
nnoremap <a-2> 2<c-w><c-w>
nnoremap <a-3> 3<c-w><c-w>
nnoremap <a-4> 4<c-w><c-w>
nnoremap <a-5> 5<c-w><c-w>
nnoremap <a-6> 6<c-w><c-w>
nnoremap <a-7> 7<c-w><c-w>
nnoremap <a-8> 8<c-w><c-w>
nnoremap <a-9> 9<c-w><c-w>
inoremap <a-h> <C-\><C-N><C-w>h
inoremap <a-j> <C-\><C-N><C-w>j
inoremap <a-k> <C-\><C-N><C-w>k
inoremap <a-l> <C-\><C-N><C-w>l
nnoremap <a-h> <C-w>h
nnoremap <a-j> <C-w>j
nnoremap <a-k> <C-w>k
nnoremap <a-l> <C-w>l

" let g:dwm_map_keys = 0
nnoremap <c-k> <c-w>W
nnoremap <c-j> <c-w><c-p>
tnoremap <c-j> <c-\><c-n><c-w><c-p>
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

" needs better mapping; note jedi has some leader keys.
" these are from fzf
" should BLines be <leader>g? to be parallel to Line?
nnoremap <leader>\ :BLines<space><CR>
nnoremap <leader>g :BLines<space><CR>
nnoremap <leader>G :Lines<space>
nnoremap <leader>a :Ag<space>
nnoremap <leader>f :Files<space>
nnoremap <leader>` :Marks<CR>
inoremap <c-x><c-l> <plug>(fzf-complete-line)

" this is a demo, wraps viw in double-q
" :nnoremap <leader>" viw<esc>a"<esc>bi"<esc>lel

" shadowing : commands
" nnoremap <leader>w :ChooseWin<cr>
" nnoremap <leader>wt :ChooseWinSwap<cr>
" nnoremap <leader>ws :ChooseWinSwapStay<cr>

" direct editing
nnoremap <leader>ev :e ~/dotfiles/vim-common/common.vim<cr>
nnoremap <leader>en :e ~/Documents/notes/vim-notes.md<cr>
nnoremap <leader>em :call EditMacro()<cr> <Plug>em

" Dash for word under point
nmap <silent> <leader>d <Plug>DashSearch

" spelling hack. NB the cursor moves bc the mark is relative to the byte
" position in the line. how to make the cursor stick?
nnoremap <leader>l mt[s1z=`t
nnoremap <c-s> mt[s1z=`t
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
let g:ale_enabled = 1
let g:ale_sign_warning = '▲'
let g:ale_sign_error = '✗'
highlight link ALEWarningSign String
highlight link ALEErrorSign Title
let g:ale_sign_column_always = 1
let g:ale_change_sign_column_color = 1
let g:ale_vim_vint_show_style_issues = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_virtualenv_dir_names = []
let b:ale_virtualenv_dir_names = []
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_save = 1
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

let g:polyglot_disabled = ['python', 'tex', 'markdown']
let g:python_highlight_all = 1
" }}}}

" }}}
" timestamp {{{
" https://gist.github.com/jelera/783801
" auto-update the timestamp right before saving a file

function! EditMacro()
  call inputsave()
  let g:regToEdit = input('Register to edit: ')
  call inputrestore()
  execute "nnoremap <Plug>em :let @" . eval("g:regToEdit") . "='<c-r><c-r>" . eval("g:regToEdit")
endfunction

autocmd! BufWritePre * :call s:timestamp()
" to update timestamp when saving if its in the first 20 lines of a file
function! s:timestamp()
    let pat = '\(\(Last\)\?\s*\([Cc]hanged\?\|[Mm]odified\|[Uu]pdated\?\)\s*:\s*\).*'
    let rep = '\1' . '<' . strftime("%a %d %b %Y %I:%M:%S %p %Z") . '>'
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
set nofoldenable
" vim: set foldmethod=marker foldlevel=1:
