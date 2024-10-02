local highlights = require('gradle.highlights')
local GradleConfig = require('gradle.config')
local Sources = require('gradle.sources')
local ProjectView = require('gradle.ui.projects_view')

local M = {}

local is_mounted = false

---Setup the plugin
M.setup = function(opts)
  GradleConfig.setup(opts)
  highlights.setup()
end

M.toggle = function()
  if not is_mounted then
    local workspace_path = vim.fn.getcwd()
    local projects = Sources.scan_projects(workspace_path)
    ProjectView.mount(projects)
    is_mounted = true
  else
    ProjectView.toggle()
  end
end

return M
