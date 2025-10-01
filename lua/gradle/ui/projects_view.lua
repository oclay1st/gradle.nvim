local NuiTree = require('nui.tree')
local NuiLine = require('nui.line')
local NuiSplit = require('nui.split')
local DependenciesView = require('gradle.ui.dependencies_view')
local HelpView = require('gradle.ui.help_view')
local Sources = require('gradle.sources')
local Utils = require('gradle.utils')
local CommandBuilder = require('gradle.utils.cmd_builder')
local Console = require('gradle.utils.console')
local GradleConfig = require('gradle.config')
local highlights = require('gradle.config.highlights')

local node_type_props = {
  custom_command = {
    icon = GradleConfig.options.icons.command,
    started_state_msg = ' ..running',
    pending_state_msg = ' ..pending',
  },
  custom_commands = { icon = GradleConfig.options.icons.tool_folder },
  task = {
    icon = GradleConfig.options.icons.tool,
    started_state_msg = ' ..running',
    pending_state_msg = ' ..pending',
  },
  tasks = {
    icon = GradleConfig.options.icons.tool_folder,
    started_state_msg = ' ..loading',
    pending_state_msg = ' ..pending',
  },
  task_group = { icon = GradleConfig.options.icons.tool_folder },
  module_dependency = { icon = GradleConfig.options.icons.package },
  project_dependency = { icon = GradleConfig.options.icons.gradle },
  dependencies = {
    icon = GradleConfig.options.icons.tool_folder,
    started_state_msg = ' ..loading',
    pending_state_msg = ' ..pending',
  },
  dependency_configuration = { icon = GradleConfig.options.icons.tool_folder },
  modules = { icon = GradleConfig.options.icons.tool_folder },
  project = { icon = GradleConfig.options.icons.project },
}

---@class ProjectView
---@field private _win NuiSplit
---@field private _tree NuiTree
---@field private _menu_header_line NuiLine
---@field private _projects_header_line NuiLine
---@field private _is_visible boolean
---@field projects Project[]
local ProjectView = {}

ProjectView.__index = ProjectView

---Create a new ProjectView
---@param projects? Project[]
---@return ProjectView
function ProjectView.new(projects)
  return setmetatable({
    projects = projects or {},
  }, ProjectView)
end

---@private Lookup for a project inside a list of projects and modules
---@param id string
---@return Project
function ProjectView:_lookup_project(id)
  local project ---@type Project

  ---@param projects Project[]
  local function _lookup(projects)
    for _, item in ipairs(projects) do
      if item.id == id then
        project = item
      end
      _lookup(item.modules)
    end
  end
  _lookup(self.projects)
  return assert(project, 'Project not found')
end

---Execute the command node
---@param node NuiTree.Node
---@param project Project
function ProjectView:_load_custom_command_node(node, project)
  local command = CommandBuilder.build_gradle_cmd(project.root_path, node.extra.cmd_args)
  local show_output = GradleConfig.options.console.show_command_execution
  Console.execute_command(command.cmd, command.args, show_output, function(state)
    vim.schedule(function()
      node.state = state
      self._tree:render()
    end)
  end)
end

---Execute the task node
---@param node NuiTree.Node
---@param project Project
function ProjectView:_load_task_node(node, project)
  local command = CommandBuilder.build_gradle_cmd(project.root_path, { node.extra.cmd_arg })
  local show_output = GradleConfig.options.console.show_task_execution
  Console.execute_command(command.cmd, command.args, show_output, function(state)
    vim.schedule(function()
      node.state = state
      self._tree:render()
    end)
  end)
end

---Load the tasks nodes for the tree
---@param node NuiTree.Node
---@param project Project
---@param force? boolean
---@param on_success? fun()
function ProjectView:_load_tasks_nodes(node, project, force, on_success)
  Sources.load_project_tasks(project.root_path, force, function(state, tasks)
    vim.schedule(function()
      if state == Utils.SUCCEED_STATE then
        project:set_tasks(tasks)
        self._tree:set_nodes({}, node:get_id())
        local group_nodes = {}
        for _, group_item in ipairs(project:group_tasks_by_group_name()) do
          local tasks_nodes = {}
          for index, task in ipairs(group_item.tasks) do
            local task_node = NuiTree.Node({
              id = Utils.uuid(),
              text = task.name,
              type = 'task',
              project_id = project.id,
              is_favorite = project:has_favorite_command(task.group .. ':' .. task.name, 'task'),
              extra = task,
            })
            tasks_nodes[index] = task_node
          end
          local group_node = NuiTree.Node({
            id = Utils.uuid(),
            text = group_item.group,
            type = 'task_group',
            project_id = project.id,
          }, tasks_nodes)

          table.insert(group_nodes, group_node)
        end
        node.is_loaded = true
        self._tree:set_nodes(group_nodes, node._id)
        if on_success then
          on_success()
        else
          node:expand()
        end
      end
      node.state = state
      self._tree:render()
    end)
  end)
