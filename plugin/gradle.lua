vim.api.nvim_create_user_command('Gradle', function()
  require('gradle').toggle()
end, { desc = 'Toggles Gradle UI', bar = true, nargs = 0 })
