assert = require('chai').assert

global.library = __dirname + '/../'
{ Node } = require '../../'
node = new Node 'test', manifests: [ 'base/test' ]

module.exports =

  '#constructor': ->
    resources = _.keys node.resourceMap

    assert.length resources, 4
    assert.deepEqual resources, [ 'user:bob', 'path:/home/bob', 'path:/home', 'group:bob' ]
