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

" editing
Plug 'godlygeek/tabular'      " should align on regex :Tab /char
Plug 'Yggdroot/indentLine'    " ??
Plug 'tpope/vim-surround'
Plug 'ervandew/supertab'
Plug 'justinmk/vim-sneak'
Plug 'kana/vim-textobj-function'
Plug 'kana/vim-textobj-user'
Plug 'tpope/vim-commentary'

" colors and UI
Plug 'frankier/neovim-colors-solarized-truecolor-only'
Plug 'airblade/vim-gitgutter' " put chars in gutter
Plug 'ap/vim-buftabline'
Plug 'inside/vim-search-pulse'
Plug 'itchyny/lightline.vim'
Plug 'qpkorr/vim-bufkill'
Plug 'luochen1990/rainbow'
Plug 'majutsushi/tagbar'

" languages
Plug 'sheerun/vim-polyglot'
Plug 'davidhalter/jedi-vim'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
Plug 'bps/vim-textobj-python'
Plug 'reedes/vim-pencil'
Plug 'vim-syntastic/syntastic'

"" Vim-Session
" Plug 'xolox/vim-misc'
" Plug 'xolox/vim-session'

" snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

call plug#end()
" }}}

" Plug configs {{{
set rtp+=$HOME/src/solarized/vim-colors-solarized
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

let g:sneak#label = 1
" }}}

" Basic setup {{{
"" cursor
:set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor
au VimLeave * set guicursor=a:block-blinkon0
set cursorline
set cursorcolumn 

"" plugin enabled
filetype plugin indent on

"" Auto commands at save
set omnifunc=syntaxcomplete#Complete
set autoread
augroup autoSaveAndRead
  autocmd!
  autocmd TextChanged,InsertLeave,FocusLost * silent! wall
  autocmd CursorHold * silent! checktime
augroup END
autocmd BufWritePre * :%s/\s\+$//e  " removes training whitespace

"" setting up right margin highlighting
augroup BgHighlight
autocmd!
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END
" makes right margin diff color
execute "set colorcolumn=" . join(range(81,335), ',')

"" automatically leave insert mode after 'updatetime' milliseconds of inaction
au CursorHoldI * stopinsert

"" Encoding
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8
set bomb
set binary

"" Fix backspace indent
set backspace=indent,eol,start

"" Tabs. May be overriten by autocmd rules
set tabstop=2
set softtabstop=0
set shiftwidth=2
set expandtab

"" Map leader to ,
let mapleader=','

"" Enable hidden buffers
set hidden

"" for MacOS
if has('macunix')
  vmap <C-x> :!pbcopy<CR>
  vmap <C-c> :w !pbcopy<CR><CR>
endif

"" Copy/Paste/Cut
if has('unnamedplus')
  set clipboard=unnamed,unnamedplus
endif

"" Disable visualbell
set noerrorbells visualbell t_vb=
if has('autocmd')
  autocmd GUIEnter * set visualbell t_vb=
endif

"" Searching
set hlsearch
set incsearch
set ignorecase
set smartcase

"" editing
set scrolloff=5

"" Directories for swp files
set nobackup
set noswapfile

set fileformats=unix,dos,mac
set showcmd

if exists('$SHELL')
    set shell=$SHELL
else
    set shell=/bin/bash
endif

" session management
let g:session_directory = "~/.config/nvim/session"
let g:session_autoload = "no"
let g:session_autosave = "no"
let g:session_command_aliases = 1
" }}}

" Visual Settings {{{

syntax on
set ruler
set number

let no_buffers_menu=1

set mousemodel=popup
set t_Co=256
set guioptions=egmrti
set gfn=Monospace\ 10

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

"" Disable the blinking cursor.
set gcr=a:blinkon0
set scrolloff=3

"" Status bar
set laststatus=2

"" Use modeline overrides
set modeline
set modelines=10

" set title
" set titleold="Terminal"
" set titlestring=%F
" }}}

" key rempping {{{

