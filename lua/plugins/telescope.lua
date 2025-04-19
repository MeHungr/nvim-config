return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-fzf-native.nvim",
		},
		config = function()
			local telescope = require("telescope")
			local builtin = require("telescope.builtin")
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			-- Key mappings for Telescope functions
			vim.keymap.set("n", "<leader>ff", function()
				builtin.find_files({ hidden = true })
			end, { desc = "Fuzzy find files from working directory" })

			vim.keymap.set("n", "<leader><Tab>", builtin.buffers, { desc = "List open buffers" })

			telescope.setup({
				pickers = {
					buffers = {
						mappings = {
							i = {
								["<C-d>"] = require("telescope.actions").delete_buffer,
							},
							n = {
								["<C-d>"] = require("telescope.actions").delete_buffer,
							},
						},
					},
				},
			})

			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep in working directory" })

			vim.keymap.set("n", "<leader>fd", function()
				builtin.find_files({
					prompt_title = "Jump to Folder",
					find_command = { "fd", "--type", "d", "--hidden", "--exclude", ".git" },
					attach_mappings = function(_, map)
						map("i", "<CR>", function(prompt_bufnr)
							local entry = action_state.get_selected_entry()
							local path = entry.path or entry.value
							actions.close(prompt_bufnr)

							local dir = vim.fn.fnamemodify(path, ":p")
							vim.cmd("cd " .. vim.fn.fnameescape(dir))
							vim.cmd("Neotree reveal dir=" .. vim.fn.fnameescape(dir))
						end)
						return true
					end,
				})
			end, { desc = "Find folder and open in Neo-tree" })

			-- Load the fzf extension
			telescope.load_extension("fzf")
		end,
	},

	{
		"nvim-telescope/telescope-ui-select.nvim",
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown({}),
					},
				},
			})
			require("telescope").load_extension("ui-select")
		end,
	},
}
