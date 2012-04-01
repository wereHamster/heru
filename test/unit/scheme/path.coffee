assert = require('chai').assert
{ Node, Resource } = require '../../../'

node = new Node 'test', {}
resource = new Resource node, 'path:/test/dir/{a,b,c/d}',
  type: 'file', mode: 0664, user: 'root', group: 'root'

module.exports =

  '#deps': ->
    deps = resource.deps()

    assert.length deps, 4
    assert.deepEqual deps, [ 'path:/test/dir', 'path:/test/dir/c', 'user:root', 'group:root' ]

  '#siblings': ->
    siblings = resource.siblings()
    assert.length siblings, 2

    assert.ok siblings[0] instanceof Resource
    assert.equal siblings[0].priority(), 0

    assert.ok siblings[1] instanceof Resource
