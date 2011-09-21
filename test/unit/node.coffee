
global.Futures = require 'futures'
global._ = require 'underscore'

assert = require 'assert'

Node = require 'node'
node = new Node 'test', manifests: [ 'base/test' ]

module.exports =

  '#constructor': ->
    resources = _.keys node.resourceMap

    assert.length resources, 4
    assert.deepEqual resources, [ 'user:bob', 'path:/home/bob', 'path:/home', 'group:bob' ]

