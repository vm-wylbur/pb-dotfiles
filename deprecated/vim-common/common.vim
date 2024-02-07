" DEPRECATED
"
" Last Modified: <Sun 23 Dec 2018 05:15:34 PM PST>
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" (c) 2018 [HRDAG](https://hrdag.org), GPL-2 or later
"
" on github at
"    git@github.com:vm-wylbur/pb-dotfiles.git
"
" this file contains common configs sourced in the various init files
"
" todo:
" - need to put the augroup cmds together
" - clean up the autocmd stuff, esp for markdown. see _learning vimscript the hard way_
" - should think more about wildmode and tab completion
"


source $HOME/dotfiles/vim-common/line.vimrc   " for the lightline config
source $HOME/dotfiles/vim-common/plugins.vimrc   " for the lightline config

source $HOME/dotfiles/vim-common/sets.vim
source $HOME/dotfiles/vim-common/remaps.vim
source $HOME/dotfiles/vim-common/gui.vim


" snippets
" let g:UltiSnipsSnippetDirectories = ['~/dotfiles/vim-common/UltiSnips', 'UltiSnips']
" let g:UltiSnipsSnippetsDir = '~/dotfiles/vim-common/UltiSnips'
" let g:UltiSnipsJumpBackwardTrigger='<c-b>'
" let g:UltiSnipsEditSplit='vertical'

set modeline
set modelines=5
setlocal foldmethod=marker
set nofoldenable
" done.
