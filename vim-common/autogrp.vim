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

" Add this to your vimrc file
" auto-update "Last update: " if present whenever saving file
" https://gist.github.com/rkumar/4166881
autocmd! BufWritePre * :call s:timestamp()
" to update timestamp when saving if its in the first 5 lines of a file
function! s:timestamp()
    let pat = '\(< Last update\s*:\s*\).* >'
    let rep = '\1' . strftime("%Y-%m-%d %H:%M") . ' >'
    call s:subst(1, 5, pat, rep)
endfunction
" subst taken from timestamp.vim
" {{{1 subst( start, end, pat, rep): substitute on range start - end.
function! s:subst(start, end, pat, rep)
    let lineno = a:start
    while lineno <= a:end
	let curline = getline(lineno)
	if match(curline, a:pat) != -1
	    let newline = substitute( curline, a:pat, a:rep, '' )
	    if( newline != curline )
		" Only substitute if we made a change
		"silent! undojoin
		keepjumps call setline(lineno, newline)
	    endif
	endif
	let lineno = lineno + 1
    endwhile
endfunction
" }}}1

" done.
