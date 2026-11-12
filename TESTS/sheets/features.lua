-- TESTS/sheets/features.lua -- the functionalities of data.nvim as its user meets them; `testing sheets report`
-- says which ones have a feature sheet (`feature = "<id>"`) and in which state, and K16 warns about a sheet that names
-- an id not listed here. Data: read with an empty environment like a sheet (testing.nvim docs/SHEETS.md).
-- The list follows docs/what-you-get.md, docs/commands.md and docs/integrations.md.
return {
  {
    id = "data.json",
    title = ":JSON pretty, compact, sort, lines, keys, ndjson and to yaml, on the buffer or a range",
    surface = { "command:JSON" },
    docs = "docs/commands.md",
  },
  {
    id = "data.yaml",
    title = ":YAML pretty, sort, lines, keys and to json, on the buffer or a range",
    surface = { "command:YAML" },
    docs = "docs/commands.md",
  },
  {
    id = "data.xml",
    title = ":XML pretty, compact, sort, lines and keys, on the buffer or a range",
    surface = { "command:XML" },
    docs = "docs/commands.md",
  },
  {
    id = "data.auto",
    title = ":Data takes the format from a fenced block, the register or the filetype, and asks when none is named",
    surface = { "command:Data" },
    docs = "docs/commands.md",
  },
  {
    id = "data.filter",
    title = "filter narrows the document through the pickers.nvim clause stack; --preview diffs before replacing",
    docs = "docs/integrations.md",
  },
  {
    id = "data.source-target",
    title = "--reg reads from a register; --inplace, --split and --out-reg say where the result goes",
    docs = "docs/commands.md",
  },
  {
    id = "data.fence-scope",
    title = "Without a range, a cursor inside a fenced block of the format scopes to that block (color_my_ascii.nvim)",
    docs = "docs/integrations.md",
  },
}
