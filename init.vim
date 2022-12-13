" do some mappins
let mapleader=";"
inoremap jj <Esc>
tnoremap jj <C-\><C-n>
nnoremap <leader>j <C-w>j<C-w>_
nnoremap <leader>k <C-w>k<C-w>_
nnoremap <leader>n :noh<cr>

" set variables
set winminheight=0
set nu
set relativenumber
set foldmethod=marker
set expandtab
set tabstop=2
set softtabstop=2
set shiftwidth=2
set mouse=a

" Setup plugins
call plug#begin(stdpath('data') . '/plugged')
Plug 'scrooloose/nerdtree'
Plug 'neovim/nvim-lspconfig'
Plug 'dense-analysis/ale'
Plug 'ackyshake/VimCompletesMe'
Plug 'joshdick/onedark.vim'
Plug 'nvim-lua/lsp_extensions.nvim'
Plug 'vim-scripts/Liquid-Carbon'
Plug 'purescript-contrib/purescript-vim'
Plug 'lukas-reineke/indent-blankline.nvim'
Plug 'sainnhe/everforest'
Plug 'ncm2/float-preview'
call plug#end()

" Colorscheme
let g:everforest_transparent_background=1
let g:everforest_ui_contrast='high'
let g:everforest_diagnostic_text_highlight=1
let g:everforest_diagnostic_line_highlight=1
let g:everforest_diagnostic_virtual_text='colored'
colorscheme everforest

" autocommands
autocmd FileType purescript let b:vcm_tab_complete = 'omni'
autocmd FileType purescript set formatoptions+=ro

" set up floating preview
set completeopt-=preview
let g:float_preview#docked=0

" keep purescript conceal simple
let g:purescript_unicode_conceal_disable_common=1

" set up lspconfig and bind some convenience things {{{
lua << EOF

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

local on_attach = function(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap=true, silent=true, buffer=bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
  --vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'ga', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format { async = true } end, bufopts)

end

local nvim_lsp = require('lspconfig')

-- set up rust w/ special command
nvim_lsp.rust_analyzer.setup {
    cmd = { "rustup", "run", "nightly", "rust-analyzer" },
    on_attach = on_attach
}

-- set up purescript stuff, e.g. purescript-language-server
ps_complete_done = function (word, fileUri)
  function autoImport ()
    arguments = vim.api.nvim_get_vvar('completed_item')['user_data']['nvim']['lsp']['completion_item']['command']['arguments']
    vim.lsp.buf.execute_command({ command="purescript.addCompletionImport", arguments=arguments })
  end
  pcall(autoImport)
end

local on_ps_attach = function (client, bufnr)
  vim.api.nvim_command("autocmd CompleteDone <buffer> lua ps_complete_done(vim.fn.expand('<cword>'), vim.fn.expand('%:p'))")
  vim.api.nvim_command("inoremap <expr> <CR> pumvisible() ? '<C-y> ' : '<CR>'")
  vim.api.nvim_command("inoremap <expr> <Esc> pumvisible() ? '<C-e>' : '<CR>'")
  on_attach(client, bufnr)
end

nvim_lsp.purescriptls.setup {
  cmd = { "yarn", "run", "purescript-language-server", "--stdio" },
  on_attach = on_ps_attach,
  settings = {
    purescript = {
      addSpagoSources = true, -- e.g. any purescript language-server config here
      addNpmPath = true,
      formatter = "purs-tidy"
    }
  }
}

-- Use a loop to conveniently both simple servers
local servers = { }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup { on_attach = on_attach }
end
EOF
" }}}

" set up ALE
let g:ale_linters = {'rust': ['analyzer']}
let g:ale_rust_analyzer_executable = "/Users/ryan/.rustup/toolchains/nightly-aarch64-apple-darwin/bin/rust-analyzer"

" set up indent_blankline
lua << EOF
vim.opt.list = true
vim.opt.listchars:append("eol:↴")

require("indent_blankline").setup {
  show_end_of_line = true,
}
EOF
