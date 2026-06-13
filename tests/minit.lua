vim.opt.rtp:append('.')

local plugins = {
  {
    path = os.getenv('MINI_DIR') or '/tmp/mini.nvim',
    repo = 'https://github.com/echasnovski/mini.nvim',
  },
  {
    path = os.getenv('NUI_DIR') or '/tmp/nui.nvim',
    repo = 'https://github.com/MunifTanjim/nui.nvim',
  },
}

for _, plugin in ipairs(plugins) do
  if vim.fn.isdirectory(plugin.path) == 0 then
    vim.fn.system({ 'git', 'clone', plugin.repo, plugin.path })
  end
  vim.opt.rtp:append(plugin.path)
end

require('mini.test').setup({
  collect = {
    find_files = function()
      return vim.fn.globpath('tests', '**/*_spec.lua', true, true)
    end,
  },
})
