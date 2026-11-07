-- Bindings checklist, section :Data: the format comes from the filetype, a fenced block or the register, and a buffer
-- that names none is asked about (the real chooser of lib.nvim).
return {
  id = "data.auto",
  title = "data.nvim: :Data, pretty, sort, lines and keys detect the format, or ask",
  task = "data.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.DOC = '{"b":1,"a":2}'
      _G.PRETTY = '{\n  "a": 2,\n  "b": 1\n}'
      _G.set(_G.DOC, "json")]],
    },

    { keys = ":Data<CR>", note = "no action: pretty, json from the filetype" },
    { expect = "_G.text() == _G.PRETTY" },

    { lua = [[_G.set('{"a":1}\n{"b":2}', "json")]] },
    { keys = ":2Data<CR>", note = "a range: only that line" },
    { expect = [[_G.text() == '{"a":1}\n{\n  "b": 2\n}']] },

    { lua = [[_G.set("b:   1", "yaml.docker-compose")]] },
    { keys = ":Data pretty<CR>", note = "yaml from the first part of a compound filetype" },
    { expect = [[_G.text() == "b: 1"]] },

    { lua = [[_G.set('<r  z="1"  a="2"/>', "xml")]] },
    { keys = ":Data pretty<CR>", note = "xml from the filetype" },
    { expect = [[_G.text() == '<r a="2" z="1"/>']] },

    {
      lua = [[_G.set(table.concat({ "text", "```json", _G.DOC, "```", "more" }, "\n"), "markdown")
      vim.api.nvim_win_set_cursor(0, { 3, 0 })]],
    },
    {
      keys = ":Data pretty<CR>",
      note = "a fenced block names the format, the block alone is the scope",
    },
    {
      expect = [[_G.text() == table.concat({ "text", "```json", _G.PRETTY, "```", "more" }, "\n")]],
    },

    {
      lua = [[_G.set("the buffer stays")
      vim.fn.setreg("a", _G.DOC)
      _G.home = vim.api.nvim_get_current_buf()]],
    },
    {
      keys = ":Data pretty --reg=a<CR>",
      note = "the register's text names the format, the result opens beside it",
    },
    {
      expect = [[vim.api.nvim_get_current_buf() ~= _G.home and _G.text() == _G.PRETTY and vim.bo.filetype == "json"]],
    },
    {
      expect = [[table.concat(vim.api.nvim_buf_get_lines(_G.home, 0, -1, false)) == "the buffer stays"]],
      note = "a register source leaves the buffer alone",
    },
    { keys = ":only<CR>" },

    { lua = [[_G.set(_G.DOC, "json")]] },
    { keys = ":Data sort<CR>", note = "the docs say: the same as pretty today" },
    { expect = "_G.text() == _G.PRETTY" },

    { lua = [[_G.set(_G.DOC, "json")]] },
    { keys = ":Data lines<CR>", note = "one path: value per leaf" },
    { expect = [[_G.text() == "a: 2\nb: 1"]] },

    { lua = [[_G.set('{"a":{"b":1}}', "json")]] },
    { keys = ":Data lines --sep=/<CR>", note = "--sep overrides the dot" },
    { expect = [[_G.text() == "a/b: 1"]] },

    { lua = [[_G.set('{"a":{"b":1}}', "json")]] },
    { keys = ":Data keys<CR>", note = "the paths without values" },
    { expect = [[_G.text() == "a.b"]] },

    {
      lua = [[_G.set(_G.DOC)
      _G.home = vim.api.nvim_get_current_buf()]],
    },
    { input = ":Data pretty<CR>", note = "nothing names the format: the chooser asks" },
    { wait = [[vim.bo.filetype == "lib-kit-chooser"]] },
    { input = "<CR>", note = "the first choice is JSON" },
    { wait = [[vim.api.nvim_get_current_buf() == _G.home and _G.text() == _G.PRETTY]] },

    { lua = [[_G.set(_G.DOC)]] },
    { input = ":Data pretty<CR>" },
    { wait = [[vim.bo.filetype == "lib-kit-chooser"]] },
    { input = "<Esc><Esc>", note = "dismissed: nothing happens" },
    { wait = [[vim.bo.filetype ~= "lib-kit-chooser"]] },
    { expect = "_G.text() == _G.DOC" },
  },
}
