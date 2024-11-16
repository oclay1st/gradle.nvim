local DependencyTreeParser = require('gradle.parsers.dependency_tree_parser')

describe('should parse the dependencies', function()
  it('should parse the runtimeClasspath configuration and 3 dependencies', function()
    local output_lines = {
      "runtimeClasspath - Runtime classpath of source set 'main'.",
      '+--- org.springframework.boot:spring-boot-starter-validation -> 3.3.4',
      '|    +--- org.springframework.boot:spring-boot-starter:3.3.4 (*)',
      '|    +--- org.apache.tomcat.embed:tomcat-embed-el:10.1.30',
    }
    local dependencies = DependencyTreeParser.parse(output_lines)
    assert.equal(3, #dependencies)
  end)
end)
