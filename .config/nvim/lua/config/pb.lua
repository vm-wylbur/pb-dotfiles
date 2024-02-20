-- [[ PB settings ]]
vim.wo.relativenumber = true
vim.o.lazyredraw = false

-- TODO: move to keymaps.lua
local wk = require("which-key")
wk.register({
  j = {
    name = "Jump", -- optional group name
    c = { "<cmd>Telescope find_files search_dirs={'~/.config/nvim/'}<cr>", "Find Configs" },
    o = { "<cmd>Telescope live_grep search_dirs={'~/.config/nvim/'}<cr>", "Grep Configs" },
    d = { "<cmd>Telescope find_files search_dirs={'~/dotfiles/'}<cr>", "Find Dotfiles" },
    t = { "<cmd>Telescope live_grep search_dirs={'~/dotfiles/'}<cr>", "Grep Dotfiles" },
    n = { "<cmd>Telescope find_files search_dirs={'~/notes/'}<cr>", "Find Notes" },
    g = { "<cmd>Telescope live_grep search_dirs={'~/notes/'}<cr>", "Grep Notes" },
    p = { "<cmd>Telescope live_grep search_dirs={'~/Downloads/python-3.12.1-docs-text/library/'}<cr>", "Grep Python docs"},
  },
}, { prefix = "<leader>" })

require("noice").setup({
  lsp = {
    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
      ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
    },
  },
  -- you can enable a preset for easier configuration
  presets = {
    bottom_search = true, -- use a classic bottom cmdline for search
    command_palette = true, -- position the cmdline and popupmenu together
    long_message_to_split = true, -- long messages will be sent to a split
    inc_rename = false, -- enables an input dialog for inc-rename.nvim
    lsp_doc_border = false, -- add a border to hover docs and signature help
  },
  messages = {
    enabled = false,
  },
})

-- deletes trailing whitespace on save, maintaining cursor position
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = {"*"},
    callback = function()
      local save_cursor = vim.fn.getpos(".")
      pcall(function() vim.cmd [[%s/\s\+$//e]] end)
      vim.fn.setpos(".", save_cursor)
    end,
})

-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})
require("huez").setup({})

require('reactive').setup {
  builtin = {
    cursorline = true,
    cursor = true,
    modemsg = true
  }
}

local colorscheme = require("huez.api").get_colorscheme()
vim.cmd("colorscheme " .. colorscheme)

local Session = require("projections.session")
vim.api.nvim_create_user_command("StoreProjectSession", function()
    Session.store(vim.loop.cwd())
end, {})

vim.api.nvim_create_user_command("RestoreProjectSession", function()
    Session.restore(vim.loop.cwd())
end, {})

local Workspace = require("projections.workspace")
-- Add workspace command
vim.api.nvim_create_user_command("AddWorkspace", function()
    Workspace.add(vim.loop.cwd())
end, {})

-- done.
