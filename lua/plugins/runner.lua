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
      local dynamic_terms = {}
      local next_run_id = 100
      local next_term_id = 6

      local function is_valid(t)
        return t and vim.api.nvim_buf_is_valid(t.bufnr)
      end

      local function purge(tbl)
        for k, t in pairs(tbl) do
          if not is_valid(t) then
            tbl[k] = nil
          end
        end
      end

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
        if is_valid(existing) then
          existing:toggle()
          vim.fn.chansend(existing.job_id, "clear\n" .. cmd .. "\n")
          return
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
        dynamic_terms[term.id] = term
        term:toggle()
        local filename = vim.fn.fnamemodify(filepath, ":t")
        vim.api.nvim_buf_set_name(term.bufnr, "term: " .. filename)
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
          if not static_terms[i] or not is_valid(static_terms[i]) then
            static_terms[i] = Terminal:new({
              count = i,
              dir = get_neotree_root(),
              direction = "horizontal",
              hidden = true,
              close_on_exit = false,
            })
          end
          static_terms[i]:toggle()
        end, { desc = "Toggle terminal " .. i })
      end

      vim.keymap.set("n", "<leader>yn", function()
        local term = Terminal:new({
          count = next_term_id,
          dir = get_neotree_root(),
          direction = "horizontal",
          hidden = true,
          close_on_exit = false,
        })
        dynamic_terms[next_term_id] = term
        next_term_id = next_term_id + 1
        term:toggle()
      end, { desc = "Open new dynamic terminal" })

      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { silent = true, noremap = true, desc = "Exit terminal" })
      vim.keymap.set("t", "jj", [[<C-\><C-n>]], { silent = true, noremap = true, desc = "Exit terminal" })
      vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { silent = true, desc = "Next buffer" })
      vim.keymap.set("n", "<leader>bp", ":bprev<CR>", { silent = true, desc = "Previous buffer" })

      vim.keymap.set("n", "<leader>yl", function()
        purge(file_to_term)
        purge(static_terms)
        purge(dynamic_terms)

        local term_set = {}
        for _, t in pairs(require("toggleterm.terminal").get_all()) do
          if is_valid(t) then
            term_set[t.id] = t
          end
        end
        for _, t in pairs(file_to_term) do term_set[t.id] = t end
        for _, t in pairs(static_terms) do term_set[t.id] = t end
        for _, t in pairs(dynamic_terms) do term_set[t.id] = t end

        local terms = {}
        for _, term in pairs(term_set) do
          table.insert(terms, term)
        end

        if #terms == 0 then
          vim.notify("No terminals open", vim.log.levels.INFO)
          return
        end

        local function term_group(term)
          if file_to_term[term.id] then return "Runner" end
          if static_terms[term.id] then return "Static" end
          if dynamic_terms[term.id] then return "Dynamic" end
          return "Other"
        end

        local function group_rank(group)
          return ({ Runner = 1, Static = 2, Dynamic = 3, Other = 4 })[group] or 99
        end

        table.sort(terms, function(a, b)
          return group_rank(term_group(a)) < group_rank(term_group(b))
        end)

        local entries = {}
        for index, term in ipairs(terms) do
          local group = term_group(term)
          local label = vim.api.nvim_buf_get_name(term.bufnr):match("term: .+") or ("Terminal " .. term.id)
          table.insert(entries, {
            display = string.format("%-8s %s", group, label),
            ordinal = group .. " " .. label,
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
            results = entries,
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

            local function delete_term()
              local selection = action_state.get_selected_entry()
              local t = selection.value.terminal
              if is_valid(t) then
                vim.api.nvim_buf_delete(t.bufnr, { force = true })
              end
              file_to_term[t.id] = nil
              static_terms[t.id] = nil
              dynamic_terms[t.id] = nil
              table.remove(entries, selection.index)
              if #entries == 0 then
                actions.close(prompt_bufnr)
              else
                picker:refresh(finders.new_table({
                  results = entries,
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
