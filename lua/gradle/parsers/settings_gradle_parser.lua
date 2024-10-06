local context_manager = require('plenary.context_manager')
local with = context_manager.with
local open = context_manager.open

---@class SettingGradle
---@field project_name string
---@field modules_names string[]

---@class SettingGradleParser
local SettingGradleParser = {}
local project_name_pattern = "rootProject%.name%s*=%s*[%'" .. '%"' .. "](.+)[%'" .. '%"]'

SettingGradleParser.parse_file = function(settings_gradle_path)
  local project_name
  local modules_names = {}
  with(open(settings_gradle_path), function(reader)
    local content = reader:read('*a')
    project_name = string.match(content, project_name_pattern)
    for modules_match in string.gmatch(content, 'include%s*%((.*)%)') do
      modules_match = string.gsub(modules_match, "[%'" .. '%"]', '')
      for module_match in string.gmatch(modules_match, '[^%,]+') do
        table.insert(modules_names, vim.trim(module_match))
      end
    end
  end)
  return { project_name = project_name, modules_names = modules_names }
end

return SettingGradleParser
