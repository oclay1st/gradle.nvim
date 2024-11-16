local highlights = require('gradle.config.highlights')
local GradleConfig = require('gradle.config')
local Sources = require('gradle.sources')
local ProjectView = require('gradle.ui.projects_view')
local ExecuteView = require('gradle.ui.execute_view')
local InitializerView = require('gradle.ui.initializer_view')

local M = {}

local projects_view -- @type ProjectView
local execute_view -- @type ExecuteView
local initializer_view -- @type InitializerView

---Setup the plugin

---Setup the plugin
M.setup = function(opts)
  GradleConfig.setup(opts)
  highlights.setup()
end

local function load_projects_view()
  local workspace_path = vim.fn.getcwd()
  projects_view = ProjectView.new()
  projects_view:mount()
  projects_view:set_loading(true)
  Sources.scan_projects(workspace_path, function(projects)
    vim.schedule(function()
      projects_view:refresh_projects(projects)
      projects_view:set_loading(false)
    end)
  end)
end

M.toggle_projects_view = function()
  if not projects_view then
    load_projects_view()
  else
    projects_view:toggle()
  end
end

M.refresh = function()
  if projects_view then
    projects_view:unmount()
  end
  load_projects_view()
end

M.show_execute_view = function()
  if not execute_view then
    execute_view = ExecuteView.new()
  end
  execute_view:mount()
end

M.show_initializer_view = function()
  if not initializer_view then
    initializer_view = InitializerView.new()
  end
  initializer_view:mount()
end

return M
