
set statusline+=%{StatuslineTabWarning()}

"recalculate the tab warning flag when idle and after writing
autocmd cursorhold,bufwritepost * unlet! b:statusline_tab_warning

"return '[&et]' if &et is set wrong
"return '[mixed-indenting]' if spaces and tabs are used to indent
"return an empty string if everything is fine
function! StatuslineTabWarning()
    if !exists("b:statusline_tab_warning")
        let tabs = search('^\t', 'nw') != 0
        let spaces = search('^ ', 'nw') != 0

        if tabs && spaces
            let b:statusline_tab_warning =  '[mixed-indenting]'
        elseif spaces
            let b:statusline_tab_warning = '[space]'
        else
            let b:statusline_tab_warning = '[tab]'
        endif
    endif
    return b:statusline_tab_warning
endfunction


" status line {{{
set laststatus=2
" todo: shorten mode name
" this was stolen from someone, can't remember whom
let g:lightline = {
        \ 'colorscheme': 'wombat',
        \ 'active': {
        \   'left': [ ['mode', 'paste'],
        \             ['readonly', 'fullpath', 'modified'] ],
        \   'right': [ [ 'lineinfo' ], ['percent'], ['filetype'], ['spaceortab'] ]
        \ },
        \ 'inactive': {
		    \   'left': [ [ 'filename' ] ],
		    \   'right': [ [ 'lineinfo' ], ['percent'], [ 'winno' ] ]
        \ },
        \ 'component': {
        \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒 ":""}',
        \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
        \   'fullpath': '%F',
        \   'spaceortab': '%{StatuslineTabWarning()}',
        \   'winno':    'win:%{winnr()}'
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
