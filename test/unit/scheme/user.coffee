assert = require('chai').assert
{ Node, Resource } = require '../../../'

node = new Node 'test', {}
resource = new Resource node, 'user:bob',
  uid: 42, group: 'staff', home: '/home/bob'

module.exports =

  '#deps': ->
    deps = resource.deps()

    assert.length deps, 1
    assert.deepEqual deps, [ 'group:bob' ]

  '#siblings': ->
    siblings = resource.siblings()
    assert.length siblings, 2

    assert.equal siblings[0].uri.href, 'path:/home/bob'
    assert.equal siblings[0].priority(), 1

    assert.equal siblings[1].uri.href, 'group:bob'
