-- Move lines up/down with Option(Alt)+j/k, like VS Code's Alt+Arrow.
-- Requires the terminal to send Option as Esc+/Meta (iTerm2: Profiles > Keys > Option key: Esc+).
local map = vim.keymap.set

-- Normal mode: move current line, re-indent
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })

-- Insert mode: move line, return to insert
map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move line up" })

-- Visual mode: move selection, reselect, re-indent
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Close the current buffer like :bd, but keep the window (and the layout with
-- the explorer) by switching it to the previous buffer first.
map("n", "<leader>d", function()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].modified then
    vim.notify("Unsaved changes: :w first, or :bd! to discard them", vim.log.levels.WARN)
    return
  end
  vim.cmd("bprevious")
  if vim.api.nvim_get_current_buf() == buf then
    vim.cmd("enew") -- it was the only buffer
  end
  vim.cmd("bdelete " .. buf)
end, { desc = "Close buffer" })

-- Cheat sheet (edit ~/.config/nvim/cheatsheet.md to customize)
map("n", "<leader>?", function() require("config.cheatsheet").open() end, { desc = "Open cheat sheet" })
map("n", "<leader>k", function() require("config.cheatsheet").search() end, { desc = "Search cheat sheet + keymaps" })
