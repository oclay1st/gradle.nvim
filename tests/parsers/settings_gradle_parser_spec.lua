local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local SettingGradleParser = require('gradle.parsers.settings_gradle_parser')

local T = MiniTest.new_set()

local function make_file(lines)
  local path = vim.fn.tempname()
  local f = io.open(path, 'w')
  if f then
    f:write(table.concat(lines, '\n'))
    f:close()
  end
  return path
end

T['should parse rootProject.name and includes'] = function()
  local path = make_file({
    "rootProject.name = 'my-project'",
    "include 'module-a'",
    "include 'module-b'",
  })
  local result = SettingGradleParser.parse_file(path)
  eq('my-project', result.project_name)
  eq({ 'module-a', 'module-b' }, result.module_names)
  os.remove(path)
end

T['should parse rootProject.name with double quotes'] = function()
  local path = make_file({
    'rootProject.name = "my-project"',
  })
  local result = SettingGradleParser.parse_file(path)
  eq('my-project', result.project_name)
  os.remove(path)
end

T['should parse multiple includes on one line'] = function()
  local path = make_file({
    "rootProject.name = 'my-project'",
    "include 'module-a', 'module-b', 'module-c'",
  })
  local result = SettingGradleParser.parse_file(path)
  eq('my-project', result.project_name)
  eq({ 'module-a', 'module-b', 'module-c' }, result.module_names)
  os.remove(path)
end

T['should parse include with parentheses'] = function()
  local path = make_file({
    "rootProject.name = 'my-project'",
    "include('module-a')",
    "include('module-b')",
  })
  local result = SettingGradleParser.parse_file(path)
  eq('my-project', result.project_name)
  eq({ 'module-a', 'module-b' }, result.module_names)
  os.remove(path)
end

T['should return nil project_name when not found'] = function()
  local path = make_file({
    "include 'module-a'",
  })
  local result = SettingGradleParser.parse_file(path)
  eq(nil, result.project_name)
  eq({ 'module-a' }, result.module_names)
  os.remove(path)
end

T['should return empty module_names when no includes'] = function()
  local path = make_file({
    "rootProject.name = 'my-project'",
  })
  local result = SettingGradleParser.parse_file(path)
  eq('my-project', result.project_name)
  eq({}, result.module_names)
  os.remove(path)
end

T['should handle project name with special characters'] = function()
  local path = make_file({
    "rootProject.name = 'my-app-1.0'",
    "include 'core-lib'",
  })
  local result = SettingGradleParser.parse_file(path)
  eq('my-app-1.0', result.project_name)
  eq({ 'core-lib' }, result.module_names)
  os.remove(path)
end

T['should handle colons in module names'] = function()
  local path = make_file({
    "rootProject.name = 'my-project'",
    "include ':sub-project'",
  })
  local result = SettingGradleParser.parse_file(path)
  eq('my-project', result.project_name)
  eq({ 'sub-project' }, result.module_names)
  os.remove(path)
end

T['should handle empty file'] = function()
  local path = make_file({ '' })
  local result = SettingGradleParser.parse_file(path)
  eq(nil, result.project_name)
  eq({}, result.module_names)
  os.remove(path)
end

return T
