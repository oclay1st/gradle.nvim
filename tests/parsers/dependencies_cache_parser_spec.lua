local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local Project = require('gradle.sources.project')
local Utils = require('gradle.utils')
local DepsCacheParser = require('gradle.parsers.dependencies_cache_parser')
local Utils_uuid = Utils.uuid

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
  local deps = DepsCacheParser.parse('nonexistent')
  eq(0, #deps)
end

T['should dump and parse module dependencies correctly'] = function()
  local key = 'test-modules'
  local id_a = Utils_uuid()
  local id_b = Utils_uuid()
  local deps = {
    Project.Dependency(id_a, nil, 'runtimeClasspath', 'module', 'bar', 'org.foo', '1.0', false, nil),
    Project.Dependency(id_b, id_a, 'runtimeClasspath', 'module', 'baz', 'org.foo', '2.0', true, '1.5'),
  }
  DepsCacheParser.dump(key, deps)
  local loaded = DepsCacheParser.parse(key)
  eq(2, #loaded)
  eq(id_a, loaded[1].id)
  eq(nil, loaded[1].parent_id)
  eq('runtimeClasspath', loaded[1].configuration)
  eq('module', loaded[1].type)
  eq('bar', loaded[1].name)
  eq('org.foo', loaded[1].group)
  eq('1.0', loaded[1].version)
  eq(false, loaded[1].is_duplicate)
  eq(nil, loaded[1].conflict_version)
  eq(id_b, loaded[2].id)
  eq(id_a, loaded[2].parent_id)
  eq('2.0', loaded[2].version)
  eq(true, loaded[2].is_duplicate)
  eq('1.5', loaded[2].conflict_version)
end

T['should dump and parse project dependencies'] = function()
  local key = 'test-projects'
  local id = Utils_uuid()
  local deps = {
    Project.Dependency(id, nil, 'runtimeClasspath', 'project', 'my-lib', nil, nil, false, nil),
  }
  DepsCacheParser.dump(key, deps)
  local loaded = DepsCacheParser.parse(key)
  eq(1, #loaded)
  eq('project', loaded[1].type)
  eq('my-lib', loaded[1].name)
  eq(nil, loaded[1].group)
  eq(nil, loaded[1].version)
end

T['should dump and parse empty dependency list'] = function()
  local key = 'empty-deps'
  DepsCacheParser.dump(key, {})
  local loaded = DepsCacheParser.parse(key)
  eq(0, #loaded)
end

T['should preserve size field'] = function()
  local key = 'test-size'
  local id = Utils_uuid()
  local deps = {
    Project.Dependency(id, nil, 'runtimeClasspath', 'module', 'bar', 'org.foo', '1.0', false, nil, 1024),
  }
  DepsCacheParser.dump(key, deps)
  local loaded = DepsCacheParser.parse(key)
  eq(1024, loaded[1].size)
end

return T
