
assert = require 'assert'
Futures = require 'futures'

{ _ } = require 'underscore'
Resource = require '../src/resource'
{ Utils } = require '../src/heru'
{ expand, joinToFuture, expandResources, topoSort } = Utils

module.exports =
  'a,b': ->
    assert.deepEqual ['a', 'b'], expand('a,b')

  '{a,b}': ->
    assert.deepEqual ['a', 'b'], expand('{a,b}')

  'p{a,b}': ->
    assert.deepEqual ['pa', 'pb'], expand('p{a,b}')

  'p{a,b}s': ->
    assert.deepEqual ['pas', 'pbs'], expand('p{a,b}s')

  'a{b,c},d': ->
    assert.deepEqual ['ab', 'ac', 'd'], expand('a{b,c},d')

  'p{a{b,c},d}s': ->
    assert.deepEqual ['pabs', 'pacs', 'pds'], expand('p{a{b,c},d}s')

  'joinToFuture: no error': ->
    future = Futures.future()
    future.deliver null, 'data1', 'data2'

    join = Futures.join()
    join.add future

    future = joinToFuture join, "msg"
    future.when ->
      args = Array.prototype.slice.call arguments
      assert.deepEqual args, [ null, [ 'data1', 'data2' ] ]

  'joinToFuture: error': ->
    future = Futures.future()
    future.deliver new Error('err')

    join = Futures.join()
    join.add future

    future = joinToFuture join, 'msg'
    future.when ->
      args = Array.prototype.slice.call arguments
      assert.length args, 1
      assert.equal args[0].message, 'msg'
      assert.length args[0].children, 1
      assert.equal args[0].children[0].message, 'err'
