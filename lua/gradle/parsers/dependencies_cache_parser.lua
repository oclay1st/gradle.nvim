local Path = require('plenary.path')
local Utils = require('gradle.utils')
local Project = require('gradle.sources.project')

local M = {}

---@class DependencyCache
---@field id string
---@field parent_id string | nil
---@field configuration string
---@field type string {module, project}
---@field name string
---@field group? string
---@field version? string
---@field is_duplicate? boolean
---@field conflict_version? string

--- Parse the dependencies cache
M.parse = function(key)
  local dependencies_json = Path:new(Utils.gradle_cache_path, 'dependencies', key .. '.json')
  if dependencies_json:exists() then
    local data = dependencies_json:read()
    local dependencies_cache = vim.json.decode(data) ---@type DependencyCache[]
    local dependencies = {}
    for _, item in ipairs(dependencies_cache) do
      table.insert(
        dependencies,
        Project.Dependency(
          item.id,
          item.parent_id,
          item.configuration,
          item.type,
          item.name,
          item.group,
          item.version,
          item.is_duplicate,
          item.conflict_version
        )
      )
    end
    return dependencies
  end
  return {}
end

--- Dump the dependencies cache to file
--- @param  key string
--- @param dependencies Project.Dependency[]
M.dump = function(key, dependencies)
  local dependencies_cache_path = Path:new(Utils.gradle_cache_path, 'dependencies')
  if not dependencies_cache_path:exists() then
    dependencies_cache_path:mkdir()
  end
  ---@type DependencyCache[]
  local dependencies_cache = {}
  for _, dependency in ipairs(dependencies) do
    table.insert(dependencies_cache, {
      id = dependency.id,
      parent_id = dependency.parent_id,
      configuration = dependency.configuration,
      type = dependency.type,
      name = dependency.name,
      group = dependency.group,
      version = dependency.version,
      is_duplicate = dependency.is_duplicate,
      conflict_version = dependency.conflict_version,
    })
  end
  local data = vim.json.encode(dependencies_cache)
  --- @type Path
  local cache_json = dependencies_cache_path:joinpath(key .. '.json')
  cache_json:write(data, 'w')
end

return M
