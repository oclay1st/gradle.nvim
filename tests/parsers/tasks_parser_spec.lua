local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local TaskParser = require('gradle.parsers.tasks_parser')

local T = MiniTest.new_set()

T['should parse a single task group with descriptions'] = function()
  local lines = {
    'Build tasks',
    '-----------',
    'build - Assembles and tests this project.',
    'clean - Deletes the build directory.',
  }
  local tasks = TaskParser.parse(lines)
  eq(2, #tasks)
  eq('build', tasks[1].name)
  eq('Assembles and tests this project.', tasks[1].description)
  eq('build', tasks[1].group)
  eq('build', tasks[1].cmd_arg)
  eq('clean', tasks[2].name)
  eq('Deletes the build directory.', tasks[2].description)
  eq('build', tasks[2].group)
  eq('clean', tasks[2].cmd_arg)
end

T['should parse tasks without descriptions'] = function()
  local lines = {
    'Help tasks',
    '----------',
    'help',
    'projects',
  }
  local tasks = TaskParser.parse(lines)
  eq(2, #tasks)
  eq('help', tasks[1].name)
  eq(nil, tasks[1].description)
  eq('help', tasks[1].group)
  eq('projects', tasks[2].name)
  eq(nil, tasks[2].description)
  eq('help', tasks[2].group)
end

T['should parse multiple task groups'] = function()
  local lines = {
    'Build tasks',
    '-----------',
    'build - Assembles.',
    'clean - Deletes.',
    '',
    'Verification tasks',
    '------------------',
    'test - Runs tests.',
    'check - Runs checks.',
  }
  local tasks = TaskParser.parse(lines)
  eq(4, #tasks)
  eq('build', tasks[1].name)
  eq('build', tasks[1].group)
  eq('clean', tasks[2].name)
  eq('build', tasks[2].group)
  eq('test', tasks[3].name)
  eq('verification', tasks[3].group)
  eq('check', tasks[4].name)
  eq('verification', tasks[4].group)
end

T['should return empty list for empty input'] = function()
  local tasks = TaskParser.parse({})
  eq(0, #tasks)
end

T['should return empty list when no task groups found'] = function()
  local lines = {
    'Some random output',
    'that does not contain',
    'any task groups',
  }
  local tasks = TaskParser.parse(lines)
  eq(0, #tasks)
end

T['should skip empty lines between groups'] = function()
  local lines = {
    'Build tasks',
    '-----------',
    'build - Build the project.',
    '',
    '',
    '',
  }
  local tasks = TaskParser.parse(lines)
  eq(1, #tasks)
  eq('build', tasks[1].name)
end

T['should ignore lines before the first task group'] = function()
  local lines = {
    'Welcome to Gradle!',
    '',
    'Build tasks',
    '-----------',
    'build - Build the project.',
  }
  local tasks = TaskParser.parse(lines)
  eq(1, #tasks)
  eq('build', tasks[1].name)
end

return T
