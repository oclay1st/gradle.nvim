local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local HelpOptionsParser = require('gradle.parsers.help_options_parser')

local T = MiniTest.new_set()

T['should parse comma-separated options'] = function()
  local lines = {
    '-?,-h,--help         Shows this help message.',
    '-v,--version         Prints version info.',
  }
  local options = HelpOptionsParser.parse(lines)
  eq(5, #options)
  eq('-?', options[1].name)
  eq('Shows this help message.', options[1].description)
  eq('-h', options[2].name)
  eq('Shows this help message.', options[2].description)
  eq('--help', options[3].name)
  eq('Shows this help message.', options[3].description)
  eq('-v', options[4].name)
  eq('Prints version info.', options[4].description)
  eq('--version', options[5].name)
  eq('Prints version info.', options[5].description)
end

T['should parse a single option'] = function()
  local lines = {
    '--no-daemon         Do not use the Gradle daemon.',
  }
  local options = HelpOptionsParser.parse(lines)
  eq(1, #options)
  eq('--no-daemon', options[1].name)
  eq('Do not use the Gradle daemon.', options[1].description)
end

T['should skip non-option lines'] = function()
  local lines = {
    'Usage: gradle [options] [tasks]',
    '',
    '-?,-h,--help         Shows this help message.',
    'Some random text that does not start with a dash.',
    '-v,--version         Prints version info.',
  }
  local options = HelpOptionsParser.parse(lines)
  eq(5, #options)
  eq('-?', options[1].name)
  eq('-h', options[2].name)
  eq('--help', options[3].name)
  eq('-v', options[4].name)
  eq('--version', options[5].name)
end

T['should return empty list for empty input'] = function()
  local options = HelpOptionsParser.parse({})
  eq(0, #options)
end

T['should return empty list when no options found'] = function()
  local lines = {
    'Usage: gradle [options] [tasks]',
    '',
    'Some random text without options.',
  }
  local options = HelpOptionsParser.parse(lines)
  eq(0, #options)
end

T['should handle options with multi-word descriptions'] = function()
  local lines = {
    '--build-cache       Enables the Gradle build cache.',
  }
  local options = HelpOptionsParser.parse(lines)
  eq(1, #options)
  eq('--build-cache', options[1].name)
  eq('Enables the Gradle build cache.', options[1].description)
end

T['should handle options with long dashes in names'] = function()
  local lines = {
    '--no-build-cache   Disables the Gradle build cache.',
  }
  local options = HelpOptionsParser.parse(lines)
  eq(1, #options)
  eq('--no-build-cache', options[1].name)
  eq('Disables the Gradle build cache.', options[1].description)
end

return T
