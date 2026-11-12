-- Bindings checklist, section :JSON: every action but filter (data-filter.sheet.lua), typed on a real buffer.
return {
  id = "data.json",
  feature = "data.json",
  title = "data.nvim: :JSON, pretty, compact, sort, lines, keys, ndjson and to, in place and on a range",
  task = "data.nvim/testblatt-bindings-checkliste",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.DOC = '{"b":1,"a":{"y":[1,2],"x":"s"}}'
      _G.PRETTY = table.concat({
        "{", '  "a": {', '    "x": "s",', '    "y": [', "      1,", "      2", "    ]", "  },", '  "b": 1', "}",
      }, "\n")
      _G.set(_G.DOC, "json")]],
    },

    { keys = ":JSON<CR>", note = "no action: pretty over the whole buffer" },
    { expect = "_G.text() == _G.PRETTY" },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":JSON pretty<CR>", note = "two spaces by default, the verb names the format" },
    { expect = "_G.text() == _G.PRETTY" },

    { keys = ":JSON compact<CR>", note = "back onto one line" },
    { expect = [[_G.text() == '{"a":{"x":"s","y":[1,2]},"b":1}']] },

    { keys = ":JSON pretty 4<CR>", note = "an explicit indent" },
    { expect = [[vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] == '    "a": {']] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":JSON sort<CR>", note = "the docs say: the same as pretty today" },
    { expect = "_G.text() == _G.PRETTY" },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":JSON lines<CR>", note = "one path: value per leaf, dotted" },
    { expect = [[_G.text() == "a.x: s\na.y.1: 1\na.y.2: 2\nb: 1"]] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":JSON lines --sep=/<CR>", note = "--sep overrides the dot" },
    { expect = [[_G.text() == "a/x: s\na/y/1: 1\na/y/2: 2\nb: 1"]] },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":JSON keys<CR>", note = "the paths without values" },
    { expect = [[_G.text() == "a.x\na.y.1\na.y.2\nb"]] },

    { lua = [[_G.set('{"a":1}\nnot json\n{"b":2}')]] },
    { keys = ":JSON ndjson<CR>", note = "each line its own document, a malformed line stays" },
    { expect = [[_G.text() == '{\n  "a": 1\n}\nnot json\n{\n  "b": 2\n}']] },
    {
      wait = [[_G.noted("1 line(s) could not be decoded")]],
      note = "the skipped line is reported",
    },

    { lua = "_G.set(_G.DOC)" },
    { keys = ":JSON to yaml<CR>", note = "converted in place" },
    { expect = [[_G.text() == "a:\n  x: s\n  y:\n    - 1\n    - 2\nb: 1"]] },

    { lua = [[_G.set('{"a":1}\n{"b":2}')]] },
    { keys = ":2JSON pretty<CR>", note = "a range: only that line" },
    { expect = [[_G.text() == '{"a":1}\n{\n  "b": 2\n}']] },

    { lua = [[_G.set('{"a":')]] },
    {
      keys = ":JSON pretty<CR>",
      ignore_errmsg = true,
      note = "malformed input is reported and left alone",
    },
    { wait = [[_G.noted("JSON decode failed")]] },
    { expect = [[_G.text() == '{"a":']] },
  },
}
