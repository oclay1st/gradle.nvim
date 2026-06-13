local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local Project = require('gradle.sources.project')
local Utils = require('gradle.utils')
local FavoritesCacheParser = require('gradle.parsers.favorites_cache_parser')

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
  local favorites = FavoritesCacheParser.parse('nonexistent')
  eq(0, #favorites)
end

T['should dump and parse favorite commands correctly'] = function()
  local key = 'test-favs'
  local favorites = {
    Project.Favorite('build:build', 'task', 'Assembles the project.', { 'build' }),
    Project.Favorite('my-cmd', 'custom_command', 'My custom command', { '--some-flag', 'value' }),
  }
  FavoritesCacheParser.dump(key, favorites)
  local loaded = FavoritesCacheParser.parse(key)
  eq(2, #loaded)
  eq('build:build', loaded[1].name)
  eq('task', loaded[1].type)
  eq('Assembles the project.', loaded[1].description)
  eq({ 'build' }, loaded[1].cmd_args)
  eq('my-cmd', loaded[2].name)
  eq('custom_command', loaded[2].type)
  eq('My custom command', loaded[2].description)
  eq({ '--some-flag', 'value' }, loaded[2].cmd_args)
end

T['should dump and parse empty favorites list'] = function()
  local key = 'empty-favs'
  FavoritesCacheParser.dump(key, {})
  local loaded = FavoritesCacheParser.parse(key)
  eq(0, #loaded)
end

T['should handle multiple cache keys independently'] = function()
  local favs_a = { Project.Favorite('cmd-a', 'task', 'Desc A', { 'a' }) }
  local favs_b = { Project.Favorite('cmd-b', 'task', 'Desc B', { 'b' }) }
  FavoritesCacheParser.dump('key-a', favs_a)
  FavoritesCacheParser.dump('key-b', favs_b)
  local loaded_a = FavoritesCacheParser.parse('key-a')
  local loaded_b = FavoritesCacheParser.parse('key-b')
  eq(1, #loaded_a)
  eq('cmd-a', loaded_a[1].name)
  eq(1, #loaded_b)
  eq('cmd-b', loaded_b[1].name)
end

return T
