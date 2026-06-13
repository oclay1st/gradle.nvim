local FileUtils = require('gradle.utils.fs')
local Utils = require('gradle.utils')

---@class HelpOptionCache
---@field name string
---@field description string

local M = {}

--- Parse the help opions cache
--- @return HelpOptionCache[]
M.parse = function()
  local help_options_json = vim.fs.joinpath(Utils.gradle_cache_path, 'help_options.json')
  if FileUtils.is_file(help_options_json) then
    local data = FileUtils.read(help_options_json)
    return vim.json.decode(data)
  end
  return {}
end

--- Dump the help options
--- @param options any
M.dump = function(options)
  local options_text = vim.json.encode(options)
  local help_options_json = vim.fs.joinpath(Utils.gradle_cache_path, 'help_options.json')
  FileUtils.write(help_options_json, options_text)
end

return M
