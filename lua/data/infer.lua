---@module 'data.infer'
--- `:JSON infer` / `:YAML infer`: derive a JSON Schema (draft-07) from an example document.
---
--- Pure Lua over the decoded value, no editor state. The rules, which are the design decisions of
--- the feature:
---
--- * Scalars: `string`, `boolean`, `null`; a number with no fraction is `integer`, any other
---   `number`. `integer` and `number` seen together merge to `number`.
--- * Object: `properties` per key, `required` = the keys present in the example. Several objects
---   (the elements of one array) merge: properties are merged, `required` is the keys present in
---   EVERY object, so a field that is missing from one element is optional.
--- * Array: `items` = the merge of the element schemas (omitted for an empty array). Elements of
---   different kinds give `items = { anyOf = { ... } }`.
--- * An empty table is both an empty array and an empty object once decoded: it gets
---   `type = { "array", "object" }` and merges into whichever it meets.
--- * Different kinds in one place (a `null` next to a string, say) become `anyOf`, in the fixed
---   order null, boolean, number, string, array, object.
---
--- XML is out of scope: it has no object model (see docs/architecture.md).
---@see data.format.json

local M = {}

M.SCHEMA_URI = "http://json-schema.org/draft-07/schema#"

---@internal
---@param v any
---@return boolean
local function is_null(v)
  return v == nil or v == vim.NIL
end

---@internal
--- Contiguous integer keys from 1 (the same rule as `lib.lua.tables.path_flatten`).
---@param v table
---@return boolean
local function is_array_like(v)
  local i = 0
  for _ in pairs(v) do
    i = i + 1
    if v[i] == nil then
      return false
    end
  end
  return true
end

---@internal
local KIND_ORDER = { "null", "boolean", "number", "string", "array", "object", "empty" }

--- The kind of a value: one of KIND_ORDER.
---@param v any
---@return string
local function kind_of(v)
  if is_null(v) then
    return "null"
  end
  local t = type(v)
  if t == "boolean" or t == "string" or t == "number" then
    return t
  end
  if t == "table" then
    if next(v) == nil then
      return "empty"
    end
    return is_array_like(v) and "array" or "object"
  end
  return "string"
end

local infer

--- Merge a list of schemas of the SAME kind-group into one. `parts` are the schemas (not values).
---@param parts table[]
---@return table
local function merge_objects(parts)
  local props, seen = {}, {}
  local total = #parts
  for _, p in ipairs(parts) do
    for name, sub in pairs(p.properties or {}) do
      props[name] = props[name] or {}
      table.insert(props[name], sub)
      seen[name] = (seen[name] or 0) + 1
    end
  end
  local out_props, required = {}, {}
  for name, subs in pairs(props) do
    out_props[name] = M.merge(subs)
    if seen[name] == total then
      required[#required + 1] = name
    end
  end
  table.sort(required)
  local out = { type = "object" }
  if next(out_props) ~= nil then
    out.properties = out_props
  end
  if #required > 0 then
    out.required = required
  end
  return out
end

--- Merge schemas (of any kinds) into one: the schema every input satisfies.
---@param schemas table[]
---@return table
function M.merge(schemas)
  if #schemas == 1 then
    return schemas[1]
  end
  local groups = {}
  local function add(kind, s)
    groups[kind] = groups[kind] or {}
    table.insert(groups[kind], s)
  end
  local function classify(s)
    if s.anyOf then
      for _, sub in ipairs(s.anyOf) do
        classify(sub)
      end
      return
    end
    local t = s.type
    if type(t) == "table" then
      add("empty", s)
    elseif t == "integer" or t == "number" then
      add("number", s)
    else
      add(t or "empty", s)
    end
  end
  for _, s in ipairs(schemas) do
    classify(s)
  end

  -- An empty table merges into the array or object that is also present: as an object it has no
  -- fields, so the fields of the others become optional. Next to both, it adds nothing.
  if groups.empty and (groups.array or groups.object) then
    if groups.object and not groups.array then
      table.insert(groups.object, { type = "object" })
    elseif groups.array and not groups.object then
      table.insert(groups.array, { type = "array" })
    end
    groups.empty = nil
  end

  local out = {}
  for _, kind in ipairs(KIND_ORDER) do
    local g = groups[kind]
    if g then
      if kind == "number" then
        local integer = true
        for _, s in ipairs(g) do
          integer = integer and s.type == "integer"
        end
        out[#out + 1] = { type = integer and "integer" or "number" }
      elseif kind == "array" then
        local items = {}
        for _, s in ipairs(g) do
          if s.items then
            items[#items + 1] = s.items
          end
        end
        local arr = { type = "array" }
        if #items > 0 then
          arr.items = M.merge(items)
        end
        out[#out + 1] = arr
      elseif kind == "object" then
        out[#out + 1] = merge_objects(g)
      elseif kind == "empty" then
        out[#out + 1] = { type = { "array", "object" } }
      else
        out[#out + 1] = { type = kind }
      end
    end
  end
  if #out == 1 then
    return out[1]
  end
  return { anyOf = out }
end

---@param value any
---@return table
infer = function(value)
  local kind = kind_of(value)
  if kind == "number" then
    return { type = (value == math.floor(value) and value == value) and "integer" or "number" }
  elseif kind == "empty" then
    return { type = { "array", "object" } }
  elseif kind == "array" then
    local items = {}
    for i = 1, #value do
      items[i] = infer(value[i])
    end
    return { type = "array", items = M.merge(items) }
  elseif kind == "object" then
    local props, required = {}, {}
    for k, v in pairs(value) do
      local name = tostring(k)
      props[name] = infer(v)
      required[#required + 1] = name
    end
    table.sort(required)
    return { type = "object", properties = props, required = required }
  end
  return { type = kind }
end

--- The draft-07 schema of an example document.
---@param value any # a decoded JSON/YAML value
---@return table schema
function M.schema(value)
  local s = vim.deepcopy(infer(value))
  local out = { ["$schema"] = M.SCHEMA_URI }
  for k, v in pairs(s) do
    out[k] = v
  end
  return out
end

return M
