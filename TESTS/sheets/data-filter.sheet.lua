-- Bindings checklist: :JSON, :YAML, :XML and :Data filter over the real pickers.refine clause stack, --sep, --tree, and
-- --preview with the real diff of diff.nvim. The child editor answers Neovim's native prompts (`inputlist`, `input`) with
-- "cancelled" by design, so vim.ui.select and vim.ui.input are answered from a script (`_G.answer`) that fails on a
-- choice the prompt does not offer. How the prompts look stays with whoever opens them.
return {
  id = "data.filter",
  title = "data.nvim: :JSON, :YAML, :XML and :Data filter, --sep, --tree and --preview",
  task = "data.nvim/testblatt-bindings-checkliste",
  requires = {
    { lua = [[pcall(require, "pickers.refine")]], reason = "filter needs pickers.nvim" },
    { lua = [[pcall(require, "diff")]], reason = "--preview needs diff.nvim" },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      _G.DOC = '{"a":{"x":"keep","y":"drop"},"b":1}'
      _G.script = {}
      -- The answers of the next filter, in order: the label of a choice, a term, false to dismiss a prompt.
      _G.answer = function(...)
        _G.script = { ... }
        _G.problem = nil
      end
      vim.ui.select = function(items, opts, cb)
        if opts.prompt:find("replace", 1, true) then
          _G.windows_at_question = #vim.api.nvim_tabpage_list_wins(0)
        end
        local want = table.remove(_G.script, 1)
        if not want then
          return cb(nil, nil)
        end
        for i, item in ipairs(items) do
          if (opts.format_item or tostring)(item):find(want, 1, true) then
            return cb(item, i)
          end
        end
        _G.problem = "no choice " .. tostring(want)
        cb(nil, nil)
      end
      vim.ui.input = function(_, cb)
        cb(table.remove(_G.script, 1))
      end
      _G.set(_G.DOC, "json")]],
    },

    {
      lua = [[_G.answer("path contains", "a.x", false)]],
      note = "path contains a.x, then stop adding clauses",
    },
    { keys = ":JSON filter<CR>" },
    { expect = [[_G.text() == "a.x: keep" and not _G.problem]] },

    { lua = [[_G.set(_G.DOC); _G.answer("path excludes", "a.x", false)]] },
    { keys = ":JSON filter<CR>" },
    { expect = [[_G.text() == "a.y: drop\nb: 1" and not _G.problem]] },

    {
      lua = [[_G.set(_G.DOC); _G.answer("line contains", "keep", false)]],
      note = "a clause can match a value",
    },
    { keys = ":JSON filter<CR>" },
    { expect = [[_G.text() == "a.x: keep" and not _G.problem]] },

    {
      lua = [[_G.set(_G.DOC); _G.answer("path contains", "a", "path excludes", "/y$/", false)]],
      note = "two clauses, the second one a pattern",
    },
    { keys = ":JSON filter<CR>" },
    { expect = [[_G.text() == "a.x: keep" and not _G.problem]] },

    { lua = [[_G.set(_G.DOC); _G.answer("path contains", "a/x", false)]] },
    { keys = ":JSON filter --sep=/<CR>", note = "--sep on the paths" },
    { expect = [[_G.text() == "a/x: keep" and not _G.problem]] },

    { lua = [[_G.set(_G.DOC); _G.answer("path contains", "a.x", false)]] },
    { keys = ":JSON filter --tree<CR>", note = "--tree: the survivors as a document" },
    { expect = [[vim.deep_equal(vim.json.decode(_G.text()), { a = { x = "keep" } })]] },

    { lua = [[_G.set(_G.DOC); _G.answer(false)]] },
    { keys = ":JSON filter<CR>", note = "dismissed before any clause: untouched" },
    { expect = "_G.text() == _G.DOC" },

    { lua = [[_G.answer("path contains", "nothing", false)]] },
    { keys = ":JSON filter<CR>", note = "nothing matches: a warning, untouched" },
    { wait = [[#_G.notes > 0]] },
    { expect = "_G.text() == _G.DOC" },

    { lua = [[_G.set("a:\n  x: keep\nb: 1"); _G.answer("path contains", "a.x", false)]] },
    { keys = ":YAML filter<CR>" },
    { expect = [[_G.text() == "a.x: keep" and not _G.problem]] },

    { lua = [[_G.set('<r a="keep" b="drop"/>'); _G.answer("path contains", "attrs.a", false)]] },
    { keys = ":XML filter<CR>" },
    { expect = [[_G.text() == "attrs.a: keep" and not _G.problem]] },

    { lua = [[_G.set("b: 1\nc: 2", "yaml"); _G.answer("path contains", "c", false)]] },
    { keys = ":Data filter<CR>", note = "the filetype names the format" },
    { expect = [[_G.text() == "c: 2" and not _G.problem]] },

    { lua = [[_G.set(_G.DOC); _G.answer("path contains", "a.x", false, "Discard")]] },
    { keys = ":JSON filter --preview<CR>", note = "the preview, then Discard" },
    { expect = "_G.windows_at_question > 1", note = "the diff was open when the question came" },
    { wait = [[#vim.api.nvim_tabpage_list_wins(0) == 1]], note = "the diff is gone" },
    { expect = "_G.text() == _G.DOC and not _G.problem", note = "Discard writes nothing" },

    { lua = [[_G.answer("path contains", "a.x", false, "Apply")]] },
    { keys = ":JSON filter --preview<CR>", note = "the preview, then Apply" },
    { expect = [[_G.text() == "a.x: keep" and not _G.problem]] },
    { wait = "#vim.api.nvim_tabpage_list_wins(0) == 1" },
  },
}
