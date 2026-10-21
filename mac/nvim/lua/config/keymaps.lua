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

-- Cheat sheet (edit ~/.config/nvim/cheatsheet.md to customize)
map("n", "<leader>?", function() require("config.cheatsheet").open() end, { desc = "Open cheat sheet" })
map("n", "<leader>k", function() require("config.cheatsheet").search() end, { desc = "Search cheat sheet + keymaps" })
