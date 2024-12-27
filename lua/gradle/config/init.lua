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

---@class DefaultArguments
---@field enabled boolean
---@field arg string
---@field value string

---@class ConsoleView
---@field show_task_execution boolean
---@field show_command_execution boolean
---@field show_dependencies_load_execution boolean
---@field show_tasks_load_execution boolean
---@field show_project_create_execution boolean
---@field clean_before_execution boolean

---@class Workspace
---@field name string
---@field path string

---@class GradleOptions
---@field projects_view? ProjectsView
---@field console ConsoleView
---@field gradle_executable string the name or path of gradle
---@field default_arguments DefaultArguments[]
---@field project_scanner_depth number
---@field custom_commands CustomCommand[]
---@field workspaces Workspace[]
local defaultOptions = {
  projects_view = {
    position = 'right',
    size = 66,
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
    show_project_create_execution = false,
    clean_before_execution = true,
  },
  gradle_executable = 'gradle',
  default_arguments = {},
  custom_commands = {},
  project_scanner_depth = 5,
}

---@type GradleOptions
M.options = defaultOptions

M.setup = function(args)
  M.options = vim.tbl_deep_extend('force', M.options, args or {})
  return M.options
end

return M
