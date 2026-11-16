-- Live check (task ALL/live-check-nachtrag-casedesk-nein-ja-data-vorschau-fokus-ui, point 2): the question over the diff
-- preview of `--preview` is the shared dialog of lib.nvim (a float, `keep_on_focus_lost`). Moving the focus into the
-- preview and back must not count as a discard; Esc in the dialog does discard and closes the preview. The filter's own
-- prompts (vim.ui.select, vim.ui.input) are answered from a script, the dialog is the real one (reloaded: the specs'
-- minimal_init.lua swaps its `choose` for vim.ui.select).
return {
  id = "data.preview-focus",
  feature = "data.filter",
  title = "data.nvim: the question over the diff preview survives a focus change, Esc discards",
  task = "ALL/live-check-nachtrag-casedesk-nein-ja-data-vorschau-fokus-ui",
  requires = {
    { lua = [[pcall(require, "pickers.refine")]], reason = "filter needs pickers.nvim" },
    { lua = [[pcall(require, "diff")]], reason = "--preview needs diff.nvim" },
    {
      lua = [[require("lib.nvim.ui.dialog").backend("confirm") ~= "native"]],
      reason = "the float of the kit is what is checked",
    },
  },
  steps = {
    {
      lua = [[dofile(vim.fn.getcwd() .. "/TESTS/sheets/_helpers.lua")
      -- TESTS/minimal_init.lua replaces dialog.choose with vim.ui.select for the specs: this sheet needs the real one
      package.loaded["lib.nvim.ui.dialog"] = nil
      require("lib.nvim.ui.dialog")
      _G.DOC = '{"a":{"x":"keep","y":"drop"},"b":1}'
      _G.script = {}
      _G.answer = function(...)
        _G.script = { ... }
        _G.problem = nil
      end
      vim.ui.select = function(items, opts, cb)
        local want = table.remove(_G.script, 1)
        if not want then
          return cb(nil, nil)
        end
        for i, item in ipairs(items) do
          if (opts.format_item or tostring)(item):find(want, 1, true) then
            return cb(item, i)
          end
        end
        _G.problem = "no choice " .. tostring(want) .. " in " .. tostring(opts.prompt)
        cb(nil, nil)
      end
      vim.ui.input = function(_, cb)
        cb(table.remove(_G.script, 1))
      end
      -- the floating window of the dialog, or nil
      _G.dialog_win = function()
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_get_config(w).relative ~= "" and vim.api.nvim_win_get_config(w).focusable ~= false then
            return w
          end
        end
      end
      -- a window of the preview (not floating, not the one that holds the document)
      _G.preview_win = function()
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_get_config(w).relative == "" and vim.api.nvim_win_get_buf(w) ~= _G.doc_buf then
            return w
          end
        end
      end
      _G.set(_G.DOC, "json")
      _G.doc_buf = vim.api.nvim_get_current_buf()]],
    },

    {
      lua = [[_G.answer("path contains", "a.x", false)]],
      note = "path contains a.x, then the preview",
    },
    { keys = ":JSON filter --preview<CR>" },
    {
      wait = "_G.dialog_win() ~= nil and _G.preview_win() ~= nil",
      note = "the dialog floats over the preview",
    },
    { expect = "not _G.problem" },
    { settle = 500 },
    { screen = "question" },

    {
      lua = [[vim.api.nvim_set_current_win(_G.preview_win())]],
      note = "the focus moves into the preview",
    },
    { settle = 500 },
    {
      expect = "_G.dialog_win() ~= nil and _G.preview_win() ~= nil",
      note = "a focus change is no discard: dialog and preview stay",
    },
    { lua = [[vim.api.nvim_set_current_win(_G.dialog_win())]], note = "back into the dialog" },
    { settle = 300 },
    { keys = "<Esc>", note = "Esc in the dialog" },
    {
      wait = "_G.dialog_win() == nil and #vim.api.nvim_tabpage_list_wins(0) == 1",
      note = "dialog and preview are gone",
    },
    {
      expect = "vim.api.nvim_buf_get_lines(_G.doc_buf, 0, -1, false)[1] == _G.DOC",
      note = "Esc discards: the document is unchanged",
    },
  },
  judge = {
    "The dialog sits readable over the diff, Discard is the focused button",
  },
}
