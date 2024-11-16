#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = '.tests'

local ok, bootstrap = pcall(
  vim.fn.system,
  'curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua'
)
if ok then
  load(bootstrap)()
else
  vim.opt.rtp:prepend(vim.env.LAZY_STDPATH)
end

-- Setup lazy.nvim
require('lazy.minit').busted({
  spec = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
  },
})
