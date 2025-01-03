local Layout = require('nui.layout')
local Input = require('nui.input')
local Tree = require('nui.tree')
local Line = require('nui.line')
local Text = require('nui.text')
local Popup = require('nui.popup')
local Sources = require('gradle.sources')
local highlights = require('gradle.config.highlights')
local GradleConfig = require('gradle.config')
local Utils = require('gradle.utils')
local Console = require('gradle.utils.console')

---@class Option
---@field name string
---@field description string

local options = {} ---@type Option[]

---@class ExecutionView
---@field private _input_component NuiInput
---@field private _options_component NuiPopup
---@field private _options_tree NuiTree
---@field private _prev_win number
---@field private _default_opts table
---@field private _layout NuiLayout
---@field private _input_prompt NuiText
local ExecutionView = {}
ExecutionView.__index = ExecutionView

---@return ExecutionView
function ExecutionView.new()
  return setmetatable({
    _default_opts = {
      ns_id = GradleConfig.namespace,
      buf_options = {
        buftype = 'nofile',
        swapfile = false,
        filetype = 'gradle',
        undolevels = -1,
      },
      win_options = {
        colorcolumn = '',
        signcolumn = 'no',
        number = false,
        relativenumber = false,
        spell = false,
        list = false,
      },
    },
    _prev_win = vim.api.nvim_get_current_win(),
    _input_prompt = Text(GradleConfig.options.icons.command .. '  gradle ', highlights.SPECIAL),
  }, ExecutionView)
end

---Create a option node
---@param option Option
local function create_option_node(option)
  return Tree.Node({ text = option.name, name = option.name, description = option.description })
end

---@private Load options nodes
---@param force? boolean
---@param on_success? function(options)
function ExecutionView:_load_options_nodes(force, on_success)
  self._options_tree:add_node(Tree.Node({ text = '...Loading options', type = 'loading' }))
  self._options_tree:render()
  Sources.load_help_options(force, function(state, help_options)
    vim.schedule(function()
      if state == Utils.SUCCEED_STATE then
        table.sort(help_options, function(a, b)
          return a.name < b.name
        end)
        options = help_options
        local options_nodes = {}
        for _, option in ipairs(options) do
          local node = create_option_node(option)
          table.insert(options_nodes, node)
        end
        self._options_tree:set_nodes(options_nodes)
        self._options_tree:render()
        if on_success then
          on_success(help_options)
        end
      end
    end)
  end)
end

---@private Create the options tree list
function ExecutionView:_create_options_tree_list()
  self._options_tree = Tree({
    ns_id = GradleConfig.namespace,
    bufnr = self._options_component.bufnr,
    prepare_node = function(node)
      local line = Line()
      line:append(' ')
      if node.type == 'loading' then
        line:append(node.text, highlights.SPECIAL)
        return line
      end
      line:append(GradleConfig.options.icons.gradle, highlights.SPECIAL)
      line:append(' ' .. node.text)
      if node.description then
        line:append(' (' .. node.description .. ')', highlights.COMMENT)
      end
      return line
    end,
  })
  self:_load_options_nodes()
end

---@private On input change handler
---@param query string
function ExecutionView:_on_input_change(query)
  local current_node = self._options_tree:get_node()
  if query == '' and current_node and current_node.type == 'loading' then
    return
  end
  query = string.match(query, '%s$') and '' or query -- reset if end on space
  query = string.match(query, '(%S+)$') or '' -- take the last option to query
  vim.schedule(function()
    query = string.gsub(query, '%W', '%%%1')
    local nodes = {}
    for _, option in ipairs(options) do
      if query == '' or string.match(option.name, query) then
        local node = create_option_node(option)
        table.insert(nodes, node)
      end
    end
    self._options_tree:set_nodes(nodes)
    self._options_tree:render()
    if self._options_component.winid then
      vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
    end
  end)
end

function ExecutionView:_force_options_reload()
  self:_load_options_nodes(true, function()
    vim.notify('Options reloaded successfully')
  end)
end

