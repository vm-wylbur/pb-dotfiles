" Preamble {{{
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" (c) 2017 [HRDAG](https://hrdag.org), GPL-2 or later
"
" moved to [github](git@github.com:vm-wylbur/pb-dotfiles.git)
"
" }}}

so $HOME/dotfiles/vim-common/common.vim

" neovim specific config here {{{

}}}

"" terminal config {{{
" only really relevant to neovim, maybe should move there
tnoremap <ESC> <C-\><C-n>
tnoremap <A-h> <C-\><C-N><C-w>h
tnoremap <A-j> <C-\><C-N><C-w>j
tnoremap <A-k> <C-\><C-N><C-w>k
tnoremap <A-l> <C-\><C-N><C-w>l

command! Cquit
    \  if exists('b:nvr')
    \|   for chanid in b:nvr
    \|     silent! call rpcnotify(chanid, 'Exit', 1)
    \|   endfor
    \| endif

autocmd BufWinEnter,WinEnter term://* startinsert
autocmd BufLeave term://* stopinsert
au BufEnter * if &buftype == 'terminal' | :startinsert | endif
" }}}

" closing {{{
set modelines=5
setlocal foldmethod=marker
" }}}
" vim: set foldmethod=marker foldlevel=0:
