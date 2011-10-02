
global.Futures = require 'futures'
global._ = require 'underscore'

assert = require 'assert'

Resource = require 'resource'

module.exports =

  'merge': ->
    r1 = new Resource 'user:jane', {}, {}
    r2 = new Resource 'user:jane', {}, {}
    r3 = new Resource 'user:andy', {}, {}

    assert.isNull Resource.merge null, null
    assert.isNull Resource.merge null, r2
    assert.isNull Resource.merge r1, null
    assert.isNull Resource.merge r1, r3
    assert.equal r1, Resource.merge r1, r1
    assert.equal r1, Resource.merge r1, r2

