"
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" git@github.com:vm-wylbur/pb-dotfiles.git
" (c) 2018 [HRDAG](https://hrdag.org), GPL-2 or later
"
" pb-dotfiles/vim-common/plugins.vim
"
let g:incsearch#auto_nohlsearch = 1
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)

let g:sneak#label = 1
let g:sneak#streak = 1
nmap s <Plug>SneakLabel_s
nmap S <Plug>SneakLabel_S

let g:rainbow_active = 1

let g:better_whitespace_enabled=1
let g:strip_whitespace_on_save=1
let g:better_whitespace_filetypes_blacklist=['rmarkdown', 'markdown', 'diff', 'gitcommit', 'unite', 'qf', 'help']

let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'
augroup pencil
	autocmd!
	autocmd FileType markdown,mkd  call pencil#init()
	autocmd FileType text          call pencil#init({'wrap': 'hard', 'autoformat': 1})
	autocmd FileType tex,rmarkdown call pencil#init()
augroup END

" done.
