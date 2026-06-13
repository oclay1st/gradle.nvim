local MiniTest = require('mini.test')
local eq = MiniTest.expect.equality
local DependencyTreeParser = require('gradle.parsers.dependency_tree_parser')

local T = MiniTest.new_set()

T['should parse the runtimeClasspath configuration and 3 dependencies'] = function()
  local output_lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.springframework.boot:spring-boot-starter-validation -> 3.3.4',
    '|    +--- org.springframework.boot:spring-boot-starter:3.3.4 (*)',
    '|    +--- org.apache.tomcat.embed:tomcat-embed-el:10.1.30',
  }
  local dependencies = DependencyTreeParser.parse(output_lines)
  eq(3, #dependencies)
  eq('org.springframework.boot', dependencies[1].group)
  eq('spring-boot-starter-validation', dependencies[1].name)
  eq('3.3.4', dependencies[1].version)
  eq('org.springframework.boot', dependencies[2].group)
  eq('spring-boot-starter', dependencies[2].name)
  eq('3.3.4', dependencies[2].version)
  eq('org.apache.tomcat.embed', dependencies[3].group)
  eq('tomcat-embed-el', dependencies[3].name)
  eq('10.1.30', dependencies[3].version)
end

T['should parse project dependencies'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- project :my-lib',
    '+--- project :other-lib (*)',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(2, #deps)
  eq('project', deps[1].type)
  eq('my-lib', deps[1].name)
  eq(false, deps[1].is_duplicate)
  eq('project', deps[2].type)
  eq('other-lib', deps[2].name)
  eq(true, deps[2].is_duplicate)
end

T['should parse conflict versions'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar:1.0 -> 2.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(1, #deps)
  eq('org.foo', deps[1].group)
  eq('bar', deps[1].name)
  eq('2.0', deps[1].version)
  eq('1.0', deps[1].conflict_version)
  eq(false, deps[1].is_duplicate)
end

T['should parse version with arrow but no original version'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar -> 2.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(1, #deps)
  eq('org.foo', deps[1].group)
  eq('bar', deps[1].name)
  eq('2.0', deps[1].version)
  eq(nil, deps[1].conflict_version)
end

T['should mark duplicates with (*)'] = function()
  local lines = {
    "compileClasspath - Compile classpath of source set 'main'.",
    '+--- org.foo:bar:1.0',
    '+--- org.foo:baz:1.0 (*)',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(2, #deps)
  eq(false, deps[1].is_duplicate)
  eq(true, deps[2].is_duplicate)
end

T['should build parent-child hierarchy with nested dependencies'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar:1.0',
    '|    +--- org.foo:baz:1.1',
    '|    \\--- org.foo:qux:1.2',
    '\\--- org.foo:other:2.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(4, #deps)
  eq(nil, deps[1].parent_id)
  eq(deps[1].id, deps[2].parent_id)
  eq(deps[1].id, deps[3].parent_id)
  eq(nil, deps[4].parent_id)
end

T['should handle deeply nested dependencies'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:a:1.0',
    '|    +--- org.foo:b:1.0',
    '|    |    +--- org.foo:c:1.0',
    '|    |    |    \\--- org.foo:d:1.0',
    '|    |    \\--- org.foo:e:1.0',
    '|    \\--- org.foo:f:1.0',
    '\\--- org.foo:g:1.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(7, #deps)
  eq(nil, deps[1].parent_id)
  eq(deps[1].id, deps[2].parent_id)
  eq(deps[2].id, deps[3].parent_id)
  eq(deps[3].id, deps[4].parent_id)
  eq(deps[2].id, deps[5].parent_id)
  eq(deps[1].id, deps[6].parent_id)
  eq(nil, deps[7].parent_id)
end

T['should handle "No dependencies"'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    'No dependencies',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(0, #deps)
end

T['should return empty list for empty input'] = function()
  local deps = DependencyTreeParser.parse({})
  eq(0, #deps)
end

T['should stop parsing deps after empty line'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar:1.0',
    '',
    '\\--- org.foo:baz:1.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(1, #deps)
  eq('org.foo', deps[1].group)
  eq('bar', deps[1].name)
end

T['should handle multiple configurations'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar:1.0',
    '',
    "compileClasspath - Compile classpath of source set 'main'.",
    '+--- org.foo:baz:2.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(2, #deps)
  eq('runtimeClasspath', deps[1].configuration)
  eq('compileClasspath', deps[2].configuration)
end

T['should skip configurations with (n) suffix in description'] = function()
  local lines = {
    "someConfig - some description (n)",
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar:1.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq(1, #deps)
  eq('org.foo', deps[1].group)
end

T['should parse dependency configuration correctly'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar:1.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq('runtimeClasspath', deps[1].configuration)
end

T['should parse version without conflict'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar:1.0',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq('1.0', deps[1].version)
  eq(nil, deps[1].conflict_version)
end

T['should handle group with dots'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- com.example.lib:my-library:1.2.3',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq('com.example.lib', deps[1].group)
  eq('my-library', deps[1].name)
  eq('1.2.3', deps[1].version)
end

T['should handle snapshot versions'] = function()
  local lines = {
    "runtimeClasspath - Runtime classpath of source set 'main'.",
    '+--- org.foo:bar:1.0-SNAPSHOT',
  }
  local deps = DependencyTreeParser.parse(lines)
  eq('1.0-SNAPSHOT', deps[1].version)
end

return T
