local Input = require('nui.input')
local Tree = require('nui.tree')
local Line = require('nui.line')
local Popup = require('nui.popup')
local Path = require('plenary.path')
local event = require('nui.utils.autocmd').event
local highlights = require('gradle.config.highlights')
local GradleConfig = require('gradle.config')
local Console = require('gradle.utils.console')
local CommandBuilder = require('gradle.utils.cmd_builder')
local Utils = require('gradle.utils')

---@class InitializerView
---@field private _dsl_component NuiPopup
---@field private _dsl string
---@field private _project_package_component NuiInput
---@field private _project_package string
---@field private _project_name_component NuiInput
---@field private _project_name string
---@field private _java_version_component NuiPopup
---@field private _java_version string
---@field private _test_framework_component NuiPopup
---@field private _test_framework string
---@field private _directory_component NuiPopup
---@field private _directory string
---@field private _default_opts table
---@field private _prev_win number
local InitializerView = {}
InitializerView.__index = InitializerView

---@return InitializerView
function InitializerView.new()
  local buf_options = {
    buftype = 'nofile',
    swapfile = false,
    filetype = 'gradle',
    undolevels = -1,
  }
  local win_options = {
    colorcolumn = '',
    signcolumn = 'no',
    number = false,
    relativenumber = false,
    spell = false,
    list = false,
  }
  return setmetatable({
    _default_opts = {
      ns_id = GradleConfig.namespace,
      position = '50%',
      size = { height = '100%', width = 50 },
      buf_options = buf_options,
      win_options = win_options,
      border = {
        style = 'rounded',
        text = {
          top_align = 'center',
        },
      },
    },
    _prev_win = vim.api.nvim_get_current_win(),
  }, InitializerView)
end

---@private Create project name component
function InitializerView:_create_project_name_component()
  self._project_name_component = Input(
    vim.tbl_deep_extend('force', self._default_opts, {
      enter = true,
      border = { text = { top = ' Create Gradle Project - Name 1/6 ' } },
    }),
    {
      prompt = '> ',
      on_change = function(value)
        self._project_name = value
      end,
    }
  )
  local function submit()
    if vim.fn.trim(self._project_name) == '' then
      vim.notify('Empty project name', vim.log.levels.ERROR)
    else
      vim.cmd('stopinsert')
      vim.schedule(function()
        self._project_name_component:hide()
        self._project_package_component:show()
      end)
    end
  end
  self._project_name_component:map('n', '<CR>', submit)
  self._project_name_component:map('i', '<CR>', submit)
  self._project_name_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end, { noremap = true })
  self._project_name_component:on(event.BufLeave, function()
    self:_quit_all()
  end)
end

---@private Create project package component
function InitializerView:_create_project_package_component()
  self._project_package_component = Input(
    vim.tbl_deep_extend('force', self._default_opts, {
      enter = true,
      size = { height = 1 },
      border = { text = { top = ' Create Gradle Project - Package 2/6 ' } },
    }),
    {
      default_value = GradleConfig.options.initializer_view.default_package or '',
      prompt = '> ',
      on_change = function(value)
        self._project_package = value
      end,
    }
  )
  local function submit()
    if not string.match(self._project_package, '(%w+)%.(%w+)') then
      vim.notify('Bad package name format', vim.log.levels.ERROR)
    else
      vim.cmd('stopinsert')
      vim.schedule(function()
        self._project_package_component:hide()
        self._java_version_component:show()
      end)
    end
  end
  self._project_package_component:map('n', '<CR>', submit)
  self._project_package_component:map('i', '<CR>', submit)
  self._project_package_component:map('n', '<bs>', function()
    self._project_package_component:hide()
    self._project_name_component:show()
  end)
  self._project_package_component:on(event.BufLeave, function()
    self:_quit_all()
  end)
  self._project_package_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end, { noremap = true })
end

---@private Create the Java component
function InitializerView:_create_java_version_component()
  self._java_version_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    enter = true,
    size = { height = 3 },
    win_options = { cursorline = true },
    border = { text = { top = ' Create Gradle Project - Java Version 3/6 ' } },
  }))
  local options_tree = Tree({
    ns_id = GradleConfig.namespace,
    bufnr = self._java_version_component.bufnr,
    prepare_node = function(node)
      local line = Line()
      line:append(' ')
      line:append(' ' .. node.text)
      return line
    end,
  })
  local nodes = {
    Tree.Node({ text = ' Java 21 ', value = 21 }),
    Tree.Node({ text = ' Java 17 ', value = 17 }),
    Tree.Node({ text = ' Java 8 ', value = 8 }),
  }
  options_tree:set_nodes(nodes)
  options_tree:render()
  self._java_version_component:on(event.BufLeave, function()
    self:_quit_all()
  end)
  self._java_version_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end)
  self._java_version_component:map('n', { '<enter>' }, function()
    local current_node = options_tree:get_node()
    if not current_node then
      return
    end
    self._java_version = current_node.value
    self._java_version_component:hide()
    self._dsl_component:show()
  end)
  self._java_version_component:map('n', '<bs>', function()
    self._project_package_component:show()
    self._java_version_component:hide()
  end)
end

