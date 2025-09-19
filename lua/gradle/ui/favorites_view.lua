local Layout = require('nui.layout')
local Input = require('nui.input')
local Tree = require('nui.tree')
local Line = require('nui.line')
local Text = require('nui.text')
local Popup = require('nui.popup')
local Utils = require('gradle.utils')
local Sources = require('gradle.sources')
local Console = require('gradle.utils.console')
local CommandBuilder = require('gradle.utils.cmd_builder')
local highlights = require('gradle.config.highlights')
local GradleConfig = require('gradle.config')

---@class FavoriteOption
---@field name string
---@field type string
---@field selectable boolean
---@field project_id string
---@field extra any

local options = {} ---@type FavoriteOption[]

local node_type_props = {
  custom_command = {
    icon = GradleConfig.options.icons.command,
    name = 'command',
  },
  task = {
    icon = GradleConfig.options.icons.tool,
    name = 'task',
  },
  project = {
    icon = GradleConfig.options.icons.project,
    name = 'project',
  },
}

---@class FavoritesView
---@field private _input_component NuiInput
---@field private _options_component NuiPopup
---@field private _options_tree NuiTree
---@field private _prev_win number
---@field private _default_opts table
---@field private _layout NuiLayout
---@field private _input_prompt NuiText
---@field private _projects Project[]
---@field private _changed boolean
local FavoritesView = {}
FavoritesView.__index = FavoritesView

---@param projects Project[]
---@return FavoritesView
function FavoritesView.new(projects)
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
    _projects = projects,
    _changed = false,
    _input_prompt = Text(GradleConfig.options.icons.search .. ' ', highlights.SPECIAL),
  }, FavoritesView)
end

---@private Lookup for a project inside a list of projects and sub-projects (modules)
---@param id string
---@return Project
function FavoritesView:_lookup_project(id)
  local project ---@type Project
  local function _lookup(projects)
    for _, item in ipairs(projects) do
      if item.id == id then
        project = item
      end
      _lookup(item.modules)
    end
  end
  _lookup(self._projects)
  return assert(project, 'Project not found')
end

---Create a new option node
---@param option FavoriteOption
---@return NuiTree.Node
local function create_option_node(option)
  return Tree.Node({
    id = Utils.uuid(),
    text = option.name,
    type = option.type,
    project_id = option.project_id,
    selectable = option.selectable,
    extra = option.extra,
  })
end

---Create option
---@param projects Project[]
local function create_options(projects)
  for _, project in ipairs(projects) do
    if #project.favorites > 0 then
      table.insert(options, {
        name = project.name,
        type = 'project',
        selectable = false,
        project_id = project.id,
        extra = {},
      })
      for _, item in ipairs(project.favorites) do
        table.insert(options, {
          name = item.name,
          type = item.type,
          selectable = true,
          project_id = project.id,
          extra = item,
        })
      end
    end
    if #project.modules ~= 0 then
      create_options(project.modules)
    end
  end
end

---@private Load options nodes
function FavoritesView:_load_options_nodes()
  options = {}
  create_options(self._projects)
  local options_nodes = {}
  for _, option in ipairs(options) do
    local node = create_option_node(option)
    table.insert(options_nodes, node)
  end
  self._options_tree:set_nodes(options_nodes)
  self._options_tree:render()
end