end

---Load the dependency nodes for the tree
---@param node NuiTree.Node
---@param project Project
---@param force? boolean
---@param on_success? fun()
function ProjectView:_load_dependencies_nodes(node, project, force, on_success)
  Sources.load_project_dependencies(project.root_path, force, function(state, dependencies)
    vim.schedule(function()
      if state == Utils.SUCCEED_STATE then
        project:set_dependencies(dependencies)
        self._tree:set_nodes({}, node:get_id())
        for _, group_item in ipairs(project:group_dependencies_by_configuration()) do
          local configuration_node = NuiTree.Node({
            id = Utils.uuid(),
            text = group_item.configuration,
            type = 'dependency_configuration',
            project_id = project.id,
          })
          self._tree:add_node(configuration_node, node:get_id())
          for _, dependency in ipairs(group_item.dependencies) do
            local dependency_node = NuiTree.Node({
              id = dependency.id,
              text = dependency:get_compact_name(),
              type = dependency.type .. '_dependency',
              project_id = project.id,
              is_duplicate = dependency.is_duplicate,
            })
            local _parent_id = dependency.parent_id and '-' .. dependency.parent_id
              or configuration_node:get_id()
            self._tree:add_node(dependency_node, _parent_id)
          end
        end
        node.is_loaded = true
        if on_success then
          on_success()
        else
          node:expand()
        end
      end
      node.state = state
      self._tree:render()
    end)
  end)
end

---@private Create a project node
---@param project Project
---@return NuiTree.Node
function ProjectView:_create_project_node(project)
  ---Map command nodes
  local custom_command_nodes = {}
  for index, command in ipairs(project.custom_commands) do
    custom_command_nodes[index] = NuiTree.Node({
      text = command.name,
      type = 'custom_command',
      started_state_message = 'running',
      project_id = project.id,
      is_favorite = project:has_favorite_command(command.name, 'custom_command'),
      extra = command,
    })
  end

  ---Map Commands node
  local commands_node = NuiTree.Node({
    text = 'Commands',
    type = 'custom_commands',
    project_id = project.id,
  }, custom_command_nodes)

  ---Map Tasks node
  local tasks_node = NuiTree.Node({
    id = project.id .. '-tasks',
    text = 'Tasks',
    type = 'tasks',
    is_loaded = false,
    started_state_message = 'loading',
    project_id = project.id,
  })

  ---Map Dependencies node
  local dependencies_node = NuiTree.Node({
    id = project.id .. '-dependencies',
    text = 'Dependencies',
    type = 'dependencies',
    is_loaded = false,
    started_state_message = 'loading',
    project_id = project.id,
  })

  local modules_nodes = {}
  for _, module in ipairs(project.modules) do
    local module_node = self:_create_project_node(module)
    table.insert(modules_nodes, module_node)
  end

  local modules_node = NuiTree.Node({
    text = 'Modules',
    type = 'modules',
    project_id = project.id,
  }, modules_nodes)

  local project_nodes = { tasks_node }

  if #custom_command_nodes > 0 then
    table.insert(project_nodes, 1, commands_node)
  end

  if project.build_gradle_path then -- if not build gradle is probably a root project
    table.insert(project_nodes, dependencies_node)
  end

  if #modules_nodes > 0 then
    table.insert(project_nodes, modules_node)
  end

  return NuiTree.Node({
    id = project.id,
    text = project.name,
    type = 'project',
    project_id = project.id,
  }, project_nodes)
end

---Create the tree component
function ProjectView:_render_projects_tree()
  self._tree = NuiTree({
    ns_id = GradleConfig.namespace,
    bufnr = self._win.bufnr,
    prepare_node = function(node)
      local props = node_type_props[node.type]
      local line = NuiLine()
      line:append(' ' .. string.rep('  ', node:get_depth() - 1))

      if node:has_children() or node.is_loaded == false then
        line:append(node:is_expanded() and ' ' or ' ', highlights.SPECIAL)
      else
        line:append('  ')
      end
      local icon = node.is_favorite and GradleConfig.options.icons.favorite or props.icon
      line:append(icon .. ' ', highlights.SPECIAL)
      if node.is_duplicate and not node:has_children() then
        line:append(node.text, highlights.COMMENT)
      else
        line:append(node.text)
      end
      if node.state == Utils.STARTED_STATE then
        line:append(props.started_state_msg, highlights.INFO)
      elseif node.state == Utils.PENDING_STATE then
        line:append(props.pending_state_msg, highlights.WARN)
      end
      if node.extra and node.extra.description then
        line:append(' (' .. node.extra.description .. ')', highlights.COMMENT)
      end
      return line
    end,
  })
  self:_render_tree_nodes()
