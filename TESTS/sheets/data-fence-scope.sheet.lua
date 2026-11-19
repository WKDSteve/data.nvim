-- Fenced-block scope: without a range, a cursor inside a ```json/```yaml/```xml block of a Markdown note scopes
-- :JSON/:YAML/:XML to that block (color_my_ascii.nvim's fence API, a dependency of the suite); an explicit range wins,
-- a block of another language is no scope, and fenced_scope.enable = false turns it off (docs/integrations.md).
return {
  id = "data.fence-scope",
  feature = "data.fence-scope",
  title = "data.nvim: a cursor inside a fenced block scopes :JSON, :YAML and :XML to it",
  task = "data.nvim/performance-pruefung-luecken-schliessen-katalog-feature-shee",
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.note = function(lang, body)
        _G.set(table.concat({ "Some notes.", "", "```" .. lang, body, "```", "", "More notes." }, "\n"), "markdown")
        vim.api.nvim_win_set_cursor(0, { 4, 0 })
        return true
      end
      _G.around = function(body)
        return table.concat({ "Some notes.", "", "```json", body, "```", "", "More notes." }, "\n")
      end
      _G.note("json", '{"b":1,"a":2}')]],
    },

    {
      keys = ":JSON pretty<CR>",
      note = "the block alone is reformatted, the note around it stays",
    },
    { expect = [[_G.text() == _G.around('{\n  "a": 2,\n  "b": 1\n}')]] },

    { lua = [[_G.note("yaml", "b:   1")]] },
    { keys = ":YAML pretty<CR>", note = "the same for a yaml block" },
    {
      expect = [[_G.text() == table.concat({ "Some notes.", "", "```yaml", "b: 1", "```", "", "More notes." }, "\n")]],
    },

    { lua = [[_G.note("xml", '<r  z="1"  a="2"/>')]] },
    { keys = ":XML pretty<CR>", note = "and for an xml block" },
    { expect = [[vim.api.nvim_buf_get_lines(0, 3, 4, false)[1] == '<r a="2" z="1"/>']] },

    { lua = [[_G.note("json", '{"b":1,"a":2}')]] },
    { keys = ":4JSON compact<CR>", note = "an explicit range wins over the block" },
    { expect = [[_G.text() == _G.around('{"a":2,"b":1}')]] },

    { lua = [[_G.note("yaml", "b:   1")]] },
    {
      keys = ":JSON pretty<CR>",
      ignore_errmsg = true,
      note = "a yaml block is no scope for :JSON: the whole note is read and refused",
    },
    { wait = [[_G.noted("JSON decode failed")]] },
    {
      expect = [[_G.text() == table.concat({ "Some notes.", "", "```yaml", "b:   1", "```", "", "More notes." }, "\n")]],
    },

    {
      lua = [[require("data.config").setup({ fenced_scope = { enable = false } })
      _G.note("json", '{"b":1,"a":2}')]],
    },
    {
      keys = ":JSON pretty<CR>",
      ignore_errmsg = true,
      note = "fenced_scope.enable = false: the whole note is the scope again",
    },
    { wait = [[_G.noted("JSON decode failed")]] },
    { expect = [[_G.text() == _G.around('{"b":1,"a":2}')]] },
  },
}
