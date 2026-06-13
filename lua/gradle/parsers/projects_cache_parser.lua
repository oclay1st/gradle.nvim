local FileUtils = require('gradle.utils.fs')
local Utils = require('gradle.utils')

---@class ProjectCache
---@field path string
---@field key string

local M = {}

---Parse the projects cache file
---@return ProjectCache[]
M.parse = function()
  local projects_json = vim.fs.joinpath(Utils.gradle_cache_path, 'projects.json')
  if FileUtils.is_file(projects_json) then
    local data = FileUtils.read(projects_json)
    if data and data ~= '' then
      local projects_cache = vim.json.decode(data)
      return projects_cache
    end
  end
  return {}
end

M.register = function(path)
  local cache_path = vim.fs.joinpath(Utils.gradle_cache_path)
  FileUtils.mkdir(cache_path)
  local data = {}
  local projects_json = vim.fs.joinpath(cache_path, 'projects.json')
  if FileUtils.is_file(projects_json) then
    local text_data = FileUtils.read(projects_json)
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
  FileUtils.write(projects_json, text_data)
  return key
end

return M
