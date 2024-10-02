local NuiTree = require('nui.tree')
local NuiLine = require('nui.line')
local NuiText = require('nui.text')
local Popup = require('nui.popup')
local Input = require('nui.input')
local Layout = require('nui.layout')
local event = require('nui.utils.autocmd').event
local highlights = require('gradle.highlights')
local GradleConfig = require('gradle.config')
local icons = require('gradle.ui.icons')

local M = {}

---Create dependency node
---@param dependency Project.Dependency
---@return NuiTree.Node
local function create_tree_node(dependency)
  return NuiTree.Node({
    id = dependency.id,
    text = dependency.name .. ':' .. dependency.version,
    name = dependency.group .. ':' .. dependency.name,
    configuration = dependency.configuration,
    is_duplicate = dependency.is_duplicate,
    has_conflict = dependency.conflict_version and true or false,
    conflict_version = dependency.conflict_version,
  })
end

---Create the node list of dependencies
---@param dependencies Project.Dependency[]
local function create_dependencies_list_nodes(dependencies)
  local nodes_indexes = {}
  for _, dependency in ipairs(dependencies) do
    local name = dependency.group .. ':' .. dependency.name
    if nodes_indexes[name] == nil then
      local node = create_tree_node(dependency)
      nodes_indexes[name] = node
    else
      nodes_indexes[name].configuration = 'multiple scopes'
    end
    if dependency.conflict_version then
      nodes_indexes[name].has_conflict = true
    end
    if dependency.is_duplicate then
      nodes_indexes[name].is_duplicate = true
    end
  end
  local nodes = vim.tbl_values(nodes_indexes)
  table.sort(nodes, function(a, b)
    return string.lower(a.text) < string.lower(b.text)
  end)
  return nodes
end

local function create_dependencies_tree(bufnr)
  return NuiTree({
    ns_id = GradleConfig.namespace,
    bufnr = bufnr,
    prepare_node = function(node)
      local line = NuiLine()
      line:append(' ')
      local icon = node.has_conflict and icons.default.warning or icons.default.package
      local icon_highlight = node.has_conflict and 'DiagnosticWarn' or 'SpecialChar'
      line:append(icon .. ' ', icon_highlight)
      line:append(node.text)
      if node.configuration then
        line:append(' (' .. node.configuration .. ')', highlights.DIM_TEXT)
      end
      return line
    end,
  })
end

local function create_dependency_usages_tree(bufnr)
  return NuiTree({
    ns_id = GradleConfig.namespace,
    bufnr = bufnr,
    prepare_node = function(node)
      local line = NuiLine()
      line:append(' ' .. string.rep('  ', node:get_depth() - 1))
      if node:has_children() then
        line:append(node:is_expanded() and ' ' or ' ', 'SpecialChar')
      else
        line:append('  ')
      end
      local icon = icons.default.package
      local icon_highlight = 'SpecialChar'
      if node.has_conflict and not node:has_children() then
        icon_highlight = 'DiagnosticWarn'
        icon = icons.default.warning
      end
      line:append(icon .. ' ', icon_highlight)
      if node.is_duplicate and not node:has_children() then
        line:append(node.text, highlights.DIM_TEXT)
      else
        line:append(node.text)
      end
      if node.configuration then
        line:append(' (' .. node.configuration .. ')', highlights.DIM_TEXT)
      end
      if node.conflict_version and not node:has_children() then
        line:append(' conflict with ' .. node.conflict_version, highlights.ERROR_TEXT)
      end
      return line
    end,
  })
end

---Filter the related dependencies by name
---@param name string
---@param indexed_dependencies table
local function filter_dependencies(name, indexed_dependencies)
  local filtered_dependencies = {}
  local filtered = {}
  for _, dependency in pairs(indexed_dependencies) do
    if name == dependency.group .. ':' .. dependency.name then
      local pos_to_insert = #filtered_dependencies + 1
      local id = dependency.id
      while id ~= nil and filtered[id] == nil do
        filtered[id] = 1
        table.insert(filtered_dependencies, pos_to_insert, indexed_dependencies[id])
        id = indexed_dependencies[id].parent_id
      end
    end
  end
  return filtered_dependencies
end

local function create_dependency_filter(wind_id, on_change)
  local win_height = vim.api.nvim_win_get_height(wind_id)
  local relative_row = win_height - 1
  local win_width = vim.api.nvim_win_get_width(wind_id)
  local input = Input({
    ns_id = GradleConfig.namespace,
    relative = 'win',
    position = {
      row = relative_row,
      col = 0,
    },
    size = {
      width = win_width,
    },
    zindex = 60,
    border = {
      style = 'rounded',
      text = {
        top = 'Filter',
        top_align = 'center',
      },
    },
  }, {
    prompt = NuiText(icons.default.search .. '  ', 'SpecialChar'),
    on_change = on_change,
  })

  input:on(event.BufLeave, function()
    input:unmount()
  end)

  input:map('n', { '<esc>', 'q' }, function()
    input:unmount()
  end)

  return input
