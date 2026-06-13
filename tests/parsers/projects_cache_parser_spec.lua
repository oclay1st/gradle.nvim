local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local Utils = require('gradle.utils')
local ProjectsCacheParser = require('gradle.parsers.projects_cache_parser')

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
  local projects = ProjectsCacheParser.parse()
  eq(0, #projects)
end

T['should register a new project and return a key'] = function()
  local key = ProjectsCacheParser.register('/path/to/project')
  eq('string', type(key))
  eq(36, #key)
end

T['should return existing key when registering same path twice'] = function()
  local key1 = ProjectsCacheParser.register('/same/path')
  local key2 = ProjectsCacheParser.register('/same/path')
  eq(key1, key2)
end

T['should return different keys for different paths'] = function()
  local key1 = ProjectsCacheParser.register('/path/one')
  local key2 = ProjectsCacheParser.register('/path/two')
  eq(true, key1 ~= key2)
end

T['should return all registered projects'] = function()
  local projects = ProjectsCacheParser.parse()
  eq(4, #projects)
end

return T
