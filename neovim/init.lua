vim.api.nvim_exec(
[[
call plug#begin('~/.local/share/nvim/plugged')
Plug 'arcticicestudio/nord-vim'
Plug 'itchyny/lightline.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-abolish'
Plug 'Valloric/ListToggle'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'godlygeek/tabular'
Plug 'bufbuild/vim-buf'
Plug 'neovim/nvim-lspconfig'
Plug 'dense-analysis/ale'
Plug 'sheerun/vim-polyglot'
" Telescope
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'
call plug#end()

filetype plugin indent on

colorscheme nord
let g:lightline = {'colorscheme': 'nord'}
]], false)

vim.opt.mouse = ''
vim.opt.cursorline = true
vim.opt.expandtab = true
vim.opt.hidden = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.number = true
vim.opt.shiftwidth = 2
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.title = true
vim.opt.wildignorecase = true
vim.opt.wildmode = 'list:longest,full'
vim.opt.shortmess = 'atI'

vim.api.nvim_exec(
[[
" Keymaps
set timeoutlen=400
nnoremap <C-n> <cmd>Telescope find_files<cr>
nnoremap <C-g> <cmd>Telescope live_grep<cr>

nmap <silent> <C-h> :wincmd h<CR>
nmap <silent> <C-k> :wincmd k<CR>
nmap <silent> <C-j> :wincmd j<CR>
nmap <silent> <C-l> :wincmd l<CR>

" Leader keymaps
nnoremap <Space> <Nop>
let mapleader = ' '
" Leader: Top row
let g:lt_quickfix_list_toggle_map = '<Leader>f'
" Leader: Home row
nnoremap <Leader>a :wqa<CR>
nnoremap <Leader>i gg=G<C-O><C-O>
nnoremap <Leader>t :NERDTreeToggle<CR>
nnoremap <Leader>n :nohlsearch<CR>
" Leader: Bottom row
nnoremap <Leader>q :q<CR>
nnoremap <Leader>w :w<CR>
nnoremap <Leader>z :qa!<CR>
" Leader: U
nnoremap <Leader>ut :TableFormat<CR>

" Autocommands
augroup filetype_python
  autocmd!
  autocmd FileType python set tabstop=4 expandtab shiftwidth=4 softtabstop=4
augroup END

augroup filetype_conf
  autocmd!
  autocmd FileType conf set tabstop=2 expandtab shiftwidth=2 softtabstop=2
augroup END

" Tag manipulation
augroup xml
  autocmd!
  autocmd FileType html,xml,javascript.jsx inoremap <buffer> <C-t> <ESC>viw"tyea><ESC>bi<<ESC>lela</<ESC>"tpa><ESC>T>i
  autocmd FileType html,xml,javascript.jsx inoremap <buffer> <C-n> <CR><CR><ESC>ka<Tab>
augroup END

" Markdown
let g:vim_markdown_folding_disabled=1
let g:vim_markdown_frontmatter=1
augroup filetype_markdown
  autocmd!
  autocmd FileType markdown setlocal textwidth=80
augroup END

" Go
let g:go_fmt_command='goimports'
let g:go_auto_type_info = 1

" NERDTree
let g:NERDTreeMinimalUI=1
let g:NERDTreeDirArrows=0
let NERDTreeShowHidden=1
let NERDTreeIgnore = []

" Ale
let g:ale_lint_on_text_changed = 'never'
let g:ale_linters_explicit = 1
let g:ale_completion_enabled = 0
let g:ale_linters = {
\   'sh': ['shellcheck'],
\   'go': ['golangci-lint'],
\   'proto': ['buf-check-lint'],
\}
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'javascript': ['eslint', 'prettier'],
\   'python': ['black'],
\   'json': ['prettier'],
\   'sh': ['shfmt'],
\   'go': ['goimports'],
\   'cpp': ['clang-format'],
\   'haskell': ['hfmt'],
\   'yaml': ['prettier'],
\   'yaml.ansible': ['prettier'],
\}
let g:ale_fix_on_save = 1
let g:ale_go_golangci_lint_options = ''
]], false)
