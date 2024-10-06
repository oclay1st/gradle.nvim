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
local console = require('gradle.utils.console')

local build_gradle_file_pattern = '.*build.gradle'

local M = {}

local create_custom_commands = function()
  local custom_commands = {}
  for index, command in ipairs(GradleConfig.options.custom_commands) do
    custom_commands[index] = Project.Command(command.name, command.description, command.cmd_args)
  end
  return custom_commands
end

local create_project_from_file = function(build_gradle_path)
  local build_gradle_file = Path:new(build_gradle_path)
  local build_gradle_parent = build_gradle_file:parent()
  local project_path = build_gradle_parent:absolute()
  local project_name = string.match(project_path, '%' .. Path.path.sep .. '(%w+)$')
  local modules_names = {}
  local settings_gradle = Path:new(build_gradle_parent, 'settings.gradle')
  local settings_gradle_kts = Path:new(build_gradle_parent, 'settings.gradle.kts')
  if settings_gradle:exists() then
    local setting = SettingsParser.parse_file(settings_gradle:absolute())
    project_name = setting.project_name
    modules_names = setting.modules_names
  elseif settings_gradle_kts:exists() then
    local setting = SettingsParser.parse_file(settings_gradle_kts:absolute())
    project_name = setting.project_name
    modules_names = setting.modules_names
  end
  return Project.new(project_path, build_gradle_path, project_name)
end

---Load the gradle projects given a directory
---@param base_path string
---@return Project[]
M.scan_projects = function(base_path)
  local projects = {}
  local custom_commands = create_custom_commands()
  scan.scan_dir(base_path, {
    search_pattern = build_gradle_file_pattern,
    depth = 10,
    on_insert = function(build_gradle_path, _)
      local project = create_project_from_file(build_gradle_path)
      project:set_commands(custom_commands)
      table.insert(projects, project)
    end,
  })
  return projects
end

M.load_project_tasks = function(project_path, callback)
  local _callback = function(state, job)
    local tasks
    if Utils.SUCCEED_STATE == state then
      local content_lines = job:result()
      tasks = TasksParser.parse(content_lines)
    end
    callback(state, tasks)
  end
  local command = CommandBuilder.build_gradle_tasks_cmd(project_path)
  local show_output = GradleConfig.options.console.show_tasks_load_execution
  console.execute_command(command.cmd, command.args, show_output, _callback)
end

M.load_project_dependencies = function(project_path, callback)
  local _callback = function(state, job)
    local dependencies
    if Utils.SUCCEED_STATE == state then
      local output_lines = job:result()
      dependencies = DependencyTreeParser.parse(output_lines)
    end
    callback(state, dependencies)
  end
  local command = CommandBuilder.build_gradle_dependencies_cmd(project_path)
  local show_output = GradleConfig.options.console.show_dependencies_load_execution
  console.execute_command(command.cmd, command.args, show_output, _callback)
end

M.load_help_options = function(callback)
  local _callback = function(state, job)
    local help_options
    if Utils.SUCCEED_STATE == state then
      local output_lines = job:result()
      help_options = HelpOptionsParser.parse(output_lines)
    end
    callback(state, help_options)
  end
  local command = CommandBuilder.build_gradle_help_cmd()
  console.execute_command(command.cmd, command.args, false, _callback)
end

return M
