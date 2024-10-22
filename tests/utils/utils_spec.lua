local Utils = require('gradle.utils')

describe('should be awesome', function()
  it('should split a path', function()
    local path = 'root/example/test'
    local split = Utils.split_path(path)
    assert.same({ 'root', 'example', 'test' }, split)
  end)
end)
