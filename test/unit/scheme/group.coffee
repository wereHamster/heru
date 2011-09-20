
global.Futures = require 'futures'
global._ = require 'underscore'

assert = require 'assert'

Resource = require 'resource'
resource = new Resource 'group:staff',
  gid: 42

module.exports =

  '#deps': ->
    deps = resource.deps()
    assert.length deps, 0

  '#siblings': ->
    siblings = resource.siblings()
    assert.length siblings, 0