---@private Create the DSL component
function InitializerView:_create_dsl_component()
  self._dsl_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    enter = true,
    size = { height = 2 },
    win_options = { cursorline = true },
    border = { text = { top = ' Create Gradle Project - DSL 4/6 ' } },
  }))
  local options_tree = Tree({
    ns_id = GradleConfig.namespace,
    bufnr = self._dsl_component.bufnr,
    prepare_node = function(node)
      local line = Line()
      line:append(' ')
      line:append(' ' .. node.text)
      return line
    end,
  })
  local nodes = {
    Tree.Node({ text = 'Kotlin', value = 'kotlin' }),
    Tree.Node({ text = 'Groovy', value = 'groovy' }),
  }
  options_tree:set_nodes(nodes)
  options_tree:render()
  self._dsl_component:on(event.BufLeave, function()
    self:_quit_all()
  end)
  self._dsl_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end, { noremap = true, nowait = true })
  self._dsl_component:map('n', { '<enter>' }, function()
    local current_node = options_tree:get_node()
    if not current_node then
      return
    end
    self._dsl = current_node.value
    self._dsl_component:hide()
    self._test_framework_component:show()
  end, { noremap = true })
  self._dsl_component:map('n', '<bs>', function()
    self._dsl_component:hide()
    self._java_version_component:show()
  end)
end

---@private Create the test framework component
function InitializerView:_create_test_framework_component()
  self._test_framework_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    enter = true,
    size = { height = 3 },
    win_options = { cursorline = true },
    border = { text = { top = '  Create Gradle Project - Test Framework 5/6 ' } },
  }))
  local options_tree = Tree({
    ns_id = GradleConfig.namespace,
    bufnr = self._test_framework_component.bufnr,
    prepare_node = function(node)
      local line = Line()
      line:append(' ')
      line:append(' ' .. node.text)
      return line
    end,
  })
  local nodes = {
    Tree.Node({ text = 'Junit 5', value = 'junit-jupiter' }),
    Tree.Node({ text = 'Junit 4', value = 'junit' }),
    Tree.Node({ text = 'Spock', value = 'spock' }),
  }
  options_tree:set_nodes(nodes)
  options_tree:render()
  self._test_framework_component:on(event.BufLeave, function()
    self:_quit_all()
  end)
  self._test_framework_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end)
  self._test_framework_component:map('n', { '<enter>' }, function()
    local current_node = options_tree:get_node()
    if not current_node then
      return
    end
    self._test_framework = current_node.value
    self._test_framework_component:hide()
    self._directory_component:show()
  end)
  self._test_framework_component:map('n', '<bs>', function()
    self._test_framework_component:hide()
    self._dsl_component:show()
  end)
end

---@private Create the directory component
function InitializerView:_create_directory_component()
  self._directory_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    enter = true,
    size = { height = #GradleConfig.options.initializer_view.workspaces },
    win_options = { cursorline = true },
    border = { text = { top = ' Create Gradle Project - Directory 6/6 ' } },
  }))
  local options_tree = Tree({
    ns_id = GradleConfig.namespace,
    bufnr = self._directory_component.bufnr,
    prepare_node = function(node)
      local line = Line()
      line:append(' ' .. node.text)
      line:append(' ' .. node.path, highlights.COMMENT)
      return line
    end,
  })
  local nodes = {}
  for _, workspace in ipairs(GradleConfig.options.initializer_view.workspaces) do
    table.insert(nodes, Tree.Node({ text = workspace.name, path = workspace.path }))
  end
  options_tree:set_nodes(nodes)
  options_tree:render()
  self._directory_component:on(event.BufWinEnter, function()
    for _, node in ipairs(options_tree:get_nodes()) do
      node.path = node.path .. Path.path.sep .. self._project_name
    end
    options_tree:render()
  end)
  self._directory_component:on(event.BufLeave, function()
    self:_quit_all()
  end)
  self._directory_component:map('n', { '<esc>', 'q' }, function()
    self:_quit_all(true)
  end)
  self._directory_component:map('n', { '<enter>' }, function()
    local current_node = options_tree:get_node()
    if not current_node then
      return
    end
    self._directory = current_node.path
    self:_create_project()
    self:_quit_all(true)
    vim.api.nvim_set_current_win(self._prev_win)
  end)
  self._directory_component:map('n', '<bs>', function()
    self._directory_component:hide()
    self._test_framework_component:show()
  end)
end

function InitializerView:_create_project()
  ---@type Path
  local directory = Path:new(self._directory)
  directory:mkdir()
  local _callback = function(state)
    vim.schedule(function()
      if state == Utils.SUCCEED_STATE then
        local choice = vim.fn.confirm(
          'Project created successfully \nDo you want to switch to the New Project?',
          '&Yes\n&No'
        )
        if choice == 1 then
          vim.api.nvim_set_current_dir(directory:absolute())
          require('gradle').refresh()
        end
      elseif state == Utils.FAILED_STATE then
        vim.notify('Error creating  project: ' .. vim.trim(self._project_name))
      end
    end)
  end
  vim.notify('Creating a new Gradle Project...')
  local command = CommandBuilder.create_project(
    vim.trim(self._project_name),
    vim.trim(self._project_package),
    self._java_version,
    self._dsl,
    self._test_framework,
    self._directory
  )
  local show_output = GradleConfig.options.console.show_project_create_execution
  Console.execute_command(command.cmd, command.args, show_output, _callback)
end

---@private Quit all
function InitializerView:_quit_all(force)
  local buf = vim.api.nvim_get_current_buf()
  local wins = {
    self._dsl_component,
    self._project_package_component,
    self._project_name_component,
    self._java_version_component,
    self._test_framework_component,
    self._directory_component,
  }
  local outside = true
  for _, win in ipairs(wins) do
    if win.bufnr == buf then
      outside = false
    end
  end
  if outside or force then
    for _, win in ipairs(wins) do
      win:unmount()
    end
  end
end

---Mount the window view
function InitializerView:mount()
  -- create the dsl menu picker
  self:_create_dsl_component()
  -- create the package input
  self:_create_project_package_component()
  -- create the name input
  self:_create_project_name_component()
  -- create the java version
  self:_create_java_version_component()
  -- create the test framework
  self:_create_test_framework_component()
  -- create the directory
  self:_create_directory_component()
  -- mount the first component
  self._project_name_component:show()
end

return InitializerView
