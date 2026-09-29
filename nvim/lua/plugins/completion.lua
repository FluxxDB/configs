return {
  "saghen/blink.cmp",
  version = "1.*",
  event = "InsertEnter",
  opts = {
    keymap = { preset = "default" },
    sources = { default = { "lsp", "path", "buffer" } },
  },
}
