return {
	"folke/which-key.nvim",
	lazy = false,
	config = function()
		local wk = require("which-key")
		wk.add({
			{ "<leader>d", group = "debug" },
			{ "<leader>r", group = "run" },
			{ "<leader>rj", group = "java specific" },
			{ "<leader>t", group = "test" },
			{ "<leader>f", group = "find" },
			{ "<leader>g", group = "formatting" },
			{ "<leader>c", group = "code" },
      { "<leader>y", group = "terminal" },
      { "<leader>b", group = "buffers" },
		})
		wk.setup({
      triggers = { "<leader>" },
			plugins = {
				presets = {
					operators = false, -- don't show d, y, etc.
					motions = false, -- don't show w, b, etc.
					text_objects = false, -- don't show ai, ip, etc.
					windows = false, -- don't show <C-w> bindings
					nav = false, -- don't show <C-d>, <C-u>, etc.
					z = false, -- don't show z-folding bindings
					g = false, -- don't show g-prefixed keys
				},
			},
			win = {
				border = "rounded",
				title = "Keymap Reference",
				title_pos = "center",
				padding = { 1, 2 },
			},
			winhl = {
				Normal = "WhichKeyFloat",
				Border = "WhichKeyBorder",
				Title = "WhichKeyTitle",
			},
			icons = {
				group = "▸",
			},
			layout = {
				spacing = 4,
				align = "center",
				width = { min = 20 },
			},
		})
	end,
}
