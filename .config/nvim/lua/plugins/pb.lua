-- PB specific plugins.
-- Time-Stamp:
return {
  {'Pocco81/auto-save.nvim', config = true },
  'famiu/bufdelete.nvim',
  'tpope/vim-sleuth',
  'rmagatti/auto-session',
  { 'StonyBoy/nvim-update-time',
    config = function()
      require('nvim-update-time').setup({ last = 5, format = '%Y-%m-%d %H:%M:%S %Z'})
    end,
  },
  {"alexghergh/nvim-tmux-navigation", config = function()
    local nvim_tmux_nav = require('nvim-tmux-navigation')

    nvim_tmux_nav.setup {
        disable_when_zoomed = true -- defaults to false
    }

    vim.keymap.set('n', "<C-h>", nvim_tmux_nav.NvimTmuxNavigateLeft)
    vim.keymap.set('n', "<C-j>", nvim_tmux_nav.NvimTmuxNavigateDown)
    vim.keymap.set('n', "<C-k>", nvim_tmux_nav.NvimTmuxNavigateUp)
    vim.keymap.set('n', "<C-l>", nvim_tmux_nav.NvimTmuxNavigateRight)
    -- vim.keymap.set('n', "<C-\\>", nvim_tmux_nav.NvimTmuxNavigateLastActive)
    vim.keymap.set('n', "<C-Space>", nvim_tmux_nav.NvimTmuxNavigateNext)

  end
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
  },
}
