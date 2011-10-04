
Resource = require 'resource'

# ---------------------------------------------------------------------------
# A manifest is a container for resources. All resources within it share the
# same assets directory.
# ---------------------------------------------------------------------------

class Manifest

  constructor: (node, @base) ->
    @name = @base.split('/').pop()

    @resources = { }
    for uri, initializer of @constructor.prototype
      continue if uri == 'constructor' or Manifest.prototype[uri]
      @resources[uri] = new Resource node, uri, initializer(), @

module.exports = Manifest
