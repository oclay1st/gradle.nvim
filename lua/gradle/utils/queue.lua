
local M = {}

---@class SystemQueueJob
---@field cmd string[]
---@field opts table|nil
---@field resolve fun(result)
---@field reject fun(err)
---@field retries number
---@field attempt number
---@field cancelled boolean
---@field _done boolean
---@field _callbacks fun(any)[]
---@field _errbacks fun(any)[]
---@field _finallys fun()[]
---@field _result any
---@field _error any

---@class SystemQueue
---@field queue SystemQueueJob[]
---@field active number
---@field max number
---@field running table<SystemQueueJob, any>
local Queue = {}
Queue.__index = Queue

function M.new(opts)
  opts = opts or {}
  return setmetatable({
    queue = {},
    active = 0,
    max = opts.concurrency or 1,
    running = {},
  }, Queue)
end

function Queue:_finalize(job, ok, value)
  if job._done then
    return
  end

  job._done = true

  if ok then
    job._result = value
    for _, cb in ipairs(job._callbacks) do
      cb(value)
    end
  else
    job._error = value
    for _, cb in ipairs(job._errbacks) do
      cb(value)
    end
  end

  for _, cb in ipairs(job._finallys) do
    cb()
  end

  job._callbacks = nil
  job._errbacks = nil
  job._finallys = nil
end

function Queue:_run_next()
  while self.active < self.max and #self.queue > 0 do
    local job = table.remove(self.queue, 1) ---@type SystemQueueJob

    if job.cancelled then
      job.reject('cancelled')
      goto continue
    end

    self.active = self.active + 1

    if job.opts and job.opts.on_start then
      job.opts.on_start()
    end

    local handle = vim.system(job.cmd, job.opts or {}, function(obj)
      self.active = self.active - 1
      self.running[job] = nil

      if job.cancelled then
        job.reject('cancelled')
      elseif obj.code == 0 then
        job.resolve(obj)
      else
        job.attempt = job.attempt + 1
        if job.attempt <= job.retries then
          table.insert(self.queue, job)
        else
          job.reject(obj)
        end
      end

      self:_run_next()
    end)

    self.running[job] = handle

    ::continue::
  end
end

function Queue:enqueue(cmd, opts)
  local job = {
    cmd = cmd,
    opts = opts,
    retries = (opts and opts.retries) or 0,
    attempt = 0,
    cancelled = false,
    _done = false,
    _callbacks = {},
    _errbacks = {},
    _finallys = {},
    _result = nil,
    _error = nil,
  }

  -- unified completion
  job.resolve = function(res)
    self:_finalize(job, true, res)
  end

  job.reject = function(err)
    self:_finalize(job, false, err)
  end

  table.insert(self.queue, job)
  self:_run_next()

  local handle = {}

  function handle:next(cb)
    if job._done and job._result ~= nil then
      cb(job._result)
    elseif not job._done then
      table.insert(job._callbacks, cb)
    end
    return self
  end

  function handle:catch(cb)
    if job._done and job._error ~= nil then
      cb(job._error)
    elseif not job._done then
      table.insert(job._errbacks, cb)
    end
    return self
  end

  function handle:finally(cb)
    if job._done then
      cb()
    else
      table.insert(job._finallys, cb)
    end
    return self
  end

  function handle:wait()
    local co = coroutine.running()
    if not co then
      error('wait() must be used in coroutine')
    end

    local resumed = false
    local function resume_once()
      if not resumed then
        resumed = true
        coroutine.resume(co)
      end
    end

    self:next(resume_once)
    self:catch(resume_once)

    coroutine.yield()

    if job._error then
      error(job._error)
    end
    return job._result
  end

  function handle:cancel()
    job.cancelled = true

    local h = self.running and self.running[job]
    if h and h.kill then
      h:kill(15)
    end

    if not job._done then
      job.reject('cancelled')
    end
  end

  return handle
end

function Queue:cancel_all()
  for _, job in ipairs(self.queue) do
    job.cancelled = true
    if not job._done then
      job.reject('cancelled')
    end
  end
  self.queue = {}

  for job, handle in pairs(self.running) do
    job.cancelled = true
    if handle and handle.kill then
      handle:kill(15)
    end
    if not job._done then
      job.reject('cancelled')
    end
  end

  self.running = {}
end

return M
