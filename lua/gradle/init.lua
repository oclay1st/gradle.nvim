local highlights = require('gradle.highlights')
local GradleConfig = require('gradle.config')
local Sources = require('gradle.sources')
local ProjectView = require('gradle.ui.projects_view')

local M = {}

local project_view

---Setup the plugin
M.setup = function(opts)
  GradleConfig.setup(opts)
  highlights.setup()
end

M.toggle = function()
  if not project_view then
    local workspace_path = vim.fn.getcwd()
    local projects = Sources.scan_projects(workspace_path)
    project_view = ProjectView.new(projects)
    project_view:mount()
  else
    project_view:toggle()
  end
end

return M
