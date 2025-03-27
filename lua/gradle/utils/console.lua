local Job = require('plenary.job')
local GradleConfig = require('gradle.config')
local Utils = require('gradle.utils')
local uv = vim.loop

local M = {}

local _buf
local _win
local _buf_name = 'gradle://GradleConsole'
local _jobs = {} ---@type Job[]

local line_patterns = {
  { pattern = '^BUILD FAILED', hl = 'DiagnosticError', col_start = 0, col_end = 12 },
  { pattern = '^FAILURE:', hl = 'DiagnosticError', col_start = 0, col_end = 8 },
  { pattern = '^BUILD SUCCESSFUL', hl = 'DiagnosticOk', col_start = 0, col_end = 16 },
  { pattern = '^>> Executing', hl = 'DiagnosticOk', col_start = 0, col_end = 14 },
}

local function highlight_buf_line(buf, line, line_number)
  for _, item in ipairs(line_patterns) do
    if string.find(line, item.pattern) then
      vim.api.nvim_buf_add_highlight(buf, 0, item.hl, line_number, item.col_start, item.col_end)
    end
  end
end

local function set_buf_modifiable(value)
  vim.api.nvim_set_option_value('modifiable', value, { buf = _buf })
  vim.api.nvim_set_option_value('readonly', not value, { buf = _buf })
end

---Append a new line to the console
---@param line string
local append_line = function(line)
  local last_line = vim.api.nvim_buf_line_count(_buf)
  vim.fn.appendbufline(_buf, last_line - 1, line)
  highlight_buf_line(_buf, line, last_line - 1)
  pcall(vim.api.nvim_win_set_cursor, _win, { last_line, 0 })
end

local function setup_buffer()
  if not _win or not vim.api.nvim_win_is_valid(_win) then
    _win = vim.fn.win_getid(vim.fn.winnr('#'))
  end
  vim.api.nvim_set_current_win(_win)
  if _buf and vim.api.nvim_buf_is_valid(_buf) then
    if not vim.api.nvim_buf_is_loaded(_buf) then
      vim.api.nvim_buf_delete(_buf, { force = true, unload = false })
    else
      vim.api.nvim_set_current_buf(_buf)
      return --nothing to do
    end
  end
  _buf = vim.api.nvim_create_buf(true, true)
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
        vim.schedule(function()
          append_line(data)
        end)
      end
    end,
    on_stderr = function(_, data)
      if show_output and _buf then
        vim.schedule(function()
          append_line(data)
        end)
      end
    end,
    on_start = function()
      if show_output then
        vim.schedule(function()
          set_buf_modifiable(true)
          if GradleConfig.options.console.clean_before_execution then
            vim.api.nvim_buf_set_lines(_buf, 0, -1, false, {})
          end
          local message = '>> Executing: ' .. command .. ' ' .. table.concat(args, ' ')
          append_line(message)
          append_line('')
        end)
      end
      if callback then
        callback(Utils.STARTED_STATE)
      end
    end,
    on_exit = function()
      if show_output then
        vim.schedule(function()
          if not GradleConfig.options.console.clean_before_execution then
            append_line('')
          end
          set_buf_modifiable(false)
        end)
        dequeue_job()
      end
    end,
  })

  if callback then
    job:after_success(function(j, code, signal)
      callback(Utils.SUCCEED_STATE, j, code, signal)
    end)

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
