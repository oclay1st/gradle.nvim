local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local Project = require('gradle.sources.project')
local Utils = require('gradle.utils')
local TasksCacheParser = require('gradle.parsers.tasks_cache_parser')

local env = {}
local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      env.temp_dir = vim.fn.tempname() .. '_test_cache'
      env.original_cache_path = Utils.gradle_cache_path
      Utils.gradle_cache_path = env.temp_dir
      vim.fn.mkdir(env.temp_dir, 'p')
    end,
    post_once = function()
      Utils.gradle_cache_path = env.original_cache_path
      vim.fn.delete(env.temp_dir, 'rf')
    end,
  },
})

T['should return empty table when no cache file exists'] = function()
  local tasks = TasksCacheParser.parse('nonexistent')
  eq(0, #tasks)
end

T['should dump and parse tasks correctly'] = function()
  local key = 'test-tasks'
  local tasks = {
    Project.Task('build', 'Assembles the project.', 'build'),
    Project.Task('clean', 'Deletes build directory.', 'build'),
    Project.Task('test', nil, 'verification'),
  }
  TasksCacheParser.dump(key, tasks)
  local loaded = TasksCacheParser.parse(key)
  eq(3, #loaded)
  eq('build', loaded[1].name)
  eq('Assembles the project.', loaded[1].description)
  eq('build', loaded[1].group)
  eq('clean', loaded[2].name)
  eq('Deletes build directory.', loaded[2].description)
  eq('test', loaded[3].name)
  eq(nil, loaded[3].description)
  eq('verification', loaded[3].group)
end

T['should dump and parse empty task list'] = function()
  local key = 'empty-tasks'
  TasksCacheParser.dump(key, {})
  local loaded = TasksCacheParser.parse(key)
  eq(0, #loaded)
end

T['should handle multiple cache keys independently'] = function()
  local tasks_a = { Project.Task('task-a', 'Description A', 'group-a') }
  local tasks_b = { Project.Task('task-b', 'Description B', 'group-b') }
  TasksCacheParser.dump('key-a', tasks_a)
  TasksCacheParser.dump('key-b', tasks_b)
  local loaded_a = TasksCacheParser.parse('key-a')
  local loaded_b = TasksCacheParser.parse('key-b')
  eq(1, #loaded_a)
  eq('task-a', loaded_a[1].name)
  eq(1, #loaded_b)
  eq('task-b', loaded_b[1].name)
end

return T
