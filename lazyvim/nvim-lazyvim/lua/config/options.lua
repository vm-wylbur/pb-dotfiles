-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.colorcolumn = "88"

-- only needed on headless linux boxen
local function copy(lines, _)
  require("osc52").copy(table.concat(lines, "\n"))
end
local function paste()
  return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end
vim.g.clipboard = {
  name = "osc52",
  copy = { ["+"] = copy, ["*"] = copy },
  paste = { ["+"] = paste, ["*"] = paste },
}

-- FAIL: doesn't leave the yank in the register.
-- vim.g.clipboard = {
--   name = "iTerm2 copy",
--   copy = {
--     ["+"] = { "bash", "-c", "$HOME/.iterm2/it2copy>$SSH_TTY" },
--     ["*"] = { "bash", "-c", "$HOME/.iterm2/it2copy>$SSH_TTY" },
--   },
--   paste = { ["+"] = "true", ["*"] = "true" },
-- }
--
--done
