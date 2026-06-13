local uv = vim.loop
local Utils = require('gradle.utils')

local M = {}

function M.exists(path)
  return uv.fs_stat(path) ~= nil
end

function M.is_dir(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == 'directory'
end

function M.is_file(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == 'file'
end

function M.mkdir(path)
  if M.is_dir(path) then
    return true
  end
  local parent = vim.fs.dirname(path)
  if parent and parent ~= path then
    M.mkdir(parent)
  end
  local ok = uv.fs_mkdir(path, 493)
  return ok ~= nil or M.is_dir(path)
end

---Read a file given a path
---@param path string
---@return string
function M.read(path)
  local fd, err = uv.fs_open(path, 'r', 438) -- 0666
  if not fd then
    error('Error reading file: ' .. err)
  end

  local stat, stat_err = uv.fs_fstat(fd)
  if not stat then
    uv.fs_close(fd)
    error('Error reading file: ' .. stat_err)
  end

  local content, read_err = uv.fs_read(fd, stat.size, 0)
  uv.fs_close(fd)

  if not content then
    error('Error reading file: ' .. read_err)
  end
  return content
end

function M.read_lines(path)
  local content, err = M.read(path)
  if not content then
    return {}
  end

  content = content:gsub('\r\n', '\n')

  if content:sub(-1) == '\n' then
    content = content:sub(1, -2)
  end

  return vim.split(content, '\n', { plain = true })
end

function M.write(path, content)
  local dir = vim.fs.dirname(path)
  if dir and not M.is_dir(dir) then
    local ok, err = M.mkdir(dir)
    if not ok then
      return false, err
    end
  end

  if type(content) == 'table' then
    content = table.concat(content, '\n')
  else
    content = tostring(content)
  end

  local fd, err = uv.fs_open(path, 'w', 438) -- 0666
  if not fd then
    return false, err
  end

  local ok, write_err = uv.fs_write(fd, content, 0)
  uv.fs_close(fd)

  if not ok then
    return false, write_err
  end

  return true
end

function M.delete(path)
  if not M.exists(path) then
    return true
  end

  local ok, err = uv.fs_unlink(path)
  if ok then
    return true
  end

  return false, err
end

---Recursively scan directory for files matching pattern
---@param root_dir string
---@param opts any
function M.scan_dir_async(root_dir, opts)
  local function scan(dir, level)
    if level > opts.depth then
      return
    end
    local handle = uv.fs_scandir(dir)
    if not handle then
      return
    end
    while true do
      local name, typ = uv.fs_scandir_next(handle)
      if not name then
        break
      end
      local path = dir .. '/' .. name
      if typ == 'file' then
        if Utils.matches_any(path, opts.search_pattern) then
          opts.on_insert(path, uv.fs_stat(path))
        end
      elseif typ == 'directory' then
        scan(path, level + 1)
      end
    end
  end
  scan(root_dir, 0)
  if opts.on_exit then
    opts.on_exit()
  end
end

return M
