-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- vim.keymap.set("n", "<leader>cs", "<cmd>SymbolsOutline<cr>")

-- vim.keymap.set(
--   {
--     "<leader>j",
--     function()
--       require("telescope.builtin").treesitter()
--     -- { symbols = { "function", "method" } }
--     end,
--     { "n", "v" },
--     desc = "find functions and methods"
-- )

-- none of these work. <leader>mm just finds the next `{` not ]m next function
-- vim.keymap.set("n", "<leader>mm", "]mzz", { noremap = true })
-- local wk = require("which-key")
-- wk.register({
--   m = {
--     name = "Movement",
--     f = { "]m", "Next function"},
--     n = { "[m", "Previous function"},
--   },
-- }, { prefix = "<leader>" })

-- vim.keymap.set("n", "<leader>mm", "]mzz")
