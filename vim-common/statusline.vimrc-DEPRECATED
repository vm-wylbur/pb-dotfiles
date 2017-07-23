" header here

set laststatus=2
"Some other colours used in statuslines.
hi User1 term=inverse,bold cterm=inverse,bold ctermfg=darkred ctermbg=yellow
hi User2 term=inverse,bold cterm=inverse,bold ctermfg=darkred ctermbg=cyan

let g:mode_map = {
    \ 'n'      : '%1* N %*',
    \ 'i'      : '%2* I %',
    \ 'R'      : ' R ',
    \ 'v'      : ' V ',
    \ 'V'      : 'V-L',
    \ 'c'      : ' C ',
    \ "\<C-v>" : 'V-B',
    \ 's'      : ' S ',
    \ 'S'      : 'S-L',
    \ "\<C-s>" : 'S-B',
    \ '?'      : '      ' }

set statusline=[%1*%{winnr()}%*]
set statusline+=\[%{MyMode()}\]
set statusline+=%<%F\ %h%m%r%=%y\ %7(%l:%c%V%)\ %P|

function! MyMode() abort
  return get(g:mode_map, mode())
endfunction

" hi User1 term=bold cterm=inverse,bold ctermfg=red
" set statusline=%<%f%=\ [%1*%M%*%n%R%H]\ %-19(%3l,%02c%03V%)%O'%02b'

" not sure if this is good, but the cursor is a good key.
set gcr=a:block

" mode aware cursors
set gcr+=o:hor50-Cursor
set gcr+=n:Cursor
set gcr+=i-ci-sm:InsertCursor
set gcr+=r-cr:ReplaceCursor-hor20
set gcr+=c:CommandCursor
set gcr+=v-ve:VisualCursor

set gcr+=a:blinkon0

hi InsertCursor  ctermfg=15 guifg=#fdf6e3 ctermbg=37  guibg=#2aa198
hi VisualCursor  ctermfg=15 guifg=#fdf6e3 ctermbg=125 guibg=#d33682
hi ReplaceCursor ctermfg=15 guifg=#fdf6e3 ctermbg=65  guibg=#dc322f
hi CommandCursor ctermfg=15 guifg=#fdf6e3 ctermbg=166 guibg=#cb4b16
