-- PB specific plugins.
-- Time-Stamp:
return {
  -- {'Pocco81/auto-save.nvim', config = true },
  'famiu/bufdelete.nvim',
  'tpope/vim-sleuth',
  'rmagatti/auto-session',
  'mrjones2014/smart-splits.nvim',
  "girishji/pythondoc.vim",
  {
    'chipsenkbeil/distant.nvim',
    branch = 'v0.3',
    config = function()
      require('distant'):setup()
    end
  },
  -- {
  --   'miversen33/netman.nvim',
  --   -- Note, you do not need this if you plan on using Netman with any of the
  --   -- supported UI Tools such as Neo-tree
  --   config = true
  -- },
  -- { "nvim-neo-tree/neo-tree.nvim",
  --   branch = "v3.x",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
  --     "MunifTanjim/nui.nvim",
  --     -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
  --   },
  --   source_selector = {
  --     sources = {
  --       -- Any other items you had in your source selector
  --       -- Just add the netman source as well
  --       { source = "remote" }
  --     }
  --   }
  -- },
  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
  },
}
