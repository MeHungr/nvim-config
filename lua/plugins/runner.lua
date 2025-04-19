return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      local toggleterm = require("toggleterm")
      toggleterm.setup({
        direction = "horizontal",
        size = 15,
        open_mapping = nil,
        start_in_insert = true,
        insert_mappings = true,
        shade_terminals = true,
        persist_size = true,
        persist_mode = true,
      })

      local Terminal = require("toggleterm.terminal").Terminal

      -- Utility: determine Java main class from src/main/java
      local function get_main_class()
        local filepath = vim.fn.expand("%:p")
        local root = filepath:match("(.-src/main/java/)")
        if not root then
          vim.notify("Not in src/main/java/ — can't infer mainClass", vim.log.levels.ERROR)
          return nil
        end
        local relative = filepath:sub(#root + 1)
        return relative:gsub("%.java$", ""):gsub("/", ".")
      end

      -- Shared terminal instance
      local runner = Terminal:new({
        direction = "horizontal",
        close_on_exit = false,
        hidden = true,
      })

      -- Run current file (non-Java)
      vim.keymap.set("n", "<leader>rr", function()
        local ft = vim.bo.filetype
        local file = vim.fn.expand("%")
        local name = vim.fn.expand("%:t:r")

        local cmd = ({
          python = "python3 " .. file,
          go = "go run " .. file,
          lua = "lua " .. file,
          sh = "bash " .. file,
        })[ft]

        if not cmd then
          vim.notify("No run command for filetype: " .. ft, vim.log.levels.WARN)
          return
        end

        if not runner:is_open() then runner:open() end
        vim.fn.chansend(runner.job_id, "clear\n")
        vim.fn.chansend(runner.job_id, cmd .. "\n")
      end, { desc = "Run current file" })

      -- Java exec:java
      vim.keymap.set("n", "<leader>rje", function()
        local main_class = get_main_class()
        if not main_class then return end
        if not runner:is_open() then runner:open() end
        vim.fn.chansend(runner.job_id, "clear\n")
        vim.fn.chansend(runner.job_id, "mvn exec:java -Dexec.mainClass=" .. main_class .. "\n")
      end, { desc = "Run mvn exec:java" })

      -- JavaFX runner
      vim.keymap.set("n", "<leader>rjg", function()
        local main_class = get_main_class()
        if not main_class then return end
        if not runner:is_open() then runner:open() end
        vim.fn.chansend(runner.job_id, "clear\n")
        vim.fn.chansend(runner.job_id, "mvn javafx:run -Djavafx.mainClass=" .. main_class .. "\n")
      end, { desc = "Run mvn javafx:run" })

      -- Manually toggle the runner terminal
      vim.keymap.set("n", "<leader>rt", function()
        runner:toggle()
      end, { desc = "Toggle runner terminal" })

      -- Exit terminal mode safely
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true, noremap = true, desc = "Exit terminal with <Esc>" })
      vim.keymap.set("t", "jj", [[<C-\><C-n>]], { silent = true, noremap = true, desc = "Exit terminal with <jj>" })
    end,
  },
}

