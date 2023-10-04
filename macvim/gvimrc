"
" Author: [Patrick Ball](mailto://pball@hrdag.org)
" git@github.com:vm-wylbur/pb-dotfiles.git
" (c) 2022 [HRDAG](https://hrdag.org), GPL-2 or later
"
" pb-dotfiles/macvim/gvimrc  symlinked to ~/.vimrc

set guifont=Monaco:h16
set runtimepath+=$HOME/.local/share/nvim
set runtimepath+=$HOME/.vim/autoload
set runtimepath+=$HOME/.config/plugged

call plug#begin(expand('~/.config/nvim/plugged'))
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-unimpaired'           " for bubbling
Plug 'justinmk/vim-sneak'
Plug 'kshenoy/vim-signature'
Plug 'airblade/vim-gitgutter'
Plug 'qpkorr/vim-bufkill'             " :BD is very useful
Plug 'machakann/vim-highlightedyank'  " blink
Plug 'itchyny/lightline.vim'
Plug 'ap/vim-buftabline'
Plug 'reedes/vim-pencil'
Plug 'junegunn/vim-easy-align'
Plug 'lifepillar/vim-solarized8'
call plug#end()

" --- plugin variables -----
let g:buftabline_numbers = 1
let g:pencil#wrapModeDefault = 'soft'   " default is 'hard'


filetype plugin indent on


if has("gui_macvim")
	let macvim_hig_shift_movement = 1
endif

set lines=60
set columns=85
color solarized8_flat
set background=dark

" --- some plugin setups, repliacing vim-common
augroup pencil
	autocmd!
	autocmd FileType markdown,mkd  call pencil#init({'wrap': 'soft'})
	autocmd FileType text          call pencil#init({'wrap': 'hard', 'autoformat': 1})
	autocmd FileType tex,rmarkdown call pencil#init({'wrap': 'soft'})
augroup END


source $HOME/dotfiles/vim-common/plugins.vim
source $HOME/dotfiles/vim-common/line.vimrc   " for the lightline config
source $HOME/dotfiles/vim-common/remaps.vim
source $HOME/dotfiles/vim-common/sets.vim
" source $HOME/dotfiles/vim-common/gui.vim
" source $HOME/dotfiles/vim-common/autogrp.vim

nnoremap <leader>ev :e $HOME/dotfiles/macvim/gvimrc<cr>

" done.
