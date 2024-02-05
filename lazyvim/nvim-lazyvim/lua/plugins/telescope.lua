return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>k",
        function()
          require("telescope.builtin").treesitter({symbols = { "function", "method" }})
        end,
      },
    },
  },
}
