return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    dependencies = { "nvim-telescope/telescope.nvim" },
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
      local file_to_term = {}
      local static_terms = {}
      local next_run_id = 100

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

      local function get_neotree_root()
        local state = require("neo-tree.sources.manager").get_state("filesystem")
        return state and state.path or vim.fn.getcwd()
      end

      local function run_file_in_terminal(filepath, cmd)
        local existing = file_to_term[filepath]
        if existing then
          if vim.api.nvim_buf_is_valid(existing.bufnr) then
            existing:toggle()
            vim.fn.chansend(existing.job_id, "clear\n" .. cmd .. "\n")
            return
          else
            file_to_term[filepath] = nil
          end
        end

        local term = Terminal:new({
          count = next_run_id,
          dir = get_neotree_root(),
          direction = "horizontal",
          hidden = true,
          close_on_exit = false,
        })
        next_run_id = next_run_id + 1
        file_to_term[filepath] = term
        term:toggle()
        vim.fn.chansend(term.job_id, "clear\n" .. cmd .. "\n")
      end

      vim.keymap.set("n", "<leader>rr", function()
        local ft = vim.bo.filetype
        local file = vim.fn.expand("%:p")
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
        run_file_in_terminal(file, cmd)
      end, { desc = "Run current file" })

      vim.keymap.set("n", "<leader>rje", function()
        local main_class = get_main_class()
        if not main_class then return end
        local file = vim.fn.expand("%:p")
        run_file_in_terminal(file, "mvn exec:java -Dexec.mainClass=" .. main_class)
      end, { desc = "Run Java exec:java" })

      vim.keymap.set("n", "<leader>rjg", function()
        local main_class = get_main_class()
        if not main_class then return end
        local file = vim.fn.expand("%:p")
        run_file_in_terminal(file, "mvn javafx:run -Djavafx.mainClass=" .. main_class)
      end, { desc = "Run JavaFX" })

      for i = 1, 5 do
        vim.keymap.set("n", "<leader>y" .. i, function()
          if not static_terms[i] then
            static_terms[i] = Terminal:new({ count = i, dir = get_neotree_root(), direction = "horizontal", hidden = true, close_on_exit = false })
          end
          static_terms[i]:toggle()
        end, { desc = "Toggle terminal " .. i })
      end

      local next_term_id = 2
      vim.keymap.set("n", "<leader>yn", function()
        local term = Terminal:new({
          count = next_term_id,
          dir = get_neotree_root(),
          direction = "horizontal",
          hidden = true,
          close_on_exit = false,
        })
        next_term_id = next_term_id + 1
        term:toggle()
      end, { desc = "Open new dynamic terminal" })

      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true, noremap = true, desc = "Exit terminal" })
      vim.keymap.set("t", "jj", [[<C-\><C-n>]], { silent = true, noremap = true, desc = "Exit terminal" })

      vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { silent = true, desc = "Next buffer" })
      vim.keymap.set("n", "<leader>bp", ":bprev<CR>", { silent = true, desc = "Previous buffer" })

            vim.keymap.set("n", "<leader>yl", function()
        local term_set = {}
        for _, t in pairs(require("toggleterm.terminal").get_all()) do
          term_set[t.id] = t
        end
        for _, t in pairs(file_to_term) do
          term_set[t.id] = t
        end
        for id, t in pairs(static_terms) do
          if t and vim.api.nvim_buf_is_valid(t.bufnr) then
            term_set[t.id] = t
          end
        end
        local terms = {}
        for _, term in pairs(term_set) do
          table.insert(terms, term)
        end

        if #terms == 0 then
          vim.notify("No terminals open", vim.log.levels.INFO)
          return
        end

        local pick_entries = {}
        for index, term in ipairs(terms) do
          table.insert(pick_entries, {
            display = "Terminal " .. term.id,
            ordinal = tostring(term.id),
            id = term.id,
            terminal = term,
            index = index,
          })
        end

        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local conf = require("telescope.config").values

        local picker
        picker = pickers.new({}, {
          prompt_title = "ToggleTerm Terminals",
          finder = finders.new_table({
            results = pick_entries,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.display,
                ordinal = entry.ordinal,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              selection.value.terminal:toggle()
            end)

            local delete_term = function()
              local selection = action_state.get_selected_entry()
              vim.api.nvim_buf_delete(selection.value.terminal.bufnr, { force = true })
              vim.notify("Closed terminal " .. selection.value.id)
              for path, term in pairs(file_to_term) do
                if term.id == selection.value.id then
                  file_to_term[path] = nil
                end
              end
              for id, term in pairs(static_terms) do
                if term.id == selection.value.id then
                  static_terms[id] = nil
                end
              end
              table.remove(pick_entries, selection.index)
              if #pick_entries == 0 then
                actions.close(prompt_bufnr)
              else
                picker:refresh(finders.new_table({
                  results = pick_entries,
                  entry_maker = function(entry)
                    return {
                      value = entry,
                      display = entry.display,
                      ordinal = entry.ordinal,
                    }
                  end,
                }), { reset_prompt = true })
              end
            end

            map("i", "<C-d>", delete_term)
            map("n", "<C-d>", delete_term)

            return true
          end,
        })

        picker:find()
      end, { desc = "List terminals with Telescope" })
    end,
  },
}
