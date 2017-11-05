" Authors:     PB
" Maintainers: PB
" License: 	   2017, HRDAG, GPL v2 or later
" ============================================
set laststatus=2

" http://got-ravings.blogspot.com/2008/10/vim-pr0n-statusline-whitespace-flags.html
"recalculate the tab warning flag when idle and after writing
autocmd cursorhold,bufwritepost * unlet! b:statusline_tab_warning

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


" the ale stuff: https://github.com/statico/dotfiles/blob/master/.vim/vimrc#L413
function! LightlineLinterWarnings() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ◆', all_non_errors)
endfunction

function! LightlineLinterErrors() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '' : printf('%d ✗', all_errors)
endfunction

function! LightlineLinterOK() abort
  let l:counts = ale#statusline#Count(bufnr(''))
  let l:all_errors = l:counts.error + l:counts.style_error
  let l:all_non_errors = l:counts.total - l:all_errors
  return l:counts.total == 0 ? '✓ ' : ''
endfunction

autocmd User ALELint call lightline#update()

" status line {{{
" todo: shorten mode name
" this was stolen from someone, can't remember whom
let g:lightline = {
        \ 'colorscheme': 'wombat',
        \ 'active': {
        \   'left': [ ['mode', 'paste'],
        \             ['readonly', 'fullpath', 'modified', 'linter_warnings', 'linter_errors', 'linter_ok'] ],
        \   'right': [ [ 'lineinfo' ], ['percent'], ['filetype'], ['spaceortab'] ]
        \ },
        \ 'inactive': {
		    \   'left': [ [ 'filename' ] ],
		    \   'right': [ [ 'lineinfo' ], ['percent'], [ 'winno' ] ]
        \ },
        \ 'component_expand': {
        \   'linter_warnings': 'LightlineLinterWarnings',
        \   'linter_errors': 'LightlineLinterErrors',
        \   'linter_ok': 'LightlineLinterOK',
        \ },
        \ 'component_type': {
        \   'readonly': 'error',
        \   'linter_errors': 'error',
        \   'linter_warnings': 'warning',
        \ },
        \ 'component': {
        \   'readonly': '%{&filetype=="help"?"":&readonly?"🔒 ":""}',
        \   'modified': '%{&filetype=="help"?"":&modified?"+":&modifiable?"":"-"}',
        \   'fullpath': '%F',
        \   'lintstat': '%{LinterStatus()}',
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