"" Search mappings:
" These will make it so that going to the next one in a
" search will center on the line it's found in.
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <space> <C-d>
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

" terminal emulation
if g:vim_bootstrap_editor == 'nvim'
  nnoremap <silent> <leader>sh :terminal<CR>
else
  nnoremap <silent> <leader>sh :VimShellCreate<CR>
endif
" }}}

" Functions {{{

if !exists('*s:setupWrapping')
  function s:setupWrapping()
    set wrap
    set wm=2
    set textwidth=79
  endfunction
endif
" }}}

" Autocmd Rules {{{

"" The PC is fast enough, do syntax highlight syncing from start unless 200 lines
augroup vimrc-sync-fromstart
  autocmd!
  autocmd BufEnter * :syntax sync maxlines=200
augroup END

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

" Mappings {{{

" session management
nnoremap <leader>so :OpenSession<Space>
nnoremap <leader>ss :SaveSession<Space>
nnoremap <leader>sd :DeleteSession<CR>
nnoremap <leader>sc :CloseSession<CR>

"" Set working directory
nnoremap <leader>. :lcd %:p:h<CR>

nnoremap <leader>w :w <CR>
nnoremap <leader>d :BD<CR>   " kill buffer leave window
noremap <leader>c :bd<CR>
nnoremap <leader>r :ll <CR>  " syntastic next error

" nnoremap <leader>h <C-W>h<C-W>_
" nnoremap <leader>l <C-W>l<C-W>_

" Emacs bindings in command line mode
cnoremap <c-a> <home>
cnoremap <c-e> <end>

" Keep the cursor in place while joining lines
nnoremap J mzJ`z

" spelling hack
nnoremap <leader>sp mt[s1z=`t

" Quick edit file lst test.
nnoremap <Leader>er :source ~/dotfiles/vim/vimrc<CR>
nnoremap <Leader>ev :e ~/dotfiles/nvim/init.vim<CR>
nnoremap <Leader>es :e ~/Documents/notes/vim-todo.md<CR>
nnoremap <Leader>et :e ~/Documents/notes/tech-todo.md<CR>
nnoremap <Leader>en :e ~/Documents/notes/vim-notes.md<CR>

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

" quickies
" FIXME: what do these do? 
noremap YY "+y<CR>
noremap <leader>p "+gP<CR>
noremap XX "+x<CR>

"" Close buffer
" fixme: this hsould leave the window open
" fixme: get spell leader and window maintainer

"" Clean search (highlight)
nnoremap <silent> <leader><space> :noh<cr>

"" Switching windows
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l
noremap <C-h> <C-w>h

"" Vmap for maintain Visual Mode after shifting > and <
vmap < <gv
vmap > >gv

"" Move visual block
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv
" Opens an edit command with the path of the currently edited file filled in
" doesn't work :( would be v good!
" noremap <Leader>e :e <C-R>=expand("%:p:h") . "/" <CR>

"" Opens a tab edit command with the path of the currently edited file filled
" noremap <Leader>te :tabe <C-R>=expand("%:p:h") . "/" <CR>
" nnoremap <silent> <leader>e :FZF -m<CR>
" cnoremap <C-P> <C-R>=expand("%:p:h") . "/" <CR>
" nnoremap <silent> <leader>b :Buffers<CR>

"" Tagbar
" nmap <silent> <F4> :TagbarToggle<CR>
nnoremap <leader>tt :TagbarToggle<CR>
let g:tagbar_autofocus = 1

"" snippets
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<c-b>"
let g:UltiSnipsEditSplit="vertical"

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



"" Open current line on GitHub
" nnoremap <Leader>o :.Gbrowse<CR>

"*****************************************************************************
"" Custom configs
"*****************************************************************************

" python
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

" syntastic
let g:syntastic_python_checkers=['python', 'flake8']

" Syntax highlight
" Default highlight is better than polyglot
let g:polyglot_disabled = ['python']
let python_highlight_all = 1

set modeline
set modelines=5
" vim: set foldmethod=marker foldlevel=0:
