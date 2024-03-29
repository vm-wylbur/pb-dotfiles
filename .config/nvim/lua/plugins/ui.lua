return {
  -- telescope
  -- a nice selection UI also to find and open files
  {
    "nvim-telescope/telescope.nvim",
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local previewers = require("telescope.previewers")
      local new_maker = function(filepath, bufnr, opts)
        opts = opts or {}
        filepath = vim.fn.expand(filepath)
        vim.loop.fs_stat(filepath, function(_, stat)
          if not stat then
            return
          end
          if stat.size > 100000 then
            return
          else
            previewers.buffer_previewer_maker(filepath, bufnr, opts)
          end
        end)
      end
      telescope.setup({
        defaults = {
          buffer_previewer_maker = new_maker,
          file_ignore_patterns = {
            "node_modules",
            "%_files/*.html",
            "%_cache",
            ".git/",
            "site_libs",
            ".venv",
          },
          layout_strategy = "flex",
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
              ["<esc>"] = actions.close,
              ["<c-j>"] = actions.move_selection_next,
              ["<c-k>"] = actions.move_selection_previous,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = false,
            find_command = {
              "rg",
              "--files",
              "--hidden",
              "--glob",
              "!.git/*",
              "--glob",
              "!**/.Rproj.user/*",
              "--glob",
              "!_site/*",
              "--glob",
              "!docs/**/*.html",
              "-L",
            },
          },
        },
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
          fzf = {
            fuzzy = true,             -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = "smart_case", -- or "ignore_case" or "respect_case"
          },
        },
      })
      -- telescope.load_extension('fzf')
      telescope.load_extension("ui-select")
      telescope.load_extension("file_browser")
      -- telescope.load_extension("dap")
    end,
  },
  { "nvim-telescope/telescope-ui-select.nvim" },
  { "nvim-telescope/telescope-fzf-native.nvim",  build = "make" },
  -- { "nvim-telescope/telescope-dap.nvim" },
  { "nvim-telescope/telescope-file-browser.nvim" },
  { "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      -- add any options here
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    }
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local function macro_recording()
        local reg = vim.fn.reg_recording()
        if reg == "" then
          return ""
        end
        return "📷[" .. reg .. "]"
      end

      local function indent_style()
        local space_pat = [[\v^ +]]
        local tab_pat = [[\v^\t+]]
        local space_indent = vim.fn.search(space_pat, 'nwc')
        local tab_indent = vim.fn.search(tab_pat, 'nwc')
        local mixed = (space_indent > 0 and tab_indent > 0)
        local mixed_same_line
        if not mixed then
          mixed_same_line = vim.fn.search([[\v^(\t+ | +\t)]], 'nwc')
          mixed = mixed_same_line > 0
        end
        if not mixed then return '' end
        if mixed_same_line ~= nil and mixed_same_line > 0 then
           return 'MI:'..mixed_same_line
        end
        local space_indent_cnt = vim.fn.searchcount({pattern=space_pat, max_count=1e3}).total
        local tab_indent_cnt =  vim.fn.searchcount({pattern=tab_pat, max_count=1e3}).total
        if space_indent_cnt > tab_indent_cnt then
          return 'MI:'..tab_indent
        else
          return 'MI:'..space_indent
        end
      end

      require("lualine").setup({
        options = {
            section_separators = { left = '', right = '' },
            component_separators = { left = '', right = '' },
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode", macro_recording },
          lualine_b = {
            { "filename",
              file_status = true,      -- Displays file status (readonly status, modified status)
              newfile_status = false,  -- Display new file status (new file means no write after created)
              path = 3,
              shorting_target = 30,    -- Shortens path to leave 40 spaces in the window
            },
          },
          lualine_c = { "branch", "diff", "diagnostics", "searchcount" },
          lualine_x = { "copilot", "encoding", "fileformat", "filetype" },
          lualine_y = { indent_style, "progress" },
          lualine_z = { "location" },
        },
        tabline = { },
        winbar = {
          lualine_a = {
            { 'buffers',
              use_mode_colors = false,
              -- colored = true,
              mode = 2,
              buffers_color = {
                active = 'WarningMsg',
                inactive = {color={fg='grey'}},
              },
              symbols = {
                modified = ' ●',      -- Text to show when the buffer is modified
                -- alternate_file = '#', -- Text to show to identify the alternate file
                directory =  '',     -- Text to show when the buffer is a directory
              },
            },
          },
        },
        inactive_winbar = {
          lualine_a = {'filename'},
        },
      })
    end,
  },
  { 'rasulomaroff/reactive.nvim' }, -- window-local highlights?

  {
    'stevearc/oil.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
  -- filetree
  -- {
  --   "nvim-tree/nvim-tree.lua",
  --   keys = {
  --     { "<c-x>", ":NvimTreeToggle<cr>", desc = "toggle nvim-tree" },
  --   },
  --   config = function()
  --     require("nvim-tree").setup({
  --       disable_netrw = true,
  --       update_focused_file = {
  --         enable = true,
  --       },
  --       git = {
  --         enable = true,
  --         ignore = false,
  --         timeout = 500,
  --       },
  --       diagnostics = {
  --         enable = true,
  --       },
  --     })
  --   end,
  -- },
  -- show keybinding help window
  { "folke/which-key.nvim" },

  -- {
  --   "simrat39/symbols-outline.nvim",
  --   cmd = "SymbolsOutline",
  --   keys = {
  --     { "<leader>lo", ":SymbolsOutline<cr>", desc = "symbols outline" },
  --   },
  --   config = function()
  --     require("symbols-outline").setup()
  --   end,
  -- },

  -- terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<c-\>]],
        direction = "float",
      })
    end,
  },

  -- show diagnostics list
  -- {
  --   "folke/trouble.nvim",
  --   config = function()
  --     require("trouble").setup({})
  --   end,
  -- },
  --
  -- {
  --   "lukas-reineke/indent-blankline.nvim",
  --   config = function()
  --     require("ibl").setup({
  --       indent = { char = "│" },
  --     })
  --   end,
  -- },

  { -- highlighting for markdown
    "lukas-reineke/headlines.nvim",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("headlines").setup({
        quarto = {
          query = vim.treesitter.query.parse(
            "markdown",
            [[
                (fenced_code_block) @codeblock
            ]]
          ),
          codeblock_highlight = "CodeBlock",
          treesitter_language = "markdown",
        },
      })
    end,
  },

  -- {
  --   "3rd/image.nvim",
  --   config = function()
  --     -- Requirements
  --     -- https://github.com/3rd/image.nvim?tab=readme-ov-file#requirements
  --     local backend = "kitty"
  --
  --     local shell
  --     if vim.fn.has("nvim-0.10.0") == 1 then
  --       -- print('nvim >= 0.10')
  --       shell = function(command)
  --         local obj = vim.system(command, { text = true }):wait()
  --         if obj.code ~= 0 then
  --           return nil
  --         end
  --         return obj.stdout
  --       end
  --     else
  --       -- print('nvim < 0.10')
  --       shell = function(command)
  --         command = table.concat(command, " ")
  --         local handle = io.popen(command)
  --         if handle == nil then
  --           return nil
  --         end
  --         local result = handle:read("*a")
  --         handle:close()
  --         return result
  --       end
  --     end
  --
  --     -- check if imagemagick is available
  --     if shell({ "convert", "-version" }) == nil then
  --       -- print("imagemagick is not available")
  --       return
  --     end
  --
  --     if backend == "kitty" then
  --       -- check if kitty is available
  --       local out = shell({ "kitty", "--version" })
  --       if out == nil then
  --         -- print("kitty is not available")
  --         return
  --       end
  --       local kitty_version = out:match("(%d+%.%d+%.%d+)")
  --       if kitty_version == nil then
  --         -- print("kitty version is not available")
  --         return
  --       end
  --       local v = vim.version.parse(kitty_version)
  --       local minimal = vim.version.parse("0.30.1")
  --       if v and vim.version.cmp(v, minimal) < 0 then
  --         -- print("kitty version is too old")
  --         return
  --       end
  --     end
  --     local tmux = vim.fn.getenv("TMUX")
  --     if tmux ~= vim.NIL then
  --       -- tmux uses number.number.(maybe letter)
  --       -- e.g. 3.3a
  --       -- but 3.3 comes before 3.3a
  --       -- so we replace a with 1
  --       local offset = 96
  --       local out = shell({ "tmux", "-V" })
  --       if out == nil then
  --         -- print("tmux is not available")
  --         return
  --       end
  --       out = out:gsub("\n", "")
  --       local letter = out:match("tmux %d+%.%d+([a-z])")
  --       local number
  --       if letter == nil then
  --         number = 0
  --       else
  --         number = string.byte(letter) - offset
  --       end
  --       local version = out:gsub("tmux (%d+%.%d+)([a-z])", "%1." .. number)
  --       local v = vim.version.parse(version)
  --       local minimal = vim.version.parse("3.3.1")
  --       if v and vim.version.cmp(v, minimal) < 0 then
  --         -- print("tmux version is too old")
  --         return
  --       end
  --     end
  --
  --     -- setup
  --     -- Example for configuring Neovim to load user-installed installed Lua rocks:
  --     --$ luarocks --local --lua-version=5.1 install magick
  --     package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua;"
  --     package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua;"
  --
  --     -- check if magick luarock is available
  --     local ok, magick = pcall(require, "magick")
  --     if not ok then
  --       -- print("magick luarock is not available")
  --       return
  --     end
  --
  --     require("image").setup({
  --       backend = backend,
  --       integrations = {
  --         markdown = {
  --           enabled = true,
  --           -- clear_in_insert_mode = true,
  --           -- download_remote_images = true,
  --           only_render_image_at_cursor = true,
  --           filetypes = { "markdown", "vimwiki", "quarto" },
  --         },
  --       },
  --       max_width = 100,
  --       max_height = 15,
  --       editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
  --       tmux_show_only_in_active_window = true, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
  --     })
  --   end,
  -- },
}
