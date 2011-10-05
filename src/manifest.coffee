
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
    for key, initializer of @constructor.prototype
      continue if key == 'constructor' or Manifest.prototype[key]

      uri = @expand key
      @resources[uri] = new Resource node, uri, initializer(), @


  # Expand the string in the context of the manifest. The string has access
  # to all class variables defined in the manifest.
  #
  # TODO: Maybe rename to `render` or something to not clash with the `expand`
  # utility function.
  expand: (str) ->
    render str, @constructor

module.exports = Manifest
