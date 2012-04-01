assert = require('chai').assert
{ Node, Resource } = require '../../../'

node = new Node 'test', {}
resource = new Resource node, 'group:staff',
  gid: 42

module.exports =

  '#deps': ->
    deps = resource.deps()
    assert.length deps, 0

  '#siblings': ->
    siblings = resource.siblings()
    assert.length siblings, 0
