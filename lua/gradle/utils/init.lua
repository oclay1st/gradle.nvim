local Path = require('plenary.path')
local random = math.random
local M = {}

M.STARTED_STATE = 'STARTED'
M.SUCCEED_STATE = 'SUCCEED'
M.FAILED_STATE = 'FAILED'
M.PENDING_STATE = 'PENDING'

M.gradle_cache_path = Path:new(vim.fn.stdpath('cache'), 'gradle'):absolute()

M.gradle_local_repository_path =
  Path:new(Path.path.home, '.gradle', 'caches', 'modules-2', 'files-2.1'):absolute()

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

M.humanize_size = function(size)
  if not size then
    return nil
  end
  local units = { 'B', 'KB', 'MB', 'GB', 'TB' }
  local unit_index = 1
  while size >= 1024 and unit_index < #units do
    size = size / 1024
    unit_index = unit_index + 1
  end
  return string.format('%.2f %s', size, units[unit_index])
end

return M
