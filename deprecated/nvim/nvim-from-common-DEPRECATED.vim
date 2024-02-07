" Preamble
"
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" (c) 2018 [HRDAG](https://hrdag.org), GPL-2 or later
"
" on github at
"    git@github.com:vm-wylbur/pb-dotfiles.git
"
"
" todo:
" - need to put the augroup cmds together
" - clean up the autocmd stuff, esp for markdown. see _learning vimscript the hard way_
" - should think more about wildmode and tab completion
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
Plug 'tpope/vim-commentary'           " wow, all the time.
Plug 'tpope/vim-unimpaired'           " many additional movements with [ and ]
Plug 'ntpeters/vim-better-whitespace' " to remove trailing whitespace on save
Plug 'tommcdo/vim-exchange'           " cx{motion} to exhange text objs
Plug 'machakann/vim-highlightedyank'  " blink
Plug 'haya14busa/incsearch.vim'

" completion
Plug 'lifepillar/vim-mucomplete'


" navigation
Plug 'justinmk/vim-sneak'        " I should use this more.
" Plug 'SirVer/ultisnips'
" Plug 'honza/vim-snippets'

"" files, buffers, and tags
Plug 'ap/vim-buftabline'         " adds buffer tabs and numbers
Plug 'dhruvasagar/vim-vinegar'   " - for curdir and adds some netrw behaviors
" Plug 'tpope/vim-eunuch'          " u-nick(s), get it? *nix bits: Find, Rename
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'

" colors and UI
Plug 'airblade/vim-gitgutter'          " put chars in gutter
Plug 'kshenoy/vim-signature'           " less cluttered, marks more visible
Plug 'itchyny/lightline.vim'           " workable. Prob could be done by hand.
Plug 'luochen1990/rainbow'             " I really like these!
Plug 'itchyny/vim-cursorword'          " this works w * operator
Plug 'mhartington/oceanic-next'
" Plug 'icymind/NeoSolarized'
" Plug 'joshdick/onedark.vim'
" Plug 'flazz/vim-colorschemes'
" Plug 'arcticicestudio/nord-vim'
" Plug 'jsit/disco.vim'
" Plug 'romainl/flattened'
" Plug 'sickill/vim-monokai'

" languages
Plug 'sheerun/vim-polyglot'
Plug 'davidhalter/jedi-vim'
Plug 'lervag/vimtex'
Plug 'raimon49/requirements.txt.vim', {'for': 'requirements'}
Plug 'reedes/vim-pencil'
" Plug 'tpope/vim-fugitive'
" Plug 'tmhedberg/SimpylFold'            " folding for python, za/zc
" Plug 'jalvesaq/Nvim-R'

" markdown stuff
Plug 'vim-pandoc/vim-pandoc'
Plug 'vim-pandoc/vim-pandoc-syntax'
Plug 'vim-pandoc/vim-rmarkdown'
Plug 'tpope/vim-markdown'

" linting
Plug 'w0rp/ale'

call plug#end()

" must follow all Plug calls
filetype plugin indent on


" plugin configs

let R_user_maps_only = 1

" :h g:incsearch#auto_nohlsearch
set hlsearch
let g:incsearch#auto_nohlsearch = 1
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

" other solarized have bad colors in terminal
" let $NVIM_TUI_ENABLE_TRUE_COLOR=1
" colorscheme OceanicNext
"---deprecated colors
" colorscheme monokai
" colorscheme NeoSolarized
" colorscheme nord
" colorscheme TangoDark
" colorscheme flattened
" g:disco_nobright = 0
" g:disco_red_error_only = 1
" let g:oceanic_next_terminal_bold = 1
" let g:oceanic_next_terminal_italic = 1

" set background=dark

let g:jedi#force_py_version = 3

