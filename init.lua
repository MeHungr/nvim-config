local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Exit keybind
vim.api.nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true, desc = "Exit insert mode with <jj>" })

-- Remove highlighting with Escape key
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>", { noremap = true, silent = true, desc = "Clears highlighting then presses <Esc>" })

-- WhichKey color configuration
vim.api.nvim_set_hl(0, "WhichKeyFloat", { bg = "#1e1e2e", fg = "#cdd6f4" })
vim.api.nvim_set_hl(0, "WhichKeyBorder", { bg = "#1e1e2e", fg = "#89b4fa" })
vim.api.nvim_set_hl(0, "WhichKeyTitle", { fg = "#f38ba8", bold = true })

-- Show relative line numbers
vim.wo.relativenumber = true

vim.o.timeout = true
vim.o.timeoutlen = 300

require("vim-options")
require("lazy").setup("plugins")
