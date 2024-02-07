-- vim: ts=2
return {
	{
		"gnikdroy/projections.nvim",
		branch = "pre_release",
		keys = {
			{
				"<leader>fp",
				function()
					vim.cmd("Telescope projections")
				end,
			},
		},
		config = function()
			vim.opt.sessionoptions:append("localoptions") -- Save localoptions to session file
			require("projections").setup({
				store_hooks = {
					workspaces = {
						{ '~/projects/hrdag', patterns = { '.git' } },
						{ '~/src', patterns = { '.git' } },
					},
					workspaces_file = "~/.local/state/nvim/workspaces.json",          -- Path to workspaces json file
          sessions_directory = "~/.local/state/nvim/sessions",        -- Directory where sessions are stored
					pre = function()
						-- nvim-tree
						local nvim_tree_present, api = pcall(require, "nvim-tree.api")
						if nvim_tree_present then
							api.tree.close()
						end

						-- neo-tree
						if pcall(require, "neo-tree") then
							vim.cmd([[Neotree action=close]])
						end
					end,
				},
			})

			-- Bind <leader>fp to Telescope projections
			require("telescope").load_extension("projections")

			-- Autostore session on VimExit
			local Session = require("projections.session")
			vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
				callback = function()
					Session.store(vim.loop.cwd())
				end,
			})
			-- If vim was started with arguments, do nothing
			-- If in some project's root, attempt to restore that project's session
			-- If not, restore last session
			-- If no sessions, do nothing
			local Session = require("projections.session")
			vim.api.nvim_create_autocmd({ "VimEnter" }, {
				callback = function()
					if vim.fn.argc() ~= 0 then return end
					local session_info = Session.info(vim.loop.cwd())
					if session_info == nil then
						Session.restore_latest()
					else
						Session.restore(vim.loop.cwd())
					end
				end,
				desc = "Restore last session automatically"
			})
		end,
	},
}
