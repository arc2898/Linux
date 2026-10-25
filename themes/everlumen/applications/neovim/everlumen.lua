-- EVERLUMEN palette for Neovim. Source this file from your init.lua.
local c = {
  bg = "#0b1020", surface = "#151c2e", text = "#e8f4f4",
  muted = "#9aabc1", mint = "#8fffd8", lilac = "#c6a7ff",
  petal = "#ffb6d9", blue = "#8acbff", amber = "#ffd6a5",
}
vim.o.termguicolors = true
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.g.colors_name = "everlumen"

local groups = {
  Normal = { fg = c.text, bg = c.bg },
  NormalFloat = { fg = c.text, bg = c.surface },
  FloatBorder = { fg = c.mint, bg = c.surface },
  CursorLine = { bg = c.surface },
  LineNr = { fg = c.muted },
  CursorLineNr = { fg = c.mint, bold = true },
  Visual = { bg = "#334b6276" },
  Search = { fg = c.bg, bg = c.mint },
  IncSearch = { fg = c.bg, bg = c.petal },
  Comment = { fg = c.muted, italic = true },
  String = { fg = c.mint },
  Function = { fg = c.lilac },
  Keyword = { fg = c.petal },
  Type = { fg = c.blue },
  Constant = { fg = c.amber },
  DiagnosticError = { fg = c.petal },
  DiagnosticWarn = { fg = c.amber },
  DiagnosticInfo = { fg = c.blue },
  DiagnosticHint = { fg = c.mint },
}
for group, opts in pairs(groups) do
  vim.api.nvim_set_hl(0, group, opts)
end
