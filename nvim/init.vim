" Preamble {{{
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" (c) 2017 [HRDAG](https://hrdag.org), GPL-2 or later
"
" moved to github
"    git@github.com:vm-wylbur/pb-dotfiles.git
"
" install by symlinking to ~/.vimrc
" if you keep getting a mess of swap files, use this at the shell:
"    $ find . -type f -name "\.*sw[klmnop]" -delete
"
" adding terminal makes neovim a game-changer!
" }}}

" todo {{{
"
" }}}

" boostrap {{{
if has('vim_starting')
  set nocompatible               " Be iMproved
endif

let vimplug_exists=expand('~/.config/nvim/autoload/plug.vim')
filetype plugin on
let g:vim_bootstrap_langs = "python"
let g:vim_bootstrap_editor = "nvim"				" nvim or vim

set termguicolors
set background=dark

" }}}

" plugins setup and bootstrap {{{
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

" plug packages {{{
call plug#begin(expand('~/.config/nvim/plugged'))
" plugins themselves
Plug 'tpope/vim-repeat'  " doesn't work? needs config for surround

" editing and formatting
Plug 'godlygeek/tabular'      " should align on regex :Tab /char
Plug 'Yggdroot/indentLine'    " ??
Plug 'tpope/vim-surround'
Plug 'ervandew/supertab'
" Plug 'justinmk/vim-sneak'
Plug 'kana/vim-textobj-function'
Plug 'kana/vim-textobj-user'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'

" files, buffers, and tags
Plug 'yegappan/mru'
Plug 'qpkorr/vim-bufkill'
Plug 'majutsushi/tagbar'
Plug 'ap/vim-buftabline'
" Plug 'scrooloose/nerdtree'

" colors and UI
Plug 'frankier/neovim-colors-solarized-truecolor-only'
Plug 'airblade/vim-gitgutter' " put chars in gutter
Plug 'inside/vim-search-pulse'
Plug 'itchyny/lightline.vim'
Plug 'luochen1990/rainbow'
" Plug 'uptech/vim-ping-cursor'

" languages
Plug 'sheerun/vim-polyglot'
" Plug 'davidhalter/jedi-vim'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
Plug 'bps/vim-textobj-python'
Plug 'reedes/vim-pencil'
Plug 'vim-syntastic/syntastic'
Plug 'tpope/vim-fugitive'

"" Vim-Session
Plug 'xolox/vim-misc'
Plug 'xolox/vim-session'

" snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

call plug#end()
" }}}

" Plug configs {{{
set rtp+=$HOME/src/solarized/vim-colors-solarized
let $NVIM_TUI_ENABLE_TRUE_COLOR=1
colorscheme solarized

source $HOME/dotfiles/vim-common/line.vimrc   " for the lightline config

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

let g:sneak#label = 1
" }}}

