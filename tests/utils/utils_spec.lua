local Utils = require('gradle.utils')
local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality

local T = MiniTest.new_set()

T['should split a path'] = function()
  local path = 'root/example/test'
  local split = Utils.split_path(path)
  eq({ 'root', 'example', 'test' }, split)
end

return T
