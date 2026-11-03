---@module 'data.filter.tree'
--- The tree half of `filter --tree`: from a decoded document and the set of flattened leaves a
--- filter kept, rebuild a document that holds only those leaves.
---
--- The leaves are numbered in exactly the order `lib.lua.tables.path_flatten` visits them (objects
--- by sorted key, arrays 1..n, scalars and empty tables as leaves), so leaf `i` here is item `i`
--- of the flattened list the filter works on. Nothing is guessed back from path strings: the
--- Array/Map type of every node is the one of the original document.
---@see data.filter

local M = {}

---@internal
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

--- Keep only the leaves whose number is in `keep`.
--- Arrays that lose elements are compacted (order kept); containers left empty are dropped.
---@param value any
---@param keep table<integer, true>
---@return any|nil pruned # nil when no leaf survived
function M.prune(value, keep)
  local n = 0
  local function walk(v)
    if type(v) ~= "table" or next(v) == nil then
      n = n + 1
      if keep[n] then
        return v, true
      end
      return nil, false
    end
    if is_array_like(v) then
      local out = {}
      for i = 1, #v do
        local child, ok = walk(v[i])
        if ok then
          out[#out + 1] = child
        end
      end
      if #out == 0 then
        return nil, false
      end
      return out, true
    end
    local keys = {}
    for k in pairs(v) do
      keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b)
      return tostring(a) < tostring(b)
    end)
    local out, any = {}, false
    for _, k in ipairs(keys) do
      local child, ok = walk(v[k])
      if ok then
        out[k] = child
        any = true
      end
    end
    if not any then
      return nil, false
    end
    return out, true
  end
  local result, ok = walk(value)
  if not ok then
    return nil
  end
  return result
end

return M