end

---@private Render project tree
function ProjectView:_render_tree_nodes()
  local nodes = {}
  for index, project in ipairs(self.projects) do
    nodes[index] = self:_create_project_node(project)
  end
  self._tree:set_nodes(nodes)
  self._tree:render(3)
  self._menu_header_line:highlight(self._win.bufnr, GradleConfig.namespace, 1)
  self._projects_header_line:highlight(self._win.bufnr, GradleConfig.namespace, 2)
  self._tree:render()
end

---@private Create the header line
function ProjectView:_render_menu_header_line()
  local line = NuiLine()
  local separator = ' '
  line:append(GradleConfig.options.icons.entry, highlights.SPECIAL)
  line:append(GradleConfig.options.icons.new, highlights.SPECIAL)
  line:append(' Create')
  line:append('<c>' .. separator, highlights.COMMENT)
  line:append(GradleConfig.options.icons.tree, highlights.SPECIAL)
  line:append(' Analyze')
  line:append('<a>' .. separator, highlights.COMMENT)
  line:append(GradleConfig.options.icons.command, highlights.SPECIAL)
  line:append(' Execute')
  line:append('<e>' .. separator, highlights.COMMENT)
  line:append(GradleConfig.options.icons.favorite, highlights.SPECIAL)
  line:append(' Favorites')
  line:append('<f>' .. separator, highlights.COMMENT)
  line:append(GradleConfig.options.icons.help, highlights.SPECIAL)
  line:append(' Help')
  line:append('<?>' .. separator, highlights.COMMENT)
  self._menu_header_line = line
  self._menu_header_line:render(self._win.bufnr, GradleConfig.namespace, 1)
end

---@private Create the projects header line
---@param line NuiLine
function ProjectView:_render_projects_header_line(line)
  self._projects_header_line = line
  self._projects_header_line:render(self._win.bufnr, GradleConfig.namespace, 2)
end

---@private Create the projects header line
function ProjectView:_create_projects_line()
  local line = NuiLine()
  line:append(GradleConfig.options.icons.gradle .. ' Gradle Projects:', highlights.COMMENT)
  if #self.projects == 0 then
    line:append(' (Projects not found, create a new one!) ', highlights.COMMENT)
  end
  return line
end

---@private Create the projects scanning line
function ProjectView:_create_projects_scanning_line()
  local line = NuiLine()
  line:append(' Projects:', highlights.COMMENT)
  line:append(' ...scanning directory ', highlights.COMMENT)
  return line
end

