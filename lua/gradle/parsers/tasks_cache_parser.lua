local FileUtils = require('gradle.utils.fs')
local Utils = require('gradle.utils')
local Project = require('gradle.sources.project')

local M = {}

---@class TaskCache
---@field name string
---@field description string
---@field group string

--- Parse the tasks cache
M.parse = function(key)
  local tasks_json = vim.fs.joinpath(Utils.gradle_cache_path, 'tasks', key .. '.json')
  if FileUtils.is_file(tasks_json) then
    local data = FileUtils.read(tasks_json)
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
  local tasks_cache_path = vim.fs.joinpath(Utils.gradle_cache_path, 'tasks')
  FileUtils.mkdir(tasks_cache_path)
  ---@type TaskCache[]
  local tasks_cache = {}
  for _, task in ipairs(tasks) do
    table.insert(
      tasks_cache,
      { name = task.name, description = task.description, group = task.group }
    )
  end
  local data = vim.json.encode(tasks_cache)
  local cache_json = vim.fs.joinpath(tasks_cache_path, key .. '.json')
  FileUtils.write(cache_json, data)
end

return M
