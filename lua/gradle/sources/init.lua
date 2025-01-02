local scan = require('plenary.scandir')
local Project = require('gradle.sources.project')
local GradleConfig = require('gradle.config')
local Path = require('plenary.path')
local SettingsParser = require('gradle.parsers.settings_gradle_parser')
local TasksParser = require('gradle.parsers.tasks_parser')
local DependencyTreeParser = require('gradle.parsers.dependency_tree_parser')
local HelpOptionsParser = require('gradle.parsers.help_options_parser')
local CommandBuilder = require('gradle.utils.cmd_builder')
local Utils = require('gradle.utils')
local Console = require('gradle.utils.console')

local M = {}

local build_gradle_file_pattern = '.*build%.gradle'

local settings_gradle_file_pattern = '.*settings%.gradle'

local scanned_path_list ---@type string[]

local custom_commands ---@type string[]

---Sort all projects and modules
---@param projects Project[]
local function sort_projects(projects)
  table.sort(projects, function(a, b)
    return string.lower(a.name) < string.lower(b.name)
  end)
  for _, project in ipairs(projects) do
    if #project.modules ~= 0 then
      sort_projects(project.modules)
    end
  end
end

local create_custom_commands = function()
  local _commands = {}
  for index, command in ipairs(GradleConfig.options.projects_view.custom_commands) do
    _commands[index] = Project.Command(command.name, command.description, command.cmd_args)
  end
  return _commands
end

local function create_project_from_build_file(build_gradle_path)
  local build_gradle_file = Path:new(build_gradle_path)
  local build_gradle_parent = build_gradle_file:parent()
  local project_path = build_gradle_parent:absolute()
  local path_parts = Utils.split_path(project_path)
  local project_name = path_parts[#path_parts]
  local project = Project.new(project_path, project_name, build_gradle_path)
  project:set_commands(custom_commands)
  return project
end

local function create_project_from_settings_file(settings_gradle_path)
  local settings_gradle_file = Path:new(settings_gradle_path)
  local settings_gradle_parent = settings_gradle_file:parent()
  local project_path = settings_gradle_parent:absolute()
  local setting = SettingsParser.parse_file(settings_gradle_file:absolute())
  local project = Project.new(project_path, setting.project_name, nil, settings_gradle_path)
  project:set_commands(custom_commands)
  for _, module_name in ipairs(setting.module_names) do
    local build_gradle_name = 'build.gradle'
    if string.match(settings_gradle_path, '%.kts$') then
      build_gradle_name = build_gradle_name .. '.kts'
    end
    local build_gradle = Path:new(project_path, module_name, build_gradle_name) ---@type Path
    local build_gradle_path = build_gradle:absolute()
    if build_gradle:exists() and not vim.tbl_contains(scanned_path_list, build_gradle_path) then
      local module = create_project_from_build_file(build_gradle_path)
      project:add_module(module)
      table.insert(scanned_path_list, build_gradle_path)
    end
  end
  return project
end

---Find project filter by settings file path or build file path
---@param file_path string
---@param projects Project[]
---@return Project | nil
local function find_project(file_path, projects)
  local _root_path = Path:new(file_path):parent():absolute()
  for _, item in ipairs(projects) do
    if item.root_path == _root_path then
      return item
    end
  end
end

---Load the gradle projects given a directory
---@param base_path string
---@param callback fun(projects: Project[])
M.scan_projects = function(base_path, callback)
  local projects = {}
  scanned_path_list = {}
  custom_commands = create_custom_commands()
  scan.scan_dir_async(base_path, {
    search_pattern = { build_gradle_file_pattern, settings_gradle_file_pattern },
    depth = GradleConfig.options.project_scanner_depth,
    on_insert = function(gradle_file_path)
      if not vim.tbl_contains(scanned_path_list, gradle_file_path) then
        local project = find_project(gradle_file_path, projects)
        if string.match(gradle_file_path, build_gradle_file_pattern) then
          if not project then
            project = create_project_from_build_file(gradle_file_path)
            table.insert(projects, project)
          end
          project.build_gradle_path = gradle_file_path
        else
          if not project then
            project = create_project_from_settings_file(gradle_file_path)
            table.insert(projects, project)
          elseif not project.settings_gradle_path then
            local settings_project = create_project_from_settings_file(gradle_file_path)
            project.name = settings_project.name
            project.modules = settings_project.modules
          end
          project.settings_gradle_path = gradle_file_path
        end
        table.insert(scanned_path_list, gradle_file_path)
      end
    end,
    on_exit = function()
      sort_projects(projects)
      callback(projects)
    end,
  })
end

M.load_project_tasks = function(project_path, callback)
  local show_output = GradleConfig.options.console.show_tasks_load_execution
  local _callback = function(state, job)
    local tasks
    if state == Utils.SUCCEED_STATE then
      local content_lines = job:result()
      tasks = TasksParser.parse(content_lines)
    elseif state == Utils.FAILED_STATE then
      local error_msg = 'Error loading tasks. '
      if not show_output then
        error_msg = error_msg .. 'Enable the console output for more details.'
      end
      vim.notify(error_msg, vim.log.levels.ERROR)
    end
    callback(state, tasks)
  end
  local command = CommandBuilder.build_gradle_tasks_cmd(project_path)
  Console.execute_command(command.cmd, command.args, show_output, _callback)
end

M.load_project_dependencies = function(project_path, callback)
  local show_output = GradleConfig.options.console.show_dependencies_load_execution
  local _callback = function(state, job)
    local dependencies
    if state == Utils.SUCCEED_STATE then
      local output_lines = job:result()
      dependencies = DependencyTreeParser.parse(output_lines)
    elseif state == Utils.FAILED_STATE then
      local error_msg = 'Error loading dependencies. '
      if not show_output then
        error_msg = error_msg .. 'Enable the console output for more details.'
      end
      vim.notify(error_msg, vim.log.levels.ERROR)
    end
    callback(state, dependencies)
  end
  local command = CommandBuilder.build_gradle_dependencies_cmd(project_path)
  Console.execute_command(command.cmd, command.args, show_output, _callback)
end

M.load_help_options = function(callback)
  local _callback = function(state, job)
    local help_options
    if state == Utils.SUCCEED_STATE then
      local output_lines = job:result()
      help_options = HelpOptionsParser.parse(output_lines)
    end
    callback(state, help_options)
  end
  local command = CommandBuilder.build_gradle_help_cmd()
  Console.execute_command(command.cmd, command.args, false, _callback)
end

return M
