
{ Utils } = require '../src/heru'
assert = require 'assert'

expand = Utils.expand
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

