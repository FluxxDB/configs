-- Personal cheat sheet backed by ~/.config/nvim/cheatsheet.md.
--   open()   shows the file in a floating window (edit it and :w to save)
--   search() fuzzy-searches the file plus every keymap that has a description
local M = {}

M.path = vim.fn.stdpath("config") .. "/cheatsheet.md"

local function open_float(lnum)
  local buf = vim.fn.bufadd(M.path)
  vim.fn.bufload(buf)
  local width = math.min(90, vim.o.columns - 4)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Cheat sheet — edit and :w to save, q to close ",
    title_pos = "center",
  })
  vim.bo[buf].buflisted = false
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close cheat sheet" })
  if lnum then
    vim.api.nvim_win_set_cursor(win, { lnum, 0 })
  end
end

function M.open()
  open_float()
end

-- Each non-heading line of cheatsheet.md becomes "Section │ line".
local function sheet_entries()
  local entries, section = {}, ""
  for lnum, line in ipairs(vim.fn.readfile(M.path)) do
    local heading = line:match("^#+%s*(.-)%s*$")
    if heading then
      section = heading
    elseif line:match("%S") and not line:match("^%s*<!%-%-") then
      table.insert(entries, { text = section .. " │ " .. line, lnum = lnum })
    end
  end
  return entries
end

local function keymap_entries()
  local entries, seen = {}, {}
  for _, mode in ipairs({ "n", "x", "i" }) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      if map.desc and not map.lhs:match("^<Plug>") then
        local lhs = map.lhs:gsub("^ ", "Space ")
        local text = ("Keymap (%s) │ %-14s %s"):format(mode, lhs, map.desc)
        if not seen[text] then
          seen[text] = true
          table.insert(entries, { text = text })
        end
      end
    end
  end
  return entries
end

function M.search()
  local lookup, items = {}, {}
  for _, list in ipairs({ sheet_entries(), keymap_entries() }) do
    for _, e in ipairs(list) do
      lookup[e.text] = e
      table.insert(items, e.text)
    end
  end
  require("fzf-lua").fzf_exec(items, {
    prompt = "Cheat sheet> ",
    actions = {
      -- Enter on a cheat-sheet line opens the file there so you can tweak it.
      ["default"] = function(selected)
        local e = selected[1] and lookup[selected[1]]
        if e and e.lnum then
          open_float(e.lnum)
        end
      end,
    },
  })
end

return M
