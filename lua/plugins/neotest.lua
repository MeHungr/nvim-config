return {
  -- Java is done with maven b/c fuck you
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter", -- Required for parsing test files
		-- Adapters (add more as needed)
		"nvim-neotest/neotest-python",
		"nvim-neotest/neotest-go",
	},
	config = function()
		local neotest = require("neotest")
		neotest.setup({
			adapters = {
				-- Python
				require("neotest-python")({
					dap = { justMyCode = false },
				}),

				-- Go
				require("neotest-go"),
		},
		})

		-- Keymaps
		vim.keymap.set("n", "<leader>tn", function()
			neotest.run.run()
		end, { desc = "Run nearest test" })

		vim.keymap.set("n", "<leader>tf", function()
			neotest.run.run(vim.fn.expand("%"))
		end, { desc = "Run test file" })

		vim.keymap.set("n", "<leader>ta", function()
			neotest.run.run(vim.fn.getcwd())
		end, { desc = "Run all tests in project" })

		vim.keymap.set("n", "<leader>ts", function()
			neotest.summary.toggle()
		end, { desc = "Toggle test summary" })

    -- vim.keymap.set("n", "<leader>mj", function()
    -- This will be maven testing eventually
	end,
}
