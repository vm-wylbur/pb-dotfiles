return {
	{
		"vague2k/huez.nvim",  -- run w :Huez
		-- I like duskfox, melange, bamboo
		dependencies = {
			-- You probably already have this installed.
			-- reccomended, but optional dependency.
			-- Will use vim.ui as a default unless specified otherwise, or a fallback.
			-- Preview does not currently work in vim.ui.
			"nvim-telescope/telescope.nvim",
		},
	},
	{ "shaunsingh/nord.nvim" },
	{ "folke/tokyonight.nvim" },
	{ "EdenEast/nightfox.nvim" },
	{ "savq/melange-nvim" },
	{ "Mofiqul/dracula.nvim" },
	{ "catppuccin/nvim" },
	{ "Shatur/neovim-ayu" },
	{ "folke/styler.nvim" },
	{ "patstockwell/vim-monokai-tasty" },
	{ "bluz71/vim-nightfly-colors" },
	{ "ribru17/bamboo.nvim" },
	{
		"olimorris/onedarkpro.nvim",
		priority = 1000,
	},

	-- color html colors
	-- {
	-- 	"NvChad/nvim-colorizer.lua",
	-- 	config = function()
	-- 		require("colorizer").setup({
	-- 			filetypes = { "*" },
	-- 			RGB = true, -- #RGB hex codes
	-- 			RRGGBB = true, -- #RRGGBB hex codes
	-- 			names = true, -- "Name" codes like Blue or blue
	-- 			RRGGBBAA = true, -- #RRGGBBAA hex codes
	-- 			AARRGGBB = false, -- 0xAARRGGBB hex codes
	-- 			rgb_fn = false, -- CSS rgb() and rgba() functions
	-- 			hsl_fn = false, -- CSS hsl() and hsla() functions
	-- 			css = false, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
	-- 			css_fn = false, -- Enable all CSS *functions*: rgb_fn, hsl_fn
	-- 			-- Available modes for `mode`: foreground, background,  virtualtext
	-- 			mode = "background", -- Set the display mode.
	-- 			-- Available methods are false / true / "normal" / "lsp" / "both"
	-- 			-- True is same as normal
	-- 			tailwind = false, -- Enable tailwind colors
	-- 			-- parsers can contain values used in |user_default_options|
	-- 			sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
	-- 			virtualtext = "■",
	-- 			-- update color values even if buffer is not focused
	-- 			-- example use: cmp_menu, cmp_docs
	-- 			always_update = false,
	-- 			-- all the sub-options of filetypes apply to buftypes
	-- 			buftypes = {},
	-- 		})
	-- 	end,
	-- },
}
