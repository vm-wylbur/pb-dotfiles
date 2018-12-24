"
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" git@github.com:vm-wylbur/pb-dotfiles.git
" (c) 2018 [HRDAG](https://hrdag.org), GPL-2 or later
"
" pb-dotfiles/vim-common/autogrp.vim

autocmd BufNewFile,BufReadPost,BufRead,BufNew *.md, set filetype=markdown
autocmd BufNewFile,BufReadPost,BufRead,BufNew *.Rmd set filetype=rmarkdown

" language
" In markdown files, Control + a surrounds highlighted text with square
" brackets, then dumps system clipboard contents into parenthesis
autocmd FileType markdown,rmarkdown	vnoremap <c-a> <Esc>`<i[<Esc>`>la](<Esc>"*]pa)<Esc>
autocmd FileType r setlocal commentstring=#\ %s
autocmd FileType r inoremap C-. %>%

"" Remember cursor position
augroup vimrc-remember-cursor-position
  autocmd!
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

