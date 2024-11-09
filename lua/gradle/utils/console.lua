local Job = require('plenary.job')
local Utils = require('gradle.utils')
local uv = vim.loop

local M = {}

local _buf
local _win
local _buf_name = 'gradle://GradleConsole'
local _jobs = {} ---@type Job[]

---Append a new line to the console
---@param line string
---@param buf number
---@param win number
local append = function(line, buf, win)
  vim.schedule(function()
    local buf_info = vim.fn.getbufinfo(buf)
    if buf_info[1] ~= nil then
      local last_line = buf_info[1].linecount
      vim.fn.appendbufline(buf, last_line, line)
      pcall(vim.api.nvim_win_set_cursor, win, { last_line + 1, 0 })
    end
  end)
end

local function setup_buffer()
  if not _win or not vim.api.nvim_win_is_valid(_win) then
    _win = vim.fn.win_getid(vim.fn.winnr('#'))
  end
  vim.api.nvim_set_current_win(_win)
  if _buf and not vim.api.nvim_buf_is_loaded(_buf) then
    vim.api.nvim_buf_delete(_buf, { force = true, unload = false })
  elseif _buf then
    vim.api.nvim_set_current_buf(_buf)
    return --nothing to do
  end
  _buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(_buf, _buf_name)
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = _buf })
  vim.api.nvim_set_option_value('swapfile', false, { buf = _buf })
  vim.api.nvim_set_option_value('filetype', 'gradle_console', { buf = _buf })
  vim.api.nvim_set_option_value('undolevels', -1, { buf = _buf })
  vim.api.nvim_set_current_buf(_buf)
  vim.api.nvim_create_autocmd({ 'BufUnload' }, {
    pattern = _buf_name,
    callback = function()
      for _, job in ipairs(_jobs) do
        if job and job.pid then
          uv.kill(job.pid, 9)
        end
      end
    end,
  })
end

local function enqueue_job(job, callback)
  local count = #_jobs
  table.insert(_jobs, job)
  if count > 0 then
    _jobs[count]:and_then(job)
    if callback then
      callback(Utils.PENDING_STATE)
    end
  else
    job:start()
  end
end

local function dequeue_job()
  table.remove(_jobs, 1)
end

---Execute gradle command
---@param command string
---@param args string[]
---@param show_output boolean
---@param callback? fun(state: string, ...)
function M.execute_command(command, args, show_output, callback)
  if show_output then
    setup_buffer()
  end
  local job = Job:new({
    command = command,
    args = args,
    on_stdout = function(_, data)
      if show_output and _buf then
        append(data, _buf, _win)
      end
    end,
    on_stderr = function(_, data)
      if show_output and _buf then
        append(data, _buf, _win)
      end
    end,
    on_start = function()
      if show_output then
        vim.schedule(function()
          local message = 'Executing: ' .. command .. ' ' .. table.concat(args, ' ')
          vim.api.nvim_buf_set_lines(_buf, 0, -1, false, { message })
        end)
      end
      if callback then
        callback(Utils.STARTED_STATE)
      end
    end,
    on_exit = function()
      if show_output then
        dequeue_job()
      end
    end,
  })
  if callback then
    job:after_success(function(j, code, signal)
      callback(Utils.SUCCEED_STATE, j, code, signal)
    end)
  end

  if callback then
    job:after_failure(function(j, code, signal)
      callback(Utils.FAILED_STATE, j, code, signal)
    end)
  end

  if show_output then
    enqueue_job(job, callback)
  else
    job:start()
  end
end

return M
