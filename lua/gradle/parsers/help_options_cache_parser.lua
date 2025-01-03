local Path = require('plenary.path')
local Utils = require('gradle.utils')

---@class HelpOptionCache
---@field name string
---@field description string

local M = {}

--- Parse the help opions cache
--- @return HelpOptionCache[]
M.parse = function()
  --- @type Path
  local help_options_json = Path:new(Utils.gradle_cache_path, 'help_options.json')
  if help_options_json:exists() then
    local data = help_options_json:read()
    return vim.json.decode(data)
  end
  return {}
end

--- Dump the help options
--- @param options any
M.dump = function(options)
  local options_text = vim.json.encode(options)
  local help_options_json = Path:new(Utils.gradle_cache_path, 'help_options.json')
  help_options_json:write(options_text, 'w')
end

return M
