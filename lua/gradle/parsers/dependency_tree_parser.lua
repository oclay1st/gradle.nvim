local Project = require('gradle.sources.project')
local Utils = require('gradle.utils')

---@class DependencyTreeParser
local DependencyTreeParser = {}

DependencyTreeParser.__index = DependencyTreeParser

---Parse the dependency text
---@param text string
---@param id string
---@param parent_id string | nil
---@param configuration string
---@return Project.Dependency
local parse_dependency = function(text, id, parent_id, configuration)
  local group, name, extra = text:match('(.-):(.-)[%s%:](.*)')
  local version = extra:match('>%s(.+)')
  local comment
  if not version then
    version, comment = extra:match('(%S+)%s?(.*)')
  end
  local is_duplicate = comment and comment:find('%(%*%)') ~= nil
  local conflict_version = nil --- TODO: review later
  return Project.Dependency(
    id,
    parent_id,
    group,
    name,
    version,
    configuration,
    is_duplicate,
    conflict_version
  )
end

---Resolve dependencies
---@return Project.Dependency[]
function DependencyTreeParser.parse(dependencies_output_lines)
  local dependencies = {}
  local space_indentation = 5 --- all the  node are indent on multiple of 3 spaces
  local deep_dependency = {}
  local adding_dependency = false
  local current_config
  for _, line in ipairs(dependencies_output_lines) do
    local config, desc = string.match(line, '(%w+)%s%-%s(.*)')
    if config and desc and not string.find(desc, '%(n%)$') then
      current_config = config
      adding_dependency = true
    elseif line == '' or line == 'No dependencies' then
      adding_dependency = false
    elseif adding_dependency then
      local clean_line = string.gsub(line, '[%+%\\%|]', ' ')
      local characters_before = assert(string.find(clean_line, '%s%w')) --- get all characters until -
      local deep_index = characters_before / space_indentation
      local dependency_id = Utils.uuid()
      deep_dependency[deep_index] = dependency_id
      local parent_dependency_id = deep_dependency[deep_index - 1]
      local text = string.sub(clean_line, characters_before + 1)
      local dependency = parse_dependency(text, dependency_id, parent_dependency_id, current_config)
      table.insert(dependencies, dependency)
    end
  end
  return dependencies
end

return DependencyTreeParser
