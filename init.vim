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

" set up lspconfig and bind some convenience things {{{
lua << EOF
local nvim_lsp = require('lspconfig')
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- autoImport

  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }
  buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', 'ga', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

  -- Set some keybinds conditional on server capabilities
  if client.resolved_capabilities.document_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.formatting()<CR>", opts)
  elseif client.resolved_capabilities.document_range_formatting then
    buf_set_keymap("n", "<space>f", "<cmd>lua vim.lsp.buf.range_formatting()<CR>", opts)
  end

  -- Set autocommands conditional on server_capabilities
  if client.resolved_capabilities.document_highlight then
    vim.api.nvim_exec([[
      hi LspReferenceRead cterm=bold ctermbg=red guibg=LightYellow
      hi LspReferenceText cterm=bold ctermbg=red guibg=LightYellow
      hi LspReferenceWrite cterm=bold ctermbg=red guibg=LightYellow
      augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
    ]], false)
  end
end


-- set up rust w/ special command
nvim_lsp.rust_analyzer.setup {
    cmd = { "rustup", "run", "nightly", "rust-analyzer" },
    on_attach = on_attach
}

-- set up purescript stuff, e.g. purescript-language-server
ps_complete_done = function (word, fileUri)
  print('complete called with', word, fileUri)
  vim.lsp.buf.execute_command({ command="purecript.importCompletionImport", arguments={word, nil, nil, fileUri} })
end

local on_ps_attach = function (client, bufnr)
  vim.api.nvim_command("autocmd CompleteDone <buffer> lua ps_complete_done(vim.fn.expand('<cword>'), vim.fn.expand('%:p'))")
  on_attach(client, bufnr)
end
ps_add_import = function ()
  local word = vim.fn.expand('<cword>')
  local fileUri = 'file://' .. vim.fn.expand('%:p')
  print('add import called with', word, fileUri)
  vim.lsp.buf.execute_command({ command="purecript.importCompletionImport", arguments={word, nil, nil, fileUri} })
end

nvim_lsp.purescriptls.setup {
  cmd = { "yarn", "run", "purescript-language-server", "--stdio" },
  --on_attach = on_ps_attach,
  on_attach = on_attach,
  settings = {
    purescript = {
      addSpagoSources = true, -- e.g. any purescript language-server config here
      addNpmPath = true,
      formatter = "purs-tidy"
    }
  },
  flags = {
    debounce_text_changes = 150
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
