-- Popup hints: press <leader> (or any prefix like g, z, ]) and pause to see what follows.
-- The full searchable cheat sheet lives in lua/config/cheatsheet.lua + cheatsheet.md.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>f", group = "find" },
      { "<leader>b", group = "buffer" },
      { "<leader>g", group = "git" },
    },
  },
}
