" Preamble {{{
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" (c) 2017 [HRDAG](https://hrdag.org), GPL-2 or later
" }}}

" statusline {{{
" set statusline=%F%m%r%h%w%=(%{&ff}/%Y)\ (line\ %l\/%L,\ col\ %c)\
" }}} 

function! AirlineInit()
  let g:airline_section_a = airline#section#create(['mode', 'paste', 'spell', 'iminsert'])
  let g:airline_section_b = '%-0.10{getcwd()}'
  let g:airline_section_c = '%t'
endfunction
autocmd VimEnter * call AirlineInit()

" vim-airline settings {{{
let g:airline_theme = 'powerlineish'
let g:airline#extensions#syntastic#enabled = 1
let g:airline#extensions#branch#enabled = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tagbar#enabled = 0
let g:airline_skip_empty_sections = 1
" }}}

set modeline
set modelines=5
" vim: set foldmethod=marker foldlevel=0:
" }}}
