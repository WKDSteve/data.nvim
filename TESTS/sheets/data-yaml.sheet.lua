-- Bindings checklist, section :YAML: every action but filter (data-filter.sheet.lua), typed on a real buffer.
return {
  id = "data.yaml",
  title = "data.nvim: :YAML, pretty, sort, lines, keys and to, in place and on a range",
  task = "data.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.DOC = "b: 1\na:\n    z:\n        - 1\n        - 2\n    x: s"
      _G.PRETTY = "a:\n  x: s\n  z:\n    - 1\n    - 2\nb: 1"
      _G.set(_G.DOC, "yaml")]],
    },

    { keys = ":YAML<CR>", note = "no action: pretty over the whole buffer" },
    { expect = "_G.text() == _G.PRETTY" },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":YAML pretty<CR>", note = "two spaces by default, the verb names the format" },
    { expect = "_G.text() == _G.PRETTY" },

    { keys = ":YAML pretty 4<CR>", note = "an explicit indent" },
    { expect = [[vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == "    x: s"]] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":YAML sort<CR>", note = "the docs say: the same as pretty today" },
    { expect = "_G.text() == _G.PRETTY" },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":YAML lines<CR>", note = "one path: value per leaf, dotted" },
    { expect = [[_G.text() == "a.x: s\na.z.1: 1\na.z.2: 2\nb: 1"]] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":YAML lines --sep=/<CR>", note = "--sep overrides the dot" },
    { expect = [[_G.text() == "a/x: s\na/z/1: 1\na/z/2: 2\nb: 1"]] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":YAML keys<CR>", note = "the paths without values" },
    { expect = [[_G.text() == "a.x\na.z.1\na.z.2\nb"]] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":YAML to json<CR>", note = "converted in place" },
    { expect = [[vim.json.decode(_G.text()).a.z[2] == 2 and vim.api.nvim_buf_line_count(0) > 1]] },

    { lua = [[_G.set("a:   1\nb:   2")]] },
    { keys = ":2YAML pretty<CR>", note = "a range: only that line" },
    { expect = [[_G.text() == "a:   1\nb: 2"]] },
  },
}
