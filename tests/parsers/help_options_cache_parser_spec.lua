local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local Utils = require('gradle.utils')
local HelpOptionsCacheParser = require('gradle.parsers.help_options_cache_parser')

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
  local options = HelpOptionsCacheParser.parse()
  eq(0, #options)
end

T['should dump and parse options correctly'] = function()
  local options = {
    { name = '-?', description = 'Shows this help message.' },
    { name = '-h', description = 'Shows this help message.' },
    { name = '--help', description = 'Shows this help message.' },
    { name = '-v', description = 'Prints version info.' },
  }
  HelpOptionsCacheParser.dump(options)
  local loaded = HelpOptionsCacheParser.parse()
  eq(4, #loaded)
  eq('-?', loaded[1].name)
  eq('Shows this help message.', loaded[1].description)
  eq('-v', loaded[4].name)
  eq('Prints version info.', loaded[4].description)
end

T['should dump and parse empty options list'] = function()
  HelpOptionsCacheParser.dump({})
  local loaded = HelpOptionsCacheParser.parse()
  eq(0, #loaded)
end

T['should overwrite previous dump'] = function()
  HelpOptionsCacheParser.dump({ { name = '-a', description = 'Alpha' } })
  HelpOptionsCacheParser.dump({ { name = '-b', description = 'Beta' } })
  local loaded = HelpOptionsCacheParser.parse()
  eq(1, #loaded)
  eq('-b', loaded[1].name)
end

return T
