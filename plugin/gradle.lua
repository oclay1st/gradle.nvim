vim.api.nvim_create_user_command('Gradle', function()
  require('gradle').toggle_projects_view()
end, { desc = 'Toggle Gradle UI', bar = true, nargs = 0 })

vim.api.nvim_create_user_command('GradleExec', function()
  require('gradle').show_execution_view()
end, { desc = 'Show Gradle Ccommand Execution UI', bar = true, nargs = 0 })

vim.api.nvim_create_user_command('GradleInit', function()
  require('gradle').show_initializer_view()
end, { desc = 'Show Gradle Initializer UI', bar = true, nargs = 0 })
