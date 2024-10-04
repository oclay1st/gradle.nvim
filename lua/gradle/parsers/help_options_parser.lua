local HelpOptionsParser = {}

---Parse help options
---@param help_content_lines any
---@return Option[]
HelpOptionsParser.parse = function(help_content_lines)
  local options = {}
  for _, line in ipairs(help_content_lines) do
    if string.find(line, '^%-') then
      local opts, description = string.match(line, '(.+)%s%s(.+)')
      for opt in string.gmatch(opts, '[^%,]+') do
        table.insert(options, { name = vim.trim(opt), description = description })
      end
    end
  end
  return options
end

return HelpOptionsParser
