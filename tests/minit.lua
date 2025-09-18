vim.opt.rtp:append('.')

local plugins = {
  {
    path = os.getenv('PLENARY_DIR') or '/tmp/plenary.nvim',
    repo = 'https://github.com/nvim-lua/plenary.nvim',
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

vim.cmd('runtime plugin/plenary.vim')
require('plenary.busted')
