-- File explorer sidebar with "Files | Buffers | Git" tabs across the top.
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle reveal<cr>", desc = "File explorer" },
    { "<leader>be", "<cmd>Neotree toggle buffers<cr>", desc = "Buffer explorer" },
    { "<leader>ge", "<cmd>Neotree toggle git_status<cr>", desc = "Git explorer" },
  },
  opts = {
    sources = { "filesystem", "buffers", "git_status" },
    commands = {
      -- Open the file under the cursor but stay in the tree, so several files
      -- can be opened in a row.
      open_keep_focus = function(state)
        local tree_win = vim.api.nvim_get_current_win()
        require("neo-tree.sources." .. state.name .. ".commands").open(state)
        if vim.api.nvim_win_is_valid(tree_win) then
          vim.api.nvim_set_current_win(tree_win)
        end
      end,
    },
    source_selector = {
      winbar = true, -- the Files / Buffers / Git tab bar
      statusline = false,
    },
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = { hide_dotfiles = false, hide_gitignored = false },
    },
    window = {
      width = 24, -- press `e` in the tree to temporarily fit long names
      mappings = {
        ["<cr>"] = "open_keep_focus",
        ["<2-LeftMouse>"] = "open_keep_focus",
      },
    },
  },
}
