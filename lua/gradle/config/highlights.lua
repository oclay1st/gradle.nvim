local M = {}

M.NORMAL = 'GradleNormal'
M.NORMAL_FLOAT = 'GradleNormalFloat'
M.CURSOR_LINE = 'GradleCursorLine'
M.SPECIAL = 'GradleSpecial'
M.COMMENT = 'GradleComment'
M.TITLE = 'GradleSpecial'
M.ERROR = 'GradleError'
M.INFO = 'GradleInfo'
M.WARN = 'GradleWarn'

local highlights = {
  {
    name = M.NORMAL,
    config = { default = true, link = 'Normal' },
  },
  {
    name = M.NORMAL_FLOAT,
    config = { default = true, link = 'NormalFloat' },
  },
  {
    name = M.CURSOR_LINE,
    config = { default = true, link = 'CursorLine' },
  },
  {
    name = M.SPECIAL,
    config = { default = true, link = 'Special' },
  },
  {
    name = M.COMMENT,
    config = { default = true, link = 'Comment' },
  },
  {
    name = M.TITLE,
    config = { default = true, link = 'Title' },
  },
  {
    name = M.ERROR,
    config = { default = true, italic = true, link = 'DiagnosticError' },
  },
  {
    name = M.WARN,
    config = { default = true, italic = true, link = 'DiagnosticWarn' },
  },
  {
    name = M.INFO,
    config = { default = true, italic = true, link = 'DiagnosticInfo' },
  },
}

M.DEFAULT_WIN_HIGHLIGHT =
  'Normal:GradleNormal,NormalFloat:GradleNormalFloat,CursorLine:GradleCursorLine'

function M.setup()
  for _, v in ipairs(highlights) do
    vim.api.nvim_set_hl(0, v.name, v.config)
  end
end

return M