" highlight Comment cterm=italic
" highlight Comment gui=italic
" change cursor shape with mode
" let &t_ZH="\e[3m"
" let &t_ZR="\e[23m"

let g:gitgutter_eager = 0
let g:gitgutter_async = 1
let g:gitgutter_realtime = 1


set signcolumn=yes

let g:sneak#label = 1
let g:sneak#streak = 1
nmap s <Plug>SneakLabel_s
nmap S <Plug>SneakLabel_S


" whitespace
autocmd BufEnter * EnableStripWhitespaceOnSave

" imap <c-x><c-l> <plug>(fzf-complete-line)

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
autocmd BufNewFile,BufReadPost *.md set filetype=markdown
autocmd BufRead,BufNew *.md set filetype=markdown


" stop spellcheck in terminal
au TermOpen * setlocal nonumber norelativenumber nospell


let g:buftabline_numbers=1
let g:buftabline_indicators='on' " this is helpful.
let g:buftabline_separators='on'
" let g:MRU_Exclude_Files = '.*/.git/COMMIT_EDITMSG$'




"" setting up right margin highlighting
augroup BgHighlight
autocmd!
    autocmd WinEnter * set cul
    autocmd WinLeave * set nocul
augroup END
" makes right margin diff color
execute 'set colorcolumn=' . join(range(81,335), ',')


"" Autocomplete
" set omnifunc=syntaxcomplete#Complete
let g:mucomplete#enable_auto_at_startup = 1
set complete+=i
set complete+=kspell
set completeopt+=menuone,noselect,noinsert
set shortmess+=c
set belloff+=ctrlg
" set completeopt+=preview
set nodigraph  " use c-k to start digraph: é
" }}}}

" Wildmenu
set wildignore+=.DS_Store,Icon\?,*.dmg,*.git,*.pyc,*.o,*.obj,*.so,*.swp,*.zip
set wildmenu " Show possible matches when autocompleting
set wildignorecase " Ignore case when completing file names and directories
" }}}}

" set inccommand=split

"" Auto commands at save
set autoread
" augroup autoSaveAndRead
"   autocmd!
"   autocmd TextChanged,InsertLeave,FocusLost * silent! wall
"   autocmd CursorHold * silent! checktime
" augroup END
" }}}}

source $HOME/dotfiles/vim-common/sets.vim
source $HOME/dotfiles/vim-common/remaps.vim
source $HOME/dotfiles/vim-common/gui.vim

" Autocmd Rules
"" Remember cursor position
augroup vimrc-remember-cursor-position
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

" language
" In markdown files, Control + a surrounds highlighted text with square
" brackets, then dumps system clipboard contents into parenthesis
autocmd FileType markdown vnoremap <c-a> <Esc>`<i[<Esc>`>la](<Esc>"*]pa)<Esc>
autocmd FileType r setlocal commentstring=#\ %s
autocmd FileType r inoremap C-. %>%


" snippets
" let g:UltiSnipsSnippetDirectories = ['~/dotfiles/vim-common/UltiSnips', 'UltiSnips']
" let g:UltiSnipsSnippetsDir = '~/dotfiles/vim-common/UltiSnips'
" let g:UltiSnipsJumpBackwardTrigger='<c-b>'
" let g:UltiSnipsEditSplit='vertical'

" w0rp/ale
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
let g:ale_change_sign_column_color = 0
let g:ale_vim_vint_show_style_issues = 1
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_virtualenv_dir_names = []
let b:ale_virtualenv_dir_names = []
let g:ale_lint_on_insert_leave = 0
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_save = 1
" }}}}

"" python
augroup vimrc-python
  autocmd!
  autocmd FileType python setlocal expandtab shiftwidth=4 tabstop=8 colorcolumn=79
      \ formatoptions+=croq softtabstop=4
      \ cinwords=if,elif,else,for,while,try,except,finally,def,class,with
augroup END

" jedi-vim
let g:jedi#popup_on_dot = 0
let g:jedi#documentation_command = 'K'
let g:jedi#usages_command = '<leader>n'
let g:jedi#rename_command = '<leader>r'
let g:jedi#show_call_signatures = '0'
let g:jedi#completions_command = '<C-Space>'
let g:jedi#smart_auto_mappings = 0

let g:polyglot_disabled = ['python', 'tex', 'markdown']
let g:python_highlight_all = 1


set modeline
set modelines=5
setlocal foldmethod=marker
set nofoldenable
" done.
