" ===============================
" vim-plug bootstrap (Vim)
" ===============================

let s:plug_path = expand('~/.vim/autoload/plug.vim')

if empty(glob(s:plug_path))
  silent execute '!curl -fLo ' . shellescape(s:plug_path) .
        \ ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" ===============================
" Plugins
" ===============================

call plug#begin('~/.vim/plugged')

Plug 'junegunn/fzf.vim'

call plug#end()

" ===============================
" Auto-install missing plugins
" ===============================

function! s:PlugMissing() abort
  if !exists('g:plugs')
    return 0
  endif

  for plug in keys(g:plugs)
    if !isdirectory(g:plugs[plug].dir)
      return 1
    endif
  endfor

  return 0
endfunction

autocmd VimEnter *
  \ if s:PlugMissing()
  \| silent! PlugInstall --sync | source $MYVIMRC
  \| endif

" Enable line numbers and relative line numbers
set number              " Absolute line numbers
set relativenumber      " Relative line numbers

" Enable syntax highlighting and auto-indentation
syntax enable
filetype plugin indent on
set smartindent         " Smart indentation for code
set tabstop=4           " Number of spaces for a tab
set shiftwidth=4        " Number of spaces for indentation
set expandtab           " Convert tabs to spaces
set smarttab            " Enable smart tabbing

" Enable search highlighting and ignore case
set ignorecase          " Ignore case in search
set smartcase           " Override ignorecase if uppercase used
set incsearch           " Incremental search (shows results as you type)
set hlsearch            " Highlight search results

" Set mapleader to Space
let mapleader = " "

" Set a better default undo behavior
set undodir=~/.vim/undo " Store undo files in a specific directory
set undofile            " Enable persistent undo

" Enable line wrapping and scrolling
set wrap                " Wrap lines that are too long
set scrolloff=8         " Keep 8 lines above/below the cursor
set sidescrolloff=8     " Keep 8 columns to the left/right of the cursor

" Show matching parentheses, brackets, and braces
set showmatch           " Highlight matching parenthesis/brackets

" Enable line and column in the status line
set ruler               " Show current line and column in the status line

" Enable auto-completion for text
set completeopt=menuone,noinsert,noselect " Completion options
set shortmess+=c        " Shorten completion messages

" Enable search history
set history=1000        " Remember the last 1000 search queries

" Show line and column numbers on the status line
set statusline=%l/%L\ %c " Show current line/column in statusline

" Enable incremental search highlighting
set incsearch           " Search while typing

" Automatically reload a file if changed outside Vim
set autoread            " Automatically reload files changed outside Vim

" Show invisible characters
set list                " Show hidden characters like tabs and spaces
set listchars=tab:»\ ,trail:· " Customize visible characters


" Enable line folding (great for large code files)
set foldmethod=syntax   " Fold code based on syntax
set foldlevel=99        " Start with all code unfolded

" Enable automatic code wrapping and spellcheck for markdown or text files
autocmd FileType markdown,text setlocal spell " Enable spellchecking in markdown/text files

" Use <leader>e to open Oil file explorer
nnoremap <leader>e :Explore<CR>

" Map leader key for some useful commands
nnoremap <leader>o :Files<CR>
nnoremap <leader><leader> :Buffers<CR>
nnoremap <leader>g :!lazygit<CR>
