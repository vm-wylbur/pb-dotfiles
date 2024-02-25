local wk = require("which-key")

P = function(x)
	print(vim.inspect(x))
	return x
end

RELOAD = function(...)
	return require("plenary.reload").reload_module(...)
end

R = function(name)
	RELOAD(name)
	return require(name)
end

local nmap = function(key, effect)
	vim.keymap.set("n", key, effect, { silent = true, noremap = true })
end

local vmap = function(key, effect)
	vim.keymap.set("v", key, effect, { silent = true, noremap = true })
end

local imap = function(key, effect)
	vim.keymap.set("i", key, effect, { silent = true, noremap = true })
end

nmap("<m-1>", "<cmd>LualineBuffersJump! 1<cr>" )
nmap("<leader>1", "<cmd>LualineBuffersJump! 1<cr>" )
nmap("<leader>2", "<cmd>LualineBuffersJump! 2<cr>" )
nmap("<leader>3", "<cmd>LualineBuffersJump! 3<cr>" )
nmap("<leader>4", "<cmd>LualineBuffersJump! 4<cr>" )
nmap("<leader>5", "<cmd>LualineBuffersJump! 5<cr>" )
nmap("<leader>6", "<cmd>LualineBuffersJump! 6<cr>" )
nmap("<leader>7", "<cmd>LualineBuffersJump! 7<cr>" )
nmap("<leader>8", "<cmd>LualineBuffersJump! 8<cr>" )
nmap("<leader>9", "<cmd>LualineBuffersJump! 9<cr>" )

-- now with smart-splits.nvim
vim.keymap.set('n', '<C-h>', require('smart-splits').move_cursor_left)
vim.keymap.set('n', '<C-j>', require('smart-splits').move_cursor_down)
vim.keymap.set('n', '<C-k>', require('smart-splits').move_cursor_up)
vim.keymap.set('n', '<C-l>', require('smart-splits').move_cursor_right)

