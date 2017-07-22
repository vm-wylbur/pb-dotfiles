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

" don't use swap files
set noswapfile

" Turn on spell checking
set spell
" }}}
" lightline
" status line {{{
set laststatus=2
" todo: shorten mode name
" this was stolen from someone, can't remember whom
let g:lightline = {
        \ 'colorscheme': 'wombat',
        \ 'active': {
        \   'left': [ ['mode', 'paste'],
        \             ['readonly', 'fullpath', 'modified'] ],
        \   'right': [ [ 'lineinfo' ], ['percent'], ['filetype'] ]
        \ },
        \ 'component': {
        \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒 ":""}',
        \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
        \   'fullpath': '%F'
        \ },
	\'component_function': {
	\    'mode' :  'MyMode',
	\    'filetype' : 'MyFiletype'
	\ },
        \ 'component_visible_condition': {
        \   'readonly': '(&filetype!="help"&& &readonly)',
        \   'modified': '(&filetype!="help"&&(&modified||!&modifiable))'
        \ },
        \ 'separator': { 'left': ' ', 'right': ' ' },
        \ 'subseparator': { 'left': ' ', 'right': ' ' }
        \ }
        let g:lightline.mode_map = {
            \ 'n'      : ' N ',
            \ 'i'      : ' I ',
            \ 'R'      : ' R ',
            \ 'v'      : ' V ',
            \ 'V'      : 'V-L',
            \ 'c'      : ' C ',
            \ "\<C-v>" : 'V-B',
            \ 's'      : ' S ',
            \ 'S'      : 'S-L',
            \ "\<C-s>" : 'S-B',
            \ '?'      : '      ' }

        function! MyMode()
            let fname = expand('%:t')
            return fname == '__Tagbar__' ? 'Tagbar' :
                    \ fname == 'ControlP' ? 'CtrlP' :
                    \ winwidth('.') > 60 ? lightline#mode() : ''
        endfunction
        function! MyFiletype()
            return winwidth('.') > 70 ? (strlen(&filetype) ? &filetype : 'no ft') : ''
        endfunction

" }}}

