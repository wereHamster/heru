assert = require('chai').assert

{ Manifest } = require '../../'
class TestManifest extends Manifest
  @var = '42'

  'path:/test/{{ var }}': ->
  'user:bob': ->

manifest = new TestManifest null, '/library/test'
module.exports =

  'constructor': ->
    assert.equal manifest.base, '/library/test'
    assert.equal manifest.name, 'test'

    assert.length _.keys(manifest.resources), 2
    assert.deepEqual _.keys(manifest.resources), [ 'path:/test/42', 'user:bob' ]
