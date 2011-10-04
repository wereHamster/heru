
global.Futures = require 'futures'
global._ = require 'underscore'

assert = require 'assert'

Manifest = require 'manifest'

class TestManifest extends Manifest
  'path:/blackhole': ->
  'user:bob': ->

manifest = new TestManifest null, '/library/test'
module.exports =

  'constructor': ->
    assert.equal manifest.base, '/library/test'
    assert.equal manifest.name, 'test'
    assert.length _.keys(manifest.resources), 2

