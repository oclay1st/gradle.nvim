local Utils = require('gradle.utils')

---@class Project
---@field id string
---@field build_gradle_path string
---@field settings_gradle_path string
---@field root_path string
---@field name string
---@field tasks Project.Task[]
---@field dependencies Project.Dependency[]
---@field commands Project.Command[]
---@field sub_projects Project[]
local Project = {}
Project.__index = Project

---Create a new instance of a Project
---@param root_path string
---@param name string
---@param build_gradle_path? string
---@param settings_gradle_path? string
---@param tasks? Project.Task[]
---@param dependencies? Project.Dependency[]
---@param commands? Project.Command[]
---@param sub_projects? Project.Command[]
---@return Project
function Project.new(
  root_path,
  name,
  build_gradle_path,
  settings_gradle_path,
  tasks,
  dependencies,
  commands,
  sub_projects
)
  return setmetatable({
    id = Utils.uuid(),
    root_path = root_path,
    name = name,
    build_gradle_path = build_gradle_path,
    settings_gradle_path = settings_gradle_path,
    tasks = tasks or {},
    dependencies = dependencies or {},
    commands = commands or {},
    sub_projects = sub_projects or {},
  }, Project)
end

---Set tasks
---@param tasks Project.Task[]
function Project:set_tasks(tasks)
  self.tasks = tasks
end

---Set dependencies
---@param dependencies Project.Dependency[]
function Project:set_dependencies(dependencies)
  self.dependencies = dependencies
end

---Set commands
---@param commands Project.Command[]
function Project:set_commands(commands)
  self.commands = commands
end

---Add sub project
---@param project Project
function Project:add_sub_project(project)
  table.insert(self.sub_projects, project)
end

---@class Project.Command
---@field name string
---@field description string
---@field cmd_args string[]
local Command = {}

Command.__index = Command

---@param name string
---@param description string
---@param cmd_args string[]
---@return table
function Project.Command(name, description, cmd_args)
  local self = {}
  setmetatable(self, Command)
  self.name = name
  self.description = description
  self.cmd_args = cmd_args
  return self
end

---@class Project.Dependency
---@field id string
---@field parent_id string | nil
---@field group string
---@field name string
---@field version string
---@field configuration string
---@field is_duplicate boolean
---@field conflict_version? string
local Dependency = {}
Dependency.__index = Dependency

---@alias Dependency Project.Dependency

---@return string
function Dependency:get_compact_name()
  return self.group .. ':' .. self.name .. ':' .. self.version
end

---@param id string
---@param parent_id string | nil
---@param group string
---@param name string
---@param version string
---@param configuration string
---@param is_duplicate? boolean
---@param conflict_version? string
---@return Project.Dependency
function Project.Dependency(
  id,
  parent_id,
  group,
  name,
  version,
  configuration,
  is_duplicate,
  conflict_version
)
  local self = {}
  setmetatable(self, Dependency)
  self.id = id
  self.parent_id = parent_id
  self.group = group
  self.name = name
  self.version = version or ''
  self.configuration = configuration
  self.is_duplicate = is_duplicate or false
  self.conflict_version = conflict_version
  return self
end

---@class DependencyGroup
---@field configuration string
---@field dependencies Project.Dependency[]

---Group dependencies by configuration name
---@return DependencyGroup[]
function Project:group_dependencies_by_configuration()
  local group_by = {}
  local last_configuration
  for _, dependency in ipairs(self.dependencies) do
    if dependency.configuration ~= last_configuration then
      table.insert(
        group_by,
        { configuration = dependency.configuration, dependencies = { dependency } }
      )
      last_configuration = dependency.configuration
    elseif last_configuration then
      table.insert(group_by[#group_by].dependencies, dependency)
    end
  end
  return group_by
end

---@class Project.Task
---@field group string
---@field name string
---@field description string
local Task = {}

Task.__index = Task

---@alias Task Project.Task

---@param name string
---@param description? string
---@param group string
---@return Project.Task
function Project.Task(name, description, group)
  local self = {}
  setmetatable(self, Task)
  self.name = name
  self.description = description
  self.group = group
  return self
end

---@class DependencyGroup
---@field group string
---@field tasks Project.Task[]
---
---Group task by group name
---@return DependencyGroup[]
function Project:group_tasks_by_group_name()
  local group_by = {}
  local last_group
  for _, task in ipairs(self.tasks) do
    if task.group ~= last_group then
      table.insert(group_by, { group = task.group, tasks = { task } })
      last_group = task.group
    elseif last_group then
      table.insert(group_by[#group_by].tasks, task)
    end
  end
  return group_by
end

return Project
