local Project = require('gradle.sources.project')
local Utils = require('gradle.utils')

---@class DependencyTreeParser
local DependencyTreeParser = {}

DependencyTreeParser.__index = DependencyTreeParser

---@param id string
---@param parent_id string | nil
---@param configuration string
---@return Project.Dependency
local parse_dependency_type_project = function(text, id, parent_id, configuration)
  local name = string.match(text, '%:(%S*)')
  local is_duplicate = text:find('%(%*%)') ~= nil
  return Project.Dependency(id, parent_id, configuration, 'project', name, nil, nil, is_duplicate)
end

---@param id string
---@param parent_id string | nil
---@param configuration string
---@return Project.Dependency
local parse_dependency_type_module = function(text, id, parent_id, configuration)
  local group, name, extra = text:match('(.-):(.-)[%s%:](.*)')
  assert(group, 'Failed to parse the dependency group from : ' .. text)
  assert(name, 'Failed to parse the dependency name from : ' .. text)
  assert(extra, 'Failed to parse the dependency extra from : ' .. text)
  local is_duplicate = extra:find('%(%*%)') ~= nil
  local conflict_version, version, _ = extra:match('(.+)%s%->%s(.+)%s?(.*)')
  if not version then
    version, _ = extra:match('%->%s(.+)%s?(.*)')
  end
  if not version then
    version, _ = extra:match('(%S+)%s?(.*)')
  end
  return Project.Dependency(
    id,
    parent_id,
    configuration,
    'module',
    name,
    group,
    version,
    is_duplicate,
    conflict_version
  )
end

---Parse the dependency text
---@param text string
---Example: org.hibernate.validator:hibernate-validator:8.0.1.Final
---@param id string
---@param parent_id string | nil
---@param configuration string
---@return Project.Dependency
local parse_dependency = function(text, id, parent_id, configuration)
  if string.find(text, '^project%s') then
    return parse_dependency_type_project(text, id, parent_id, configuration)
  end
  return parse_dependency_type_module(text, id, parent_id, configuration)
end

---Resolve dependencies for gradle command output
---@param dependencies_output_lines string[] -- gradle tree output lines
---Example:
---  {
---   "runtimeClasspath - Runtime classpath of source set 'main'.",
---   "+--- org.springframework.boot:spring-boot-starter-validation -> 3.3.4",
---   "|    +--- org.springframework.boot:spring-boot-starter:3.3.4 (*)",
---   "|    +--- org.apache.tomcat.embed:tomcat-embed-el:10.1.30",
---   "|    \--- org.hibernate.validator:hibernate-validator:8.0.1.Final",
---   "|         +--- jakarta.validation:jakarta.validation-api:3.0.2",
---   "|         +--- org.jboss.logging:jboss-logging:3.4.3.Final -> 3.5.3.Final",
---   "|         \--- com.fasterxml:classmate:1.5.1 -> 1.7.0"
--- }
---@return Project.Dependency[]
function DependencyTreeParser.parse(dependencies_output_lines)
  local dependencies = {}
  local space_indentation = 5 --- all the  node are indent on multiple of 3 spaces
  local dependencies_depth = {}
  local adding_dependency = false
  local current_config
  for _, line in ipairs(dependencies_output_lines) do
    local configuration, description = string.match(line, '(%w+)%s%-%s(.*)')
    if configuration and description and not string.find(description, '%(n%)$') then
      current_config = configuration
      adding_dependency = true
    elseif line == '' or line == 'No dependencies' then
      adding_dependency = false
    elseif adding_dependency then
      local cleaned_line = string.gsub(line, '[%+%\\%|]', ' ')
      local characters_before = assert(string.find(cleaned_line, '%s%w')) --- get all characters until -
      local depth_index = characters_before / space_indentation
      local dependency_id = Utils.uuid()
      dependencies_depth[depth_index] = dependency_id
      local parent_dependency_id = dependencies_depth[depth_index - 1]
      local text = string.sub(cleaned_line, characters_before + 1)
      local dependency = parse_dependency(text, dependency_id, parent_dependency_id, current_config)
      table.insert(dependencies, dependency)
    end
  end
  return dependencies
end

return DependencyTreeParser
