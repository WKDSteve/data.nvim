-- TESTS/sheets/_helpers.lua -- what the data.nvim test sheets need in their child editor. Not a sheet (`testing.sheet`
-- only reads *.sheet.lua); a sheet's first step runs it with `dofile`, the child's cwd is the project root. The directory
-- is in the spec's @cache-inputs, so a change here re-runs the sheets. Everything lives in buffers and named registers:
-- no file is written and the clipboard is not touched.

vim.opt.shortmess:append("I")
vim.o.swapfile = false
vim.o.hidden = true
-- The native prompts of `:JSON filter` print a list: no hit-enter prompt may swallow the next typed key.
vim.o.cmdheight = 10

require("data").setup({})

_G.notes = {}
local notify = vim.notify
vim.notify = function(msg, level, opts)
  _G.notes[#_G.notes + 1] = tostring(msg)
  return notify(msg, level, opts)
end

--- A fresh buffer holding `text`, with `ft` as its filetype. The notes start over too.
---@param text string
---@param ft? string
---@return boolean
_G.set = function(text, ft)
  vim.cmd.enew({ bang = true })
  vim.bo.buftype = "nofile"
  vim.bo.filetype = ft or ""
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, "\n", { plain = true }))
  _G.notes = {}
  return true
end

--- The current buffer's text.
---@return string
_G.text = function()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

--- Whether a notification so far holds `needle`.
---@param needle string
---@return boolean
_G.noted = function(needle)
  for _, note in ipairs(_G.notes) do
    if note:find(needle, 1, true) then
      return true
    end
  end
  return false
end
