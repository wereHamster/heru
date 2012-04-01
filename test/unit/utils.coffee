assert = require('chai').assert

{ Resource, Utils } = require '../../'
{ expand, joinToFuture, expandResources, topoSort, idHash, basename, deepCompare } = Utils

module.exports =
  'expand': ->
    assert.deepEqual ['a', 'b'], expand('a,b')
    assert.deepEqual ['a', 'b'], expand('{a,b}')
    assert.deepEqual ['pa', 'pb'], expand('p{a,b}')
    assert.deepEqual ['pas', 'pbs'], expand('p{a,b}s')
    assert.deepEqual ['ab', 'ac', 'd'], expand('a{b,c},d')
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

  'idHash': ->
    assert.equal idHash(''), 1000
    assert.equal idHash('a'), 1097
    assert.equal idHash('bear'), 6035
    assert.equal idHash('mole'), 1712
    assert.equal idHash('zxcvbk'), 7990

  'basename': ->
    assert.equal basename(''), ''
    assert.equal basename('file.gz'), 'file'
    assert.equal basename('file.tar.gz'), 'file'

  'deepCompare': ->
    assert.ok deepCompare {}, {}
    assert.ok deepCompare { x:1 }, { x:1 }
    assert.ok ! deepCompare { x:1 }, {}
    assert.ok ! deepCompare { x:1 }, { x:2 }
    assert.ok ! deepCompare { x:1 }, { y:1 }
