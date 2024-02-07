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
  },
}, { prefix = "<leader>" })

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

-- https://stackoverflow.com/questions/77466697
-- vim.api.nvim_create_augroup("AutoFormat", {})
-- vim.api.nvim_create_autocmd(
--     "BufWritePost",
--     {
--         pattern = "*.py",
--         group = "AutoFormat",
--         callback = function()
--             vim.cmd("silent !black --quiet %")
--             vim.cmd("edit")
--         end,
--     }
-- )
-- vim.api.nvim_create_autocmd({ "BufWritePre" }, {
--     pattern = {"*"},
--     callback = function(ev)
--         save_cursor = vim.fn.getpos(".")
--         vim.cmd([[%s/\s\+$//e]])
--         vim.fn.setpos(".", save_cursor)
--     end,
-- })

-- done.
