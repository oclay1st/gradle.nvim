local GradleConfig = require('gradle.config')

---@class Command
---@field cmd string
---@field args string[]

---@class CommandBuilder
local CommandBuilder = {}

---Build the mvn cmd
---@param project_path string
---@param extra_args string[]
---@return Command
CommandBuilder.build_gradle_cmd = function(project_path, extra_args)
  local _args = {
    '-p',
    project_path,
  }
  for _, value in ipairs(extra_args) do
    table.insert(_args, value)
  end
  return {
    cmd = GradleConfig.options.gradle_executable,
    args = _args,
  }
end

---Build the tasks list cmd
---@param project_path string
---@return Command
CommandBuilder.build_gradle_tasks_cmd = function(project_path)
  return CommandBuilder.build_gradle_cmd(project_path, { ':tasks' })
end

---Build the dependency tree cmd
---@param project_path string
---@return Command
CommandBuilder.build_gradle_dependencies_cmd = function(project_path)
  return CommandBuilder.build_gradle_cmd(project_path, { 'dependencies' })
end

---Build the  help cmd
---@return Command
CommandBuilder.build_gradle_help_cmd = function()
  return {
    cmd = GradleConfig.options.gradle_executable,
    args = { '--help' },
  }
end

return CommandBuilder
