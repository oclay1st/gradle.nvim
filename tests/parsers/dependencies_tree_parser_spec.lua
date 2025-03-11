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
    -- first dependency
    assert.equal('org.springframework.boot', dependencies[1].group)
    assert.equal('spring-boot-starter-validation', dependencies[1].name)
    assert.equal('3.3.4', dependencies[1].version)
    -- second dependency
    assert.equal('org.springframework.boot', dependencies[2].group)
    assert.equal('spring-boot-starter', dependencies[2].name)
    assert.equal('3.3.4', dependencies[2].version)
    -- third dependency
    assert.equal('org.apache.tomcat.embed', dependencies[3].group)
    assert.equal('tomcat-embed-el', dependencies[3].name)
    assert.equal('10.1.30', dependencies[3].version)
  end)
end)
