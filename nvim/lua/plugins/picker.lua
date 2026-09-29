return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  keys = {
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Grep" },
    { "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
    { "<leader>fh", "<cmd>FzfLua help_tags<cr>", desc = "Help" },
    { "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent files" },
  },
  opts = {},
}
