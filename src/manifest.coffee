
render = require('mustache').to_html
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


  # Expand the string in the context of the manifest. The string has access
  # to all class variables defined in the manifest.
  expand: (str) ->
    render str, @constructor

module.exports = Manifest
