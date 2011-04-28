
assert = require 'assert'
Futures = require 'futures'

{ Utils } = require '../src/heru'
{ expand, joinToFuture } = Utils

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
    future.deliver null

    join = Futures.join()
    join.add future

    future = joinToFuture join, "msg"
    future.when ->
      args = Array.prototype.slice.call arguments
      assert.length args, 1

  'joinToFuture: error': ->
    future = Futures.future()
    future.deliver new Error('err')

    join = Futures.join()
    join.add future

    future = joinToFuture join, 'msg'
    future.when ->
      args = Array.prototype.slice.call arguments
      assert.length args, 2
      assert.equal args[0].message, 'msg'
      assert.length args[1], 1
      assert.equal args[1][0][0].message, 'err'

