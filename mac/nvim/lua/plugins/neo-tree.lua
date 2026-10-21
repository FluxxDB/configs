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
    source_selector = {
      winbar = true, -- the Files / Buffers / Git tab bar
      statusline = false,
    },
    filesystem = {
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = { hide_dotfiles = false, hide_gitignored = false },
    },
    window = { width = 24 }, -- press `e` in the tree to temporarily fit long names
  },
}
