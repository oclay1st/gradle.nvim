local Path = require('plenary.path')
local Utils = require('gradle.utils')
local Project = require('gradle.sources.project')

local M = {}

---@class FavoriteCache
---@field name string
---@field type string
---@field description string
---@field cmd_args string

---Parse the favorite commands cache
---@param key string
---@return Project.Favorite[]
M.parse = function(key)
  local favorite_commands_json =
    Path:new(Utils.gradle_cache_path, 'favorite_commands', key .. '.json')
  local favorite_commands = {}
  if favorite_commands_json:exists() then
    local data = favorite_commands_json:read()
    local cache = vim.json.decode(data)
    for _, item in ipairs(cache) do
      table.insert(
        favorite_commands,
        Project.Favorite(item.name, item.type, item.description, item.cmd_args)
      )
    end
  end
  return favorite_commands
end

---Dump the favorites commands to a file
---@param key string
---@param favorite_commands Project.Favorite[]
M.dump = function(key, favorite_commands)
  local favorite_commands_cache_path = Path:new(Utils.gradle_cache_path, 'favorite_commands')
  if not favorite_commands_cache_path:exists() then
    favorite_commands_cache_path:mkdir()
  end
  ---@type FavoriteCache[]
  local favorite_commands_cache = {}
  for _, command in pairs(favorite_commands) do
    table.insert(favorite_commands_cache, {
      name = command.name,
      type = command.type,
      description = command.description,
      cmd_args = command.cmd_args,
    })
  end
  local data = vim.json.encode(favorite_commands_cache)
  --- @type Path
  local cache_json = favorite_commands_cache_path:joinpath(key .. '.json')
  cache_json:write(data, 'w')
end

return M
