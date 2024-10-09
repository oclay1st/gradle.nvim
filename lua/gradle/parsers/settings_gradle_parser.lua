local context_manager = require('plenary.context_manager')
local with = context_manager.with
local open = context_manager.open

---@class SettingGradle
---@field project_name string
---@field modules_names string[]

---@class SettingGradleParser
local SettingGradleParser = {}
local project_name_pattern = "rootProject%.name%s*=%s*[%'" .. '%"' .. "](%w+)[%'" .. '%"]'
local sub_project_pattern = "include%s*%(?[%'" .. '%"' .. "](.+)[%'" .. '%"]'

SettingGradleParser.parse_file = function(settings_gradle_path)
  local project_name
  local sub_projects_names = {}
  with(open(settings_gradle_path), function(reader)
    for line in reader:lines() do
      if not project_name then
        project_name = string.match(line, project_name_pattern) or project_name
      end
      for sub_projects_match in string.gmatch(line, sub_project_pattern) do
        sub_projects_match = string.gsub(sub_projects_match, "[%'" .. '%"%(%):]', '')
        for sub_project_match in string.gmatch(sub_projects_match, '[^%,]+') do
          table.insert(sub_projects_names, vim.trim(sub_project_match))
        end
      end
    end
  end)
  return { project_name = project_name, sub_projects_names = sub_projects_names }
end

return SettingGradleParser
