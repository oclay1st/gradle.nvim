local Path = require('plenary.path')
local Utils = require('gradle.utils')
local Project = require('gradle.sources.project')

local M = {}

---@class TaskCache
---@field name string
---@field description string
---@field group string

--- Parse the tasks cache
M.parse = function(key)
  local tasks_json = Path:new(Utils.gradle_cache_path, 'tasks', key .. '.json')
  if tasks_json:exists() then
    local data = tasks_json:read()
    local tasks_cache = vim.json.decode(data)
    local tasks = {}
    for _, item in ipairs(tasks_cache) do
      table.insert(tasks, Project.Task(item.name, item.description, item.group))
    end
    return tasks
  end
  return {}
end

--- Dump the tasks cache to file
--- @param  key string
--- @param tasks Project.Task[]
M.dump = function(key, tasks)
  local tasks_cache_path = Path:new(Utils.gradle_cache_path, 'tasks')
  if not tasks_cache_path:exists() then
    tasks_cache_path:mkdir()
  end
  ---@type TaskCache[]
  local tasks_cache = {}
  for _, task in ipairs(tasks) do
    table.insert(
      tasks_cache,
      { name = task.name, description = task.description, group = task.group }
    )
  end
  local data = vim.json.encode(tasks_cache)
  --- @type Path
  local cache_json = tasks_cache_path:joinpath(key .. '.json')
  cache_json:write(data, 'w')
end

return M
