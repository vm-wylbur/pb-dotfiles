
-- [[ PB settings ]]
vim.wo.relativenumber = true

-- ^j, ^k to change splits
local opts = { noremap = true, silent = true }
local keymap = vim.api.nvim_set_keymap
keymap('n', "<C-j>", "<C-w>j", opts)
keymap('n', "<C-k>", "<C-w>k", opts)
keymap('n', "<C-h>", "<C-w>h", opts)
keymap('n', "<C-l>", "<C-w>l", opts)
keymap('n', "<C-1>", ":bd<CR>", opts)



-- https://stackoverflow.com/questions/77466697
vim.api.nvim_create_augroup("AutoFormat", {})
vim.api.nvim_create_autocmd(
    "BufWritePost",
    {
        pattern = "*.py",
        group = "AutoFormat",
        callback = function()
            vim.cmd("silent !black --quiet %")
            vim.cmd("edit")
        end,
    }
)
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
    pattern = {"*"},
    callback = function(ev)
        save_cursor = vim.fn.getpos(".")
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.setpos(".", save_cursor)
    end,
})

-- done.
