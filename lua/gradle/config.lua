local Path = require('plenary.path')
---@class GradleConfig
local M = {}

M.namespace = vim.api.nvim_create_namespace('gradle')

---@class ProjectsView
---@field position string
---@field size integer

---@class InitializerView
---@field default_package string
---@field workspaces Workspace[]

---@class CustomCommand
---@field name string
---@field description string
---@field cmd_args string[]

---@class ConsoleView
---@field show_task_execution boolean
---@field show_command_execution boolean
---@field show_dependencies_load_execution boolean
---@field show_tasks_load_execution boolean
---@field show_create_project_execution boolean

---@class Workspace
---@field name string
---@field path string

---@class GradleOptions
---@field projects_view? ProjectsView
---@field console ConsoleView
---@field gradle_executable string the name or path of mvn
---@field custom_commands CustomCommand[]
---@field workspaces Workspace[]
local defaultOptions = {
  projects_view = {
    position = 'right',
    size = 68,
  },
  initializer_view = {
    default_package = '',
    workspaces = {
      { name = 'HOME', path = vim.loop.os_homedir() },
      { name = 'CURRENT_DIR', path = vim.fn.getcwd() },
    },
  },
  console = {
    show_command_execution = true,
    show_task_execution = true,
    show_dependencies_load_execution = false,
    show_tasks_load_execution = false,
    show_create_project_execution = false,
  },
  gradle_executable = 'gradle',
  custom_commands = {},
}

---@type GradleOptions
M.options = defaultOptions

M.setup = function(args)
  M.options = vim.tbl_deep_extend('force', M.options, args or {})
  return M.options
end

return M
