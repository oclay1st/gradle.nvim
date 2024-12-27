local NuiPopup = require('nui.popup')
local NuiLine = require('nui.line')
local event = require('nui.utils.autocmd').event
local highlights = require('gradle.config.highlights')
local GradleConfig = require('gradle.config')
local M = {}

local help_keys = {
  { key = 'c', desc = 'Create a new project' },
  { key = 'e', desc = 'Execute command' },
  { key = 'a', desc = '[Projects] analyze dependencies' },
  { key = 'g', desc = 'Select default gradle arguments' },
  { key = '/, s', desc = '[Dependencies] search' },
  { key = '<Ctrl>s', desc = '[Dependencies] switch window' },
  { key = '<Esc>, q', desc = 'Close' },
}

M.mount = function()
  local popup = NuiPopup({
    enter = true,
    ns_id = GradleConfig.namespace,
    relative = 'win',
    position = '50%',
    win_options = {
      cursorline = false,
      scrolloff = 2,
      sidescrolloff = 1,
      cursorcolumn = false,
      colorcolumn = '',
      spell = false,
      list = false,
      wrap = false,
    },
    border = {
      style = 'rounded',
      text = {
        top = ' Gradle Help? ',
        top_align = 'center',
      },
    },
    size = {
      width = '80%',
      height = '20%',
    },
  })

  popup:mount()

  popup:on(event.BufLeave, function()
    popup:unmount()
  end)
  popup:map('n', { '<esc>', 'q' }, function()
    popup:unmount()
  end)
  local keys_header = NuiLine()
  keys_header:append(string.format(' %14s', 'KEY(S)'), highlights.SPECIAL_TITLE)
  keys_header:append('    ', highlights.DIM_TEXT)
  keys_header:append('COMMAND', highlights.SPECIAL_TITLE)
  keys_header:render(popup.bufnr, GradleConfig.namespace, 2)
  for index, value in pairs(help_keys) do
    local line = NuiLine()
    line:append(string.format(' %14s', value.key), highlights.SPECIAL_TEXT)
    line:append(' -> ', highlights.DIM_TEXT)
    line:append(value.desc)
    line:render(popup.bufnr, GradleConfig.namespace, index + 2)
  end
end

return M