-- send code with ctrl+Enter
-- just like in e.g. RStudio
-- needs kitty (or other terminal) config:
-- map shift+enter send_text all \x1b[13;2u
-- map ctrl+enter send_text all \x1b[13;5u
nmap("<c-cr>", "<Plug>SlimeSendCell")
nmap("<s-cr>", "<Plug>SlimeSendCell")
imap("<c-cr>", "<esc><Plug>SlimeSendCell<cr>i")
imap("<s-cr>", "<esc><Plug>SlimeSendCell<cr>i")

-- send code with Enter and leader Enter
vmap("<cr>", "<Plug>SlimeRegionSend")
nmap("<leader><cr>", "<Plug>SlimeSendCell")

-- keep selection after indent/dedent
vmap(">", ">gv")
vmap("<", "<gv")

-- remove search highlight on esc
nmap("<esc>", "<cmd>noh<cr>")

-- find files with telescope
-- nmap("<c-p>", "<cmd>Telescope find_files<cr>")
nmap("<leader><space>", "<cmd>Telescope buffers<cr>")

-- paste and without overwriting register
vmap("<leader>p", '"_dP')

-- delete and without overwriting register
vmap("<leader>d", '"_d')

-- center after search and jumps
nmap("n", "nzz")
nmap("<c-d>", "<c-d>zz")
nmap("<c-u>", "<c-u>zz")

--show kepbindings with whichkey
--add your own here if you want them to
--show up in the popup as well
wk.register({
  a = { "<cmd>Telescope command_history<cr>", "command history" },
	b = {
		name = "buffers",
		d = { ":Bdelete<cr>", "delete current buffer" },
	},
	c = {
		name = "code",
		c ={ ":SlimeConfig<cr>", "slime config" },
		n = { ":vsplit term://$SHELL<cr>", "new terminal" },
		r = { ":vsplit term://R<cr>", "new R terminal" },
		p = { ":vsplit term://python<cr>", "new python terminal" },
		i = { ":vsplit term://ipython<cr>", "new ipython terminal" },
		j = { ":vsplit term://julia<cr>", "new julia terminal" },
	},
	f = {
		name = "find (telescope)",
		f = { "<cmd>Telescope find_files<cr>", "files" },
		h = { "<cmd>Telescope help_tags<cr>", "help" },
		k = { "<cmd>Telescope keymaps<cr>", "keymaps" },
		r = { "<cmd>Telescope lsp_references<cr>", "references" },
		g = { "<cmd>Telescope live_grep<cr>", "grep" },
		b = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", "fuzzy" },
		o = { "<cmd>Telescope oldfiles<cr>", "recents" },
		m = { "<cmd>Telescope marks<cr>", "marks" },
		M = { "<cmd>Telescope man_pages<cr>", "man pages" },
		c = { "<cmd>Telescope git_commits<cr>", "git commits" },
		s = { "<cmd>Telescope lsp_document_symbols<cr>", "symbols" },
		d = { "<cmd>Telescope buffers<cr>", "buffers" },
		q = { "<cmd>Telescope quickfix<cr>", "quickfix" },
		l = { "<cmd>Telescope loclist<cr>", "loclist" },
		j = { "<cmd>Telescope jumplist<cr>", "marks" },
		p = { "project" },
	},
	g = {
		name = "git",
		c = { ":GitConflictRefresh<cr>", "conflict" },
		g = { ":Neogit<cr>", "neogit" },
		s = { ":Gitsigns<cr>", "gitsigns" },
		pl = { ":Octo pr list<cr>", "gh pr list" },
		pr = { ":Octo review start<cr>", "gh pr review" },
		wc = { ":lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>", "worktree create" },
		ws = { ":lua require('telescope').extensions.git_worktree.git_worktrees()<cr>", "worktree switch" },
		d = {
			name = "diff",
			o = { ":DiffviewOpen<cr>", "open" },
			c = { ":DiffviewClose<cr>", "close" },
		},
		b = {
			name = "blame",
			b = { ":GitBlameToggle<cr>", "toggle" },
			o = { ":GitBlameOpenCommitURL<cr>", "open" },
			c = { ":GitBlameCopyCommitURL<cr>", "copy" },
		},
	},
	h = {
		name = "help/debug/conceal",
		c = {
			name = "conceal",
			h = { ":set conceallevel=1<cr>", "hide/conceal" },
			s = { ":set conceallevel=0<cr>", "show/unconceal" },
		},
		t = {
			name = "treesitter",
			t = { vim.treesitter.inspect_tree, "show tree" },
			c = { ":=vim.treesitter.get_captures_at_cursor()<cr>", "show capture" },
			n = { ":=vim.treesitter.get_node():type()<cr>", "show node" },
		},
	},
  j = {
    name = "Jump", -- optional group name
    c = { "<cmd>Telescope find_files search_dirs={'~/.config/nvim/'}<cr>", "Find Configs" },
    o = { "<cmd>Telescope live_grep search_dirs={'~/.config/nvim/'}<cr>", "Grep Configs" },
    d = { "<cmd>Telescope find_files search_dirs={'~/dotfiles/'}<cr>", "Find Dotfiles" },
    t = { "<cmd>Telescope live_grep search_dirs={'~/dotfiles/'}<cr>", "Grep Dotfiles" },
    n = { "<cmd>Telescope find_files search_dirs={'~/notes/'}<cr>", "Find Notes" },
    g = { "<cmd>Telescope live_grep search_dirs={'~/notes/'}<cr>", "Grep Notes" },
    p = { "<cmd>Telescope live_grep search_dirs={'~/Downloads/python-3.12.1-docs-text/library/'}<cr>", "Grep Python docs"},
  },
	l = {
		name = "language/lsp",
		r = { "<cmd>Telescope lsp_references<cr>", "references" },
		R = { "rename" },
		D = { vim.lsp.buf.type_definition, "type definition" },
		a = { vim.lsp.buf.code_action, "coda action" },
		e = { vim.diagnostic.open_float, "diagnostics" },
		d = {
			name = "diagnostics",
			d = { vim.diagnostic.disable, "disable" },
			e = { vim.diagnostic.enable, "enable" },
		},
		g = { ":Neogen<cr>", "neogen docstring" },
		s = { ":ls!<cr>", "list all buffers" },
	},
	o = {
		name = "otter & code",
		a = { require("otter").dev_setup, "otter activate" },
		["o"] = { "o# %%<cr>", "new code chunk below" },
		["O"] = { "O# %%<cr>", "new code chunk above" },
		["b"] = { "o```{bash}<cr>```<esc>O", "bash code chunk" },
		["r"] = { "o```{r}<cr>```<esc>O", "r code chunk" },
		["p"] = { "o```{python}<cr>```<esc>O", "python code chunk" },
		["j"] = { "o```{julia}<cr>```<esc>O", "julia code chunk" },
		["l"] = { "o```{julia}<cr>```<esc>O", "julia code chunk" },
	},
	q = {
		name = "quarto",
		a = { ":QuartoActivate<cr>", "activate" },
		p = { ":lua require'quarto'.quartoPreview()<cr>", "preview" },
		q = { ":lua require'quarto'.quartoClosePreview()<cr>", "close" },
		h = { ":QuartoHelp ", "help" },
		r = {
			name = "run",
			r = { ":QuartoSendAbove<cr>", "to cursor" },
			a = { ":QuartoSendAll<cr>", "all" },
		},
		e = { ":lua require'otter'.export()<cr>", "export" },
		E = { ":lua require'otter'.export(true)<cr>", "export overwrite" },
	},
	s = {
		name = "spellcheck",
		s = { "<cmd>Telescope spell_suggest<cr>", "spelling" },
		["/"] = { "<cmd>setlocal spell!<cr>", "spellcheck" },
		n = { "]s", "next" },
		p = { "[s", "previous" },
		g = { "zg", "good" },
		r = { "zg", "rigth" },
		w = { "zw", "wrong" },
		b = { "zw", "bad" },
		["?"] = { "<cmd>Telescope spell_suggest<cr>", "suggest" },
	},
	v = {
		name = "vim",
		t = { toggle_light_dark_theme, "switch theme" },
		c = { ":Telescope colorscheme<cr>", "colortheme" },
		l = { ":Lazy<cr>", "Lazy" },
		m = { ":Mason<cr>", "Mason" },
		s = { ":e $MYVIMRC | :cd %:p:h | split . | wincmd k<cr>", "Settings" },
		h = { ':execute "h " . expand("<cword>")<cr>', "help" },
	},
	w = { ":w<cr>", "write" },  -- TODO repurppose me!
	x = { ":w<cr>:source %<cr>", "run file" }, -- run this file
}, { mode = "n", prefix = "<leader>" })

local is_code_chunk = function()
	local current, range = require("otter.keeper").get_current_language_context()
	if current then
		return true
	else
		return false
	end
end

local insert_code_chunk = function(lang)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "n", true)
	local keys
	if is_code_chunk() then
		keys = [[o```<cr><cr>```{]] .. lang .. [[}<esc>o]]
	else
		keys = [[o```{]] .. lang .. [[}<cr>```<esc>O]]
	end
	keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end

local insert_r_chunk = function()
	insert_code_chunk("r")
end

local insert_py_chunk = function()
	insert_code_chunk("python")
end

-- normal mode
wk.register({
	["<c-LeftMouse>"] = { "<cmd>lua vim.lsp.buf.definition()<CR>", "go to definition" },
	-- ["<c-q>"] = { "<cmd>q<cr>", "close buffer" }, -- this closes everything :(
	["<esc>"] = { "<cmd>noh<cr>", "remove search highlight" },
	["n"] = { "nzzzv", "center search" },
	["gN"] = { "Nzzzv", "center search" },
	["gl"] = { "<c-]>", "open help link" },
	["gf"] = { ":e <cfile><CR>", "edit file" },
	-- ["<m-i>"] = { insert_r_chunk, "r code chunk" },
	-- ["<cm-i>"] = { insert_py_chunk, "python code chunk" },
	-- ["<m-I>"] = { insert_py_chunk, "python code chunk" },
	["]q"] = { ":silent cnext<cr>", "quickfix next" },
	["[q"] = { ":silent cprev<cr>", "quickfix prev" },
}, { mode = "n", silent = true })

-- -- visual mode
-- wk.register({
-- 	["<cr>"] = { "<Plug>SlimeRegionSend", "run code region" },
-- 	["<M-j>"] = { ":m'>+<cr>`<my`>mzgv`yo`z", "move line down" },
-- 	["<M-k>"] = { ":m'<-2<cr>`>my`<mzgv`yo`z", "move line up" },
-- 	["."] = { ":norm .<cr>", "repat last normal mode command" },
-- 	["q"] = { ":norm @q<cr>", "repat q macro" },
-- }, { mode = "v" })
--
-- wk.register({
-- 	["<leader>"] = { "<Plug>SlimeRegionSend", "run code region" },
-- 	["p"] = { '"_dP', "replace without overwriting reg" },
-- }, { mode = "v", prefix = "<leader>" })
--
-- -- insert mode
-- wk.register({
-- 	-- ['<c-e>'] = { "<esc>:FeMaco<cr>i", "edit code" },
-- 	["<m-->"] = { " <- ", "assign" },
-- 	["<m-m>"] = { " |>", "pipe" },
-- 	["<m-i>"] = { insert_r_chunk, "r code chunk" },
-- 	["<cm-i>"] = { insert_py_chunk, "python code chunk" },
-- 	["<m-I>"] = { insert_py_chunk, "python code chunk" },
-- 	["<c-x><c-x>"] = { "<c-x><c-o>", "omnifunc completion" },
-- }, { mode = "i" })

