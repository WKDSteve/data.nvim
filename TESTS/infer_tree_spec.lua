---@diagnostic disable: need-check-nil
-- TESTS/infer_tree_spec.lua — `:JSON infer` (data.infer, data.infer through data.infer()) and
-- `filter --tree` (data.filter.tree, data.filter in tree mode, data.filter through data.filter()).

local infer = require("data.infer")
local tree = require("data.filter.tree")

describe("data.infer.schema", function()
  it("types the scalars, integers apart from other numbers", function()
    assert.same(
      { type = "string" },
      infer.schema("x")["type"] and { type = infer.schema("x").type }
    )
    assert.equals("integer", infer.schema(3).type)
    assert.equals("number", infer.schema(3.5).type)
    assert.equals("boolean", infer.schema(true).type)
    assert.equals("null", infer.schema(vim.NIL).type)
    assert.equals(infer.SCHEMA_URI, infer.schema(1)["$schema"])
  end)

  it("describes an object: properties and the keys it has as required", function()
    local s = infer.schema({ name = "a", age = 3 })
    assert.equals("object", s.type)
    assert.equals("string", s.properties.name.type)
    assert.equals("integer", s.properties.age.type)
    assert.same({ "age", "name" }, s.required)
  end)

  it("describes an array by the merge of its elements", function()
    local s = infer.schema({ 1, 2, 3 })
    assert.equals("array", s.type)
    assert.equals("integer", s.items.type)
    assert.is_nil(infer.schema({}).items)
  end)

  it("integer and number together are number", function()
    assert.equals("number", infer.schema({ 1, 2.5 }).items.type)
  end)

  it("a field missing from one element of an array is optional", function()
    local s = infer.schema({ { id = 1, tag = "a" }, { id = 2 } })
    local item = s.items
    assert.equals("object", item.type)
    assert.same({ "id" }, item.required)
    assert.equals("string", item.properties.tag.type)
  end)

  it("different kinds in one place become anyOf in a fixed order, null first", function()
    local s = infer.schema({ "a", vim.NIL, 1 })
    assert.same({ { type = "null" }, { type = "integer" }, { type = "string" } }, s.items.anyOf)
  end)

  it("nested arrays and objects merge recursively", function()
    local s = infer.schema({ { xs = { 1 } }, { xs = { "a" } } })
    assert.equals("array", s.items.properties.xs.type)
    assert.equals(2, #s.items.properties.xs.items.anyOf)
  end)

  it("an empty table is either, and merges into the one that is present", function()
    assert.same({ "array", "object" }, infer.schema({}).type)
    local s = infer.schema({ { a = 1 }, {} })
    assert.equals("object", s.items.type)
    assert.is_nil(s.items.required)
  end)
end)

describe("data.filter.tree.prune", function()
  -- leaves in path_flatten order: a.1, a.2, b.c, b.d, e
  local doc = { a = { 10, 20 }, b = { c = "x", d = "y" }, e = true }

  it("keeps the Array/Map type of the original nodes", function()
    local out = tree.prune(doc, { [2] = true, [3] = true })
    assert.same({ a = { 20 }, b = { c = "x" } }, out)
  end)

  it("compacts an array that lost elements and keeps their order", function()
    assert.same({ a = { 10, 20 } }, tree.prune(doc, { [1] = true, [2] = true }))
    assert.same({ a = { 20 } }, tree.prune(doc, { [2] = true }))
  end)

  it("a map with numeric-looking keys stays a map", function()
    local m = { ["1"] = "a", ["2"] = "b" }
    assert.same({ ["2"] = "b" }, tree.prune(m, { [2] = true }))
  end)

  it("drops containers left empty and returns nil when nothing survived", function()
    assert.same({ e = true }, tree.prune(doc, { [5] = true }))
    assert.is_nil(tree.prune(doc, {}))
  end)

  it("treats an empty table as a leaf", function()
    local d = { a = {}, b = 1 }
    assert.same({ a = {} }, tree.prune(d, { [1] = true }))
  end)

  it("a scalar root is one leaf", function()
    assert.equals(5, tree.prune(5, { [1] = true }))
  end)

  it("numbers the leaves like lib.lua.tables.path_flatten", function()
    local items = require("lib.lua.tables").path_flatten(doc)
    for i, it in ipairs(items) do
      local out = tree.prune(doc, { [i] = true })
      local flat = require("lib.lua.tables").path_flatten(out)
      assert.equals(1, #flat)
      assert.equals(it.value, flat[1].value)
    end
  end)
end)

--- A pickers.refine double: `apply` keeps the items whose `path` is in `paths`.
---@param paths table<string, true>
local function fake_refine(paths)
  package.loaded["pickers.refine"] = nil
  package.preload["pickers.refine"] = function()
    return {
      new = function()
        local h = {}
        function h:prompt(_, on_done)
          on_done()
        end
        function h:is_active()
          return true
        end
        function h:apply(items)
          local out = {}
          for _, it in ipairs(items) do
            if paths[it.path] then
              out[#out + 1] = it
            end
          end
          return out
        end
        return h
      end,
    }
  end
end

local function unfake()
  package.preload["pickers.refine"] = nil
  package.loaded["pickers.refine"] = nil
end

describe("data.filter.run in tree mode", function()
  after_each(unfake)

  it("returns a pretty document of the kept leaves", function()
    fake_refine({ ["a.2"] = true, ["b.c"] = true })
    local json = require("data.format.json")
    local got
    require("data.filter").run(
      json,
      { a = { 10, 20 }, b = { c = "x", d = "y" } },
      { indent = 2 },
      function(out)
        got = out
      end,
      { tree = true }
    )
    assert.same({ a = { 20 }, b = { c = "x" } }, json.decode(table.concat(got, "\n")))
  end)

  it("nothing kept gives an empty list", function()
    fake_refine({})
    local json = require("data.format.json")
    local got
    require("data.filter").run(json, { a = 1 }, {}, function(out)
      got = out
    end, { tree = true })
    assert.same({}, got)
  end)

  it("without tree it still hands back path: value lines", function()
    fake_refine({ ["a"] = true })
    local json = require("data.format.json")
    local got
    require("data.filter").run(json, { a = 1, b = 2 }, {}, function(out)
      got = out
    end)
    assert.same({ "a: 1" }, got)
  end)
end)

describe("data.infer / data.filter through the editor", function()
  local function buf_with(lines, ft)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = ft
    vim.api.nvim_set_current_buf(buf)
    return buf
  end

  after_each(function()
    unfake()
    vim.cmd("silent! %bwipeout!")
  end)

  it("infer puts the schema in a scratch split and leaves the source alone", function()
    local src = buf_with({ '{"a": 1, "b": [true]}' }, "json")
    require("data").infer("json", { line1 = 1, line2 = 1, range = 0 }, {}, {})
    assert.not_equals(src, vim.api.nvim_get_current_buf())
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    local schema = require("data.format.json").decode(text)
    assert.equals(infer.SCHEMA_URI, schema["$schema"])
    assert.equals("integer", schema.properties.a.type)
    assert.equals("boolean", schema.properties.b.items.type)
    assert.equals("json", vim.bo.filetype)
    assert.same({ '{"a": 1, "b": [true]}' }, vim.api.nvim_buf_get_lines(src, 0, -1, false))
  end)

  it("infer works on YAML input and refuses --inplace and XML", function()
    buf_with({ "a: 1", "b: x" }, "yaml")
    require("data").infer("yaml", { line1 = 1, line2 = 2, range = 0 }, {}, {})
    local schema = require("data.format.json").decode(
      table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    )
    assert.equals("string", schema.properties.b.type)

    local msgs = {}
    local orig = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(m)
      msgs[#msgs + 1] = tostring(m)
    end
    local src = buf_with({ '{"a":1}' }, "json")
    require("data").infer("json", { line1 = 1, line2 = 1, range = 0 }, {}, { inplace = true })
    require("data").infer("xml", { line1 = 1, line2 = 1, range = 0 }, {}, {})
    vim.wait(30)
    vim.notify = orig
    assert.equals(src, vim.api.nvim_get_current_buf())
    assert.matches("never replaces", table.concat(msgs, "\n"))
    assert.matches("XML", table.concat(msgs, "\n"))
  end)

  it("filter --tree writes the kept leaves as a document", function()
    fake_refine({ ["a.2"] = true })
    local src = buf_with({ '{"a": [10, 20], "b": 1}' }, "json")
    require("data").filter(
      "json",
      { line1 = 1, line2 = 1, range = 0 },
      { tree = true },
      { split = true }
    )
    assert.not_equals(src, vim.api.nvim_get_current_buf())
    local got = require("data.format.json").decode(
      table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
    )
    assert.same({ a = { 20 } }, got)
    assert.equals("json", vim.bo.filetype)
  end)

  it("filter --tree is refused for XML", function()
    local msgs = {}
    local orig = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(m)
      msgs[#msgs + 1] = tostring(m)
    end
    buf_with({ "<a/>" }, "xml")
    require("data").filter("xml", { line1 = 1, line2 = 1, range = 0 }, { tree = true }, {})
    vim.wait(30)
    vim.notify = orig
    assert.matches("not available for XML", table.concat(msgs, "\n"))
  end)
end)
