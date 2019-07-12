" Colors and GUI

set background=dark
highlight Comment cterm=italic
highlight Comment gui=italic
execute 'set colorcolumn=' . join(range(81,335), ',')

" depends on buftabline plugin
let g:buftabline_numbers=1
let g:buftabline_indicators='on' 
let g:buftabline_separators='on'

" depends on the OceanicNext plugin being loaded first
colorscheme OceanicNext
let g:oceanic_next_terminal_bold = 1
let g:oceanic_next_terminal_italic = 1

" depends on gitgutter
let g:gitgutter_eager = 0
let g:gitgutter_async = 1
let g:gitgutter_realtime = 1

" done. 
