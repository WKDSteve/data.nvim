-- Bindings checklist, section :XML: every action but filter (data-filter.sheet.lua), typed on a real buffer.
return {
  id = "data.xml",
  title = "data.nvim: :XML, pretty, compact, sort, lines and keys, in place and on a range",
  task = "data.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.DOC = '<r z="1" a="2"><c>t</c></r>'
      _G.set(_G.DOC, "xml")]],
    },

    { keys = ":XML<CR>", note = "no action: pretty over the whole buffer" },
    { wait = "vim.api.nvim_buf_line_count(0) > 1" },
    { lua = "_G.PRETTY = _G.text()" },
    {
      expect = [[_G.PRETTY:find('^<r a="2" z="1">\n  <c>') ~= nil]],
      note = "two spaces, attributes in order",
    },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":XML pretty<CR>", note = "the same as no action" },
    { expect = "_G.text() == _G.PRETTY" },

    { keys = ":XML compact<CR>", note = "back onto one line" },
    { expect = [[_G.text() == '<r a="2" z="1"><c>t</c></r>']] },

    { keys = ":XML pretty 4<CR>", note = "an explicit indent" },
    { expect = [[vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]:find("^    <c>") ~= nil]] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":XML sort<CR>", note = "the docs say: the same as pretty today" },
    { expect = "_G.text() == _G.PRETTY" },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":XML lines<CR>", note = "the raw element tree, one path: value per leaf" },
    {
      expect = [[_G.text():find("tag: r", 1, true) ~= nil and _G.text():find("attrs.a: 2", 1, true) ~= nil]],
    },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":XML lines --sep=/<CR>", note = "--sep overrides the dot" },
    { expect = [[_G.text():find("attrs/a: 2", 1, true) ~= nil]] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":XML keys<CR>", note = "the paths without values" },
    {
      expect = [[_G.text():find("attrs.a", 1, true) ~= nil and _G.text():find(": ", 1, true) == nil]],
    },

    -- Both lines are documents compact would change: the first has to stay as typed, the second has to change.
    { lua = [[_G.set('<a  x="1"/>\n<b  z="1" a="2"><c/></b>')]] },
    { keys = ":2XML compact<CR>", note = "a range: only that line" },
    { expect = [[_G.text() == '<a  x="1"/>\n<b a="2" z="1"><c/></b>']] },
  },
}