" Basic setup {{{
"" cursor {{{{
:set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor
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

"" setting up right margin highlighting {{{{
augroup BgHighlight
autocmd!
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END
" makes right margin diff color
execute "set colorcolumn=" . join(range(81,335), ',')
" }}}}

"" automatically leave insert mode after 'updatetime' milliseconds of inaction {{{{
" au CursorHoldI * stopinsert
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

"" Map leader to , {{{{
let mapleader=','
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

"" editing {{{{
set scrolloff=5
" }}}}

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

"" CWD to current buffer's path {{{{
" autocmd BufEnter * lcd %:p:h
" au BufEnter * if &buftypedufRead,BufNewFile *.ext,*.ext3|<buffer[=N]> 

" }}}}

"" session management {{{{
let g:session_directory = "~/.config/nvim/session"
let g:session_autoload = "no"
let g:session_autosave = "no"
let g:session_command_aliases = 1
" }}}}
" }}}

" Visual Settings {{{

"" Tagbar
" nmap <silent> <F4> :TagbarToggle<CR>
nnoremap <leader>tg :TagbarToggle<CR>
let g:tagbar_autofocus = 1
" nnoremap <leader>tt :NERDTreeToggle<CR>

syntax on
set ruler
set relativenumber
set number

let no_buffers_menu=1

set mousemodel=popup
set t_Co=256
set guioptions=egmrti
" set gfn=Monospace\ 10

"" setup gui or not {{{{
if has("gui_running")
  if has("gui_mac") || has("gui_macvim")
    set guifont=Menlo:h12
    set transparency=7
  endif
else
  let g:CSApprox_loaded = 1
  " IndentLine
  let g:indentLine_enabled = 1
  let g:indentLine_concealcursor = 0
  let g:indentLine_char = '┆'
  let g:indentLine_faster = 1
endif
" }}}}

"" Disable the blinking cursor. {{{{
set gcr=a:blinkon0
" }}}}

"" Status bar {{{{
set laststatus=2
" }}}}

"" Use modeline overrides {{{{
set modeline
set modelines=10
" }}}}
" }}}

" Abbreviations {{{

"" abbreviations for quick datestamping in Insert mode
iab xsdate <c-r>=strftime("%Y-%m-%dT%H:%M%Z")<CR>
iab xldate <c-r>=strftime("%a %d %b %Y %H:%M:%S%Z")<CR>

"" no one is really happy until you have this shortcuts
cnoreabbrev W! w!
cnoreabbrev Q! q!
cnoreabbrev Qall! qall!
cnoreabbrev Wq wq
cnoreabbrev Wa wa
cnoreabbrev wQ wq
cnoreabbrev WQ wq
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev Qall qall
" }}}

" {{{ uncategorized
" vimshell.vim
let g:vimshell_user_prompt = 'fnamemodify(getcwd(), ":~")'
let g:vimshell_prompt =  '$ '

"" terminal emulation {{{{
if g:vim_bootstrap_editor == 'nvim'
  nnoremap <silent> <leader>sh :terminal<CR>
else
  nnoremap <silent> <leader>sh :VimShellCreate<CR>
endif
" }}}}
" }}}

" Autocmd Rules {{{

"" Remember cursor position
augroup vimrc-remember-cursor-position
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

"" txt
augroup vimrc-wrapping
  autocmd!
  autocmd BufRead,BufNewFile *.txt call s:setupWrapping()
augroup END

set autoread
" }}}

" terminal config {{{
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
" }}}

" Mappings {{{

"" Search mappings:
" These will make it so that going to the next one in a
" search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <space> <C-d>

"" bubbling text with vim-impaired and Drew Neil's mappings
nmap <C-Up> [e
nmap <C-Down> ]e
" Bubble multiple lines
vmap <C-Up> [egv
vmap <C-Down> ]egv

"" FIXME: not so great session management
nnoremap <leader>so :OpenSession<Space>
nnoremap <leader>ss :SaveSession<Space>
nnoremap <leader>sd :DeleteSession<CR>
nnoremap <leader>sc :CloseSession<CR>

" fugitive mappings
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader>gc :Gcommit -a<CR>
nnoremap <leader>gp :Gpush<CR>
nnoremap <leader>gl :Gpull<CR>

"" Set working directory
" doesn't work
" nnoremap <leader>. :lcd %:p:h<CR>

nnoremap <leader>w :w <CR>
nnoremap <leader>W :BD<CR>   " kill buffer leave window
nnoremap <leader>m :MRU<CR>
nnoremap <leader>r :ll <CR>  " syntastic next error
nnoremap <A-a> <C-a>  " increment a number

" to normal mode with jj or jk
inoremap jj <ESC>
inoremap jk <ESC>

" Emacs bindings in command line mode
cnoremap <c-a> <home>
cnoremap <c-e> <end>
cnoremap <A-bs> <c-w>
" Keep the cursor in place while joining lines
nnoremap J mzJ`z

" spelling hack
nnoremap <leader>l mt[s1z=`t

" Quick filx
nnoremap <Leader>sx :source %<CR>
nnoremap <Leader>ei :e ~/dotfiles/nvim/init.vim<CR>
" edit in current buffer's path
nnoremap <Leader>ew :e <C-R>=expand("%:p:h") . "/"<CR>



"" add a freq-access-file list to draw from
" nnoremap <Leader>es :e ~/Documents/notes/vim-todo.md<CR>
" nnoremap <Leader>et :e ~/Documents/notes/tech-todo.md<CR>
" nnoremap <Leader>en :e ~/Documents/notes/vim-notes.md<CR>

" this doesn't work but it's in the right direction
" nnoremap <leader>r :lcd %:p:h<CR>:Dispatch! run <CR>

"" folding
nnoremap <leader>z za
nnoremap <leader>Z zA

"" buffer navigation
nnoremap <leader>1 :b1<CR>
nnoremap <leader>2 :b2 <CR>
nnoremap <leader>3 :b3 <CR>
nnoremap <leader>4 :b4 <CR>
nnoremap <leader>5 :b5 <CR>
nnoremap <leader>6 :b6 <CR>
nnoremap <leader>7 :b7 <CR>
nnoremap <leader>8 :b8 <CR>
nnoremap <leader>9 :b9 <CR>

nnoremap <A-1> 1<c-w><c-w>
nnoremap <A-2> 2<c-w><c-w>
nnoremap <A-3> 3<c-w><c-w>
nnoremap <A-4> 4<c-w><c-w>
nnoremap <A-5> 5<c-w><c-w>
nnoremap <A-6> 6<c-w><c-w>
nnoremap <A-7> 7<c-w><c-w>
nnoremap <A-8> 8<c-w><c-w>
nnoremap <A-9> 9<c-w><c-w>

" quickies
" FIXME: what do these do?
" noremap YY "+y<CR>
" noremap <leader>p "+gP<CR>
" noremap XX "+x<CR>

"" Clean search (highlight)
nnoremap <silent> <leader><space> :noh<cr>

"" Switching windows
" this is so important that even though
" these keys have other uses (esp C-l), we need them
" for window navigation
" " this is so important that even though
" these keys have other uses (esp C-l), we need them
" for window navigation
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l
noremap <C-h> <C-w>h
noremap <silent> <c-p> :nohls<cr>zz<c-l>

"" Vmap for maintain Visual Mode after shifting > and <
vmap < <gv
vmap > >gv

"" Move visual block
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

"" not working but cool sounding stuff
" Opens an edit command with the path of the currently edited file filled in
" doesn't work :( would be v good!
" noremap <Leader>e :e <C-R>=expand("%:p:h") . "/" <CR>

"" Opens a tab edit command with the path of the currently edited file filled
" noremap <Leader>te :tabe <C-R>=expand("%:p:h") . "/" <CR>
" nnoremap <silent> <leader>e :FZF -m<CR>
" cnoremap <C-P> <C-R>=expand("%:p:h") . "/" <CR>
" nnoremap <silent> <leader>b :Buffers<CR>


" snippets {{{
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"
let g:UltiSnipsEditSplit="vertical"
" }}}

" syntastic {{{
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
let g:syntastic_python_checkers=['pep8']
let g:syntastic_r_checkers = ['lintr']
" }}}

" languages {{{
"" python {{{{
" vim-python
augroup vimrc-python
  autocmd!
  autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=8 colorcolumn=79
      \ formatoptions+=croq softtabstop=4
      \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
augroup END

" jedi-vim
let g:jedi#popup_on_dot = 0
let g:jedi#goto_assignments_command = "<leader>g"
let g:jedi#goto_definitions_command = "<leader>d"
" let g:jedi#documentation_command = "K"
let g:jedi#usages_command = "<leader>n"
let g:jedi#rename_command = "<leader>r"
let g:jedi#show_call_signatures = "0"
let g:jedi#completions_command = "<C-Space>"
let g:jedi#smart_auto_mappings = 0
" }}}}

"" syntastic {{{{
let g:syntastic_python_checkers=['python', 'flake8']
" }}}}

"" Syntax highlight {{{{
" Default highlight is better than polyglot
let g:polyglot_disabled = ['python']
let python_highlight_all = 1
" }}}}

set modeline
set modelines=5
" vim: set foldmethod=marker foldlevel=0:
