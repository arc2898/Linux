-- EVERLUMEN // NEUROGLASS Neovim colors
local c = { bg="#080811", surface="#111321", raised="#1a2033", text="#ecfaff", muted="#8ea3bc", cyan="#3bf7ee", acid="#c6ff3b", pink="#ff42d0", violet="#9870ff", orange="#ffb35c", red="#ff5378" }
vim.o.termguicolors = true
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.g.colors_name = "everlumen"
local groups = {
  Normal={fg=c.text,bg=c.bg}, NormalFloat={fg=c.text,bg=c.surface}, FloatBorder={fg=c.cyan,bg=c.surface},
  CursorLine={bg=c.raised}, LineNr={fg=c.muted}, CursorLineNr={fg=c.acid,bold=true},
  Visual={bg="#33435b"}, Search={fg=c.bg,bg=c.cyan}, IncSearch={fg=c.bg,bg=c.pink},
  Comment={fg=c.muted,italic=true}, String={fg=c.acid}, Function={fg=c.violet},
  Keyword={fg=c.pink,bold=true}, Type={fg=c.cyan}, Constant={fg=c.orange},
  DiagnosticError={fg=c.red}, DiagnosticWarn={fg=c.orange}, DiagnosticInfo={fg=c.cyan}, DiagnosticHint={fg=c.acid},
  Pmenu={fg=c.text,bg=c.raised}, PmenuSel={fg=c.bg,bg=c.cyan}, StatusLine={fg=c.text,bg=c.surface},
  StatusLineNC={fg=c.muted,bg=c.bg}, MatchParen={fg=c.acid,bold=true,underline=true}
}
for name, opts in pairs(groups) do vim.api.nvim_set_hl(0, name, opts) end
