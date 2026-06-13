local FileUtils = require('gradle.utils.fs')

---@class SettingGradle
---@field project_name string
---@field modules_names string[]

---@class SettingGradleParser
local SettingGradleParser = {}
local project_name_pattern = "rootProject%.name%s*=%s*[%'" .. '%"' .. "](.-)[%'" .. '%"]'
local module_pattern = "include%s*%(?[%'" .. '%"' .. "](.+)[%'" .. '%"]'

SettingGradleParser.parse_file = function(settings_gradle_path)
  local project_name
  local module_names = {}
  local lines = FileUtils.read_lines(settings_gradle_path)
  for _, line in ipairs(lines) do
    if not project_name then
      project_name = string.match(line, project_name_pattern)
    end
    for modules_match in string.gmatch(line, module_pattern) do
      modules_match = string.gsub(modules_match, "[%'" .. '%"%(%):]', '')
      for module_match in string.gmatch(modules_match, '[^%,]+') do
        table.insert(module_names, vim.trim(module_match))
      end
    end
  end
  return { project_name = project_name, module_names = module_names }
end

return SettingGradleParser
