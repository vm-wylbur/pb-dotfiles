"
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" git@github.com:vm-wylbur/pb-dotfiles.git
" (c) 2018 [HRDAG](https://hrdag.org), GPL-2 or later
"
" pb-dotfiles/nvim/init.vim symlinked to ~/.config/nvim/init.vim
"
" setup
set nocompatible
let g:python_host_skip_check = 1
let g:python3_host_skip_check = 1
let g:vim_bootstrap_editor = 'nvim'				" nvim or vim
set runtimepath+=$HOME/dotfiles/vim-common

" plugins
call plug#begin(expand('~/.config/nvim/plugged'))

"" hack for plugins themselves
Plug 'tpope/vim-repeat'               " doesn't work? config for surround

" screen and window management
Plug 'mhinz/vim-startify'             " cute!
Plug 'qpkorr/vim-bufkill'             " :BD is very useful

" editing and formatting
Plug 'tpope/vim-surround'             " adds surround action to create cmts
Plug 'tomtom/tcomment_vim'            " gc to toggle comments
Plug 'tpope/vim-unimpaired'           " many additional movements with [ and ]
Plug 'ntpeters/vim-better-whitespace' " to remove trailing whitespace on save
Plug 'machakann/vim-highlightedyank'  " blink
Plug 'haya14busa/incsearch.vim'

" completion
Plug 'lifepillar/vim-mucomplete'

" navigation
Plug 'justinmk/vim-sneak'        " I should use this more.
" Plug 'ctrlpvim/ctrlp.vim'
Plug '/usr/local/opt/fzf'

" snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

"" files, buffers, and tags
Plug 'ap/vim-buftabline'         " adds buffer tabs and numbers
Plug 'majutsushi/tagbar'
Plug 'vim-scripts/Align'


" colors and UI
Plug 'airblade/vim-gitgutter'          " put chars in gutter
Plug 'kshenoy/vim-signature'           " less cluttered, marks more visible
Plug 'itchyny/lightline.vim'           " workable. Prob could be done by hand.
Plug 'luochen1990/rainbow'             " I really like these!
Plug 'itchyny/vim-cursorword'          " this works w * operator
Plug 'mhartington/oceanic-next'

" languages
Plug 'sheerun/vim-polyglot'
" Plug 'davidhalter/jedi-vim'
Plug 'lervag/vimtex'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
Plug 'reedes/vim-pencil'
Plug 'vim-scripts/dbext.vim'
" Plug 'jalvesaq/Nvim-R'

" markdown stuff
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vim-pandoc/vim-rmarkdown'
" Plug 'tpope/vim-markdown'

" linting
Plug 'w0rp/ale'

call plug#end()

" must follow all Plug calls
filetype plugin indent on


"---temp------------------------------
nnoremap gt :TagbarToggle<CR>
" TESTING: tComment vs tpope's vim-commentary
" tComment extra mappings:
" yank visual before toggle comment
vmap gy ygvgc
" yank and past visual before toggle comment
vmap gyy ygvgc'>gp'.
" yank line before toggle comment
nmap gy yygcc
" yank and paste line before toggle comment and remember position
" it works both in normal and insert mode
" Use :t-1 instead of yyP to preserve registers
nmap gyy mz:t-1<cr>gCc`zmz
imap gyy <esc>:t-1<cr>gCcgi
nnoremap <leader>t :CtrlPTag<CR>

set listchars=eol:⏎,tab:␉·,trail:␠,nbsp:⎵

source $HOME/dotfiles/vim-common/line.vimrc   " for the lightline config
source $HOME/dotfiles/vim-common/plugins.vim

" terminal stuff, neovim specific
tnoremap <Esc> <C-\><C-n>
tnoremap jj <c-\><c-n>
tnoremap jk <c-\><c-n>:q<cr>
highlight! link TermCursor Cursor
highlight! TermCursorNC guibg=red guifg=white ctermbg=1 ctermfg=15
" Change cursor shape between insert and normal mode in iTerm2.app

" note quite with :w | bd  which should be <leader> gw
let $GIT_EDITOR = 'nvr -cc split --remote-wait'
let g:vimtex_compiler_progname = 'nvr'

"" TODO: move to common file
" Autocomplete
let g:mucomplete#enable_auto_at_startup = 1

nnoremap <leader>s :call UltiSnips#ListSnippets()<CR>

let g:mucomplete#chains = {
	\ 'default' : ['path', 'omni', 'ulti', 'keyn', 'dict', 'uspl'],
	\ 'vim'     : ['path', 'cmd', 'keyn']
	\ }

" Wildmenu
set wildignore+=.DS_Store,Icon\?,*.dmg,*.git,*.pyc,*.o,*.obj,*.so,*.swp,*.zip
set wildmenu " Show possible matches when autocompleting
set wildignorecase " Ignore case when completing file names and directories
"


"" terminal config
" TODO: stop spellcheck in terminal
au TermOpen * setlocal nonumber norelativenumber nospell

" w0rp/ale
let g:ale_linters = {
			\	   'python': ['flake8'],
			\	   'r': ['lintr'],
			\	   'sh': ['shell'],
			\	   'yaml': ['yamllint'],
			\	   'tex': ['chktex'],
			\	   'vim': ['vint'],
\}
let g:ale_fixers = {'r': ['styler']}
let g:ale_enabled = 1
let g:ale_sign_warning = '▲'
let g:ale_sign_error = '✗'
highlight link ALEWarningSign String
highlight link ALEErrorSign Title
let g:ale_sign_column_always = 1
let g:ale_change_sign_column_color = 0
let g:ale_vim_vint_show_style_issues = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_virtualenv_dir_names = []
let b:ale_virtualenv_dir_names = []
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_save = 1


"" python
augroup vimrc-python
  autocmd!
  autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=8 colorcolumn=79
      \ formatoptions+=croq softtabstop=4
      \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
augroup END

" jedi-vim
let g:jedi#popup_on_dot = 0
let g:jedi#force_py_version = 3
let g:jedi#documentation_command = 'K'
let g:jedi#usages_command = '<leader>n'
let g:jedi#rename_command = '<leader>r'
let g:jedi#show_call_signatures = '0'
let g:jedi#completions_command = '<C-Space>'
let g:jedi#smart_auto_mappings = 0

let g:polyglot_disabled = ['python', 'tex', 'markdown']
let g:python_highlight_all = 1

source $HOME/dotfiles/vim-common/remaps.vim
source $HOME/dotfiles/vim-common/sets.vim
source $HOME/dotfiles/vim-common/gui.vim
source $HOME/dotfiles/vim-common/autogrp.vim

nnoremap <leader>ev :e $HOME/dotfiles/nvim/init.vim<cr>
let $NVIM_TUI_ENABLE_TRUE_COLOR=1

" done.
