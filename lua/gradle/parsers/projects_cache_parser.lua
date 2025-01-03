local Path = require('plenary.path')
local Utils = require('gradle.utils')

---@class ProjectCache
---@field path string
---@field key string

local M = {}

---Parse the projects cache file
---@return ProjectCache[]
M.parse = function()
  local projects_json = Path:new(Utils.gradle_cache_path, 'projects.json')
  if projects_json:exists() then
    local data = projects_json:read()
    if data and data ~= '' then
      local projects_cache = vim.json.decode(data)
      return projects_cache
    end
  end
  return {}
end

M.register = function(path)
  --- @type Path
  local cache_path = Path:new(Utils.gradle_cache_path)
  if not cache_path:exists() then
    cache_path:mkdir()
  end
  local data = {}
  --- @type Path
  local projects_json = cache_path:joinpath('projects.json')
  if projects_json:exists() then
    --- @type string
    local text_data = projects_json:read()
    data = vim.json.decode(text_data)
  end
  local key = nil
  for _, item in ipairs(data) do
    if item.path == path then
      return item.key
    end
  end
  key = Utils.uuid()
  table.insert(data, { path = path, key = key })
  local text_data = vim.json.encode(data)
  projects_json:write(text_data, 'w')
  return key
end

return M
