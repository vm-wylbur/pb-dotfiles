-- return { 'github/copilot.vim', }

 return {
  { "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    suggestion = { enabled = false },
    panel = { enabled = false },
    config = function()
      require("copilot").setup()
    end,
  },

--     opts = {
--       suggestion = {
-- 	enabled = true,
-- 	auto_trigger = true,
-- 	debounce = 75,
--       },
--       panel = { enabled = false },
--       filetypes = {
-- 	markdown = true,
-- 	help = true,
-- 	python = true,
-- 	R = true,
--       },
--     },
--   },

  {
    "zbirenbaum/copilot-cmp",
    config = function ()
      require("copilot_cmp").setup()
    end
  },
  { 'AndreM222/copilot-lualine' },
}
-- done.