end

---Create the component layout
---@param left_win NuiPopup
---@param right_win NuiPopup
local function create_layout(left_win, right_win)
  local prev_win = vim.api.nvim_get_current_win()
  local layout = Layout(
    {
      ns_id = GradleConfig.namespace,
      relative = 'editor',
      position = '50%',
      size = {
        width = '60%',
        height = '80%',
      },
    },
    Layout.Box({
      Layout.Box(left_win, { size = '50%' }),
      Layout.Box(right_win, { size = '50%' }),
    }, { dir = 'row' })
  )

  for _, win in pairs({ left_win, right_win }) do
    win:on(event.BufLeave, function()
      vim.schedule(function()
        local current_buf = vim.api.nvim_get_current_buf()
        for _, w in pairs({ left_win, right_win }) do
          if w.bufnr == current_buf then
            return
          end
        end
        layout:unmount()
        vim.api.nvim_set_current_win(prev_win)
      end)
    end)
    win:map('n', { '<esc>', 'q' }, function()
      layout:unmount()
      vim.api.nvim_set_current_win(prev_win)
    end)
  end
  return layout
end

---Mount component
---@param project_name string
---@param dependencies Project.Dependency[]
M.mount = function(project_name, dependencies)
  local default_win_opts = {
    ns_id = GradleConfig.namespace,
    win_options = {
      cursorline = true,
      scrolloff = 1,
      sidescrolloff = 1,
      cursorcolumn = false,
      colorcolumn = '',
      spell = false,
      list = false,
      wrap = false,
    },
    border = {
      style = 'rounded',
    },
  }
  --- Setup the dependencies win
  local dependencies_win_opts = vim.tbl_deep_extend('force', default_win_opts, {
    enter = true,
    border = { text = { top = ' Resolved Dependencies (' .. project_name .. ') ' } },
  })
  local dependencies_win = Popup(dependencies_win_opts)
  local dependencies_tree = create_dependencies_tree(dependencies_win.bufnr)
  local dependencies_nodes = create_dependencies_list_nodes(dependencies)
  dependencies_tree:set_nodes(dependencies_nodes)
  dependencies_tree:render()

  --- Setup the dependency usages win
  local dependency_usages_win_opts = vim.tbl_deep_extend('force', default_win_opts, {
    border = { text = { top = ' Dependency Usages ' } },
  })
  local dependency_usages_win = Popup(dependency_usages_win_opts)
  local dependency_usages_tree = create_dependency_usages_tree(dependency_usages_win.bufnr)
  local indexed_dependencies = {}
  for _, item in ipairs(dependencies) do
    indexed_dependencies[item.id] = item
  end

  dependencies_win:on(event.CursorMoved, function()
    local current_node = dependencies_tree:get_node()
    if current_node == nil then
      return
    end
    local filtered_dependencies = filter_dependencies(current_node.name, indexed_dependencies)
    dependency_usages_tree:set_nodes({})
    for _, dependency in pairs(filtered_dependencies) do
      local parent_id = dependency.parent_id and '-' .. dependency.parent_id or nil
      local node = create_tree_node(dependency)
      dependency_usages_tree:add_node(node, parent_id)
      if parent_id then
        dependency_usages_tree:get_node(parent_id):expand()
      end
    end
    dependency_usages_tree:render()
  end)

  dependency_usages_win:map('n', '<enter>', function()
    local node = dependency_usages_tree:get_node()
    if node == nil then
      return
    end
    local updated = false
    if node:is_expanded() then
      updated = node:collapse() or updated
    else
      updated = node:expand() or updated
    end
    if updated then
      dependency_usages_tree:render()
    end
  end)

  ---Setup the layout
  local layout = create_layout(dependencies_win, dependency_usages_win)
  layout:mount()
  ---Setup the filter
  dependencies_win:map('n', { '/', 's' }, function()
    local filter = create_dependency_filter(dependencies_win.winid, function(search)
      local nodes = vim.tbl_filter(function(node)
        return string.find(node.name, search) and true or false
      end, dependencies_nodes)
      vim.schedule(function()
        vim.api.nvim_win_set_cursor(dependencies_win.winid, { 1, 0 })
        dependencies_tree:set_nodes(nodes)
        dependencies_tree:render()
      end)
    end)
    filter:mount()
  end)
  dependency_usages_win:map('n', { '<c-s>' }, function()
    vim.api.nvim_set_current_win(dependencies_win.winid)
  end)
  dependencies_win:map('n', { '<c-s>' }, function()
    vim.api.nvim_set_current_win(dependency_usages_win.winid)
  end)
end

return M
