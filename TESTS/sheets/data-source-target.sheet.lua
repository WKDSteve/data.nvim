-- Source and target flags: --reg reads a register, --inplace/--split/--out-reg say where the result goes, and the
-- refusals of docs/commands.md. The system clipboard (the bare --reg/--out-reg default "+") is an in-memory
-- g:clipboard provider of Lua functions: the real one would start a program (win32yank, pbpaste, xclip) and touch the
-- user's clipboard.
return {
  id = "data.source-target",
  feature = "data.source-target",
  title = "data.nvim: --reg, --inplace, --split and --out-reg, with the clipboard and the refusals",
  task = "data.nvim/performance-pruefung-luecken-schliessen-katalog-feature-shee",
  steps = {
    {
      lua = [[_G.CLIP = { lines = { "" }, regtype = "v" }
      vim.g.clipboard = {
        name = "sheet-memory",
        copy = {
          ["+"] = function(lines, regtype) _G.CLIP = { lines = lines, regtype = regtype } end,
          ["*"] = function(lines, regtype) _G.CLIP = { lines = lines, regtype = regtype } end,
        },
        paste = {
          ["+"] = function() return { _G.CLIP.lines, _G.CLIP.regtype } end,
          ["*"] = function() return { _G.CLIP.lines, _G.CLIP.regtype } end,
        },
      }
      dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.DOC = '{"b":1,"a":2}'
      _G.PRETTY = '{\n  "a": 2,\n  "b": 1\n}'
      _G.home_is = function(text)
        return table.concat(vim.api.nvim_buf_get_lines(_G.home, 0, -1, false), "\n") == text
      end
      _G.set(_G.DOC, "json")
      _G.home = vim.api.nvim_get_current_buf()]],
    },

    { keys = ":JSON lines --split<CR>", note = "a buffer source into a scratch split beside it" },
    {
      expect = [[vim.api.nvim_get_current_buf() ~= _G.home and _G.text() == "a: 2\nb: 1"
        and vim.bo.buftype == "nofile" and vim.api.nvim_buf_get_name(0):find("data://json lines", 1, true) ~= nil]],
    },
    { expect = "_G.home_is(_G.DOC)", note = "the source buffer is left as it was" },
    { keys = ":only<CR>" },

    { lua = "_G.set(_G.DOC, 'json') _G.home = vim.api.nvim_get_current_buf()" },
    { keys = ":JSON compact --out-reg=b<CR>", note = "into a named register, and it says so" },
    { wait = [[_G.noted("wrote 1 line(s) to register 'b'")]] },
    { expect = [[vim.fn.getreg("b", 1, true)[1] == '{"a":2,"b":1}' and _G.home_is(_G.DOC)]] },

    {
      lua = "_G.set('the buffer stays') _G.home = vim.api.nvim_get_current_buf() vim.fn.setreg('a', _G.DOC)",
    },
    { keys = ":JSON pretty --reg=a<CR>", note = "a register source opens a split by default" },
    {
      expect = [[vim.api.nvim_get_current_buf() ~= _G.home and _G.text() == _G.PRETTY and vim.bo.filetype == "json"]],
    },
    { expect = [[_G.home_is("the buffer stays")]] },
    { keys = ":only<CR>" },

    { lua = "_G.set('keep\\nreplace me\\nkeep') _G.home = vim.api.nvim_get_current_buf()" },
    {
      keys = ":2JSON pretty --reg=a --inplace<CR>",
      note = "a register pasted formatted over a range",
    },
    { expect = [[_G.text() == "keep\n" .. _G.PRETTY .. "\nkeep"]] },

    {
      lua = "_G.set('the buffer stays') _G.home = vim.api.nvim_get_current_buf() _G.CLIP = { lines = { '[3,1]' }, regtype = 'v' }",
    },
    {
      keys = ":JSON pretty --reg<CR>",
      note = "a bare --reg reads the clipboard (here: the in-memory provider)",
    },
    { expect = [[vim.api.nvim_get_current_buf() ~= _G.home and _G.text() == "[\n  3,\n  1\n]"]] },
    { keys = ":only<CR>" },

    { lua = "_G.set(_G.DOC, 'json')" },
    { keys = ":JSON compact --out-reg<CR>", note = "a bare --out-reg writes the clipboard" },
    { wait = [[_G.noted("wrote 1 line(s) to register '+'")]] },
    {
      expect = [[_G.CLIP.lines[1] == '{"a":2,"b":1}']],
      note = "the provider got the line (a linewise copy hands it a trailing empty line too)",
    },

    { lua = "_G.set(_G.DOC, 'json')" },
    {
      keys = ":JSON pretty --split --out-reg=b<CR>",
      ignore_errmsg = true,
      note = "two targets are an error",
    },
    { wait = [[_G.noted("mutually exclusive")]] },
    { expect = "_G.text() == _G.DOC and #vim.api.nvim_list_wins() == 1" },

    { lua = "_G.set(_G.DOC, 'json')" },
    {
      keys = ":JSON pretty --reg=a --inplace<CR>",
      ignore_errmsg = true,
      note = "--reg --inplace needs a range",
    },
    { wait = [[_G.noted("needs an explicit range")]] },
    { expect = "_G.text() == _G.DOC" },

    { lua = "_G.set(_G.DOC, 'json')" },
    {
      keys = ":JSON pretty --out-reg=%<CR>",
      ignore_errmsg = true,
      note = "a read-only register is refused by name",
    },
    { wait = [[_G.noted("register '%' is read-only")]] },

    { lua = "_G.set(_G.DOC, 'json')" },
    {
      keys = ":JSON pretty --reg==<CR>",
      ignore_errmsg = true,
      note = "the expression register is never read",
    },
    { wait = [[_G.noted("expression register")]] },

    { lua = "_G.set(_G.DOC, 'json') vim.fn.setreg('c', '')" },
    {
      keys = ":JSON pretty --reg=c<CR>",
      ignore_errmsg = true,
      note = "an empty register is reported",
    },
    { wait = [[_G.noted("register 'c' is empty")]] },
    { expect = "_G.text() == _G.DOC and #vim.api.nvim_list_wins() == 1" },
  },
}
