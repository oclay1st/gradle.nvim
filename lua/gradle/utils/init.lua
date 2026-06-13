local random = math.random

local M = {}

M.STARTED_STATE = 'STARTED'
M.SUCCEED_STATE = 'SUCCEED'
M.FAILED_STATE = 'FAILED'
M.PENDING_STATE = 'PENDING'

M.path_separator = (function()
  if jit then
    local os = string.lower(jit.os)
    if os ~= 'windows' then
      return '/'
    else
      return '\\'
    end
  else
    return package.config:sub(1, 1)
  end
end)()

M.gradle_cache_path = vim.fs.joinpath(vim.fn.stdpath('cache'), 'gradle')

M.gradle_local_repository_path =
  vim.fs.joinpath(vim.fn.expand('~'), '.gradle', 'caches', 'modules-2', 'files-2.1')

M.split_path = function(filepath)
  local formatted = string.format('([^%s]+)', M.path_separator)
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

M.get_jar_file_path = function(group, name, version)
  local jar_directory = vim.fn.resolve(
    M.gradle_local_repository_path
      .. M.path_separator
      .. group
      .. M.path_separator
      .. name
      .. M.path_separator
      .. version
  )
  return vim.fn.glob(
    jar_directory .. M.path_separator .. '*' .. M.path_separator .. name .. '-' .. version .. '.jar'
  )
end

M.matches_any = function(str, patterns)
  if patterns == nil then
    return false
  end
  if type(patterns) == 'string' then
    patterns = { patterns }
  end
  return vim.iter(patterns):any(function(pattern)
    return str:match(pattern) ~= nil
  end)
end

return M
