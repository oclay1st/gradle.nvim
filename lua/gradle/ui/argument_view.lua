local Layout = require('nui.layout')
local Input = require('nui.input')
local Tree = require('nui.tree')
local Line = require('nui.line')
local Text = require('nui.text')
local Popup = require('nui.popup')
local icons = require('gradle.ui.icons')
local highlights = require('gradle.config.highlights')
local GradleConfig = require('gradle.config')

---@class Option
---@field name string
---@field description string

local options = {} ---@type Option[]

---@class ArgumentView
---@field private _input_component NuiInput
---@field private _options_component NuiPopup
---@field private _options_tree NuiTree
---@field private _prev_win number
---@field private _default_opts table
---@field private _layout NuiLayout
---@field private _input_prompt NuiText
local ArgumentView = {}
ArgumentView.__index = ArgumentView

---@return ArgumentView
function ArgumentView.new()
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
    _input_prompt = Text(icons.default.command .. '  Default Gradle Arguments ', 'SpecialChar'),
  }, ArgumentView)
end

local function create_option_node(option)
  return Tree.Node({
    arg = option.arg,
    value = option.value,
    text = option.arg .. '=' .. option.value,
    description = 'Enabled: ' .. tostring(option.enabled),
  })
end

---@private Load options nodes
function ArgumentView:_load_options_nodes()
  options = GradleConfig.options.gradle_default_args
  local options_nodes = {}
  for _, option in ipairs(options) do
    local node = create_option_node(option)
    table.insert(options_nodes, node)
  end

  self._options_tree:set_nodes(options_nodes)

  self._options_tree:render()
end

---@private Create the options tree list
function ArgumentView:_create_options_tree_list()
  if not self._options_tree or self._options_tree.bufnr ~= self._options_component.bufnr then
    self._options_tree = Tree({
      ns_id = GradleConfig.namespace,
      bufnr = self._options_component.bufnr,
      prepare_node = function(node)
        local line = Line()
        line:append(' ')
        if node.type == 'loading' then
          line:append(node.text, highlights.SPECIAL_TEXT)
          return line
        end
        line:append(icons.default.gradle, 'SpecialChar')
        line:append(' ' .. node.text)
        if node.description then
          line:append(' (' .. node.description .. ')', highlights.DIM_TEXT)
        end
        return line
      end,
    })
  end
  self._options_tree:add_node(Tree.Node({ text = '...Loading options', type = 'loading' }))
  self._options_tree:render()
  self:_load_options_nodes()
end
---@private On input change handler
---@param query string
function ArgumentView:_on_input_change(query)
  local current_node = self._options_tree:get_node()

  if query == '' and current_node and current_node.type == 'loading' then
    return
  end
  query = string.match(query, '%s$') and '' or query -- reset if end on space
  query = string.match(query, '(%S+)$') or '' -- take the last option to query
  vim.schedule(function()
    query = string.gsub(query, '%W', '%%%1')
    local nodes = {}
    for i = 1, #options do
      if
        query == ''
        or string.match(options[i].arg, query)
        or string.match(options[i].value, query)
      then
        local node = create_option_node(options[i])
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
---@private Create the input component
function ArgumentView:_create_input_component()
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
      style = { '╭', '─', '╮', '│', '│', '─', '│', '│' },
      text = {
        top = ' Set default command arguments ',
        top_align = 'center',
      },
    },
  }, {
    prompt = self._input_prompt,

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
  self._input_component:map('i', { '<enter>' }, move_next)
  self._input_component:map('n', { '<esc>', 'q' }, function()
    self._layout:unmount()
    if vim.api.nvim_win_is_valid(self._prev_win) then
      vim.api.nvim_set_current_win(self._prev_win)
    end
  end)
end

---@private Create the options component
function ArgumentView:_create_options_component()
  self._options_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    win_options = { cursorline = true },
    border = {
      style = { '', '', '', '│', '╯', '─', '╰', '│' },
    },
  }))
  self:_create_options_tree_list()
  self._options_component:map('n', '<enter>', function()
    local current_node = self._options_tree:get_node()

    if not current_node or current_node.type == 'loading' then
      return
    end
    vim.schedule(function()
      for i = 1, #GradleConfig.options.gradle_default_args do
        if
          GradleConfig.options.gradle_default_args[i].arg == current_node.arg
          and GradleConfig.options.gradle_default_args[i].value == current_node.value
        then
          if GradleConfig.options.gradle_default_args[i].enabled then
            GradleConfig.options.gradle_default_args[i].enabled = false
          else
            GradleConfig.options.gradle_default_args[i].enabled = true
          end
        end
      end
      self:_create_options_tree_list()
    end)
  end)
  self._options_component:map('n', 'i', function()
    vim.api.nvim_set_current_win(self._input_component.winid)
    vim.api.nvim_win_set_cursor(self._input_component.winid, { 1, 0 })
  end)
  self._options_component:map('n', { '<esc>', 'q' }, function()
    self._layout:unmount()
    vim.api.nvim_set_current_win(self._prev_win)
  end)
end

---@private Crete the layout
function ArgumentView:_create_layout()
  self._layout = Layout(
    {
      ns_id = GradleConfig.namespace,
      relative = 'editor',
      position = '50%',
      size = {
        width = '40%',
        height = '60%',
      },
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
function ArgumentView:mount()
  -- crete the list of options
  self:_create_options_component()
  -- create the input component
  self:_create_input_component()
  -- create the layout
  self:_create_layout()
end

return ArgumentView
