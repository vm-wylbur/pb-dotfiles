
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