---@private Setup key maps
function ProjectView:_setup_win_maps()
  self._win:map('n', 'g', function()
    require('gradle').show_argument_view()
  end, { noremap = true })

  self._win:map('n', { '<esc>', 'q' }, function()
    self:hide()
  end)

  self._win:map('n', 'c', function()
    require('gradle').show_initializer_view()
  end)

  self._win:map('n', 'e', function()
    require('gradle').show_execution_view()
  end)

  self._win:map('n', 'a', function()
    local node = self._tree:get_node()
    if node == nil then
      vim.notify('Not project selected')
      return
    end
    local project = self:_lookup_project(node.project_id)
    local dependencies_node = self._tree:get_node('-' .. project.id .. '-dependencies')
    if not dependencies_node then
      vim.notify('Not dependencies found on project: ' .. project.root_path)
      return
    end
    if dependencies_node.is_loaded then
      local dependency_view = DependenciesView.new(project.name, project.dependencies)
      dependency_view:mount()
    else
      self:_load_dependencies_nodes(dependencies_node, project, false, function()
        local dependency_view = DependenciesView.new(project.name, project.dependencies)
        dependency_view:mount()
      end)
    end
  end, { noremap = true, nowait = true })

  self._win:map('n', 'f', function()
    local _projects = self.projects
    local node = self._tree:get_node()
    if node ~= nil then
      local project = self:_lookup_project(node.project_id)
      _projects = { project }
    end
    require('gradle').show_favorite_commands(_projects)
  end, { noremap = true })

  self._win:map('n', 'F', function()
    local node = self._tree:get_node()
    if node == nil then
      return
    end
    local project = self:_lookup_project(node.project_id)
    if node.type == 'custom_command' or node.type == 'task' then
      if not node.is_favorite then
        node.is_favorite = true
        Sources.add_favorite_command(node.extra:as_favorite(), project)
        vim.notify(node.text .. ' was added to favorites successfully')
      else
        node.is_favorite = false
        Sources.remove_favorite_command(node.extra:as_favorite(), project)
        vim.notify(node.text .. ' removed from favorites successfully')
      end
      self._tree:render()
    end
  end, { noremap = true })

  self._win:map('n', { '<c-r>' }, function()
    local node = self._tree:get_node()
    if node == nil then
      return
    end
    local project = self:_lookup_project(node.project_id)
    if
      node.type == 'dependencies'
      or node.type == 'dependency_configuration'
      or node.type == 'module_dependency'
      or node.type == 'project_dependency'
    then
      local dependencies_node = self._tree:get_node('-' .. project.id .. '-dependencies')
      assert(dependencies_node, "Dependencies node doesn't exist on project: " .. project.root_path)
      self:_load_dependencies_nodes(dependencies_node, project, true, function()
        vim.notify('Dependencies reloaded successfully')
      end)
    end
    if node.type == 'tasks' or node.type == 'task_group' or node.type == 'task' then
      local tasks_node = self._tree:get_node('-' .. project.id .. '-tasks')
      assert(tasks_node, "Tasks node doesn't exist on project: " .. project.root_path)
      self:_load_tasks_nodes(tasks_node, project, true, function()
        vim.notify('Tasks reloaded successfully')
      end)
    end
  end, { noremap = true, nowait = true })

  self._win:map('n', '?', function()
    HelpView.mount()
  end)

  self._win:map('n', { '<enter>', '<2-LeftMouse>' }, function()
    local node = self._tree:get_node()
    if node == nil then
      return
    end
    local updated = false
    local project = self:_lookup_project(node.project_id)
    if node.type == 'custom_command' then
      self:_load_custom_command_node(node, project)
    elseif node.type == 'task' then
      self:_load_task_node(node, project)
    elseif node.type == 'tasks' and not node.is_loaded then
      self:_load_tasks_nodes(node, project)
    elseif node.type == 'dependencies' and not node.is_loaded then
      self:_load_dependencies_nodes(node, project)
    end
    if node:is_expanded() then
      updated = node:collapse() or updated
    else
      updated = node:expand() or updated
    end
    if updated then
      self._tree:render()
    end
  end, { noremap = true, nowait = true })
end

---@private Create win component
function ProjectView:_render_win()
  self._win = NuiSplit({
    ns_id = GradleConfig.namespace,
    relative = 'editor',
    position = GradleConfig.options.projects_view.position,
    size = GradleConfig.options.projects_view.size,
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
  })
  self._win:mount()
  self._is_visible = true
end

---Mount the explorer component
function ProjectView:mount()
  ---Mount the component
  self:_render_win()
  ---Create the header  line
  self:_render_menu_header_line()
  ---Create the Projects line
  local _line = self:_create_projects_line()
  self:_render_projects_header_line(_line)
  ---Create the tree
  self:_render_projects_tree()
  ---Setup maps
  self:_setup_win_maps()
end

---Hide the ui
function ProjectView:hide()
  self._win:hide()
  self._is_visible = false
end

---Show the ui
function ProjectView:show()
  self._win:show()
  self._is_visible = true
end

---Toggle the ui
function ProjectView:toggle()
  if self._is_visible then
    self:hide()
  else
    self:show()
  end
end

---Show the ui
function ProjectView:unmount()
  self._win:unmount()
  self._is_visible = false
end

---Set project loading
---@param loading boolean
function ProjectView:set_loading(loading)
  local line
  if loading then
    line = self:_create_projects_scanning_line()
  else
    line = self:_create_projects_line()
  end
  vim.api.nvim_set_option_value('modifiable', true, { buf = self._win.bufnr })
  vim.api.nvim_set_option_value('readonly', false, { buf = self._win.bufnr })
  self:_render_projects_header_line(line)
  vim.api.nvim_set_option_value('modifiable', false, { buf = self._win.bufnr })
  vim.api.nvim_set_option_value('readonly', true, { buf = self._win.bufnr })
end

---Refresh projects
---@param projects Project[]
function ProjectView:refresh_projects(projects)
  self.projects = projects
  self:_render_tree_nodes()
end

return ProjectView
