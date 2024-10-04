local highlights = require('gradle.highlights')
local GradleConfig = require('gradle.config')
local Sources = require('gradle.sources')
local ProjectView = require('gradle.ui.projects_view')

local M = {}

local projects_view

---Setup the plugin
M.setup = function(opts)
  GradleConfig.setup(opts)
  highlights.setup()
end

M.toggle = function()
  if not projects_view then
    local workspace_path = vim.fn.getcwd()
    local projects = Sources.scan_projects(workspace_path)
    projects_view = ProjectView.new(projects)
    projects_view:mount()
  else
    projects_view:toggle()
  end
end

return M