---@private Create the options tree list
function FavoritesView:_create_options_tree_list()
  if not self._options_tree or self._options_tree.bufnr ~= self._options_component.bufnr then
    self._options_tree = Tree({
      ns_id = GradleConfig.namespace,
      bufnr = self._options_component.bufnr,
      prepare_node = function(node)
        local line = Line()
        local props = node_type_props[node.type]
        line:append(' ')
        if node.type == 'loading' then
          line:append(node.text, highlights.SPECIAL)
          return line
        end
        if node.type == 'custom_command' or node.type == 'task' then
          line:append(' - ' .. props.icon .. ' ', highlights.SPECIAL)
          line:append(node.text)
          line:append(' (' .. props.name, highlights.COMMENT)
          if node.extra and node.extra.description then
            line:append(' - ' .. node.extra.description, highlights.COMMENT)
          end
          line:append(')', highlights.COMMENT)
        else
          line:append(props.icon .. ' ', highlights.SPECIAL)
          line:append(node.text)
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
function FavoritesView:_on_input_change(query)
  local current_node = self._options_tree:get_node()

  if query == '' and current_node and current_node.type == 'loading' then
    return
  end
  query = string.match(query, '%s$') and '' or query -- reset if end on space
  query = string.match(query, '(%S+)$') or '' -- take the last option to query
  vim.schedule(function()
    query = string.gsub(query, '%W', '%%%1')
    local nodes = {}
    local _options = {}
    for i = 1, #options do
      if
        query == ''
        or options[i].type == 'project'
        or string.match(options[i].name, query)
        or string.match(options[i].extra.description or '', query)
      then
        table.insert(_options, options[i])
      end
    end
    -- only preserve options of type `project` with children
    for index, _option in ipairs(_options) do
      if
        _option.type ~= 'project'
        or (index < #_options and _option.project_id == _options[index + 1].project_id)
      then
        local node = create_option_node(_options[index])
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
function FavoritesView:_create_input_component()
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
      text = {
        top = ' Favorite Gradle Commands ',
        top_align = 'center',
      },
      style = GradleConfig.options.favorite_commands_view.input_win.border.style,
      padding = GradleConfig.options.favorite_commands_view.input_win.border.padding
        or { 0, 0, 0, 0 },
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

---Execute command
---@param node NuiTree.Node
---@param project Project
function FavoritesView:_execute_custom_command_node(node, project)
  local command = CommandBuilder.build_gradle_cmd(project.root_path, node.extra.cmd_args)
  local show_output = GradleConfig.options.console.show_command_execution
  Console.execute_command(command.cmd, command.args, show_output)
end

---Execute task
---@param node NuiTree.Node
---@param project Project
function FavoritesView:_execute_task_node(node, project)
  local command = CommandBuilder.build_gradle_cmd(project.root_path, node.extra.cmd_args)
  local show_output = GradleConfig.options.console.show_task_execution
  Console.execute_command(command.cmd, command.args, show_output)
end

---@private Create the options component
function FavoritesView:_create_options_component()
  self._options_component = Popup(vim.tbl_deep_extend('force', self._default_opts, {
    win_options = { cursorline = true, winhighlight = highlights.DEFAULT_WIN_HIGHLIGHT },
    border = {
      style = GradleConfig.options.favorite_commands_view.options_win.border.style,
      padding = GradleConfig.options.favorite_commands_view.options_win.border.padding
        or { 0, 0, 0, 0 },
    },
  }))
  self:_create_options_tree_list()
  self._options_component:map('n', '<enter>', function()
    local current_node = self._options_tree:get_node()
    if not current_node or current_node.type == 'loading' or current_node.type == 'project' then
      return
    end
    local project = self:_lookup_project(current_node.project_id)
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(self._prev_win) then
        vim.api.nvim_set_current_win(self._prev_win)
      end
      self._layout:unmount()
      if current_node.type == 'custom_command' then
        self:_execute_custom_command_node(current_node, project)
      elseif current_node.type == 'task' then
        self:_execute_task_node(current_node, project)
      end
    end)
  end)
  self._options_component:map('n', 'i', function()
    vim.api.nvim_set_current_win(self._input_component.winid)
    vim.api.nvim_win_set_cursor(self._input_component.winid, { 1, 0 })
  end)
  self._options_component:map('n', 'dd', function()
    local current_node = self._options_tree:get_node()
    if not current_node or current_node.type == 'loading' or current_node.type == 'project' then
      return
    end
    local project = self:_lookup_project(current_node.project_id)
    Sources.remove_favorite_command(current_node.extra, project)
    self:_load_options_nodes()
    self._changed = true
  end)
  self._options_component:map('n', { '<esc>', 'q' }, function()
    self._layout:unmount()
    if vim.api.nvim_win_is_valid(self._prev_win) then
      vim.api.nvim_set_current_win(self._prev_win)
    end
    if self._changed then
      require('gradle').refresh_projects_view(self._projects)
    end
  end)
end

---@private Crete the layout
function FavoritesView:_create_layout()
  self._layout = Layout(
    {
      ns_id = GradleConfig.namespace,
      relative = 'editor',
      position = '50%',
      size = GradleConfig.options.favorite_commands_view.size,
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
function FavoritesView:mount()
  -- crete the list of options
  self:_create_options_component()
  -- create the input component
  self:_create_input_component()
  -- create the layout
  self:_create_layout()
end

return FavoritesView
