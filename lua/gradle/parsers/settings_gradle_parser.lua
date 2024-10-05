local context_manager = require('plenary.context_manager')
local with = context_manager.with
local open = context_manager.open

---@class SettingGradle
---@field project_name string
---@field modules_names string[]

---@class SettingGradleParser
local SettingGradleParser = {}

SettingGradleParser.parse_file = function(settings_gradle_path)
  local project_name
  local modules_names = {}
  with(open(settings_gradle_path), function(reader)
    local content = reader:read('*a')
    project_name = string.match(content, "rootProject%.name = '(.+)'")
    for match in string.gmatch(content, "include%('(%w+)'%)") do
      table.insert(modules_names, match)
    end
  end)
  return {
    project_name = project_name,
    modules_names = modules_names,
  }
end

return SettingGradleParser