---@private Create the input component
function ExecutionView:_create_input_component()
  self._input_component = Input({
    enter = true,
    ns_id = GradleConfig.namespace,
    relative = 'win',
    position = {
      row = 1,
      col = 0,
    },
    size = {
      width = '100%',
      height = 20,
    },
    zindex = 60,
    border = {
      text = { top = ' Execute Gradle Command ', top_align = 'center' },
      style = GradleConfig.options.execution_view.input_win.border.style,
      padding = GradleConfig.options.execution_view.input_win.border.padding or { 0, 0, 0, 0 },
    },
  }, {
    prompt = self._input_prompt,
    on_submit = function(value)
      local args = {}
      for item in string.gmatch(value, '[^%s]+') do
        table.insert(args, item)
      end
      Console.execute_command(GradleConfig.options.gradle_executable, args, true, function(state)
        vim.schedule(function()
          if state == Utils.FAILED_STATE then
            vim.notify('Failed command execution', vim.log.levels.ERROR)
          end
        end)
      end)
    end,
    on_change = function(query)
      self:_on_input_change(query)
    end,
  })
  local function move_next()
    vim.api.nvim_set_current_win(self._options_component.winid)
    vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
  end
  self._input_component:map('i', { '<C-n>', '<Down>' }, move_next)
  self._input_component:map('n', { 'j', '<C-n>', '<Down>' }, move_next)
  self._input_component:map('n', { '<esc>', 'q' }, function()
    self._layout:unmount()
    if vim.api.nvim_win_is_valid(self._prev_win) then
      vim.api.nvim_set_current_win(self._prev_win)
    end
  end)
  self._input_component:map('n', { '<c-r>' }, function()
    self:_force_options_reload()
  end)
end

---@private Create the options component
function ExecutionView:_create_options_component()
  self._options_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    win_options = { cursorline = true, winhighlight = highlights.DEFAULT_WIN_HIGHLIGHT },
    border = {
      style = GradleConfig.options.execution_view.options_win.border.style,
      padding = GradleConfig.options.execution_view.options_win.border.padding or { 0, 0, 0, 0 },
    },
  }))
  self:_create_options_tree_list()
  self._options_component:map('n', '<enter>', function()
    local current_node = self._options_tree:get_node()
    if not current_node or current_node.type == 'loading' then
      return
    end
    vim.schedule(function()
      local line_text = vim.api.nvim_buf_get_lines(self._input_component.bufnr, 0, 1, false)[1]
      line_text = string.gsub(line_text, '(%S+)$', '')
      local text = line_text .. current_node.name
      vim.api.nvim_buf_set_lines(self._input_component.bufnr, 0, 1, false, { text })
      self._input_prompt:highlight(self._input_component.bufnr, GradleConfig.namespace, 1, 0)
      vim.api.nvim_set_current_win(self._input_component.winid)
      vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
      vim.api.nvim_win_set_cursor(self._input_component.winid, { 1, string.len(text) })
      vim.cmd('startinsert!')
    end)
  end)
  self._options_component:map('n', { 'i' }, function()
    vim.api.nvim_win_set_cursor(self._options_component.winid, { 1, 0 })
    vim.api.nvim_set_current_win(self._input_component.winid)
    vim.api.nvim_win_set_cursor(self._input_component.winid, { 1, 0 })
    vim.cmd('startinsert!')
  end)
  self._options_component:map('n', { '<esc>', 'q' }, function()
    self._layout:unmount()
    vim.api.nvim_set_current_win(self._prev_win)
  end)

  self._options_component:map('n', { '<c-r>' }, function()
    self:_force_options_reload()
  end)
end

---@private Crete the layout
function ExecutionView:_create_layout()
  self._layout = Layout(
    {
      ns_id = GradleConfig.namespace,
      relative = 'editor',
      position = '50%',
      size = GradleConfig.options.execution_view.size,
    },
    Layout.Box({
      Layout.Box(self._input_component, { size = { height = 1, width = '100%' } }),
      Layout.Box(self._options_component, { size = '100%' }),
    }, { dir = 'col' })
  )

  self._layout:mount()
  for _, component in pairs({ self._input_component, self._options_component }) do
    component:on('BufLeave', function()
      vim.schedule(function()
        local current_bufnr = vim.api.nvim_get_current_buf()
        for _, p in pairs({ self._input_component, self._options_component }) do
          if p.bufnr == current_bufnr then
            return
          end
        end
        self._layout:unmount()
      end)
    end)
  end
end

---Mount the window view
function ExecutionView:mount()
  -- crete the list of options
  self:_create_options_component()
  -- create the input component
  self:_create_input_component()
  -- create the layout
  self:_create_layout()
end

return ExecutionView
