-- only needed on headless linux boxen
return {
  "ojroques/nvim-osc52",
  opts = {
    silent = true, 
  }
  -- keys = {
  --   {
  --     "<leader>y",
  --     function()
  --       return require("osc52").copy_operator()
  --     end,
  --     desc = "copy selection to system clipboard (normal mode)",
  --     expr = true,
  --   },
  --   {
  --     "<leader>Y",
  --     "<leader>y_",
  --     remap = true,
  --     desc = "copy current line into system clipboard (normal mode)",
  --   },
  --   {
  --     mode = "v",
  --     "<leader>y",
  --     function()
  --       require("osc52").copy_visual()
  --     end,
  --     desc = "copy selection to system clipboard (visual mode)",
  --   },
  -- },
}
