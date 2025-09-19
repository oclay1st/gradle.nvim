---@class GradleConfig
local M = {}

M.namespace = vim.api.nvim_create_namespace('gradle')

---@class Border
---@field style any
---@field padding? any

---@class ProjectsViewConfig
---@field position string
---@field size integer
---@field custom_commands CustomCommand[]

---@class ProjectNameWin
---@field border Border

---@class ProjectPackageWin
---@field border Border

---@class JavaVersionWin
---@field border Border

---@class DSLWin
---@field border Border

---@class TestFrameworkWin
---@field border Border

---@class WorkspaceOption
---@field name string
---@field path string

---@class WorkspacesWin
---@field options WorkspaceOption[]
---@field border Border

---@class InitializerViewConfig
---@field project_name_win ProjectNameWin
---@field project_package_win ProjectPackageWin
---@field java_version_win JavaVersionWin
---@field dsl_win DSLWin
---@field test_framework_win TestFrameworkWin
---@field workspaces_win WorkspacesWin

---@class CustomCommand
---@field name string
---@field description string
---@field cmd_args string[]

---@class DefaultArguments
---@field enabled boolean
---@field arg string
---@field value string

---@class ConsoleViewConfig
---@field show_task_execution boolean
---@field show_command_execution boolean
---@field show_dependencies_load_execution boolean
---@field show_tasks_load_execution boolean
---@field show_project_create_execution boolean
---@field clean_before_execution boolean

---@class ExecutionViewConfig
---@field size any
---@field input_win any
---@field options_win any

---@class HelpViewConfig
---@field border Border
---@flied size any

---@class Cache
---@field enable_tasks_cache boolean
---@field enable_dependencies_cache boolean
---@field enable_help_options_cache boolean

---@class GradleOptions
---@field projects_view ProjectsViewConfig
---@field initializer_view InitializerViewConfig
---@field execution_view ExecutionViewConfig
---@field help_view HelpViewConfig
---@field console ConsoleViewConfig
---@field gradle_executable string
---@field project_scanner_depth number
---@field cache Cache
local defaultOptions = {
  gradle_executable = 'gradle', -- the name or path of gradle
  project_scanner_depth = 5,
  projects_view = {
    custom_commands = {},
    position = 'right',
    size = 66,
  },
  dependencies_view = {
    size = {
      width = '70%',
      height = '80%',
    },
    resolved_dependencies_win = {
      border = { style = 'rounded' },
    },
    dependency_usages_win = {
      border = { style = 'rounded' },
    },
    filter_win = {
      border = { style = 'rounded' },
    },
    dependency_details_win = {
      size = {
        width = '80%',
        height = '6',
      },
      border = { style = 'rounded' },
    },
  },
  initializer_view = {
    project_name_win = {
      border = { style = 'rounded' },
    },
    project_package_win = {
      default_value = '',
      border = { style = 'rounded' },
    },
    java_version_win = {
      border = { style = 'rounded' },
    },
    dsl_win = {
      border = { style = 'rounded' },
    },
    test_framework_win = {
      border = { style = 'rounded' },
    },
    workspaces_win = {
      options = {
        { name = 'HOME', path = vim.loop.os_homedir() },
        { name = 'CURRENT_DIR', path = vim.fn.getcwd() },
      },
      border = { style = 'rounded' },
    },
  },
  execution_view = {
    size = {
      width = '40%',
      height = '60%',
    },
    input_win = {
      border = {
        style = { '╭', '─', '╮', '│', '│', '─', '│', '│' },
      },
    },
    options_win = {
      border = {
        style = { '', '', '', '│', '╯', '─', '╰', '│' },
      },
    },
  },
  help_view = {
    size = {
      width = '80%',
      height = '34%',
    },
    border = { style = 'rounded' },
  },
  default_arguments_view = {
    arguments = {},
    size = {
      width = '40%',
      height = '30%',
    },
    input_win = {
      border = {
        style = { '╭', '─', '╮', '│', '│', '─', '│', '│' },
      },
    },
    options_win = {
      border = {
        style = { '', '', '', '│', '╯', '─', '╰', '│' },
      },
    },
  },
  favorite_commands_view = {
    size = {
      width = '40%',
      height = '30%',
    },
    input_win = {
      border = {
        style = { '╭', '─', '╮', '│', '│', '─', '│', '│' },
      },
    },
    options_win = {
      border = {
        style = { '', '', '', '│', '╯', '─', '╰', '│' },
      },
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
  cache = {
    enable_tasks_cache = true,
    enable_dependencies_cache = true,
    enable_help_options_cache = true,
  },
  icons = {
    package = '',
    new = '',
    tree = '󰙅',
    expanded = ' ',
    collapsed = ' ',
    gradle = '',
    project = '',
    tool_folder = '',
    tool = '',
    command = '',
    help = '󰘥',
    package_dependents = '',
    package_dependencies = '',
    warning = '',
    entry = ' ',
    search = '',
    argument = '',
    favorite = '',
  },
}

---@type GradleOptions
M.options = defaultOptions

M.setup = function(args)
  M.options = vim.tbl_deep_extend('force', M.options, args or {})
  return M.options
end

return M
