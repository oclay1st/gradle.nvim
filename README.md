<br/>
<div align="center">
  <a  href="https://github.com/oclay1st/gradle.nvim">
    <img src="assets/gradle.png" alt="Logo" >
  </a>
</div>

**gradle.nvim** is a Gradle plugin for Neovim.

<div>
  <img src ="assets/screenshot.png">
</div>

## 🔥 Status
This plugin is under **development** and has some known issues, so it is **not** considered stable enough.

## ✨ Features

- Execute tasks and custom commands
- List dependencies and their relationship
- Analyze dependencies usages, conflicts and duplications
- Enqueue multiple goal executions
- Show the output of the commands executions

## ⚡️ Requirements

- Neovim 0.10 or superior

## 📦 Installation

### lazy.nvim

```lua
{
   "oclay1st/gradle.nvim",
   dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
   },
   config = function()
     require("gradle").setup({
      -- options, see default configuration
    })
   end
}
```

## ⚙️  Default configuration

```lua
{
  projects_view = {
    position = 'right',
    size = 68,
  },
  console = {
    show_command_execution = true,
    show_task_execution = true,
    show_dependencies_load_execution = false,
    show_tasks_load_execution = false,
  },
  gradle_executable = 'gradle',
  custom_commands = {
    -- Example: 
    -- {
    --   name = "lazy",
    --   cmd_args = { "build" },
    --   description = "build the project",
    -- }
  }, 
}
```
