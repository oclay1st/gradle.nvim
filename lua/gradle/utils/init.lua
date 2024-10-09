local Path = require('plenary.path')
local random = math.random
local M = {}

M.STARTED_STATE = 'STARTED'
M.SUCCEED_STATE = 'SUCCEED'
M.FAILED_STATE = 'FAILED'
M.PENDING_STATE = 'PENDING'

M.split_path = function(filepath)
  local formatted = string.format('([^%s]+)', Path.path.sep)
  local t = {}
  for str in string.gmatch(filepath, formatted) do
    table.insert(t, str)
  end
  return t
end

M.uuid = function()
  local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function(c)
    local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
    return string.format('%x', v)
  end)
end

return M
