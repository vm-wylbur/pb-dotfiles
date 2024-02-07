if vim.fn.hostname() == "scott" then
  return {
    "ojroques/nvim-osc52",
    opts = {
      silent = true,
<<<<<<< HEAD:lazyvim/nvim/lua/plugins/nvim-osc52.lua
    },
=======
    }
>>>>>>> 57bf336 (moving lazyvim out of the way (delete soon)):lazyvim/nvim-lazyvim/lua/plugins/nvim-osc52.lua
  }
else
  return {}
end
-- done.
