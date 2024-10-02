local Project = require('gradle.sources.project')
local TaskParser = {}

---Parse the tasks
---@param tasks_content_lines string[]
---@return Project.Task[]
TaskParser.parse = function(tasks_content_lines)
  local tasks = {} ---@type Project.Task[]
  local skipping_hyphen_line = false
  local current_group ---@type string
  local adding_tasks = false
  for _, line in ipairs(tasks_content_lines) do
    if skipping_hyphen_line then
      skipping_hyphen_line = false
      adding_tasks = true
    elseif adding_tasks then
      if not line or line == '\n' or line == '' then
        adding_tasks = false
      else
        local name, description = string.match(line, '(%w+)%s?%-?%s?(.*)')
        description = description ~= '' and description or nil
        local group = string.lower(current_group)
        table.insert(tasks, Project.Task(name, description, group))
      end
    else
      local task_group = string.match(line, '(.+) tasks$')
      if task_group then
        current_group = task_group
        skipping_hyphen_line = true
      end
    end
  end
  return tasks
end

return TaskParser
